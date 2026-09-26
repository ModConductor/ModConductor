#ifndef MOD_CONDUCTOR_DESKTOP_IDENTITY_H_
#define MOD_CONDUCTOR_DESKTOP_IDENTITY_H_

#include <windows.h>

#include <string>

class DesktopIdentity {
 public:
  DesktopIdentity();
  ~DesktopIdentity();

  DesktopIdentity(const DesktopIdentity&) = delete;
  DesktopIdentity& operator=(const DesktopIdentity&) = delete;

  bool Primary() const { return primary_; }
  const std::wstring& PipeName() const { return pipe_name_; }
  const std::wstring& PipeDescriptor() const { return pipe_descriptor_; }
  const std::wstring& ReadyName() const { return ready_name_; }

 private:
  HANDLE mutex_ = nullptr;
  bool primary_ = false;
  std::wstring pipe_name_, pipe_descriptor_, ready_name_;
};

#endif
