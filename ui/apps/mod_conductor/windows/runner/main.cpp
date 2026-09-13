#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <exception>

#include "desktop_instance.h"
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  try {
    DesktopInstance desktop;
    const auto arguments = GetCommandLineArguments();
    if (!desktop.Primary()) {
      const bool delivered = desktop.Forward(arguments);
      if (!delivered)
        MessageBoxW(
            nullptr,
            L"Mod Conductor cannot accept this request. Use the open window.",
            L"Mod Conductor", MB_OK | MB_ICONERROR);
      ::CoUninitialize();
      return delivered ? EXIT_SUCCESS : EXIT_FAILURE;
    }
    desktop.Add(arguments);
    flutter::DartProject project(L"data");

    FlutterWindow window(project, desktop);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.Create(L"Mod Conductor", origin, size)) {
      return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);

    ::MSG msg;
    while (::GetMessage(&msg, nullptr, 0, 0)) {
      ::TranslateMessage(&msg);
      ::DispatchMessage(&msg);
    }

    // Teardown can send window messages; clear the controller while the window
    // lives.
    window.SetQuitOnClose(false);
    window.Destroy();

  } catch (const std::exception&) {
    MessageBoxW(
        nullptr,
        L"Mod Conductor could not start. Desktop ownership is unavailable.",
        L"Mod Conductor", MB_OK | MB_ICONERROR);
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
