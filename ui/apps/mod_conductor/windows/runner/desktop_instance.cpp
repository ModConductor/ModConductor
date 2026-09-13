#include "desktop_instance.h"

#include <flutter/standard_method_codec.h>
#include <sddl.h>

#include <stdexcept>
#include <vector>

namespace {
std::wstring SidText(PSID sid) {
  LPWSTR value = nullptr;
  if (!ConvertSidToStringSidW(sid, &value))
    throw std::runtime_error("Desktop identity is unavailable.");
  const std::wstring result(value);
  LocalFree(value);
  return result;
}
std::vector<BYTE> TokenData(HANDLE token, TOKEN_INFORMATION_CLASS kind) {
  DWORD length = 0;
  GetTokenInformation(token, kind, nullptr, 0, &length);
  std::vector<BYTE> bytes(length);
  if (!GetTokenInformation(token, kind, bytes.data(), length, &length))
    throw std::runtime_error("Desktop identity is unavailable.");
  return bytes;
}
std::vector<BYTE> Encode(const desktop::Arguments& input) {
  const auto args = desktop::IsNxm(input) ? input : desktop::Screen(input);
  std::vector<BYTE> bytes;
  auto number = [&](uint32_t value) {
    for (int i = 0; i < 4; ++i)
      bytes.push_back(static_cast<BYTE>(value >> (i * 8)));
  };
  number(static_cast<uint32_t>(args.size()));
  for (const auto& arg : args) {
    number(static_cast<uint32_t>(arg.size()));
    bytes.insert(bytes.end(), arg.begin(), arg.end());
  }
  return bytes;
}
bool Decode(const BYTE* data, DWORD length, desktop::Arguments& args) {
  size_t offset = 0;
  auto number = [&](uint32_t& value) {
    if (offset + 4 > length) return false;
    value = 0;
    for (int i = 0; i < 4; ++i)
      value |= static_cast<uint32_t>(data[offset++]) << (i * 8);
    return true;
  };
  uint32_t count = 0;
  if (!number(count) || count > 8) return false;
  for (uint32_t i = 0; i < count; ++i) {
    uint32_t size = 0;
    if (!number(size) || size > 4096 || offset + size > length) return false;
    if (size > 0 &&
        MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                            reinterpret_cast<const char*>(data + offset),
                            static_cast<int>(size), nullptr, 0) == 0)
      return false;
    args.emplace_back(reinterpret_cast<const char*>(data + offset), size);
    offset += size;
  }
  return offset == length;
}
}  // namespace

DesktopInstance::DesktopInstance() {
  HANDLE token = nullptr;
  if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token))
    throw std::runtime_error("Desktop identity is unavailable.");
  std::wstring user, logon;
  try {
    const auto identity = TokenData(token, TokenUser);
    user =
        SidText(reinterpret_cast<const TOKEN_USER*>(identity.data())->User.Sid);
    const auto group_bytes = TokenData(token, TokenGroups);
    const auto* groups =
        reinterpret_cast<const TOKEN_GROUPS*>(group_bytes.data());
    for (DWORD i = 0; i < groups->GroupCount; ++i) {
      if ((groups->Groups[i].Attributes & SE_GROUP_LOGON_ID) ==
          SE_GROUP_LOGON_ID)
        logon = SidText(groups->Groups[i].Sid);
    }
  } catch (...) {
    CloseHandle(token);
    throw;
  }
  CloseHandle(token);
  if (logon.empty())
    throw std::runtime_error("The desktop session is unavailable.");
  DWORD session = 0;
  if (!ProcessIdToSessionId(GetCurrentProcessId(), &session))
    throw std::runtime_error("The desktop session is unavailable.");
  const std::wstring mutex_name = L"Global\\ModConductor.Desktop." + user;
  mutex_ = CreateMutexW(nullptr, TRUE, mutex_name.c_str());
  if (!mutex_) throw std::runtime_error("Desktop ownership is unavailable.");
  if (GetLastError() != ERROR_ALREADY_EXISTS)
    primary_ = true;
  else {
    const auto result = WaitForSingleObject(mutex_, 0);
    primary_ = result == WAIT_OBJECT_0 || result == WAIT_ABANDONED;
  }
  pipe_name_ = L"\\\\.\\pipe\\ModConductor.Desktop." + user + L"." +
               std::to_wstring(session);
  pipe_descriptor_ = L"D:P(A;;GA;;;" + logon + L")";
  ready_ = CreateEventW(nullptr, TRUE, FALSE,
                        (L"Local\\ModConductor.Desktop.Ready." + user).c_str());
  if (primary_ && ready_) ResetEvent(ready_);
  stop_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!stop_ || !ready_) {
    if (stop_) CloseHandle(stop_);
    if (ready_) CloseHandle(ready_);
    if (primary_) ReleaseMutex(mutex_);
    CloseHandle(mutex_);
    mutex_ = nullptr;
    throw std::runtime_error("Desktop handoff is unavailable.");
  }
}
DesktopInstance::~DesktopInstance() {
  Detach();
  if (stop_) CloseHandle(stop_);
  if (ready_) CloseHandle(ready_);
  if (mutex_) {
    if (primary_) ReleaseMutex(mutex_);
    CloseHandle(mutex_);
  }
}
void DesktopInstance::Detach() {
  requests_.Stop();
  if (stop_) SetEvent(stop_);
  if (listener_.joinable()) listener_.join();
  nxm_.reset();
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
    channel_.reset();
  }
}
bool DesktopInstance::Transfer(HANDLE pipe, void* bytes, DWORD size, bool write,
                               DWORD& transferred) {
  OVERLAPPED operation{};
  operation.hEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!operation.hEvent) return false;
  const bool immediate =
      (write ? WriteFile(pipe, bytes, size, &transferred, &operation)
             : ReadFile(pipe, bytes, size, &transferred, &operation)) != FALSE;
  bool success = immediate;
  if (!immediate && GetLastError() == ERROR_IO_PENDING) {
    HANDLE events[] = {stop_, operation.hEvent};
    success =
        WaitForMultipleObjects(2, events, FALSE, 5000) == WAIT_OBJECT_0 + 1;
    if (!success) CancelIoEx(pipe, &operation);
    success =
        GetOverlappedResult(pipe, &operation, &transferred, TRUE) && success;
  }
  CloseHandle(operation.hEvent);
  return success;
}
bool DesktopInstance::Forward(const desktop::Arguments& arguments) {
  if (WaitForSingleObject(ready_, 5000) != WAIT_OBJECT_0 ||
      !WaitNamedPipeW(pipe_name_.c_str(), 5000))
    return false;
  HANDLE pipe =
      CreateFileW(pipe_name_.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                  OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nullptr);
  if (pipe == INVALID_HANDLE_VALUE) return false;
  if (desktop::IsNxm(arguments)) {
    ULONG server_pid = 0;
    bool trusted = GetNamedPipeServerProcessId(pipe, &server_pid) != FALSE;
    HANDLE server = trusted ? OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, server_pid) : nullptr;
    wchar_t current_path[32768], server_path[32768];
    DWORD server_length = 32768;
    const DWORD current_length = GetModuleFileNameW(nullptr, current_path, 32768);
    trusted = server && current_length > 0 && current_length < 32768 && QueryFullProcessImageNameW(server, 0, server_path, &server_length) && current_length == server_length && _wcsnicmp(current_path, server_path, server_length) == 0;
    if (server) CloseHandle(server);
    if (!trusted) { CloseHandle(pipe); return false; }
  }
  auto bytes = Encode(arguments);
  DWORD sent = 0, received = 0, answer = 0;
  const bool success =
      Transfer(pipe, bytes.data(), static_cast<DWORD>(bytes.size()), true,
               sent) &&
      sent == bytes.size() &&
      Transfer(pipe, &answer, sizeof(answer), false, received) &&
      received == sizeof(answer) && answer == 1;
  if (success) {
    DWORD confirmation = 0, written = 0;
    Transfer(pipe, &confirmation, sizeof(confirmation), true, written);
  }
  std::fill(bytes.begin(), bytes.end(), 0);
  CloseHandle(pipe);
  return success;
}
void DesktopInstance::Listen() {
  PSECURITY_DESCRIPTOR descriptor = nullptr;
  if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(
          pipe_descriptor_.c_str(), SDDL_REVISION_1, &descriptor, nullptr))
    return;
  SECURITY_ATTRIBUTES security{sizeof(SECURITY_ATTRIBUTES), descriptor, FALSE};
  while (WaitForSingleObject(stop_, 0) != WAIT_OBJECT_0) {
    HANDLE pipe = CreateNamedPipeW(pipe_name_.c_str(),
                                   PIPE_ACCESS_DUPLEX | FILE_FLAG_OVERLAPPED |
                                       FILE_FLAG_FIRST_PIPE_INSTANCE,
                                   PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE |
                                       PIPE_WAIT | PIPE_REJECT_REMOTE_CLIENTS,
                                   1, 32772, 32772, 5000, &security);
    if (pipe == INVALID_HANDLE_VALUE) break;
    if (!available_.exchange(true)) {
      SetEvent(ready_);
      PostMessage(window_, kRequestMessage, 0, 0);
    }
    OVERLAPPED connection{};
    connection.hEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!connection.hEvent) {
      CloseHandle(pipe);
      break;
    }
    bool connected = ConnectNamedPipe(pipe, &connection) != FALSE;
    if (!connected) {
      const DWORD error = GetLastError();
      if (error == ERROR_PIPE_CONNECTED)
        connected = true;
      else if (error == ERROR_IO_PENDING) {
        HANDLE events[] = {stop_, connection.hEvent};
        connected = WaitForMultipleObjects(2, events, FALSE, INFINITE) ==
                    WAIT_OBJECT_0 + 1;
        if (!connected) CancelIoEx(pipe, &connection);
        DWORD transferred = 0;
        connected =
            GetOverlappedResult(pipe, &connection, &transferred, TRUE) &&
            connected;
      }
    }
    CloseHandle(connection.hEvent);
    if (connected) {
      BYTE buffer[32772];
      DWORD length = 0;
      desktop::Arguments args;
      DWORD answer = Transfer(pipe, buffer, sizeof(buffer), false, length) &&
                             Decode(buffer, length, args) && requests_.Add(args)
                         ? 1
                         : 0;
      if (answer) { if (nxm_) nxm_->Notify(); PostMessage(window_, kRequestMessage, 1, 0); }
      DWORD sent = 0;
      if (Transfer(pipe, &answer, sizeof(answer), true, sent)) {
        DWORD confirmation = 0, read = 0;
        Transfer(pipe, &confirmation, sizeof(confirmation), false, read);
      }
    }
    DisconnectNamedPipe(pipe);
    CloseHandle(pipe);
  }
  available_ = false;
  ResetEvent(ready_);
  PostMessage(window_, kRequestMessage, 0, 0);
  LocalFree(descriptor);
}
flutter::EncodableValue DesktopInstance::State() {
  using V = flutter::EncodableValue;
  const auto state = requests_.Read();
  flutter::EncodableMap result{
      {V("available"), V(available_.load())},
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
  listener_ = std::thread([this] { Listen(); });
}
void DesktopInstance::Changed(bool present) {
  if (present) {
    if (IsIconic(window_)) ShowWindow(window_, SW_RESTORE);
    SetForegroundWindow(window_);
  }
  if (channel_) channel_->InvokeMethod("changed", nullptr);
}
