#ifndef MOD_CONDUCTOR_DESKTOP_REQUESTS_H_
#define MOD_CONDUCTOR_DESKTOP_REQUESTS_H_

#include <cstdint>
#include <deque>
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
  if (args[0] != "--workspace" && args[0] != "--archive") return invalid;
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
};
struct Snapshot {
  size_t count;
  std::optional<Request> first;
};
class Requests {
 public:
  bool Add(const Arguments& input) {
    auto args = Screen(input);
    std::lock_guard<std::mutex> guard(mutex_);
    if (stopping_) return false;
    if (args.empty()) return true;
    for (const auto& item : queue_)
      if (item.arguments == args) return true;
    if (queue_.size() >= 16) return false;
    queue_.push_back({++serial_, std::move(args)});
    return true;
  }
  Snapshot Read() {
    std::lock_guard<std::mutex> guard(mutex_);
    return {queue_.size(), queue_.empty()
                               ? std::nullopt
                               : std::optional<Request>(queue_.front())};
  }
  void Dismiss(int64_t id) {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!queue_.empty() && queue_.front().id == id) queue_.pop_front();
  }
  void Stop() {
    std::lock_guard<std::mutex> guard(mutex_);
    stopping_ = true;
  }

 private:
  std::mutex mutex_;
  std::deque<Request> queue_;
  int64_t serial_ = 0;
  bool stopping_ = false;
};
}  // namespace desktop
#endif
