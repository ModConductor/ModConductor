#include "desktop_instance.h"

#include <flutter/standard_method_codec.h>

DesktopInstance::DesktopInstance() : handoff_(requests_) {}

DesktopInstance::~DesktopInstance() { Detach(); }

bool DesktopInstance::Primary() const { return handoff_.Primary(); }

bool DesktopInstance::Forward(const desktop::Arguments& arguments) {
  return handoff_.Forward(arguments);
}

void DesktopInstance::Detach() {
  requests_.Stop();
  handoff_.Stop();
  nxm_.reset();
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
    channel_.reset();
  }
}

flutter::EncodableValue DesktopInstance::State() {
  using V = flutter::EncodableValue;
  const auto state = requests_.Read();
  flutter::EncodableMap result{
      {V("available"), V(handoff_.Available())},
      {V("count"), V(static_cast<int64_t>(state.count))}};
  if (state.first) {
    flutter::EncodableList args;
    for (const auto& arg : state.first->arguments) args.emplace_back(arg);
    result[V("nxmPending")] = V(state.first->private_pending);
    result[V("nxmFailed")] = V(state.first->delivery_failed);
    result[V("nxmReference")] = V(state.first->reference);
    result[V("id")] = V(state.first->id);
    result[V("arguments")] = V(args);
  }
  result[V("processId")] = V(static_cast<int32_t>(GetCurrentProcessId()));
  return V(result);
}
void DesktopInstance::Attach(flutter::BinaryMessenger* messenger, HWND window) {
  window_ = window;
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "dev.modconductor/desktop",
      &flutter::StandardMethodCodec::GetInstance());
  nxm_ = std::make_unique<desktop::NxmDelivery>(requests_, [this] { PostMessage(window_, kRequestMessage, 0, 0); });
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "configureNxm") {
      const auto* args = call.arguments() ? std::get_if<flutter::EncodableMap>(call.arguments()) : nullptr;
      if (!args) { result->Error("invalid", "Invalid desktop connection."); return; }
      const auto endpoint = args->find(flutter::EncodableValue("endpoint"));
      const auto capability = args->find(flutter::EncodableValue("capability"));
      const auto pid = args->find(flutter::EncodableValue("processId"));
      if (endpoint == args->end() || capability == args->end() || pid == args->end() || !std::holds_alternative<std::string>(endpoint->second) || !std::holds_alternative<std::vector<uint8_t>>(capability->second) || !std::holds_alternative<int32_t>(pid->second)) {
        result->Error("invalid", "Invalid desktop connection."); return;
      }
      nxm_->Configure({std::get<std::string>(endpoint->second), std::get<std::vector<uint8_t>>(capability->second), std::get<int32_t>(pid->second)});
    } else if (call.method_name() == "dismiss") {
      const auto* value = call.arguments();
      if (!value || (!std::holds_alternative<int64_t>(*value) &&
                     !std::holds_alternative<int32_t>(*value))) {
        result->Error("invalid", "Invalid request.");
        return;
      }
      requests_.Dismiss(std::holds_alternative<int64_t>(*value)
                            ? std::get<int64_t>(*value)
                            : std::get<int32_t>(*value));
      nxm_->Notify();
    } else if (call.method_name() != "state") {
      result->NotImplemented();
      return;
    }
    result->Success(State());
  });
  handoff_.Start([this](bool present) {
    if (present && nxm_) nxm_->Notify();
    PostMessage(window_, kRequestMessage, present ? 1 : 0, 0);
  });
}
void DesktopInstance::Changed(bool present) {
  if (present) {
    if (IsIconic(window_)) ShowWindow(window_, SW_RESTORE);
    SetForegroundWindow(window_);
  }
  if (channel_) channel_->InvokeMethod("changed", nullptr);
}
