namespace ModConductor.Desktop

open System
open System.IO
open System.Runtime.InteropServices
open System.Runtime.Versioning
open System.Text
open Microsoft.Win32

type LinkSetupValue =
    { Path: string
      Name: string
      Value: string }

type IWindowsLinkValues =
    abstract Read: string * string -> string option
    abstract ProtocolRegistered: string -> bool
    abstract Write: LinkSetupValue -> unit
    abstract Remove: string * string -> unit
    abstract Default: unit -> LinkDefault
    abstract Changed: unit -> unit

module private WindowsSetupNative =
    [<DllImport("shlwapi.dll", CharSet = CharSet.Unicode)>]
    extern int AssocQueryStringW(
        uint32 flags,
        int kind,
        string association,
        string extra,
        StringBuilder output,
        uint32& length
    )

    [<DllImport("shell32.dll")>]
    extern void SHChangeNotify(int event, uint32 flags, nativeint item1, nativeint item2)

[<SupportedOSPlatform("windows")>]
type WindowsLinkValues() =
    interface IWindowsLinkValues with
        member _.Read(path, name) =
            use key = Registry.CurrentUser.OpenSubKey path

            if isNull key then
                None
            else
                match
                    key.GetValue(name, null, RegistryValueOptions.DoNotExpandEnvironmentNames)
                with
                | :? string as value -> Some value
                | _ -> None

        member _.ProtocolRegistered scheme =
            use key = Registry.ClassesRoot.OpenSubKey scheme

            not (isNull key) && key.GetValue("URL Protocol", null) :? string

        member _.Write value =
            use key = Registry.CurrentUser.CreateSubKey value.Path
            key.SetValue(value.Name, value.Value, RegistryValueKind.String)

        member _.Remove(path, name) =
            use key = Registry.CurrentUser.OpenSubKey(path, true)

            if not (isNull key) then
                key.DeleteValue(name, false)

            if not (isNull key) && key.ValueCount = 0 && key.SubKeyCount = 0 then
                key.Dispose()
                Registry.CurrentUser.DeleteSubKey(path, false)

        member _.Default() =
            let output = StringBuilder(1024)
            let mutable length = uint32 output.Capacity

            let result =
                WindowsSetupNative.AssocQueryStringW(0x1000u, 20, "nxm", null, output, &length)

            if result = 0 then
                if output.ToString() = "ModConductor.Nxm" then
                    LinkDefault.ModConductor
                else
                    LinkDefault.AnotherApp
            elif result = int 0x80070483u then // ERROR_NO_ASSOCIATION
                LinkDefault.None
            else
                LinkDefault.Unknown

        member _.Changed() =
            WindowsSetupNative.SHChangeNotify(0x08000000, 0u, 0n, 0n)

type WindowsLinkSetup
    (stateDirectory: string, values: IWindowsLinkValues, openSettings: unit -> unit) =
    let gate = obj ()
    let receipt = Path.Combine(stateDirectory, "nxm-windows-setup")
    let registrationName = "Mod Conductor"

    let protocolEntries executable =
        [ { Path = "Software\\Classes\\nxm"
            Name = "URL Protocol"
            Value = "" }
          { Path = "Software\\Classes\\nxm\\shell\\open\\command"
            Name = ""
            Value = "\"" + executable + "\" --uri \"%1\"" } ]

    let entries executable =
        let app = "Software\\ModConductor\\NexusLinks\\Capabilities"

        [ { Path = "Software\\Classes\\ModConductor.Nxm"
            Name = ""
            Value = "Mod Conductor Nexus download links" }
          { Path = "Software\\Classes\\ModConductor.Nxm"
            Name = "URL Protocol"
            Value = "" }
          { Path = "Software\\Classes\\ModConductor.Nxm\\shell\\open\\command"
            Name = ""
            Value = "\"" + executable + "\" --uri \"%1\"" }
          { Path = app
            Name = "ApplicationName"
            Value = "Mod Conductor" }
          { Path = app
            Name = "ApplicationDescription"
            Value = "Nexus download links" }
          { Path = app + "\\URLAssociations"
            Name = "nxm"
            Value = "ModConductor.Nxm" }
          { Path = "Software\\RegisteredApplications"
            Name = registrationName
            Value = app } ]

    let saved () =
        SetupFiles.read receipt
        |> Option.map (fun text ->
            text.Split('\n', StringSplitOptions.RemoveEmptyEntries)
            |> Array.map (fun line ->
                let fields = line.Split('\t')

                if fields.Length <> 3 then
                    raise (FormatException())

                { Path = SetupFiles.decode fields[0]
                  Name = SetupFiles.decode fields[1]
                  Value = SetupFiles.decode fields[2] })
            |> Array.toList)

    let status () =
        let available =
            saved ()
            |> Option.exists (
                List.forall (fun value -> values.Read(value.Path, value.Name) = Some value.Value)
            )
            && values.ProtocolRegistered "nxm"

        let current = values.Default()

        { Windows = true
          Available = Some available
          CanRemove = File.Exists receipt
          Default = current
          Changed = available && current = LinkDefault.AnotherApp
          Problem = None }

    let protect action =
        lock gate (fun () -> SetupFiles.protect true action)

    interface ILinkSetup with
        member _.OpenSettings() =
            protect (fun () ->
                openSettings ()
                status ())

        member _.Read() = protect status

        member _.Add executable =
            protect (fun () ->
                SetupFiles.executable executable

                if executable.Contains '"' then
                    SetupFiles.refuse "The Mod Conductor app path cannot be used for Nexus links."

                let previous = saved () |> Option.defaultValue []

                let ownsProtocol =
                    previous |> List.exists (fun value -> value.Path = "Software\\Classes\\nxm")

                let desired =
                    entries executable
                    @ if ownsProtocol || not (values.ProtocolRegistered "nxm") then
                          protocolEntries executable
                      else
                          []

                for value in desired do
                    match values.Read(value.Path, value.Name) with
                    | None -> ()
                    | Some current when
                        previous
                        |> List.exists (fun old ->
                            old.Path = value.Path && old.Name = value.Name && old.Value = current)
                        ->
                        ()
                    | Some _ ->
                        SetupFiles.refuse
                            "The Nexus link setup changed outside MC. It was not overwritten."

                SetupFiles.write
                    receipt
                    (desired
                     |> List.map (fun value ->
                         String.concat
                             "\t"
                             [ SetupFiles.encode value.Path
                               SetupFiles.encode value.Name
                               SetupFiles.encode value.Value ])
                     |> String.concat "\n")

                for value in desired do
                    values.Write value

                values.Changed()
                status ())

        member _.Remove() =
            protect (fun () ->
                let mutable changed = false

                for value in saved () |> Option.defaultValue [] |> List.rev do
                    match values.Read(value.Path, value.Name) with
                    | Some current when current = value.Value ->
                        values.Remove(value.Path, value.Name)
                    | Some _ -> changed <- true
                    | None -> ()

                File.Delete receipt
                values.Changed()
                let result = status ()

                { result with
                    Problem =
                        if changed then
                            Some
                                "Some link setup values changed outside MC and were left unchanged."
                        else
                            None })

module LinkSetup =
    let create directory : ILinkSetup =
        if OperatingSystem.IsWindows() then
            WindowsLinkSetup(
                directory,
                WindowsLinkValues(),
                fun () ->
                    use started =
                        System.Diagnostics.Process.Start(
                            System.Diagnostics.ProcessStartInfo(
                                "ms-settings:defaultapps?registeredAppUser=Mod%20Conductor",
                                UseShellExecute = true
                            )
                        )

                    ()
            )
        else
            let home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)

            let environment name fallback =
                match Environment.GetEnvironmentVariable name with
                | null
                | "" -> fallback
                | value -> value

            let split name fallback =
                (environment name fallback).Split(':', StringSplitOptions.RemoveEmptyEntries)
                |> Array.toList

            LinuxLinkSetup(
                directory,
                environment "XDG_CONFIG_HOME" (Path.Combine(home, ".config")),
                environment "XDG_DATA_HOME" (Path.Combine(home, ".local", "share")),
                split "XDG_CURRENT_DESKTOP" "",
                split "XDG_CONFIG_DIRS" "/etc/xdg",
                split "XDG_DATA_DIRS" "/usr/local/share:/usr/share"
            )
