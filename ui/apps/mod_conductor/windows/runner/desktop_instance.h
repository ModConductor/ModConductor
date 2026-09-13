#ifndef MOD_CONDUCTOR_DESKTOP_INSTANCE_H_
#define MOD_CONDUCTOR_DESKTOP_INSTANCE_H_
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <atomic>
#include <memory>
#include <thread>

#include "../../runner/nxm_delivery.h"

class DesktopInstance {
 public:
  static constexpr UINT kRequestMessage = WM_APP + 58;
  DesktopInstance();
  ~DesktopInstance();
  bool Primary() const { return primary_; }
  bool Forward(const desktop::Arguments& arguments);
  void Attach(flutter::BinaryMessenger* messenger, HWND window);
  bool Add(const desktop::Arguments& arguments) {
    const bool result = requests_.Add(arguments);
    if (nxm_) nxm_->Notify();
    return result;
  }
  void Changed(bool present);
  void Detach();

 private:
  bool Transfer(HANDLE pipe, void* bytes, DWORD size, bool write,
                DWORD& transferred);
  void Listen();
  flutter::EncodableValue State();
  HANDLE mutex_ = nullptr, stop_ = nullptr, ready_ = nullptr;
  std::atomic<bool> available_{false};
  bool primary_ = false;
  HWND window_ = nullptr;
  std::wstring pipe_name_, pipe_descriptor_;
  std::thread listener_;
  desktop::Requests requests_;
  std::unique_ptr<desktop::NxmDelivery> nxm_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};
#endif
