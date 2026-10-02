namespace ModConductor.Persistence

open ModConductor.BepInEx

module internal BepInExWorkingStorage =
    let available = LoaderWorkingStorage.available

    let readConfig root profile =
        LoaderWorkingStorage.within root profile WorkingPaths.config true (fun directory _ ->
            LoaderWorkingStorage.read directory "BepInEx.cfg" |> Result.map fst)

    let saveConfig root profile original content =
        LoaderWorkingStorage.within root profile WorkingPaths.config true (fun directory _ ->
            LoaderWorkingStorage.save directory "BepInEx.cfg" original content)

    let readLog root profile =
        LoaderWorkingStorage.within
            root
            profile
            (fst WorkingPaths.logs.Head)
            false
            (fun directory name -> LoaderWorkingStorage.read directory name.Value |> Result.map fst)
