namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform
open ModConductor.GameContexts

module internal DataLocations =
    let root path =
        let selected =
            HostPath.create path
            |> Result.bind (fun value -> RootSelection.select value |> Result.mapError string)
            |> Result.defaultWith (fun _ ->
                raise (
                    ProfileDataException(
                        ProfileDataError.Unavailable "The settings folder is unavailable."
                    )
                ))

        match (RootSelection.facts selected).File with
        | Known identity ->
            { Path = RootSelection.path selected
              Identity = identity }
            : DataRoot
        | Unknown reason -> raise (ProfileDataException(ProfileDataError.Unavailable reason))

    let documents (game: GameContextState) =
        match game.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            match binding.Evidence.Locations.Documents with
            | Location.Located(path, _) -> root path
            | Location.Unavailable reason ->
                raise (ProfileDataException(ProfileDataError.Unavailable reason))
        | _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable "Select and refresh the game installation first."
                )
            )

    let id (workspace: Guid) (documents: DataRoot) =
        let physical =
            match documents.Identity.Device with
            | LinuxDevice(major, minor) ->
                "linux:"
                + major.ToString(Globalization.CultureInfo.InvariantCulture)
                + ":"
                + minor.ToString(Globalization.CultureInfo.InvariantCulture)
            | WindowsVolume serial ->
                "windows:" + serial.ToString(Globalization.CultureInfo.InvariantCulture)

        let key =
            workspace.ToString("N")
            + "\n"
            + GameId.value Skyrim.definition.Id
            + "\n"
            + physical
            + ":"
            + documents.Identity.Low.ToString(Globalization.CultureInfo.InvariantCulture)
            + ":"
            + documents.Identity.High.ToString(Globalization.CultureInfo.InvariantCulture)

        Guid(SHA256.HashData(Encoding.UTF8.GetBytes key) |> Array.take 16)

    let child (parent: DataRoot) name =
        use held = HeldDirectory.Open(parent.Path, parent.Identity)

        if held.InspectEntry name |> Option.isSome then
            raise (
                ProfileDataException(
                    ProfileDataError.Conflict
                        "The private folder already exists without a recorded identity."
                )
            )

        use created = held.CreateDirectory name

        { Path =
            HostPath.create (Path.Combine(HostPath.value parent.Path, name))
            |> Result.defaultWith invalidOp
          Identity = created.Identity }
        : DataRoot

    let existing (parent: DataRoot) (expected: DataRoot) =
        use held = HeldDirectory.Open(parent.Path, parent.Identity)

        use child =
            held.Directory(Path.GetFileName(HostPath.value expected.Path), Some expected.Identity)

        expected

    let iniNames (documents: HeldDirectory) =
        let entries = documents.Names |> Seq.toList

        Skyrim.definition.IniFiles
        |> List.map (fun declared ->
            let matches =
                entries
                |> List.filter (fun actual ->
                    actual.Equals(declared, StringComparison.OrdinalIgnoreCase))

            match matches with
            | [] -> declared, declared
            | [ actual ] -> declared, actual
            | _ -> DataFiles.fail (declared + " has more than one matching filename."))
