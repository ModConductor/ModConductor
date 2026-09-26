#include "desktop_handoff.h"

#include <sddl.h>

#include <algorithm>
#include <stdexcept>
#include <utility>
#include <vector>

namespace {
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

bool TrustedNxmServer(HANDLE pipe) {
  ULONG server_pid = 0;
  bool trusted = GetNamedPipeServerProcessId(pipe, &server_pid) != FALSE;
  HANDLE server = trusted
                      ? OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE,
                                    server_pid)
                      : nullptr;
  wchar_t current_path[32768], server_path[32768];
  DWORD server_length = 32768;
  const DWORD current_length = GetModuleFileNameW(nullptr, current_path, 32768);
  trusted = server && current_length > 0 && current_length < 32768 &&
            QueryFullProcessImageNameW(server, 0, server_path, &server_length) &&
            current_length == server_length &&
            _wcsnicmp(current_path, server_path, server_length) == 0;
  if (server) CloseHandle(server);
  return trusted;
}
}  // namespace

DesktopHandoff::DesktopHandoff(desktop::Requests& requests)
    : requests_(requests) {
  ready_ = CreateEventW(nullptr, TRUE, FALSE, identity_.ReadyName().c_str());
  if (identity_.Primary() && ready_) ResetEvent(ready_);
  stop_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!stop_ || !ready_) {
    if (stop_) CloseHandle(stop_);
    if (ready_) CloseHandle(ready_);
    throw std::runtime_error("Desktop handoff is unavailable.");
  }
}

DesktopHandoff::~DesktopHandoff() {
  Stop();
  CloseHandle(stop_);
  CloseHandle(ready_);
}

void DesktopHandoff::Start(std::function<void(bool)> on_request) {
  on_request_ = std::move(on_request);
  listener_ = std::thread([this] { Listen(); });
}

void DesktopHandoff::Stop() {
  SetEvent(stop_);
  if (listener_.joinable()) listener_.join();
}

bool DesktopHandoff::Transfer(HANDLE pipe, void* bytes, DWORD size, bool write,
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
bool DesktopHandoff::Forward(const desktop::Arguments& arguments) {
  if (WaitForSingleObject(ready_, 5000) != WAIT_OBJECT_0 ||
      !WaitNamedPipeW(identity_.PipeName().c_str(), 5000))
    return false;
  HANDLE pipe = CreateFileW(identity_.PipeName().c_str(),
                            GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                            OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nullptr);
  if (pipe == INVALID_HANDLE_VALUE) return false;
  if (desktop::IsNxm(arguments) && !TrustedNxmServer(pipe)) {
    CloseHandle(pipe);
    return false;
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
  std::fill(bytes.begin(), bytes.end(), BYTE{0});
  CloseHandle(pipe);
  return success;
}

std::optional<bool> DesktopHandoff::Connect(HANDLE pipe) {
  OVERLAPPED connection{};
  connection.hEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!connection.hEvent) return std::nullopt;
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
      connected = GetOverlappedResult(pipe, &connection, &transferred, TRUE) &&
                  connected;
    }
  }
  CloseHandle(connection.hEvent);
  return connected;
}

void DesktopHandoff::Receive(HANDLE pipe) {
  BYTE buffer[32772];
  DWORD length = 0;
  desktop::Arguments args;
  DWORD answer = Transfer(pipe, buffer, sizeof(buffer), false, length) &&
                         Decode(buffer, length, args) && requests_.Add(args)
                     ? 1
                     : 0;
  if (answer) on_request_(true);
  DWORD sent = 0;
  if (Transfer(pipe, &answer, sizeof(answer), true, sent)) {
    DWORD confirmation = 0, read = 0;
    Transfer(pipe, &confirmation, sizeof(confirmation), false, read);
  }
}

void DesktopHandoff::Listen() {
  PSECURITY_DESCRIPTOR descriptor = nullptr;
  if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(
          identity_.PipeDescriptor().c_str(), SDDL_REVISION_1, &descriptor,
          nullptr))
    return;
  SECURITY_ATTRIBUTES security{sizeof(SECURITY_ATTRIBUTES), descriptor, FALSE};
  while (WaitForSingleObject(stop_, 0) != WAIT_OBJECT_0) {
    HANDLE pipe = CreateNamedPipeW(identity_.PipeName().c_str(),
                                   PIPE_ACCESS_DUPLEX | FILE_FLAG_OVERLAPPED |
                                       FILE_FLAG_FIRST_PIPE_INSTANCE,
                                   PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE |
                                       PIPE_WAIT | PIPE_REJECT_REMOTE_CLIENTS,
                                   1, 32772, 32772, 5000, &security);
    if (pipe == INVALID_HANDLE_VALUE) break;
    if (!available_.exchange(true)) {
      SetEvent(ready_);
      on_request_(false);
    }
    const auto connected = Connect(pipe);
    if (!connected) {
      CloseHandle(pipe);
      break;
    }
    if (*connected) Receive(pipe);
    DisconnectNamedPipe(pipe);
    CloseHandle(pipe);
  }
  available_ = false;
  ResetEvent(ready_);
  on_request_(false);
  LocalFree(descriptor);
}
