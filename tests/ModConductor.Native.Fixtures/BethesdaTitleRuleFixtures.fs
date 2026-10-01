namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Bethesda
open ModConductor.GameContexts
open ModConductor.ProfileGameData
open ModConductor.Platform

module BethesdaTitleRuleFixtures =
    let private token = CancellationToken.None

    let private result value =
        value |> Result.defaultWith (fun error -> invalidOp (string error))

    let private check (writer: Utf8JsonWriter) (name: string) (value: bool) =
        writer.WriteBoolean(name, value)

        if not value then
            invalidOp ("Bethesda title rule failed: " + name)

    let private plugin rules name flags =
        use input = new MemoryStream(BethesdaSamples.header flags 1.0f [] false)
        HeaderReader.readFor rules name input token |> result

    let private archives (writer: Utf8JsonWriter) =
        let inspection = Inspection(Unchecked.defaultof<IArtifactSource>)

        for version in [ 1u; 2u; 3u; 7u; 8u ] do
            use source = new MemoryStream(BethesdaArchiveSamples.ba2 version)

            let passed =
                inspection.WithOwnedStream(
                    "fixture",
                    source,
                    token,
                    fun contents ->
                        let entry = contents.Manifest.Entries.Head
                        use output = new MemoryStream()
                        contents.ReadEntry(entry.Index, fun stream -> stream.CopyTo output)
                        Encoding.UTF8.GetString(output.ToArray()) = "archive payload"
                )

            check writer ("ba2GeneralPayloadV" + string version) passed

        use source = new MemoryStream(BethesdaArchiveSamples.morrowind ())

        let passed =
            inspection.WithOwnedStream(
                "fixture",
                source,
                token,
                fun contents ->
                    let entry = contents.Manifest.Entries.Head
                    use output = new MemoryStream()
                    contents.ReadEntry(entry.Index, fun stream -> stream.CopyTo output)

                    LogicalPath.display entry.Path = "meshes/example.txt"
                    && Encoding.UTF8.GetString(output.ToArray()) = "archive payload"
            )

        check writer "morrowindArchivePayloadAndPath" passed

        for version in [ 103u; 104u ] do
            use source = new MemoryStream(InvalidationArchive.bytes version)

            let passed =
                inspection.WithOwnedStream(
                    "fixture",
                    source,
                    token,
                    fun contents ->
                        contents.Manifest.Format = "BSA v" + string version
                        && contents.Manifest.Entries.Length = 1
                )

            check writer ("gameInvalidationArchiveV" + string version) passed

    let private ini (writer: Utf8JsonWriter) =
        let mw = GameCatalog.rules GameId.MorrowindSteam

        let original =
            Encoding.UTF8.GetBytes
                "; retained\r\n[Archives]\r\nArchive 0=Morrowind.bsa\r\nArchive 1=Old.bsa\r\nArchive 2=Obsolete.bsa\r\n[General]\r\nSkipIntro=1\r\n"

        let changed, receipt =
            IniArchives.applyFor mw [ "Morrowind.bsa"; "New.bsa" ] (Some original) |> result

        let names = Ini.tryArchiveEntriesFor [] changed |> result |> List.map _.Name

        check
            writer
            "morrowindArchiveListRestoresOriginalBytes"
            (names = [ "Morrowind.bsa"; "New.bsa" ]
             && Ini.removeArchives receipt changed = Ok(Some original))

        let fo4 = GameCatalog.rules GameId.Fallout4Steam

        let original =
            Encoding.UTF8.GetBytes
                "[Archive]\r\nbInvalidateOlderFiles=0\r\nsResourceDataDirsFinal=STRINGS\\\r\nSResourceStartUpArchiveList=Base.ba2\r\nOther=retained\r\n"

        let changed, receipt =
            IniArchives.applyFor fo4 [ "Base.ba2" ] (Some original) |> result

        check
            writer
            "creationLooseFilesAndRestore"
            (IniArchives.looseFilesEnabled changed = Ok true
             && Ini.removeArchives receipt changed = Ok(Some original))

    let private kinds (writer: Utf8JsonWriter) =
        let rules = GameCatalog.rules GameId.StarfieldSteam

        let headers =
            [ "Full.esm", 1u
              "Light.esm", 0x101u
              "Medium.esm", 0x401u
              "Overlay.esm", 0x201u
              "BlueprintShips-Full.esm", 0x801u ]
            |> List.map (fun (name, flags) -> name, plugin rules name flags)

        let header name =
            headers |> List.find (fst >> (=) name) |> snd

        check
            writer
            "starfieldFlagsKeepOverlayFull"
            ((header "Light.esm").Kind = PluginKind.LightMaster
             && (header "Medium.esm").Kind = PluginKind.MediumMaster
             && (header "Overlay.esm").Kind = PluginKind.Master)

        let rows =
            headers
            |> List.map (fun (name, header) ->
                { Name = name
                  Path = LogicalPath.create [ name ] |> result
                  Winner = None
                  Alternatives = []
                  Header = Ok header
                  Ambiguity = None
                  Masters = [] })

        let order enabled =
            { Document = [||]
              Entries =
                headers
                |> List.map (fun (name, _) ->
                    { Name = name
                      Enabled = Some(if name = "Full.esm" then enabled else true)
                      LockedIndex = None }) }
            |> BlueprintPlugins.synchronize

        let facts =
            { Early = []
              Required = []
              DefaultEnabled = []
              Implicit = [] }

        let on = OrderRules.inspectFor rules facts rows (order true)
        let off = OrderRules.inspectFor rules facts rows (order false)

        check
            writer
            "blueprintFollowsParentWithoutPluginSlot"
            (on.Full = 2
             && on.Light = 1
             && on.Medium = 1
             && off.Full = 1
             && (off.Order.Entries |> List.find (fun row -> row.Name = "BlueprintShips-Full.esm"))
                 .Enabled = Some false)


        let mw = GameCatalog.rules GameId.MorrowindSteam
        let bytes = BethesdaFamilySamples.header mw true
        use complete = new MemoryStream(bytes)
        use truncated = new MemoryStream(bytes[.. bytes.Length - 2])

        check
            writer
            "tes3IsNotTes4AndTruncationRefuses"
            (HeaderReader.readFor mw "Morrowind.esm" complete token
             |> Result.exists (fun header -> header.Kind = PluginKind.Master)
             && HeaderReader.readFor mw "Broken.esp" truncated token |> Result.isError)

    let observe (writer: Utf8JsonWriter) =
        writer.WriteStartObject "bethesdaTitleRules"
        archives writer
        ini writer
        kinds writer
        writer.WriteEndObject()
