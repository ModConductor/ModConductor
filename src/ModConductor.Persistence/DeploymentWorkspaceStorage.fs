namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations
open ModConductor.Deployment

module internal DeploymentWorkspaceStorage =
    let child (root: Location) name =
        use parent = HeldDirectory.Open(root.Path, root.Identity)
        use created = parent.CreateDirectory name

        { Path =
            HostPath.create (System.IO.Path.Combine(HostPath.value root.Path, name))
            |> Result.defaultWith invalidOp
          Identity = created.Identity }

    let private durableChild (root: Location) name =
        use parent = HeldDirectory.Open(root.Path, root.Identity)

        use directory =
            match parent.InspectEntry name with
            | None -> parent.CreateDirectory name
            | Some entry when entry.Kind = EntryKind.Directory ->
                parent.Directory(name, Some entry.Identity)
            | Some _ -> RecoveryFiles.fail "Owned working storage is not a directory."

        { Path =
            HostPath.create (System.IO.Path.Combine(HostPath.value root.Path, name))
            |> Result.defaultWith invalidOp
          Identity = directory.Identity }

    let componentWorking
        (workspace: Location)
        (profile: Guid)
        (components: ReviewedComponent list)
        =
        if components.IsEmpty then
            []
        else
            let root = durableChild workspace ".mc-component-working"
            let profileRoot = durableChild root (profile.ToString "N")

            components
            |> List.collect _.Writable
            |> List.map (fun declaration ->
                let relative =
                    LogicalPath.create [ declaration.Id.ToString("N") + ".working" ]
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid working file name.")

                { Declaration = declaration.Id
                  Initialized =
                    let location =
                        System.IO.Path.Combine(
                            HostPath.value profileRoot.Path,
                            LogicalPath.display relative
                        )

                    match declaration.Target with
                    | WritableTarget.File _ -> System.IO.File.Exists location
                    | WritableTarget.Subtree _ -> System.IO.Directory.Exists location
                  Root = profileRoot
                  Path = relative })
