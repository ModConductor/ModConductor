namespace ModConductor.InventoryExport.Tests

open System
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open FsUnit
open NUnit.Framework
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.ModSelection
open ModConductor.Platform
open ModConductor.Workspaces

[<TestFixture>]
type InventoryExportTests() =
    let value =
        function
        | Ok result -> result
        | Error error -> invalidOp (string error)

    let host path =
        HostPath.create path |> Result.defaultWith invalidOp

    let outputError expected =
        function
        | Error actual -> actual |> should equal expected
        | Ok _ -> Assert.Fail "The output operation did not fail."

    let exportError expected =
        function
        | Error actual -> actual |> should equal expected
        | Ok _ -> Assert.Fail "The export preparation did not fail."

    let row id name notes comment categories selection =
        { Entry =
            { Mod =
                { Id = id
                  WorkspaceId = Guid.Empty
                  Kind = ModKind.Regular
                  Metadata =
                    { Name = name
                      Notes = notes
                      Comment = comment
                      Version = "1.0"
                      Source = "local"
                      Categories = categories }
                  Revision = 1L
                  SourcePath = Some(LogicalPath.create [ "mods"; "source" ] |> value)
                  CurrentVersion = None
                  VersionOrigin = None
                  Status = InventoryStatus.Ready
                  Actions = [] }
              Selection = selection }
          GroupId = None
          GroupSize = None }

    [<Test>]
    member _.``CSV output should preserve text and apply the fixed portable format``() =
        task {
            let id = Guid.Parse "11111111-2222-3333-4444-555555555555"

            let categories =
                [ { Id = Guid.Parse "bbbbbbbb-0000-0000-0000-000000000000"
                    Label = "Two"
                    Missing = false }
                  { Id = Guid.Parse "aaaaaaaa-0000-0000-0000-000000000000"
                    Label = "One, missing"
                    Missing = true } ]

            let value =
                row
                    id
                    " =SUM(A1), Café"
                    "first\r\nsecond"
                    "say \"yes\""
                    categories
                    (SelectionState.Managed(0, true))

            let fields =
                InventoryExportCsv.canonical
                    [ InventoryExportField.Comment
                      InventoryExportField.Categories
                      InventoryExportField.Name
                      InventoryExportField.ModId
                      InventoryExportField.Notes ]

            let path = Path.GetTempFileName()

            try
                let output = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None)

                let! _ =
                    InventoryExportCsv.write
                        output
                        fields
                        [ value ]
                        (fun _ -> Task.CompletedTask)
                        CancellationToken.None

                output.Flush()
                output.Dispose()
                let bytes = File.ReadAllBytes path
                bytes[0..2] |> should not' (equal [| 0xEFuy; 0xBBuy; 0xBFuy |])
                let text = Encoding.UTF8.GetString bytes

                text
                |> should
                    equal
                    ("\"mod_id\",\"name\",\"notes\",\"comment\",\"categories\"\r\n"
                     + "\"11111111222233334444555555555555\",\"' =SUM(A1), Café\",\"first\r\nsecond\",\"say \"\"yes\"\"\",\"One, missing [aaaaaaaa000000000000000000000000] | Two [bbbbbbbb000000000000000000000000]\"\r\n")
            finally
                File.Delete path
        }
        :> Task

    [<Test>]
    member _.``atomic output should preserve a destination on refusal cancellation and failure``() =
        task {
            let directory =
                Directory.CreateDirectory(
                    Path.Combine(Path.GetTempPath(), "mc-export-" + Guid.NewGuid().ToString("N"))
                )

            try
                let destination = Path.Combine(directory.FullName, "mods.csv")
                File.WriteAllText(destination, "original", UTF8Encoding(false))
                let inspected = AtomicOutput.inspect (host destination) |> value

                let! refused =
                    AtomicOutput.write
                        inspected
                        false
                        (fun _ _ -> Task.FromResult 0L)
                        CancellationToken.None

                refused |> outputError AtomicOutputError.ReplacementRequired

                let! failed =
                    AtomicOutput.write
                        inspected
                        true
                        (fun output _ ->
                            task {
                                do! output.WriteAsync([| 1uy; 2uy |])
                                return raise (IOException "injected write failure")
                            })
                        CancellationToken.None

                failed |> outputError AtomicOutputError.WriteFailed
                File.ReadAllText destination |> should equal "original"
                Directory.GetFiles(directory.FullName, ".mc-csv-*.tmp") |> should be Empty

                use cancelled = new CancellationTokenSource()

                let! stopped =
                    AtomicOutput.write
                        inspected
                        true
                        (fun output token ->
                            task {
                                do! output.WriteAsync([| 3uy |], token)
                                cancelled.Cancel()
                                token.ThrowIfCancellationRequested()
                                return 1L
                            })
                        cancelled.Token

                stopped |> outputError AtomicOutputError.Cancelled
                File.ReadAllText destination |> should equal "original"
                Directory.GetFiles(directory.FullName, ".mc-csv-*.tmp") |> should be Empty
            finally
                directory.Delete true
        }
        :> Task

    [<Test>]
    member _.``atomic output should not replace a destination that changes during staging``() =
        task {
            let directory =
                Directory.CreateDirectory(
                    Path.Combine(Path.GetTempPath(), "mc-export-" + Guid.NewGuid().ToString("N"))
                )

            try
                let destination = Path.Combine(directory.FullName, "mods.csv")
                File.WriteAllText(destination, "original", UTF8Encoding(false))
                let inspected = AtomicOutput.inspect (host destination) |> value

                let! result =
                    AtomicOutput.write
                        inspected
                        true
                        (fun output token ->
                            task {
                                do! output.WriteAsync(Encoding.UTF8.GetBytes "export", token)
                                File.WriteAllText(destination, "foreign", UTF8Encoding(false))
                                return 6L
                            })
                        CancellationToken.None

                result |> outputError AtomicOutputError.DestinationChanged
                File.ReadAllText destination |> should equal "foreign"

                let staged = Directory.GetFiles(directory.FullName, ".mc-csv-*.tmp")
                staged.Length |> should equal 1
                File.ReadAllText staged[0] |> should equal "export"
            finally
                directory.Delete true
        }
        :> Task

    [<Test>]
    member _.``export preparation should reject row and byte limits before destination work``() =
        task {
            let workspaceId, profileId = Guid.NewGuid(), Guid.NewGuid()

            let query =
                { Text = ""
                  Mode = FilterMode.All
                  Filters = []
                  View = OrganizationView.Flat
                  Sort = OrganizationSort.Priority }

            let workspace =
                { Id = workspaceId
                  Name = "Export"
                  Path = host (Path.GetTempPath())
                  Revision = 1L
                  SelectedProfile = Some { Id = profileId; Name = "Profile" }
                  PendingRoot = None }

            let workspaces =
                { new IWorkspaceState with
                    member _.Read(id, _) =
                        Task.FromResult(
                            if id = workspaceId then
                                Ok
                                    { Workspace = workspace
                                      Profiles = [ workspace.SelectedProfile.Value ]
                                      NextProfile = None }
                            else
                                Error WorkspaceError.NotFound
                        )

                    member _.Create(_, _, _) = raise (NotSupportedException())
                    member _.Open _ = raise (NotSupportedException())
                    member _.Edit(_, _, _) = raise (NotSupportedException())
                    member _.EditWithProgress(_, _, _, _, _) = raise (NotSupportedException())
                    member _.ResumeProfileEdit(_, _, _, _) = raise (NotSupportedException())
                    member _.Check(_, _) = raise (NotSupportedException())
                    member _.Recent _ = raise (NotSupportedException()) }

            let prepare rows fields =
                let organization =
                    { new IModOrganization with
                        member _.Query(_, _, _, _) =
                            Task.FromResult(
                                Ok
                                    { CatalogueRevision = 1L
                                      SelectionRevision = 1L
                                      QueryIdentity = OrganizationPolicy.identity profileId query
                                      Entries = rows
                                      Context = []
                                      Inspected = None
                                      Next = None
                                      MatchingMods = rows.Length
                                      MatchingSeparators = 0
                                      MatchingGroups = 0
                                      TotalMods = rows.Length
                                      EnabledCount = 0 }
                            )

                        member _.Categories(_, _, _, _) = raise (NotSupportedException())
                        member _.EditCategory(_, _, _) = raise (NotSupportedException()) }

                InventoryExportSession(workspaces, organization).Prepare
                    { WorkspaceId = workspaceId
                      WorkspaceRevision = 1L
                      ProfileId = profileId
                      Scope = InventoryExportScope.All
                      SelectedModIds = []
                      Query = query
                      QueryIdentity = OrganizationPolicy.identity profileId query
                      CatalogueRevision = 1L
                      SelectionRevision = 1L
                      Fields = fields }

            let small = row Guid.Empty "name" "" "" [] (SelectionState.Managed(0, false))

            let! tooMany =
                prepare
                    (List.replicate (InventoryExportCsv.maximumRows + 1) small)
                    [ InventoryExportField.Name ]

            tooMany |> exportError InventoryExportError.LimitExceeded

            let large =
                row Guid.Empty "name" (String('x', 8192)) "" [] (SelectionState.Managed(0, false))

            let! tooLarge =
                prepare
                    (List.replicate 8192 large)
                    [ InventoryExportField.Name; InventoryExportField.Notes ]

            tooLarge |> exportError InventoryExportError.LimitExceeded
        }
        :> Task
