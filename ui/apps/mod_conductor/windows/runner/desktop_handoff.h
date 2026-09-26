#ifndef MOD_CONDUCTOR_DESKTOP_HANDOFF_H_
#define MOD_CONDUCTOR_DESKTOP_HANDOFF_H_

#include <windows.h>

#include <atomic>
#include <functional>
#include <optional>
#include <thread>

#include "desktop_identity.h"
#include "../../runner/desktop_requests.h"

class DesktopHandoff {
 public:
  explicit DesktopHandoff(desktop::Requests& requests);
  ~DesktopHandoff();

  DesktopHandoff(const DesktopHandoff&) = delete;
  DesktopHandoff& operator=(const DesktopHandoff&) = delete;

  bool Primary() const { return identity_.Primary(); }
  bool Available() const { return available_.load(); }
  bool Forward(const desktop::Arguments& arguments);
  void Start(std::function<void(bool)> on_request);
  void Stop();

 private:
  bool Transfer(HANDLE pipe, void* bytes, DWORD size, bool write,
                DWORD& transferred);
  std::optional<bool> Connect(HANDLE pipe);
  void Receive(HANDLE pipe);
  void Listen();

  DesktopIdentity identity_;
  desktop::Requests& requests_;
  HANDLE stop_ = nullptr, ready_ = nullptr;
  std::atomic<bool> available_{false};
  std::thread listener_;
  std::function<void(bool)> on_request_;
};

#endif
