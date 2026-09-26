namespace ModConductor.Migration

open System
open System.Collections.Generic
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module internal ModOrganizerProfiles =
    open ModOrganizerInput
    open ModOrganizerSettings
    open MigrationResult

    let private unsupported directory detail =
        Error(Error.UnsupportedData("The profile " + directory + " " + detail))

    let private profileEntries directory entries =
        entries
        |> List.filter (fun entry ->
            match components entry with
            | first :: _ -> String.Equals(first, directory, StringComparison.Ordinal)
            | _ -> false)

    let private checkLocalSaves directory entries =
        match
            entries
            |> List.tryFind (fun entry ->
                match components entry with
                | [ _; saves; _ ] ->
                    String.Equals(saves, "saves", StringComparison.OrdinalIgnoreCase)
                | _ -> false)
        with
        | Some _ ->
            unsupported
                directory
                "contains local saves. Turn off local saves in Mod Organizer, then try again."
        | None -> Ok()

    let private checkSettings root directory entries (stamps: ResizeArray<Stamp>) =
        result {
            match exactChild directory entries "settings.ini" with
            | None -> return ()
            | Some entry ->
                let! observed = stamp root entry
                stamps.Add observed
                let! content = text observed
                let values = ini content

                if boolSetting "LocalSaves" values || boolSetting "LocalSettings" values then
                    return!
                        unsupported
                            directory
                            "uses local game files. Move those files back to the game profile, then try again."
        }

    let private checkProfileFiles root directory entries (stamps: ResizeArray<Stamp>) =
        result {
            let blocked =
                set
                    [ "plugins.txt"
                      "loadorder.txt"
                      "lockedorder.txt"
                      "archives.txt"
                      "profile_tweaks.ini" ]

            for entry in entries do
                match components entry with
                | [ _; name ] when
                    blocked.Contains(name.ToLowerInvariant())
                    && entry.TargetKind = EntryKind.RegularFile
                    ->
                    let! observed = stamp root entry
                    stamps.Add observed
                    let! content = text observed

                    if meaningfulLines content then
                        return!
                            unsupported
                                directory
                                "contains game plug-in or profile settings that this migration cannot move safely."
                | [ _; name ] when
                    name.EndsWith(".ini", StringComparison.OrdinalIgnoreCase)
                    && not (name.Equals("settings.ini", StringComparison.OrdinalIgnoreCase))
                    && entry.TargetKind = EntryKind.RegularFile
                    ->
                    let! observed = stamp root entry
                    stamps.Add observed

                    if observed.Length > 0L then
                        return!
                            unsupported
                                directory
                                "contains local game settings that this migration cannot move safely."
                | _ -> ()
        }

    let private listedMods
        root
        directory
        entries
        (names: Dictionary<string, SourceMod>)
        (stamps: ResizeArray<Stamp>)
        =
        result {
            let! modlistEntry =
                match exactChild directory entries "modlist.txt" with
                | Some entry -> Ok entry
                | None ->
                    Error(Error.InvalidSource("The profile " + directory + " has no modlist.txt."))

            let! observed = stamp root modlistEntry
            stamps.Add observed
            let! content = text observed
            let seen = HashSet<string>(StringComparer.OrdinalIgnoreCase)
            let listed = ResizeArray<SourceMod * bool>()

            for raw in content.Replace("\r\n", "\n").Split('\n') do
                let line = raw.Trim()

                if line <> "" && not (line.StartsWith('#')) then
                    let enabled, name =
                        if line[0] = '-' then
                            false, line.Substring(1).Trim()
                        elif line[0] = '+' || line[0] = '*' then
                            true, line.Substring(1).Trim()
                        else
                            true, line

                    if name <> "" && seen.Add name then
                        match names.TryGetValue name with
                        | true, item when item.Kind <> ModKind.Backup -> listed.Add(item, enabled)
                        | true, _ -> ()
                        | _ ->
                            return!
                                Error(
                                    Error.InvalidSource(
                                        "The profile "
                                        + directory
                                        + " refers to a missing mod: "
                                        + name
                                        + "."
                                    )
                                )

            return seen, List.ofSeq listed |> List.rev
        }

    let private orderedMods
        (mods: SourceMod list)
        (seen: HashSet<string>)
        (listed: (SourceMod * bool) list)
        =
        let omitted =
            mods
            |> List.filter (fun item ->
                item.Kind <> ModKind.Backup && not (seen.Contains item.Name))
            |> List.sortWith (fun left right ->
                StringComparer.OrdinalIgnoreCase.Compare(left.Name, right.Name))

        listed @ (omitted |> List.map (fun item -> item, false))
        |> List.mapi (fun priority (item, enabled) ->
            { Id = item.Id
              Priority = priority
              Enabled = if item.Kind = ModKind.Separator then None else Some enabled })

    let private readProfile root entries mods names directory (stamps: ResizeArray<Stamp>) =
        result {
            let files = profileEntries directory entries
            do! checkLocalSaves directory files
            do! checkSettings root directory entries stamps
            do! checkProfileFiles root directory files stamps
            let! seen, listed = listedMods root directory entries names stamps

            return
                { Id = Guid.NewGuid()
                  Name = directory
                  Mods = orderedMods mods seen listed }
        }

    let readProfiles root entries (mods: SourceMod list) selectedName =
        result {
            let directories = rootDirectories entries

            if directories.IsEmpty then
                return! Error(Error.InvalidSource "The Mod Organizer workspace has no profiles.")

            let names = Dictionary<string, SourceMod>(StringComparer.OrdinalIgnoreCase)

            for item in mods do
                names[item.Name] <- item

            let stamps = ResizeArray<Stamp>()

            let! profiles =
                directories
                |> traverse (fun directory -> readProfile root entries mods names directory stamps)

            let selected =
                profiles
                |> List.filter (fun profile ->
                    profile.Name.Equals(selectedName, StringComparison.OrdinalIgnoreCase))

            match selected with
            | [ profile ] -> return profiles, profile.Id, List.ofSeq stamps
            | [] ->
                return! Error(Error.InvalidSource "The selected Mod Organizer profile is missing.")
            | _ -> return! Error(Error.CaseCollision selectedName)
        }
