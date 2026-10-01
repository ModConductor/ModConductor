namespace ModConductor.ProfileGameData

module internal Ini =
    let tryArchiveEntriesFor = IniArchives.tryArchiveEntriesFor
    let applyArchivesFor = IniArchives.applyArchivesFor
    let tryArchiveEntries = IniArchives.tryArchiveEntries
    let applyArchives = IniArchives.applyArchives
    let removeArchives = IniArchiveRestoration.removeArchives
    let testFiles = IniSavePaths.testFiles
    let apply = IniSavePaths.apply
    let remove = IniSavePaths.remove
