namespace ModConductor.Migration

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module internal Direct =
    type File =
        { Path: LogicalPath
          Read: FileStream -> CancellationToken -> Result<int64 * string, Error> }

    type Mod =
        { Id: Guid
          VersionId: Guid
          Kind: ModKind
          Metadata: ModMetadata
          CategorySourceIds: int list
          Files: File list }

    type Profile =
        { Id: Guid
          Name: string
          Mods: OrderedMod list }

    type Artifact =
        { Id: Guid
          OriginalName: string
          OriginalPath: string
          File: File
          Partial: bool
          Sources: string list
          InstalledMod: Guid option }

    type Input =
        { Categories: Category list
          Mods: Mod list
          Profiles: Profile list
          SelectedProfile: Guid
          Artifacts: Artifact list
          Verify: CancellationToken -> Result<unit, Error> }

    exception private Refused of Error

    let private refuse error = raise (Refused error)

    let private remove path =
        if Directory.Exists path then
            Directory.Delete(path, true)

    let migrateAtCheckpoint
        (store: IStore)
        workspace
        (readSource: unit -> Result<Input, Error>)
        (progress: Progress -> unit)
        (token: CancellationToken)
        checkpoint
        =
        task {
            let mutable target = None
            let mutable published = false
            let mutable committed = false

            try
                try
                    let! loaded = Task.Run(readSource, token)
                    let source = loaded |> Result.defaultWith refuse
                    token.ThrowIfCancellationRequested()
                    let action = Guid.NewGuid()
                    let staged = ".mod-conductor-migration-" + action.ToString("N") + ".partial"
                    let final = ".mod-conductor-library-" + Guid.NewGuid().ToString("N")
                    let! begun = store.Begin(workspace, action, staged, final)
                    let targetValue = begun |> Result.defaultWith refuse
                    target <- Some targetValue

                    let total =
                        source.Mods
                        |> List.sumBy (fun item -> item.Files.Length)
                        |> (+) source.Artifacts.Length

                    let mutable completed = 0

                    use root =
                        HeldDirectory.Open(targetValue.WorkspacePath, targetValue.WorkspaceIdentity)

                    use stage = root.CreateDirectory staged
                    let preparedMods = ResizeArray<ModConductor.Migration.Mod>()

                    for item in source.Mods do
                        let files = ResizeArray<ModConductor.Migration.File>()

                        for file in item.Files do
                            token.ThrowIfCancellationRequested()
                            let id = Guid.NewGuid()
                            let output, identity = stage.Create(id.ToString("N") + ".payload")
                            use output = output
                            let length, sha = file.Read output token |> Result.defaultWith refuse

                            files.Add
                                { Id = id
                                  Path = file.Path
                                  Length = length
                                  Sha256 = sha
                                  Identity = identity }

                            completed <- completed + 1

                            progress
                                { Completed = completed
                                  Total = total
                                  Message = "Copying mods" }

                        preparedMods.Add
                            { Id = item.Id
                              VersionId = item.VersionId
                              Kind = item.Kind
                              Metadata = item.Metadata
                              CategorySourceIds = item.CategorySourceIds
                              Files = List.ofSeq files }

                    let preparedArtifacts = ResizeArray<ModConductor.Migration.Artifact>()

                    for item in source.Artifacts do
                        token.ThrowIfCancellationRequested()

                        let fileName =
                            "artifact-"
                            + item.Id.ToString("N")
                            + if item.Partial then ".partial" else ".archive"

                        let output, identity = stage.Create fileName
                        use output = output
                        let length, sha = item.File.Read output token |> Result.defaultWith refuse

                        preparedArtifacts.Add
                            { Id = item.Id
                              OriginalName = item.OriginalName
                              OriginalPath = item.OriginalPath
                              FileName = fileName
                              File =
                                { Id = item.Id
                                  Path = item.File.Path
                                  Length = length
                                  Sha256 = sha
                                  Identity = identity }
                              Partial = item.Partial
                              Sources = item.Sources
                              InstalledMod = item.InstalledMod }

                        completed <- completed + 1

                        progress
                            { Completed = completed
                              Total = total
                              Message = "Copying downloads" }

                    checkpoint "before-source-recheck"
                    token.ThrowIfCancellationRequested()
                    source.Verify token |> Result.defaultWith refuse
                    checkpoint "before-publication"
                    token.ThrowIfCancellationRequested()

                    let! ready = store.Ready targetValue
                    ready |> Result.defaultWith refuse
                    token.ThrowIfCancellationRequested()

                    let stagedEntry =
                        match root.InspectEntry staged with
                        | Some entry when
                            entry.Kind = EntryKind.Directory && entry.Identity = stage.Identity
                            ->
                            entry
                        | _ -> refuse Error.SourceChanged

                    root.MoveOriginal(staged, stagedEntry, root, final)
                    published <- true
                    checkpoint "after-publication"
                    token.ThrowIfCancellationRequested()

                    let! result =
                        store.Complete
                            { Target = targetValue
                              LibraryIdentity = stagedEntry.Identity
                              Categories = source.Categories
                              Mods = List.ofSeq preparedMods
                              Profiles =
                                source.Profiles
                                |> List.map (fun value ->
                                    { Id = value.Id
                                      Name = value.Name
                                      Mods = value.Mods })
                              SelectedProfile = source.SelectedProfile
                              Artifacts = List.ofSeq preparedArtifacts }

                    match result with
                    | Ok value ->
                        committed <- true

                        progress
                            { Completed = total
                              Total = total
                              Message = "Migration complete" }

                        return Ok value
                    | Error error -> return Error error
                with
                | :? OperationCanceledException -> return Error Error.Cancelled
                | :? IOException as error -> return Error(Error.Unavailable error.Message)
                | :? UnauthorizedAccessException ->
                    return Error(Error.Unavailable "A source or workspace file is unavailable.")
                | Refused error -> return Error error
            finally
                match target with
                | Some value when not committed ->
                    let rootPath = HostPath.value value.WorkspacePath

                    try
                        remove (Path.Combine(rootPath, value.StagedName))

                        if published then
                            remove (Path.Combine(rootPath, value.FinalName))
                    with _ ->
                        ()

                    try
                        store.Abandon(value).GetAwaiter().GetResult()
                    with _ ->
                        ()
                | _ -> ()
        }
