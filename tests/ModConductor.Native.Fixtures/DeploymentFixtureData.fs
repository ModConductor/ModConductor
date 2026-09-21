namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Runtime.InteropServices
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.Persistence

module internal DeploymentFixtureData =
    exception Interrupted

    let interrupt wanted phase index =
        if phase = wanted && (index = 0 || index = -1) then
            raise Interrupted

    let stopped action =
        try
            action () |> ignore
            invalidOp "Expected an interruption."
        with Interrupted ->
            ()

    let id value =
        Guid.Parse((string value).PadLeft(32, '0'))

    let rootId = id 1
    let contextId = id 2

    let path (value: string) =
        LogicalPath.create (value.Split('/') |> Array.toList)
        |> Result.defaultWith (fun _ -> invalidOp "Invalid fixture path.")

    let target value : TargetFile = { Root = rootId; Path = path value }
    let get (task: Task<'T>) = task.GetAwaiter().GetResult()

    let ok =
        function
        | Ok value -> value
        | Error error -> raise (RecoveryException error)

    let location value =
        let host = HostPath.create value |> Result.defaultWith invalidOp

        let selected =
            RootSelection.select host
            |> Result.defaultWith (fun _ -> invalidOp "Fixture root unavailable.")

        match (RootSelection.facts selected).File with
        | Known identity ->
            { Path = RootSelection.path selected
              Identity = identity }
        | Unknown _ -> invalidOp "Fixture identity unavailable."

    [<DllImport("libc", EntryPoint = "link", SetLastError = true)>]
    extern int private link(string source, string target)

    [<DllImport("kernel32.dll",
                EntryPoint = "CreateHardLinkW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern int private hardLink(string target, string source, nativeint security)

    let private share source target =
        let result =
            if OperatingSystem.IsLinux() then
                link (source, target) = 0
            else
                hardLink (target, source, 0n) <> 0

        if not result then
            invalidOp "The owned immutable fixture could not create its hard link."

    let private write root name (value: string) =
        let file = Path.Combine(root, name)
        Directory.CreateDirectory(Path.GetDirectoryName file) |> ignore
        File.WriteAllText(file, value)
        file

    let input revision directory files =
        let entries: SnapshotFile list =
            files
            |> List.map (fun (name, _, _) ->
                let source = path (rootId.ToString("N") + "/" + name)

                let metadata =
                    RecoveryFiles.withParent (location directory) source (fun parent child ->
                        parent.InspectFile(child, None))

                { Path = path name
                  Identity =
                    SnapshotFileIdentity.Metadata
                        { Identity = metadata.Identity
                          Length = metadata.Length
                          Modified = metadata.Modified } })

        { Profile =
            { ProfileId = id 3
              Revision = revision
              Complete = true
              Mods = [] }
          Roots =
            [ { Id = rootId
                Policy =
                  if OperatingSystem.IsWindows() then
                      TargetPolicy.windows
                  else
                      TargetPolicy.linux } ]
          ReadOnly =
            [ { Id = id 4
                Generation = "fixture-" + string revision
                Kind = ReadOnlyLayerKind.Base
                Priority = 0
                Complete = true
                Files = entries
                Mappings =
                  [ { SourcePrefix = PlanPath.Root
                      TargetRoot = rootId
                      TargetPrefix = PlanPath.Root } ]
                Archives = [] } ]
          Writable =
            [ { Id = id 5
                Target = WritableTarget.Subtree(rootId, PlanPath.At(path "outputs")) } ] }

    let ready input =
        match Planner.compute input with
        | PlanningResult.Ready plan -> plan
        | PlanningResult.Blocked _ -> invalidOp "Fixture plan blocked."

    type Area =
        { Root: string
          State: string
          Game: string
          Originals: string
          First: Generation
          Second: Generation
          Bindings: RootBinding list }

    let create root =
        Directory.CreateDirectory root |> ignore
        let game = Path.Combine(root, "game")
        let originals = Path.Combine(root, "originals")
        let state = Path.Combine(root, "state")

        for directory in [ game; originals; state; Path.Combine(game, "outputs") ] do
            Directory.CreateDirectory directory |> ignore

        write game "outputs/save.dat" "save-one" |> ignore
        let shared = write root "payloads/shared.payload" "shared"

        let firstFiles =
            [ "shared.txt", "shared", 10
              "removed.txt", "old", 11
              "folder/file.txt", "directory-old", 12 ]

        let secondFiles =
            [ "shared.txt", "shared", 10
              "added.txt", "new", 13
              "folder/file.txt", "directory-new", 14 ]

        let prepare number (files: (string * string * int) list) =
            let directory = Path.Combine(root, "generation-" + string number)
            Directory.CreateDirectory directory |> ignore

            for name, value, _ in files do
                let dest = Path.Combine(directory, rootId.ToString("N"), name)
                Directory.CreateDirectory(Path.GetDirectoryName dest) |> ignore

                if name = "shared.txt" then
                    share shared dest
                else
                    File.WriteAllText(dest, value)

            let proposed = input (int64 number) directory files
            Generations.capture (id (200 + number)) (location directory) (ready proposed) proposed

        let first = prepare 1 firstFiles
        let second = prepare 2 secondFiles

        { Root = root
          State = state
          Game = game
          Originals = originals
          First = first
          Second = second
          Bindings =
            [ { Root = first.Roots.Head
                Directory = location game
                Originals = location originals } ] }

    let request area receipt revision generation =
        { Id = receipt
          ContextId = contextId
          ContextFingerprint = "owned-fixture-context"
          ExpectedRevision = revision
          Roots = area.Bindings
          Generation = generation
          DirectoryBoundaries = [ target "folder" ]
          PreserveOriginals = []
          ExpectedSources = None }

    let run (store: OperationStore) (receipt: Receipt) restore hook =
        get (
            store.Deployment.Run(
                receipt.Id,
                receipt.Revision,
                restore,
                CancellationToken.None,
                hook
            )
        )

    let start (store: OperationStore) area receipt revision generation =
        get (store.Deployment.Start(request area receipt revision generation)) |> ok

    let apply (store: OperationStore) receipt =
        run store receipt false (fun _ _ -> ()) |> ok

    let read (store: OperationStore) id =
        get (store.Deployment.Read id) |> Option.get

    let context (store: OperationStore) =
        get (store.Deployment.Context contextId) |> Option.get

    let check condition name =
        if not condition then
            invalidOp ("Deployment fixture: " + name)

    let contents area name =
        File.ReadAllText(Path.Combine(area.Game, name))
