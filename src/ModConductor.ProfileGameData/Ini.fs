namespace ModConductor.ProfileGameData

module internal Ini =
    let tryArchiveEntries = IniArchives.tryArchiveEntries
    let applyArchives = IniArchives.applyArchives
    let removeArchives = IniArchives.removeArchives
    let testFiles = IniSavePaths.testFiles
    let apply = IniSavePaths.apply
    let remove = IniSavePaths.remove
