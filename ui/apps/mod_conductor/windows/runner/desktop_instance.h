#ifndef MOD_CONDUCTOR_DESKTOP_INSTANCE_H_
#define MOD_CONDUCTOR_DESKTOP_INSTANCE_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

#include "desktop_handoff.h"
#include "../../runner/nxm_delivery.h"

class DesktopInstance {
 public:
  static constexpr UINT kRequestMessage = WM_APP + 58;
  DesktopInstance();
  ~DesktopInstance();
  bool Primary() const;
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
  flutter::EncodableValue State();
  HWND window_ = nullptr;
  desktop::Requests requests_;
  DesktopHandoff handoff_;
  std::unique_ptr<desktop::NxmDelivery> nxm_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};
#endif
