#include "nxm_delivery.h"
#include <cstring>
#ifdef _WIN32
#include <windows.h>
#include <bcrypt.h>
#else
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <poll.h>
#include <glib.h>
#endif
namespace desktop {
std::optional<std::array<uint8_t,32>> NxmFingerprint(const std::string& input) {
  std::array<uint8_t,32> digest{};
#ifdef _WIN32
  BCRYPT_ALG_HANDLE algorithm = nullptr;
  if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) != 0) return std::nullopt;
  const auto status = BCryptHash(algorithm, nullptr, 0, reinterpret_cast<PUCHAR>(const_cast<char*>(input.data())), static_cast<ULONG>(input.size()), digest.data(), static_cast<ULONG>(digest.size()));
  BCryptCloseAlgorithmProvider(algorithm, 0);
  if (status != 0) return std::nullopt;
#else
  auto* checksum = g_checksum_new(G_CHECKSUM_SHA256);
  if (!checksum) return std::nullopt;
  g_checksum_update(checksum, reinterpret_cast<const guchar*>(input.data()), input.size());
  gsize length = digest.size();
  g_checksum_get_digest(checksum, digest.data(), &length);
  g_checksum_free(checksum);
#endif
  return digest;
}

NxmDelivery::NxmDelivery(Requests& requests, std::function<void()> changed)
  : requests_(requests), changed_(std::move(changed)), worker_([this] { Run(); }) {}
NxmDelivery::~NxmDelivery() { Stop(); }
void NxmDelivery::Stop() {
  { std::lock_guard<std::mutex> guard(mutex_); stopping_ = true; }
  event_.notify_one();
  if (worker_.joinable()) worker_.join();
}
void NxmDelivery::Notify() {
  { std::lock_guard<std::mutex> guard(mutex_); notified_ = true; }
  event_.notify_one();
}
void NxmDelivery::Configure(Ingress value) {
  { std::lock_guard<std::mutex> guard(mutex_); target_ = std::move(value); notified_ = true; }
  requests_.Retry();
  event_.notify_one();
}
void NxmDelivery::Run() {
  std::unique_lock<std::mutex> lock(mutex_);
  while (!stopping_) {
    event_.wait(lock, [this] { return stopping_ || notified_; });
    if (stopping_) break;
    notified_ = false;
    const auto target = target_;
    if (target.pid <= 0 || target.capability.size() != 32) continue;
    lock.unlock();
    while (const auto request = requests_.Pending()) {
      const bool success = Send(target, *request, false);
      if (!requests_.Delivered(request->serial, success)) Send(target, *request, true);
      changed_();
      { std::lock_guard<std::mutex> guard(mutex_); if (stopping_) break; }
    }
    lock.lock();
  }
}
bool NxmDelivery::Send(const Ingress& target, const PrivateRequest& request, bool dismiss) {
  std::vector<uint8_t> frame;
  frame.push_back(dismiss ? 2 : 1);
  frame.insert(frame.end(), target.capability.begin(), target.capability.end());
  frame.insert(frame.end(), request.id.begin(), request.id.end());
  uint32_t length = dismiss ? 0 : static_cast<uint32_t>(request.input.size());
  for (int shift = 0; shift < 32; shift += 8) frame.push_back((length >> shift) & 255);
  if (!dismiss) frame.insert(frame.end(), request.input.begin(), request.input.end());
  std::array<uint8_t,16> answer{};
#ifdef _WIN32
  std::wstring path = L"\\\\.\\pipe\\";
  if (target.endpoint.size() > 200) return false;
  for (unsigned char c : target.endpoint) { if (c < 33 || c > 126 || c == '\\' || c == '/') return false; path += c; }
  if (!WaitNamedPipeW(path.c_str(), 5000)) return false;
  HANDLE pipe = CreateFileW(path.c_str(), GENERIC_READ|GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nullptr);
  if (pipe == INVALID_HANDLE_VALUE) return false;
  ULONG pid = 0;
  bool valid = GetNamedPipeServerProcessId(pipe, &pid) && pid == static_cast<ULONG>(target.pid);
  const ULONGLONG deadline = GetTickCount64() + 5000;
  auto transfer = [&](void* bytes, DWORD size, bool write) {
    DWORD offset = 0;
    while (offset < size) {
      const ULONGLONG now = GetTickCount64();
      if (now >= deadline) return false;
      OVERLAPPED operation{};
      operation.hEvent = CreateEvent(nullptr, TRUE, FALSE, nullptr);
      DWORD count = 0;
      BOOL ok = write ? WriteFile(pipe, static_cast<char*>(bytes)+offset, size-offset, &count, &operation)
                      : ReadFile(pipe, static_cast<char*>(bytes)+offset, size-offset, &count, &operation);
      if (!ok && GetLastError() == ERROR_IO_PENDING) {
        if (WaitForSingleObject(operation.hEvent, static_cast<DWORD>(deadline - now)) == WAIT_OBJECT_0) ok = GetOverlappedResult(pipe, &operation, &count, FALSE);
        else { CancelIoEx(pipe, &operation); GetOverlappedResult(pipe, &operation, &count, TRUE); }
      }
      CloseHandle(operation.hEvent);
      if (!ok || !count) return false;
      offset += count;
    }
    return true;
  };
  valid = valid && transfer(frame.data(), static_cast<DWORD>(frame.size()), true) && transfer(answer.data(), 16, false);
  CloseHandle(pipe);
#else
  if (target.endpoint.size() >= sizeof(sockaddr_un::sun_path)) return false;
  int socket = ::socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0);
  if (socket < 0) return false;
  sockaddr_un address{}; address.sun_family = AF_UNIX;
  std::memcpy(address.sun_path, target.endpoint.c_str(), target.endpoint.size()+1);
  bool valid = connect(socket, reinterpret_cast<sockaddr*>(&address), sizeof(address)) == 0;
  ucred peer{}; socklen_t size = sizeof(peer);
  valid = valid && getsockopt(socket, SOL_SOCKET, SO_PEERCRED, &peer, &size) == 0 && peer.pid == target.pid && peer.uid == getuid();
  const auto deadline = std::chrono::steady_clock::now()+std::chrono::seconds(5);
  auto transfer = [&](uint8_t* bytes, size_t length, bool write) {
    size_t offset = 0;
    while (offset < length) {
      const auto wait = std::chrono::duration_cast<std::chrono::milliseconds>(deadline-std::chrono::steady_clock::now()).count();
      if (wait <= 0) return false;
      pollfd descriptor{socket, static_cast<short>(write ? POLLOUT : POLLIN), 0};
      if (poll(&descriptor, 1, static_cast<int>(wait)) != 1) return false;
      auto count = write ? send(socket, bytes+offset, length-offset, MSG_NOSIGNAL) : recv(socket, bytes+offset, length-offset, 0);
      if (count <= 0) return false;
      offset += static_cast<size_t>(count);
    }
    return true;
  };
  valid = valid && transfer(frame.data(), frame.size(), true) && transfer(answer.data(), answer.size(), false);
  close(socket);
#endif
  std::fill(frame.begin(), frame.end(), 0);
  return valid && answer == request.id;
}
}
