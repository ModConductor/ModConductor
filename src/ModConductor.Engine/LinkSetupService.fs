namespace ModConductor.Engine

open System.Threading.Tasks
open ModConductor.Desktop
open ModConductor.Protocol.V1

type LinkSetupService(setup: ILinkSetup) =
    inherit NexusLinkSetup.NexusLinkSetupBase()

    let wire (status: LinkSetupStatus) =
        let value =
            LinkSetupReply(
                Windows = status.Windows,
                Changed = status.Changed,
                CanRemove = status.CanRemove
            )

        status.Available |> Option.iter (fun available -> value.Available <- available)
        status.Problem |> Option.iter (fun problem -> value.Problem <- problem)

        value.DefaultApp <-
            match status.Default with
            | ModConductor.Desktop.LinkDefault.ModConductor ->
                ModConductor.Protocol.V1.LinkDefault.Mc
            | ModConductor.Desktop.LinkDefault.AnotherApp ->
                ModConductor.Protocol.V1.LinkDefault.Other
            | ModConductor.Desktop.LinkDefault.None -> ModConductor.Protocol.V1.LinkDefault.None
            | ModConductor.Desktop.LinkDefault.Unknown ->
                ModConductor.Protocol.V1.LinkDefault.Unknown

        value

    override _.ReadLinkSetup(_, _) = Task.FromResult(wire (setup.Read()))

    override _.AddLinkSetup(request, _) =
        Task.FromResult(wire (setup.Add request.Executable))

    override _.RemoveLinkSetup(_, _) = Task.FromResult(wire (setup.Remove()))

    override _.OpenLinkDefaults(_, _) =
        Task.FromResult(wire (setup.OpenSettings()))
