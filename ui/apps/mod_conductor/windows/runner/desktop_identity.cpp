#include "desktop_identity.h"

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
}  // namespace

DesktopIdentity::DesktopIdentity() {
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
  ready_name_ = L"Local\\ModConductor.Desktop.Ready." + user;
}

DesktopIdentity::~DesktopIdentity() {
  if (mutex_) {
    if (primary_) ReleaseMutex(mutex_);
    CloseHandle(mutex_);
  }
}
