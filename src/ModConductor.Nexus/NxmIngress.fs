namespace ModConductor.Nexus

open System
open System.Threading

type internal NxmIngress
    (gate: obj, accountSubject: unit -> string option, context: unit -> int64 * bool) =
    let authorizations = NxmAuthorizations()

    let expiry =
        new Timer(
            TimerCallback(fun _ -> lock gate (fun () -> authorizations.Expire())),
            null,
            TimeSpan.FromSeconds 30.,
            TimeSpan.FromSeconds 30.
        )

    member _.Accept(id, input) =
        lock gate (fun () -> authorizations.Accept(id, input))

    member _.Read(id) =
        lock gate (fun () -> authorizations.Read id |> Result.map (fun link -> link.File))

    member _.Validate(id, subject) =
        lock gate (fun () ->
            authorizations.Validate(id, subject) |> Result.map (fun link -> link.File))

    member _.Admit(id, subject, invalidateLease: string * int64 * int64 * string -> unit) =
        lock gate (fun () ->
            let epoch, _ = context ()

            if accountSubject () <> Some subject then
                Error Nxm.mismatch
            else
                authorizations.Admit(id, subject)
                |> Result.map (fun (file, cancel) ->
                    if file.Keyed then
                        invalidateLease (file.Game, file.ModId, file.FileId, subject)

                    new NxmAdmission(
                        file,
                        fun () ->
                            lock gate (fun () ->
                                let current, cancelled = context ()

                                if epoch = current && not cancelled then
                                    cancel ())
                    )))

    member _.Grant(key) = authorizations.Grant key

    member _.Dismiss(id) =
        lock gate (fun () -> authorizations.Dismiss id)

    member _.Clear() = authorizations.Clear()

    interface IDisposable with
        member _.Dispose() = expiry.Dispose()
