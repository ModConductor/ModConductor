module ModConductor.Engine.NxmIngress

let internal create
    (nexus: ModConductor.Nexus.NexusSession)
    (skse: SkseCoordinator)
    (enb: EnbCoordinator)
    (fnis: FnisCoordinator)
    =
    new ModConductor.Desktop.PrivateIngress(
        (fun (id, input) ->
            let accepted = nexus.AcceptNxm(id, input)

            if accepted then
                match nexus.ReadNxm id with
                | Ok file when file.ModId = ModConductor.Skse.SkseResolver.NexusModId ->
                    skse.AcceptNxm id
                | Ok file when
                    file.ModId = ModConductor.Enb.EnbCatalogue.LeanModId
                    || file.ModId = ModConductor.Enb.EnbCatalogue.CathedralModId
                    ->
                    enb.AcceptNxm id
                | Ok file when file.ModId = ModConductor.Fnis.FnisCatalogue.NexusModId ->
                    fnis.AcceptNxm id
                | Ok _ -> ()
                | Error _ ->
                    skse.AcceptNxm id
                    enb.AcceptNxm id
                    fnis.AcceptNxm id

            accepted),
        nexus.DismissNxm
    )
