namespace ModConductor.Engine

open System
open ModConductor.Bethesda
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

module internal PluginOrderWire =
    let reply =
        function
        | Error error -> PluginOrderReply(Problem = ProfileDataWire.problem error)
        | Ok(value: ModConductor.ProfileGameData.ProfilePluginOrder) ->
            let headers = BethesdaPluginWire.reply (Ok value.Headers)

            if not (isNull headers.Fault) then
                PluginOrderReply(
                    Problem =
                        ProfileDataWire.problem (ProfileDataError.Unavailable headers.Fault.Detail)
                )
            else
                let result =
                    ProfilePluginOrder(
                        Reference = ProfileDataWire.reference value.Reference,
                        Headers = headers.Snapshot,
                        Full = value.View.Full,
                        Light = value.View.Light,
                        FullLimit = value.View.FullLimit,
                        Saved = value.Saved,
                        Applied = value.Applied,
                        ExternalChanged = value.ExternalChanged,
                        Pending = value.Pending,
                        PendingProblem = Option.defaultValue "" value.Problem
                    )

                for entry in value.View.Order.Entries do
                    let row =
                        PluginOrderSetting(
                            Name = entry.Name,
                            Required = (OrderRules.requirement value.Facts entry.Name).IsSome,
                            RequiredReason =
                                (match OrderRules.requirement value.Facts entry.Name with
                                 | Some PluginRequirement.Engine -> PluginRequiredReason.Engine
                                 | Some PluginRequirement.SkyrimIni ->
                                     PluginRequiredReason.SkyrimIni
                                 | None -> PluginRequiredReason.Unspecified)
                        )

                    entry.Enabled |> Option.iter (fun enabled -> row.Enabled <- enabled)
                    entry.LockedIndex |> Option.iter (fun index -> row.LockedIndex <- index)
                    result.Entries.Add row

                let known name =
                    value.Headers.Entries
                    |> List.exists (fun entry ->
                        entry.Name.Equals(name, StringComparison.OrdinalIgnoreCase))

                for name, enabled in
                    (OrderDocument.names value.View.Order.Document
                     @ (value.View.Order.Entries
                        |> List.map (fun entry -> entry.Name, entry.Enabled = Some true)))
                    |> List.filter (fun (name, _) -> not (known name))
                    |> List.distinctBy (fun (name, _) -> name.ToUpperInvariant()) do
                    result.Unknown.Add(PluginOrderSetting(Name = name, Enabled = enabled))

                for issue in value.View.Issues do
                    result.Issues.Add(
                        PluginOrderIssue(
                            Name = Option.defaultValue "" issue.Name,
                            Detail = issue.Detail
                        )
                    )

                if result.CalculateSize() > 17 * 1024 * 1024 - 1024 then
                    PluginOrderReply(
                        Problem =
                            ProfileDataWire.problem (
                                ProfileDataError.Unavailable
                                    "The plugin order exceeds the reply limit."
                            )
                    )
                else
                    PluginOrderReply(Order = result)

type PluginOrderService(orders: IProfilePluginOrders) =
    inherit PluginOrders.PluginOrdersBase()

    override _.ReadPluginOrder(request, _) =
        task {
            let! result =
                orders.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.id request.HeadersId
                )

            return PluginOrderWire.reply result
        }

    override _.ChangePluginOrder(request, _) =
        task {
            let names = List.ofSeq request.Names

            let change =
                match request.ChangeCase with
                | ChangePluginOrderRequest.ChangeOneofCase.Enabled ->
                    PluginOrderChange.Enable(names, request.Enabled)
                | ChangePluginOrderRequest.ChangeOneofCase.MoveUp ->
                    PluginOrderChange.Move(names, request.MoveUp)
                | ChangePluginOrderRequest.ChangeOneofCase.Locked ->
                    PluginOrderChange.Lock(names, request.Locked)
                | ChangePluginOrderRequest.ChangeOneofCase.None ->
                    ModLibraryWire.reject "Choose a plugin action."
                | _ -> ModLibraryWire.reject "The plugin action is not supported."

            let! result =
                orders.Change(
                    ProfileDataWire.readReference request.Expected,
                    ModLibraryWire.id request.HeadersId,
                    change
                )

            return PluginOrderWire.reply result
        }

    override _.UseGamePluginOrder(request, _) =
        task {
            let! result =
                orders.UseGameOrder(
                    ProfileDataWire.readReference request.Expected,
                    ModLibraryWire.id request.HeadersId
                )

            return PluginOrderWire.reply result
        }
