namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.DeploymentRecovery
open ModConductor.Persistence

module internal PersistenceEncodingFixtures =
    let private marker (version: int) = BitConverter.GetBytes version

    let private textMarker version =
        marker version |> Convert.ToBase64String

    let private rejectsActivation action =
        try
            action ()
            false
        with RecoveryException(RecoveryError.Corrupt message) ->
            message = "The activation record version is unsupported."

    let private rejects message action =
        try
            action ()
            false
        with :? InvalidDataException as error ->
            error.Message = message

    let observe (writer: Utf8JsonWriter) =
        writer.WriteStartObject("codecVersions")

        writer.WriteBoolean(
            "deploymentContext",
            rejectsActivation (fun () -> DeploymentEncoding.contextFrom (marker 2) |> ignore)
        )

        writer.WriteBoolean(
            "deploymentReceipt",
            rejectsActivation (fun () -> DeploymentEncoding.receiptFrom (marker 2) |> ignore)
        )

        writer.WriteBoolean(
            "deploymentGeneration",
            rejectsActivation (fun () -> DeploymentEncoding.generationFrom (marker 5) |> ignore)
        )

        writer.WriteBoolean(
            "executablePreset",
            rejects "The executable record version is unsupported." (fun () ->
                ExecutableEncoding.decodePreset (textMarker 2) |> ignore)
        )

        writer.WriteBoolean(
            "executableRun",
            rejects "The executable record version is unsupported." (fun () ->
                ExecutableEncoding.decodeRun (textMarker 3) |> ignore)
        )

        writer.WriteBoolean(
            "outputAction",
            rejects "The output action record version is unsupported." (fun () ->
                OutputEncoding.decode (marker 2) |> ignore)
        )

        writer.WriteBoolean(
            "profileContext",
            rejects "The profile settings record version is unsupported." (fun () ->
                ProfileDataEncoding.readContext (marker 5) |> ignore)
        )

        writer.WriteBoolean(
            "profile",
            rejects "The profile settings record version is unsupported." (fun () ->
                ProfileDataEncoding.readProfile (marker 5) |> ignore)
        )

        writer.WriteBoolean(
            "profileAction",
            rejects "The profile settings record version is unsupported." (fun () ->
                ProfileDataEncoding.readAction (marker 5) |> ignore)
        )

        writer.WriteEndObject()
