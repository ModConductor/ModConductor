namespace ModConductor.SteamDiscovery

open System
open System.IO
open Microsoft.Win32

module DefaultRoots =
    let read () =
        let roots = ResizeArray<SearchRoot>()

        let add origin path =
            if not (String.IsNullOrWhiteSpace path) && Path.IsPathFullyQualified path then
                roots.Add { Path = path; Origin = origin }

        if OperatingSystem.IsWindows() then
            try
                use key = Registry.CurrentUser.OpenSubKey("Software\\Valve\\Steam", false)

                if not (isNull key) then
                    match key.GetValue("SteamPath") with
                    | :? string as path -> add "Steam registry path" path
                    | _ -> ()

                    match key.GetValue("SteamExe") with
                    | :? string as path when Path.IsPathFullyQualified path ->
                        add "Steam registry executable" (Path.GetDirectoryName path)
                    | _ -> ()
            with
            | :? UnauthorizedAccessException -> ()
            | :? System.Security.SecurityException -> ()
            | :? IOException -> ()
            | :? ArgumentException -> ()

            for folder in
                [ Environment.SpecialFolder.ProgramFilesX86
                  Environment.SpecialFolder.ProgramFiles ] do
                let path =
                    Environment.GetFolderPath(folder, Environment.SpecialFolderOption.DoNotVerify)

                if not (String.IsNullOrEmpty path) then
                    add "Default Steam folder" (Path.Combine(path, "Steam"))
        else
            let home =
                Environment.GetFolderPath(
                    Environment.SpecialFolder.UserProfile,
                    Environment.SpecialFolderOption.DoNotVerify
                )

            if not (String.IsNullOrEmpty home) then
                add "Steam home link" (Path.Combine(home, ".steam", "steam"))
                let data = Environment.GetEnvironmentVariable "XDG_DATA_HOME"

                let data =
                    if not (String.IsNullOrEmpty data) && Path.IsPathFullyQualified data then
                        data
                    else
                        Path.Combine(home, ".local", "share")

                add "Default Steam data folder" (Path.Combine(data, "Steam"))

        roots
        |> Seq.distinct
        |> Seq.sortBy (fun root -> root.Path, root.Origin)
        |> Seq.toList
