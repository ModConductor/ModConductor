namespace ModConductor.Platform

open System

module NativeProcessLaunch =
    let start request =
        if OperatingSystem.IsWindows() then
            WindowsChildProcess.start request
        elif OperatingSystem.IsLinux() then
            LinuxChildProcess.start request
        else
            raise (
                PlatformNotSupportedException
                    "Native executable launch is unavailable on this platform."
            )
