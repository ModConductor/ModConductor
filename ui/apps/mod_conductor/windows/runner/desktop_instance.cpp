#include "desktop_instance.h"

#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <string>

namespace {
bool LaunchUpdateConsole(const std::string& encoded_command,
                         DWORD& process_id, HANDLE& process_handle) {
  if (encoded_command.empty() || encoded_command.size() > 16384 ||
      !std::all_of(encoded_command.begin(), encoded_command.end(), [](char value) {
        return (value >= 'A' && value <= 'Z') ||
               (value >= 'a' && value <= 'z') ||
               (value >= '0' && value <= '9') || value == '+' ||
               value == '/' || value == '=';
      })) return false;
  wchar_t windows[MAX_PATH];
  const UINT length = GetWindowsDirectoryW(windows, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) return false;
  const std::wstring powershell = std::wstring(windows, length) +
      L"\\System32\\WindowsPowerShell\\v1.0\\powershell.exe";
  std::wstring command_line = L"\"" + powershell +
      L"\" -NoProfile -NoExit -EncodedCommand " +
      std::wstring(encoded_command.begin(), encoded_command.end());
  STARTUPINFOW startup{};
  startup.cb = sizeof(startup);
  PROCESS_INFORMATION process{};
  if (!CreateProcessW(powershell.c_str(), command_line.data(), nullptr,
                      nullptr, FALSE,
                      CREATE_NEW_CONSOLE | CREATE_UNICODE_ENVIRONMENT,
                      nullptr, nullptr, &startup, &process)) return false;
  process_id = process.dwProcessId;
  process_handle = process.hProcess;
  CloseHandle(process.hThread);
  return true;
}
}  // namespace

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
  for (const auto& waiter : update_waiters_) CloseHandle(waiter.second);
  update_waiters_.clear();
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
  result[V("version")] = V(FLUTTER_VERSION);
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
    } else if (call.method_name() == "launchUpdateWaiter") {
      const auto* args = call.arguments() ? std::get_if<flutter::EncodableMap>(call.arguments()) : nullptr;
      if (!args) {
        result->Error("invalid", "Invalid update handoff."); return;
      }
      const auto encoded = args->find(flutter::EncodableValue("command"));
      if (encoded == args->end() || !std::holds_alternative<std::string>(encoded->second)) {
        result->Error("invalid", "Invalid update handoff."); return;
      }
      DWORD process_id = 0;
      HANDLE process_handle = nullptr;
      if (!LaunchUpdateConsole(std::get<std::string>(encoded->second), process_id,
                               process_handle)) {
        result->Error("unavailable", "Could not open the update console."); return;
      }
      update_waiters_.emplace(process_id, process_handle);
      result->Success(flutter::EncodableValue(static_cast<int64_t>(process_id)));
      return;
    } else if (call.method_name() == "cancelUpdateWaiter") {
      const auto* value = call.arguments();
      if (!value || (!std::holds_alternative<int64_t>(*value) &&
                     !std::holds_alternative<int32_t>(*value))) {
        result->Error("invalid", "Invalid update waiter."); return;
      }
      const DWORD process_id = std::holds_alternative<int64_t>(*value)
          ? static_cast<DWORD>(std::get<int64_t>(*value))
          : static_cast<DWORD>(std::get<int32_t>(*value));
      const auto waiter = update_waiters_.find(process_id);
      if (waiter == update_waiters_.end()) {
        result->Success(flutter::EncodableValue(false)); return;
      }
      const bool stopped = TerminateProcess(waiter->second, 1) != FALSE ||
                           WaitForSingleObject(waiter->second, 0) == WAIT_OBJECT_0;
      const bool completed = stopped &&
                             WaitForSingleObject(waiter->second, 5000) == WAIT_OBJECT_0;
      if (completed) {
        CloseHandle(waiter->second);
        update_waiters_.erase(waiter);
      }
      result->Success(flutter::EncodableValue(completed));
      return;
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
