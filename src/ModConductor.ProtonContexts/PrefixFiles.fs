namespace ModConductor.ProtonContexts

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform
open ModConductor.GameContexts

module internal PrefixFiles =
    let directory path =
        HostPath.create path
        |> Result.bind (fun p ->
            RootSelection.select p
            |> Result.mapError (fun _ -> "The folder is unavailable."))
        |> Result.bind (fun root ->
            match (RootSelection.facts root).File with
            | Unknown _ -> Error "The folder identity is unavailable."
            | Known id -> Ok(RootSelection.path root |> HostPath.value, id))
        |> Result.defaultWith (fun message -> raise (IOException message))

    let read limit path =
        let parent, identity = directory (Path.GetDirectoryName(path: string))

        use held =
            HeldDirectory.Open(HostPath.create parent |> Result.defaultWith invalidOp, identity)

        let stream, fileId = held.Read(Path.GetFileName path, None)
        use stream = stream

        if stream.Length > int64 limit then
            raise (IOException "The context file exceeds the read limit.")

        let length = stream.Length
        let modified = File.GetLastWriteTimeUtc stream.SafeFileHandle
        let bytes = Array.zeroCreate<byte> (int length)
        stream.ReadExactly(bytes)
        use current = fst (held.Read(Path.GetFileName path, Some fileId))

        if
            stream.Length <> length
            || current.Length <> length
            || File.GetLastWriteTimeUtc stream.SafeFileHandle <> modified
        then
            raise (IOException "The context file changed during the check.")

        bytes,
        { Path = Path.Combine(parent, Path.GetFileName path)
          Identity = fileId
          Sha256 = SHA256.HashData bytes |> Convert.ToHexStringLower }

    let text limit path =
        let bytes, evidence = read limit path
        UTF8Encoding(false, true).GetString(bytes), evidence

    let contained (root: string) (path: string) =
        path = root
        || path.StartsWith(
            root.TrimEnd(Path.DirectorySeparatorChar) + string Path.DirectorySeparatorChar,
            StringComparison.Ordinal
        )
