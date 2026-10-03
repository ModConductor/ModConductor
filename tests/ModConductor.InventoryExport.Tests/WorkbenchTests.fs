namespace ModConductor.InventoryExport.Tests

open System
open System.IO
open System.Threading.Tasks
open FsUnit
open NUnit.Framework
open Microsoft.Data.Sqlite
open ModConductor.DeploymentPlanning
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

[<TestFixture>]
type WorkbenchTests() =
    let value result =
        result |> Result.defaultWith (fun error -> invalidOp (string error))

    let metadata name =
        { Name = name
          Notes = ""
          Comment = ""
          Version = ""
          Source = ""
          Categories = [] }

    let query =
        { Text = ""
          Mode = FilterMode.All
          Filters = []
          View = OrganizationView.Groups
          Sort = OrganizationSort.Priority }

    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()

    [<Test>]
    member _.``prior private database schemas should be refused without changing their files``() =
        let area =
            Path.Combine(
                Environment.GetEnvironmentVariable "MC_TEST_ROOT"
                |> Option.ofObj
                |> Option.defaultValue (Path.GetTempPath()),
                "schema-" + Guid.NewGuid().ToString("N")
            )

        Directory.CreateDirectory area |> ignore

        try
            for version in [ 1; 2 ] do
                let state = Directory.CreateDirectory(Path.Combine(area, string version)).FullName
                let path = Path.Combine(state, "state.db")

                do
                    use connection = new SqliteConnection("Data Source=" + path + ";Pooling=False")
                    connection.Open()
                    use command = connection.CreateCommand()

                    command.CommandText <-
                        "CREATE TABLE prior_state(value INTEGER); INSERT INTO prior_state VALUES(42); PRAGMA application_id=1296253774; PRAGMA user_version="
                        + string version

                    command.ExecuteNonQuery() |> ignore

                let bytes = File.ReadAllBytes path
                let entries = Directory.GetFileSystemEntries state |> Array.sort

                Assert.Throws<InvalidOperationException>(
                    Action(fun () -> use _ = new OperationStore(state) in ())
                )
                |> ignore

                File.ReadAllBytes path |> should equal bytes
                Directory.GetFileSystemEntries state |> Array.sort |> should equal entries
        finally
            Directory.Delete(area, true)

    [<Test>]
    member _.``organization moves should include filtered group members without changing file winners or enablement``
        ()
        =
        let area =
            Path.Combine(
                Environment.GetEnvironmentVariable "MC_TEST_ROOT"
                |> Option.ofObj
                |> Option.defaultValue (Path.GetTempPath()),
                "workbench-" + Guid.NewGuid().ToString("N")
            )

        Directory.CreateDirectory area |> ignore

        try
            let state = Path.Combine(area, "state")
            let mutable store = new OperationStore(state)

            use lifetime =
                { new IDisposable with
                    member _.Dispose() = (store :> IDisposable).Dispose() }

            let workspaces = store.Workspaces :> IWorkspaceState
            let library = store.ModLibrary :> IModLibrary
            let organization = store.ModOrganization :> IModOrganization
            let selection = store.ModSelection :> IModSelection

            let workspace, profile, first, second =
                Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

            let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
            let selectedRoot = HostPath.create root |> value |> RootSelection.select |> value
            let created = workspaces.Create(workspace, "Test", selectedRoot) |> wait |> value

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Main" }
            )
            |> wait
            |> value
            |> ignore

            let register id name registration =
                library.Register(workspace, id, metadata name, registration) |> wait |> value

            register first "First" Registration.Separator |> ignore
            let low = Guid.NewGuid()

            let addFiles id name =
                let folder = Directory.CreateDirectory(Path.Combine(root, name)).FullName
                File.WriteAllText(Path.Combine(folder, "shared.txt"), name)

                let entry =
                    register
                        id
                        name
                        (Registration.Directory(
                            ModKind.Regular,
                            LogicalPath.create [ name ] |> value
                        ))

                library.Publish(id, entry.Revision, Guid.NewGuid()) |> wait |> value |> ignore

            addFiles low "Low"

            let hidden =
                [ for index in 1..40 do
                      let id = Guid.NewGuid()
                      let name = "Hidden" + string index
                      Directory.CreateDirectory(Path.Combine(root, name)) |> ignore

                      register
                          id
                          name
                          (Registration.Directory(
                              ModKind.Regular,
                              LogicalPath.create [ name ] |> value
                          ))
                      |> ignore

                      yield id ]

            register second "Second" Registration.Separator |> ignore
            let high = Guid.NewGuid()
            addFiles high "High"

            let readFrom (organization: IModOrganization) =
                let rec page cursor =
                    let result = organization.Query(profile, query, cursor, None) |> wait |> value

                    result.Entries
                    @ (result.Next |> Option.map (Some >> page) |> Option.defaultValue [])

                page None

            let read () = readFrom organization

            let revision () =
                (organization.Query(profile, query, None, None) |> wait |> value).SelectionRevision

            selection.Change(profile, revision (), [ low; high ], SelectionEdit.Enable true)
            |> wait
            |> value
            |> ignore

            let winner () =
                let target = Guid.NewGuid()

                let mods =
                    read ()
                    |> List.choose (fun row ->
                        match row.Entry.Selection, row.Entry.Mod.CurrentVersion with
                        | SelectionState.Managed(priority, enabled), Some version ->
                            Some
                                { ModId = row.Entry.Mod.Id
                                  Priority = priority
                                  Enabled = enabled
                                  Version = Some(library.Version(version, 0) |> wait |> value)
                                  Mappings =
                                    [ { SourcePrefix = PlanPath.Root
                                        TargetRoot = target
                                        TargetPrefix = PlanPath.Root } ]
                                  Archives = [] }
                        | _ -> None)

                let input =
                    { Profile =
                        { ProfileId = profile
                          Revision = revision ()
                          Complete = true
                          Mods = mods }
                      Roots =
                        [ { Id = target
                            Policy = TargetPolicy.windows } ]
                      ReadOnly = []
                      Writable = [] }

                match Planner.compute input with
                | PlanningResult.Blocked _ -> invalidOp "The test file plan was blocked."
                | PlanningResult.Ready plan -> (Planner.view plan).ReadOnlyFiles.Head.Winner.LayerId

            let before =
                read ()
                |> List.map (fun row -> row.Entry.Mod.Id, row.Entry.Selection)
                |> Map.ofList

            winner () |> should equal high
            // Only the header is supplied, as when its members are collapsed or filtered out.
            organization.Change(
                profile,
                revision (),
                [ second ],
                OrganizationEdit.Place(first, OrganizationPlacement.Before)
            )
            |> wait
            |> value
            |> ignore

            let moved = read ()

            moved
            |> List.map (fun row -> row.Entry.Mod.Id, row.Entry.Selection)
            |> Map.ofList
            |> should equal before

            moved
            |> List.map (fun row -> row.Entry.Mod.Id)
            |> should equal ([ second; high; first; low ] @ hidden)

            moved
            |> List.filter (fun row -> row.GroupId = Some first)
            |> List.map (fun row -> row.Entry.Mod.Id)
            |> should equal (low :: hidden)

            winner () |> should equal high

            organization.Change(
                profile,
                revision (),
                [ low; hidden[0] ],
                OrganizationEdit.Place(hidden[1], OrganizationPlacement.After)
            )
            |> wait
            |> value
            |> ignore

            winner () |> should equal high

            let orderBeforeFiles =
                read () |> List.map (fun row -> row.Entry.Mod.Id, row.Position, row.GroupId)

            selection.Change(profile, revision (), [ low ], SelectionEdit.MoveFilesDown)
            |> wait
            |> value
            |> ignore

            winner () |> should equal low

            read ()
            |> List.map (fun row -> row.Entry.Mod.Id, row.Position, row.GroupId)
            |> should equal orderBeforeFiles

            let beforeGrouping =
                read ()
                |> List.map (fun row -> row.Entry.Mod.Id, row.Entry.Selection)
                |> Map.ofList

            organization.Change(
                profile,
                revision (),
                [ high; List.last hidden ],
                OrganizationEdit.Place(first, OrganizationPlacement.Inside)
            )
            |> wait
            |> value
            |> ignore

            let grouped = read ()

            grouped
            |> List.map (fun row -> row.Entry.Mod.Id, row.Entry.Selection)
            |> Map.ofList
            |> should equal beforeGrouping

            grouped
            |> List.filter (fun row ->
                row.Entry.Mod.Id = high || row.Entry.Mod.Id = List.last hidden)
            |> List.map (fun row -> row.Entry.Mod.Id, row.GroupId)
            |> should equal [ high, Some first; List.last hidden, Some first ]

            winner () |> should equal low

            let current = revision ()

            organization.Change(profile, current - 1L, [ first ], OrganizationEdit.MoveDown)
            |> wait
            |> should equal (Error LibraryError.StaleRevision: Result<int64, LibraryError>)

            revision () |> should equal current
            let saved = read ()
            (store :> IDisposable).Dispose()
            store <- new OperationStore(state)
            readFrom (store.ModOrganization :> IModOrganization) |> should equal saved
        finally
            Directory.Delete(area, true)

    [<Test>]
    member _.``grouping should preserve selected member order and layout should survive reopening independently``
        ()
        =
        let first, second, a, b, c =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let item id position group separator =
            { Id = id
              Position = position
              GroupId = group
              IsSeparator = separator }

        let current =
            [ item first 0 None true
              item a 1 (Some first) false
              item b 2 (Some first) false
              item second 3 None true
              item c 4 (Some second) false ]

        let grouped =
            GroupPolicy.change [ c; a ] (OrganizationEdit.Group second) current |> value

        grouped
        |> List.filter (fun row -> row.GroupId = Some second)
        |> List.map _.Id
        |> should equal [ a; c ]

        grouped
        |> List.filter (fun row -> row.GroupId = Some first)
        |> List.map _.Id
        |> should equal [ b ]

        let moved =
            GroupPolicy.change [ second; a ] OrganizationEdit.MoveDown grouped |> value

        moved
        |> List.filter (fun row -> row.GroupId = Some second)
        |> List.map _.Id
        |> should equal [ a; c ]

        let area =
            Path.Combine(
                Environment.GetEnvironmentVariable "MC_TEST_ROOT"
                |> Option.ofObj
                |> Option.defaultValue (Path.GetTempPath()),
                "layout-" + Guid.NewGuid().ToString("N")
            )

        Directory.CreateDirectory area |> ignore

        try
            let state, root =
                Path.Combine(area, "state"),
                Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

            let workspace, profile, clone = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
            let layout = [ "plugin:base.esm"; "files:" + string a; "plugin:patch.esp" ]

            do
                use store = new OperationStore(state)
                let workspaces = store.Workspaces :> IWorkspaceState

                let created =
                    workspaces.Create(
                        workspace,
                        "Test",
                        HostPath.create root |> value |> RootSelection.select |> value
                    )
                    |> wait
                    |> value

                workspaces.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = profile; Name = "Main" }
                )
                |> wait
                |> value
                |> ignore

                let organization = store.ModOrganization :> IModOrganization
                let before = organization.Query(profile, query, None, None) |> wait |> value
                organization.SaveLoadOrderLayout(profile, layout) |> wait |> value

                (organization.Query(profile, query, None, None) |> wait |> value).SelectionRevision
                |> should equal before.SelectionRevision

                workspaces.Edit(
                    workspace,
                    created.Workspace.Revision + 1L,
                    ProfileEdit.Clone(profile, { Id = clone; Name = "Copy" })
                )
                |> wait
                |> value
                |> ignore

                organization.LoadOrderLayout clone |> wait |> value |> should equal layout
                organization.SaveLoadOrderLayout(clone, List.rev layout) |> wait |> value
                organization.LoadOrderLayout profile |> wait |> value |> should equal layout

            use reopened = new OperationStore(state)

            (reopened.ModOrganization :> IModOrganization).LoadOrderLayout profile
            |> wait
            |> value
            |> should equal layout

            (reopened.ModOrganization :> IModOrganization).LoadOrderLayout clone
            |> wait
            |> value
            |> should equal (List.rev layout)
        finally
            Directory.Delete(area, true)

    [<Test>]
    member _.``drag placement should preserve whole group membership and reject cross parent reorders``
        ()
        =
        let first, second, a, b, c, d =
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid()

        let item id position group separator : OrganizationItem =
            { Id = id
              Position = position
              GroupId = group
              IsSeparator = separator }

        let current =
            [ item first 0 None true
              item a 1 (Some first) false
              item b 2 (Some first) false
              item second 3 None true
              item c 4 (Some second) false
              item d 5 (Some second) false ]

        let changed =
            GroupPolicy.change
                [ first; a ]
                (OrganizationEdit.Place(c, OrganizationPlacement.After))
                current
            |> value

        changed |> List.map _.Id |> should equal [ second; c; d; first; a; b ]

        changed
        |> List.map (fun row -> row.Id, row.GroupId)
        |> Map.ofList
        |> should equal (current |> List.map (fun row -> row.Id, row.GroupId) |> Map.ofList)

        GroupPolicy.change [ a ] (OrganizationEdit.Place(c, OrganizationPlacement.Before)) current
        |> should
            equal
            (Error LibraryError.UnsupportedAction: Result<OrganizationItem list, LibraryError>)

        GroupPolicy.change
            [ first ]
            (OrganizationEdit.Place(b, OrganizationPlacement.Before))
            current
        |> should
            equal
            (Error LibraryError.UnsupportedAction: Result<OrganizationItem list, LibraryError>)

        let grouped =
            GroupPolicy.change
                [ d; a ]
                (OrganizationEdit.Place(second, OrganizationPlacement.Inside))
                current
            |> value

        grouped |> List.map _.Id |> should equal [ first; b; second; c; a; d ]

        grouped
        |> List.filter (fun row -> row.GroupId = Some second)
        |> List.map _.Id
        |> should equal [ c; a; d ]
