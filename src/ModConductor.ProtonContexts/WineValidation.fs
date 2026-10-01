namespace ModConductor.WineContexts

open System
open System.IO
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.ProtonContexts

module WineValidation =
    let inspect (game: InstallationEvidence) (selection: WineSelection) =
        let checkedGame =
            if
                not (OperatingSystem.IsLinux())
                || not (Path.IsPathFullyQualified selection.Executable)
                || not (Path.IsPathFullyQualified selection.Prefix)
            then
                { game with
                    Problems =
                        game.Problems
                        @ [ { Path = selection.Prefix
                              Detail =
                                "Select an absolute Wine executable and existing prefix on Linux." } ] }
            else
                try
                    let prefix, prefixIdentity = PrefixFiles.directory selection.Prefix
                    let executable = Path.GetFullPath selection.Executable
                    let target = File.ResolveLinkTarget(executable, true)
                    let resolved = if isNull target then executable else target.FullName

                    let resolvedParent, resolvedIdentity =
                        PrefixFiles.directory (Path.GetDirectoryName resolved)

                    use resolvedDirectory =
                        HeldDirectory.Open(
                            HostPath.create resolvedParent |> Result.defaultWith invalidOp,
                            resolvedIdentity
                        )

                    let file, identity = resolvedDirectory.Read(Path.GetFileName resolved, None)
                    use file = file
                    let mode = File.GetUnixFileMode resolved

                    let executableBits =
                        UnixFileMode.UserExecute
                        ||| UnixFileMode.GroupExecute
                        ||| UnixFileMode.OtherExecute

                    if mode &&& executableBits = enum<UnixFileMode> 0 then
                        { game with
                            Problems =
                                game.Problems
                                @ [ { Path = selection.Executable
                                      Detail = "The selected Wine file is not executable." } ] }
                    else
                        let registry =
                            File.ReadAllText(Path.Combine(prefix, "user.reg")) |> WineRegistry.read

                        let definition =
                            GameCatalog.forRuntime
                                game.DefinitionId
                                game.Executable.Value.FileVersion

                        let paths =
                            PrefixPaths.locationsWith true definition prefix prefixIdentity registry

                        let locate name =
                            paths |> List.find (fun path -> path.Name = name) |> _.HostLocation

                        { game with
                            Platform = ContextPlatform.Wine
                            Proton = None
                            Wine =
                                Some
                                    { Selection =
                                        { Executable = executable
                                          Prefix = prefix }
                                      PrefixIdentity = prefixIdentity
                                      ExecutableIdentity = identity
                                      Paths = paths }
                            Locations =
                                { Documents = locate "Documents"
                                  Saves = locate "Saves"
                                  LocalAppData = locate "Local AppData" } }
                with
                | :? IOException as error ->
                    { game with
                        Problems =
                            game.Problems
                            @ [ { Path = selection.Prefix
                                  Detail = "The Wine context could not be checked. " + error.Message } ] }
                | :? UnauthorizedAccessException ->
                    { game with
                        Problems =
                            game.Problems
                            @ [ { Path = selection.Prefix
                                  Detail = "The Wine context cannot be read." } ] }

        let checkedGame =
            { checkedGame with
                Locations =
                    GameLocations.apply game.DefinitionId game.RootPath checkedGame.Locations }

        { checkedGame with
            Fingerprint = ContextIdentity.fingerprint checkedGame }
