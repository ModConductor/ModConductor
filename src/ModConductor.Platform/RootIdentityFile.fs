namespace ModConductor.Platform

open System
open System.IO
open System.Runtime.InteropServices
open Microsoft.Win32.SafeHandles

module RootIdentityFile =
    let name = ".mod-conductor-root"

    let private identity kind handle =
        match Native.handleFacts handle with
        | Ok { File = Known id; Kind = actual } when kind = actual -> id
        | _ -> raise (IOException("The held object identity is not available or its type changed."))

    let private openRoot path expectedIdentity =
        let handle = Native.directoryHandle (HostPath.value path)

        try
            let actual = identity EntryKind.Directory handle

            if expectedIdentity <> actual then
                raise (IOException("The selected root changed."))

            handle
        with _ ->
            handle.Dispose()
            reraise ()

    let private checkContents (contents: byte array) =
        if isNull contents || contents.Length = 0 || contents.Length > 256 then
            invalidArg "contents" "Use a root identity record of 1 to 256 bytes."

    let validateRoot path expectedIdentity =
        use directory = openRoot path expectedIdentity
        ()

    let create path rootIdentity (contents: byte array) =
        checkContents contents
        use directory = openRoot path rootIdentity
        use handle = RelativeFile.openChild directory name false true
        use file = new FileStream(handle, FileAccess.Write)
        file.Write contents
        file.Flush true
        identity EntryKind.RegularFile handle

    let matches path rootIdentity expectedIdentity (contents: byte array) =
        checkContents contents
        use directory = openRoot path rootIdentity
        use handle = RelativeFile.openChild directory name false false

        if identity EntryKind.RegularFile handle <> expectedIdentity then
            false
        else
            use file = new FileStream(handle, FileAccess.Read)
            let observed = Array.zeroCreate<byte> (contents.Length + 1)
            let mutable count = 0
            let mutable reading = true

            while reading && count < observed.Length do
                let read = file.Read(observed, count, observed.Length - count)
                if read = 0 then reading <- false else count <- count + read

            count = contents.Length && observed[0 .. count - 1] = contents
