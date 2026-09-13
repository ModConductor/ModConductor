namespace ModConductor.Desktop

open System
open System.IO

[<RequireQualifiedAccess>]
type LinkDefault =
    | ModConductor
    | AnotherApp
    | None
    | Unknown

type LinkSetupStatus =
    { Windows: bool
      Available: bool option
      CanRemove: bool
      Default: LinkDefault
      Changed: bool
      Problem: string option }

type ILinkSetup =
    abstract Read: unit -> LinkSetupStatus
    abstract Add: string -> LinkSetupStatus
    abstract Remove: unit -> LinkSetupStatus
    abstract OpenSettings: unit -> LinkSetupStatus

exception internal LinkSetupFailure of string

module internal SetupFiles =
    let refuse message = raise (LinkSetupFailure message)

    let read path =
        if File.Exists path then
            Some(File.ReadAllText path)
        else
            None

    let write (path: string) (text: string) =
        if not (isNull (FileInfo(path).LinkTarget)) then
            refuse "This link setup is managed outside MC. It was not overwritten."

        Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
        let temporary = path + "." + Guid.NewGuid().ToString("N")

        try
            File.WriteAllText(temporary, text)

            if OperatingSystem.IsLinux() then
                File.SetUnixFileMode(temporary, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)

            File.Move(temporary, path, true)
        finally
            if File.Exists temporary then
                File.Delete temporary

    let encode (text: string) =
        Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes text)

    let decode text =
        System.Text.Encoding.UTF8.GetString(Convert.FromBase64String text)

    let executable (path: string) =
        if
            not (Path.IsPathFullyQualified path)
            || not (File.Exists path)
            || path |> Seq.exists Char.IsControl
        then
            refuse "Choose an available Mod Conductor app."

    let protect windows action =
        try
            action ()
        with
        | :? IOException
        | :? UnauthorizedAccessException
        | :? System.Security.SecurityException
        | :? FormatException
        | :? System.ComponentModel.Win32Exception ->
            { Windows = windows
              Available = None
              CanRemove = false
              Default = LinkDefault.Unknown
              Changed = false
              Problem = Some "The Nexus link setup could not be checked or changed." }
        | LinkSetupFailure message ->
            { Windows = windows
              Available = None
              CanRemove = false
              Default = LinkDefault.Unknown
              Changed = false
              Problem = Some message }

type LinuxLinkSetup
    (
        stateDirectory: string,
        configHome: string,
        dataHome: string,
        desktops: string list,
        configDirs: string list,
        dataDirs: string list
    ) =
    let gate = obj ()
    let desktopId = "dev.modconductor.nxm.desktop"
    let owned = Path.Combine(dataHome, "applications", desktopId)
    let receipt = Path.Combine(stateDirectory, "nxm-linux-setup")

    let desktopNames =
        desktops
        |> List.filter (fun name ->
            name <> ""
            && name |> Seq.forall (fun c -> Char.IsAsciiLetterOrDigit c || c = '-' || c = '_'))
        |> List.map (fun value -> value.ToLowerInvariant())

    let names =
        (desktopNames |> List.map (fun d -> d + "-mimeapps.list")) @ [ "mimeapps.list" ]

    let target = Path.Combine(configHome, names.Head)

    let candidates =
        [ for root in configHome :: configDirs do
              for name in names do
                  Path.Combine(root, name)
          for root in dataHome :: dataDirs do
              for name in names do
                  Path.Combine(root, "applications", name) ]

    let entry (text: string) =
        let mutable section = false

        text.Split('\n')
        |> Array.tryPick (fun raw ->
            let line = raw.TrimEnd('\r')

            if line.StartsWith '[' then
                section <- line = "[Default Applications]"

            if section && line.StartsWith("x-scheme-handler/nxm=", StringComparison.Ordinal) then
                Some(line.Substring 21)
            else
                None)

    let rewrite (text: string) (value: string option) =
        let lines = ResizeArray<string>()
        let mutable section = false
        let mutable added = false

        for raw in text.Split('\n') do
            let line = raw.TrimEnd('\r')

            if line.StartsWith '[' then
                section <- line = "[Default Applications]"

            if section && line.StartsWith("x-scheme-handler/nxm=", StringComparison.Ordinal) then
                if not added then
                    value |> Option.iter (fun v -> lines.Add("x-scheme-handler/nxm=" + v))
                    added <- true
            else
                lines.Add raw

                if line = "[Default Applications]" && not added then
                    value |> Option.iter (fun v -> lines.Add("x-scheme-handler/nxm=" + v))
                    added <- true

        if not added && value.IsSome then
            lines.Add "[Default Applications]"
            lines.Add("x-scheme-handler/nxm=" + value.Value)

        String.concat "\n" lines

    let defaultApp () =
        candidates
        |> List.tryPick (fun path ->
            SetupFiles.read path
            |> Option.bind entry
            |> Option.bind (fun value ->
                value.Split(';', StringSplitOptions.RemoveEmptyEntries)
                |> Array.tryFind (fun id ->
                    not (id.Contains '/')
                    && not (id.Contains '\\')
                    && dataHome :: dataDirs
                       |> List.exists (fun root ->
                           File.Exists(Path.Combine(root, "applications", id))))))

    let saved () =
        SetupFiles.read receipt
        |> Option.map (fun text ->
            let values = text.TrimEnd('\n').Split('\n')

            if values.Length <> 3 then
                raise (FormatException())

            SetupFiles.decode values[0],
            SetupFiles.decode values[1],
            (if values[2] = "-" then
                 None
             else
                 Some(SetupFiles.decode values[2])))

    let status () =
        let available =
            match saved () with
            | Some(content, _, _) -> SetupFiles.read owned = Some content
            | None -> false

        let current = defaultApp ()

        { Windows = false
          Available = Some available
          CanRemove = File.Exists receipt
          Default =
            match current with
            | Some id when id = desktopId -> LinkDefault.ModConductor
            | Some _ -> LinkDefault.AnotherApp
            | None -> LinkDefault.None
          Changed = available && current <> Some desktopId
          Problem = None }

    let protect action =
        lock gate (fun () -> SetupFiles.protect false action)

    interface ILinkSetup with
        member _.OpenSettings() = protect status
        member _.Read() = protect status

        member _.Add executable =
            protect (fun () ->
                SetupFiles.executable executable

                let escaped =
                    executable
                        .Replace("\\", "\\\\\\\\")
                        .Replace("\"", "\\\\\\\"")
                        .Replace("`", "\\\\`")
                        .Replace("$", "\\\\$")
                        .Replace("%", "%%")

                let content =
                    "[Desktop Entry]\nType=Application\nName=Mod Conductor\nNoDisplay=true\nExec=\""
                    + escaped
                    + "\" --uri %u\nMimeType=x-scheme-handler/nxm;\n"

                let current = SetupFiles.read target |> Option.defaultValue ""

                let previous =
                    match saved () with
                    | Some(old, path, before) ->
                        if
                            path <> target || (SetupFiles.read owned |> Option.exists ((<>) old))
                        then
                            SetupFiles.refuse
                                "The Nexus link setup changed outside MC. It was not overwritten."

                        if entry current = Some(desktopId + ";") then
                            before
                        else
                            entry current
                    | None ->
                        if File.Exists owned then
                            SetupFiles.refuse
                                "A different Nexus link setup already uses this app entry. It was not overwritten."

                        entry current

                SetupFiles.write
                    receipt
                    (SetupFiles.encode content
                     + "\n"
                     + SetupFiles.encode target
                     + "\n"
                     + (previous |> Option.map SetupFiles.encode |> Option.defaultValue "-")
                     + "\n")

                SetupFiles.write owned content

                if SetupFiles.read target |> Option.defaultValue "" <> current then
                    SetupFiles.refuse "The default app changed. Check it before trying again."

                SetupFiles.write target (rewrite current (Some(desktopId + ";")))
                status ())

        member _.Remove() =
            protect (fun () ->
                match saved () with
                | None -> status ()
                | Some(content, path, previous) ->
                    let current = SetupFiles.read path |> Option.defaultValue ""

                    if entry current = Some(desktopId + ";") && defaultApp () = Some desktopId then
                        SetupFiles.write path (rewrite current previous)

                    let changed = SetupFiles.read owned |> Option.exists ((<>) content)

                    if not changed then
                        File.Delete owned

                    File.Delete receipt
                    let result = status ()

                    { result with
                        Problem =
                            if changed then
                                Some "The app entry changed outside MC and was left unchanged."
                            else
                                None })
