namespace ModConductor.Platform

open System
open System.IO

module CapabilityProbe =
    let passive root =
        { Identity = RootSelection.facts root
          Write = NotTested "No write probe was requested."
          DistinctCaseNames = Unknown "Case behavior has not been tested."
          CaseOnlyRename = NotTested "No rename probe was requested."
          HardLink = NotTested "No hard-link probe was requested."
          SymbolicLink = NotTested "No symbolic-link probe was requested."
          LongPath = NotTested "No long-path probe was requested."
          TestedPathLength = None
          Reflink = NotTested "Reflink creation has not been tested."
          MetadataPreservation = NotTested "Metadata preservation has not been tested." }

    let private attempt action =
        try
            action ()
            Observed
        with
        | :? IOException as error -> Refused error.Message
        | :? UnauthorizedAccessException as error -> Refused error.Message
        | :? PlatformNotSupportedException as error -> Refused error.Message

    let private requireEmpty root =
        let path = RootSelection.path root |> HostPath.value

        if Directory.EnumerateFileSystemEntries path |> Seq.isEmpty then
            path
        else
            invalidArg "root" "Capability probes need an owned empty fixture directory."

    let private create path =
        use file =
            new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None)

        file.WriteByte 42uy
        file.Flush true

    let private sameFile left right =
        match Native.facts left, Native.facts right with
        | Ok { File = Known a }, Ok { File = Known b } -> Known(a = b)
        | _ -> Unknown "File identity was not available."

    /// The caller must own this empty disposable fixture. This is not a passive selected-root check.
    let probeOwnedFixture root =
        let directory = requireEmpty root
        let prefix = Guid.NewGuid().ToString("N")
        let path name = Path.Combine(directory, prefix + name)

        let source, differentCase, temporary, renamed =
            path "-case", path "-CASE", path "-temporary", path "-Case"

        let hard, symbolic, longRoot = path "-hard", path "-symbolic", path "-long"
        let baseline = passive root

        try
            let write =
                attempt (fun () ->
                    create source

                    if File.ReadAllBytes source <> [| 42uy |] then
                        invalidOp "The write probe did not read back its data.")

            match write with
            | Refused _
            | NotTested _ -> { baseline with Write = write }
            | Observed ->
                let distinct =
                    match attempt (fun () -> create differentCase) with
                    | Observed ->
                        sameFile source differentCase
                        |> function
                            | Known same -> Known(not same)
                            | Unknown reason -> Unknown reason
                    | Refused _ ->
                        sameFile source differentCase
                        |> function
                            | Known true -> Known false
                            | Known false
                            | Unknown _ -> Unknown "The second case variant could not be created."
                    | NotTested reason -> Unknown reason

                File.Delete differentCase
                // On an insensitive filesystem the alternate path names the source itself.
                if not (File.Exists source) then
                    create source

                let hardResult = Native.createHardLink source hard

                let symbolicResult =
                    attempt (fun () -> File.CreateSymbolicLink(symbolic, source) |> ignore)

                let rename =
                    attempt (fun () ->
                        let before = Native.facts source
                        File.Move(source, temporary)
                        File.Move(temporary, renamed)

                        if
                            not (
                                Directory.EnumerateFiles directory
                                |> Seq.exists (fun p ->
                                    String.Equals(p, renamed, StringComparison.Ordinal))
                            )
                            || before <> Native.facts renamed
                        then
                            invalidOp "The case-only rename did not preserve the file.")

                let mutable longDirectory = longRoot

                while longDirectory.Length < 512 do
                    longDirectory <-
                        Path.Combine(longDirectory, "long-name-012345678901234567890123")

                let longFile = Path.Combine(longDirectory, "file")

                let longResult =
                    attempt (fun () ->
                        Directory.CreateDirectory longDirectory |> ignore
                        create longFile

                        match Native.facts longFile with
                        | Ok facts when facts.Kind = EntryKind.RegularFile -> ()
                        | _ ->
                            raise (
                                IOException(
                                    "The platform adapter could not inspect the long path."
                                )
                            ))

                { baseline with
                    Write = write
                    DistinctCaseNames = distinct
                    CaseOnlyRename = rename
                    HardLink = hardResult
                    SymbolicLink = symbolicResult
                    LongPath = longResult
                    TestedPathLength = Some longFile.Length }
        finally
            for file in [ source; differentCase; temporary; renamed; hard; symbolic ] do
                File.Delete file

            if Directory.Exists longRoot then
                Directory.Delete(longRoot, true)

    let compareDevices source target =
        match (RootSelection.facts source).File, (RootSelection.facts target).File with
        | Known source, Known target ->
            if source.Device = target.Device then
                SameDevice
            else
                DifferentDevices
        | Unknown _, _
        | _, Unknown _ -> UnknownDevices

    /// Both roots must be owned empty disposable fixtures; no deployment operation is performed.
    let probeOwnedPair source target =
        let sourceDirectory, targetDirectory = requireEmpty source, requireEmpty target
        let name = Guid.NewGuid().ToString("N")

        let sourceFile, targetFile =
            Path.Combine(sourceDirectory, name), Path.Combine(targetDirectory, name + "-link")

        try
            let hardLink =
                match attempt (fun () -> create sourceFile) with
                | Observed -> Native.createHardLink sourceFile targetFile
                | other -> other

            { Devices = compareDevices source target
              HardLink = hardLink }
        finally
            File.Delete sourceFile
            File.Delete targetFile
