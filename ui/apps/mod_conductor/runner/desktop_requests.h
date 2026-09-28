#ifndef MOD_CONDUCTOR_DESKTOP_REQUESTS_H_
#define MOD_CONDUCTOR_DESKTOP_REQUESTS_H_

#include <cstdint>
#include <array>
#include <random>
#include <algorithm>
#include <deque>
#include <iterator>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

namespace desktop {
using Arguments = std::vector<std::string>;

inline Arguments Screen(const Arguments& args) {
  const Arguments invalid = {"--invalid-request"};
  const Arguments unsupported = {"--unsupported-link"};
  if (args.size() > 8) return invalid;
  for (const auto& arg : args) {
    if (arg.size() > 4096) return invalid;
    for (unsigned char c : arg)
      if (c < 32 || c == 127) return invalid;
  }
  if (args.empty()) return args;
  if (args.size() == 1 &&
      (args[0] == "--invalid-request" || args[0] == "--unsupported-link"))
    return args;
  if (args.size() == 1 && args[0].rfind("file://", 0) == 0)
    return args;
  if (args.size() != 2) return invalid;
  if (args[0] == "--uri") {
    const auto& uri = args[1];
    size_t prefix = 0;
    for (const auto* route :
         {"modconductor://workspace/", "modconductor://archives/"}) {
      if (uri.rfind(route, 0) == 0) prefix = std::string(route).size();
    }
    if (prefix == 0 || uri.size() != prefix + 32) return unsupported;
    for (size_t i = prefix; i < uri.size(); ++i) {
      const auto c = uri[i];
      if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') ||
            (c >= 'A' && c <= 'F')))
        return unsupported;
    }
    return args;
  }
  if (args[0] != "--workspace" && args[0] != "--archive" &&
      args[0] != "--profile") return invalid;
  const auto& path = args[1];
#ifdef _WIN32
  const bool absolute = (path.size() > 2 && path[1] == ':' &&
                         (path[2] == '\\' || path[2] == '/')) ||
                        path.rfind("\\\\", 0) == 0;
#else
  const bool absolute = !path.empty() && path[0] == '/';
#endif
  return absolute ? args : invalid;
}

struct Request {
  int64_t id;
  Arguments arguments;
  std::string reference;
  bool private_pending = false;
  bool delivery_failed = false;
};
struct Snapshot { size_t count; std::optional<Request> first; };
struct PrivateRequest { int64_t serial; std::array<uint8_t, 16> id; std::string input; };
inline bool IsNxm(const Arguments& args) {
  if (args.size() != 2 || args[0] != "--uri" || args[1].size() > 4096 || args[1].size() < 6) return false;
  std::string prefix = args[1].substr(0,6);
  for (auto& c : prefix) if (c >= 'A' && c <= 'Z') c += 'a' - 'A';
  if (prefix != "nxm://") return false;
  for (unsigned char c : args[1]) if (c < 32 || c == 127) return false;
  return true;
}
inline std::string Reference(const std::array<uint8_t,16>& id) {
  static constexpr int order[] = {3,2,1,0,5,4,7,6,8,9,10,11,12,13,14,15};
  std::string value;
  for (auto i : order) { value += "0123456789abcdef"[id[i]>>4]; value += "0123456789abcdef"[id[i]&15]; }
  return value;
}
std::optional<std::array<uint8_t,32>> NxmFingerprint(const std::string& input);
class Requests {
 public:
  bool Add(const Arguments& input) {
    const bool nxm = IsNxm(input);
    auto args = nxm ? Arguments{} : Screen(input);
    const auto fingerprint = nxm ? NxmFingerprint(input[1]) : std::optional<std::array<uint8_t,32>>{};
    if (nxm && !fingerprint) return false;
    std::lock_guard<std::mutex> guard(mutex_);
    if (stopping_) return false;
    if (!nxm && args.empty()) return true;
    for (auto item = queue_.begin(); item != queue_.end(); ++item)
      if (nxm ? item->fingerprint == fingerprint : (!item->view.private_pending && item->view.reference.empty() && item->view.arguments == args)) {
        if (nxm) std::rotate(queue_.begin(), item, std::next(item));
        return true;
      }
    if (queue_.size() >= 16) return false;
    Entry entry;
    entry.view.id = ++serial_;
    entry.view.arguments = std::move(args);
    entry.view.private_pending = nxm;
    if (nxm) {
      entry.raw = input[1];
      entry.fingerprint = fingerprint;
      std::random_device random;
      for (auto& value : entry.key) value = static_cast<uint8_t>(random());
      entry.view.reference = Reference(entry.key);
    }
    if (nxm)
      queue_.push_front(std::move(entry));
    else
      queue_.push_back(std::move(entry));
    return true;
  }
  Snapshot Read() {
    std::lock_guard<std::mutex> guard(mutex_);
    return {queue_.size(), queue_.empty() ? std::nullopt : std::optional<Request>(queue_.front().view)};
  }
  std::optional<PrivateRequest> Pending() {
    std::lock_guard<std::mutex> guard(mutex_);
    for (const auto& entry : queue_)
      if (entry.view.private_pending && !entry.view.delivery_failed) return PrivateRequest{entry.view.id, entry.key, entry.raw};
    return std::nullopt;
  }
  bool Delivered(int64_t serial, bool success) {
    std::lock_guard<std::mutex> guard(mutex_);
    for (auto& entry : queue_) if (entry.view.id == serial) {
      entry.view.delivery_failed = !success;
      if (success) {
        entry.view.private_pending = false;
        std::fill(entry.raw.begin(), entry.raw.end(), '\0');
        entry.raw.clear();
      }
      return true;
    }
    return false;
  }
  void Retry() {
    std::lock_guard<std::mutex> guard(mutex_);
    for (auto& entry : queue_) entry.view.delivery_failed = false;
  }
  void Dismiss(int64_t id) {
    std::lock_guard<std::mutex> guard(mutex_);
    const auto item = std::find_if(queue_.begin(), queue_.end(),
                                   [id](const Entry& entry) { return entry.view.id == id; });
    if (item != queue_.end()) queue_.erase(item);
  }
  void Stop() {
    std::lock_guard<std::mutex> guard(mutex_);
    stopping_ = true;
    queue_.clear();
  }
 private:
  struct Entry { Request view; std::string raw; std::array<uint8_t,16> key{}; std::optional<std::array<uint8_t,32>> fingerprint; };
  std::mutex mutex_;
  std::deque<Entry> queue_;
  int64_t serial_ = 0;
  bool stopping_ = false;
};
}  // namespace desktop
#endif
