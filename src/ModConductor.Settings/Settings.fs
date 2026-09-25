namespace ModConductor.Settings

open System
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.Settings.Serialization

[<RequireQualifiedAccess>]
type Appearance =
    | System
    | Light
    | Dark

[<RequireQualifiedAccess>]
type Contrast =
    | System
    | Standard
    | High

type Presentation =
    { Appearance: Appearance
      TextScale: double
      InterfaceScale: double
      Contrast: Contrast }

[<RequireQualifiedAccess>]
type SettingsScope =
    | Application
    | Workspace of string

type SettingsSnapshot =
    { Presentation: Presentation
      InheritsApplication: bool }

[<RequireQualifiedAccess>]
type SettingsError =
    | InvalidDocument of string
    | UnsupportedVersion of int64
    | InvalidValue of string
    | Unavailable

type SettingsOwner(applicationDirectory: string) =
    let utf8 = UTF8Encoding(false, true)
    let maxFileBytes = 32L * 1024L

    let defaults =
        { Appearance = Appearance.System
          TextScale = 1.0
          InterfaceScale = 1.0
          Contrast = Contrast.System }

    let path =
        function
        | SettingsScope.Application -> Path.Combine(applicationDirectory, "settings.toml")
        | SettingsScope.Workspace root -> Path.Combine(root, "mod-conductor.toml")

    let decodeAppearance =
        function
        | "system" -> Ok Appearance.System
        | "light" -> Ok Appearance.Light
        | "dark" -> Ok Appearance.Dark
        | _ -> Error(SettingsError.InvalidValue "The appearance value is not supported.")

    let decodeContrast =
        function
        | "system" -> Ok Contrast.System
        | "standard" -> Ok Contrast.Standard
        | "high" -> Ok Contrast.High
        | _ -> Error(SettingsError.InvalidValue "The contrast value is not supported.")

    let encodeAppearance =
        function
        | Appearance.System -> "system"
        | Appearance.Light -> "light"
        | Appearance.Dark -> "dark"

    let encodeContrast =
        function
        | Contrast.System -> "system"
        | Contrast.Standard -> "standard"
        | Contrast.High -> "high"

    let validate presentation =
        if
            Double.IsNaN presentation.TextScale
            || Double.IsInfinity presentation.TextScale
            || (presentation.TextScale <> 1.0
                && presentation.TextScale <> 1.25
                && presentation.TextScale <> 1.5)
        then
            Error(SettingsError.InvalidValue "The text scale value is not supported.")
        elif
            Double.IsNaN presentation.InterfaceScale
            || Double.IsInfinity presentation.InterfaceScale
            || (presentation.InterfaceScale <> 0.9 && presentation.InterfaceScale <> 1.0)
        then
            Error(SettingsError.InvalidValue "The interface scale value is not supported.")
        else
            Ok presentation

    let decode (scope: SettingsScope) (document: SettingsDocument) =
        if document.Version <> 1L then
            Error(SettingsError.UnsupportedVersion document.Version)
        else
            match document.Presentation with
            | null when scope = SettingsScope.Application ->
                Error(
                    SettingsError.InvalidDocument "Application settings need a presentation table."
                )
            | null ->
                Ok
                    { Presentation = defaults
                      InheritsApplication = true }
            | value ->
                match decodeAppearance value.Appearance, decodeContrast value.Contrast with
                | Ok appearance, Ok contrast ->
                    validate
                        { Appearance = appearance
                          TextScale = value.TextScale
                          InterfaceScale = value.InterfaceScale
                          Contrast = contrast }
                    |> Result.map (fun presentation ->
                        { Presentation = presentation
                          InheritsApplication = false })
                | Error error, _
                | _, Error error -> Error error

    let encode scope snapshot =
        let presentation =
            if scope <> SettingsScope.Application && snapshot.InheritsApplication then
                null
            else
                PresentationDocument(
                    Appearance = encodeAppearance snapshot.Presentation.Appearance,
                    TextScale = snapshot.Presentation.TextScale,
                    InterfaceScale = snapshot.Presentation.InterfaceScale,
                    Contrast = encodeContrast snapshot.Presentation.Contrast
                )

        SettingsDocument(Version = 1L, Presentation = presentation)

    let readText file =
        try
            use stream = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.Read)
            let bytes = Array.zeroCreate<byte> (int maxFileBytes + 1)
            let mutable count = 0
            let mutable reading = true

            while reading && count < bytes.Length do
                let next = stream.Read(bytes, count, bytes.Length - count)

                if next = 0 then reading <- false else count <- count + next

            if count > int maxFileBytes then
                Error(SettingsError.InvalidDocument "The settings file is larger than 32 KiB.")
            else
                let offset =
                    if
                        count >= 3 && bytes[0] = 0xEFuy && bytes[1] = 0xBBuy && bytes[2] = 0xBFuy
                    then
                        3
                    else
                        0

                Ok(utf8.GetString(bytes, offset, count - offset))
        with
        | :? DecoderFallbackException ->
            Error(SettingsError.InvalidDocument "The settings file is not valid UTF-8.")
        | :? IOException
        | :? UnauthorizedAccessException -> Error SettingsError.Unavailable

    member _.Defaults = defaults

    member _.Read(scope) =
        let file = path scope

        if not (File.Exists file) then
            Ok
                { Presentation = defaults
                  InheritsApplication = scope <> SettingsScope.Application }
        else
            readText file
            |> Result.bind (fun text ->
                try
                    SettingsToml.Deserialize text |> decode scope
                with :? Tomlyn.TomlException as error ->
                    Error(SettingsError.InvalidDocument error.Message))

    member internal _.SaveWithBoundary
        (scope, snapshot, beforeReplace: unit -> unit, token: CancellationToken)
        : Task<Result<SettingsSnapshot, SettingsError>> =
        task {
            let saved =
                if scope = SettingsScope.Application then
                    { snapshot with
                        InheritsApplication = false }
                else
                    snapshot

            match validate saved.Presentation with
            | Error error -> return Error error
            | Ok _ ->
                let file = path scope
                let parent = Path.GetDirectoryName file

                let temporary =
                    Path.Combine(parent, ".mc-settings-" + Guid.NewGuid().ToString("N") + ".tmp")

                try
                    try
                        token.ThrowIfCancellationRequested()
                        let text = SettingsToml.Serialize(encode scope saved)
                        let bytes = utf8.GetBytes text

                        if int64 bytes.Length > maxFileBytes then
                            return
                                Error(
                                    SettingsError.InvalidDocument
                                        "The settings file is larger than 32 KiB."
                                )
                        else
                            use output =
                                new FileStream(
                                    temporary,
                                    FileMode.CreateNew,
                                    FileAccess.Write,
                                    FileShare.None,
                                    4096,
                                    FileOptions.WriteThrough
                                )

                            do! output.WriteAsync(bytes.AsMemory(), token)
                            do! output.FlushAsync token
                            output.Flush true
                            output.Dispose()
                            token.ThrowIfCancellationRequested()
                            beforeReplace ()
                            File.Move(temporary, file, true)
                            return Ok saved
                    with
                    | :? OperationCanceledException -> return Error SettingsError.Unavailable
                    | :? IOException
                    | :? UnauthorizedAccessException -> return Error SettingsError.Unavailable
                finally
                    if File.Exists temporary then
                        try
                            File.Delete temporary
                        with _ ->
                            ()
        }

    member this.Save(scope, snapshot, token: CancellationToken) =
        this.SaveWithBoundary(scope, snapshot, ignore, token)
