namespace ModConductor.Engine

open ModConductor.Nexus
open ModConductor.Protocol.V1

type NexusInteractionsService(session: NexusSession, details: NexusModDetails) =
    inherit NexusInteractions.NexusInteractionsBase()

    let reply =
        function
        | Error error -> ModNexusInteractionsReply(Failure = NexusWire.failure error)
        | Ok(value: ModConductor.Nexus.ModNexusDetails) ->
            match value.Identity with
            | None -> ModNexusInteractionsReply(State = ModNexusInteractionState())
            | Some identity ->
                ModNexusInteractionsReply(
                    State = NexusMetadataWire.interaction (session.InteractionState identity)
                )

    override _.ReadModNexusInteractions(request, _) =
        task {
            let! result = NexusMetadataWire.expected details request
            return reply result
        }

    override _.ChangeModNexusInteraction(request, _) =
        task {
            let action =
                match request.Action with
                | "track" -> NexusInteraction.Track
                | "untrack" -> NexusInteraction.Untrack
                | "endorse" -> NexusInteraction.Endorse
                | "abstain" -> NexusInteraction.Abstain
                | _ -> ModLibraryWire.reject "Choose a Nexus action."

            let! expected = NexusMetadataWire.expected details request.Reference

            match expected with
            | Error error -> return reply (Error error)
            | Ok value ->
                let! result = details.Change(value, request.Revision, action)

                return
                    match result with
                    | Error error -> ModNexusInteractionsReply(Failure = NexusWire.failure error)
                    | Ok state ->
                        ModNexusInteractionsReply(State = NexusMetadataWire.interaction state)
        }
