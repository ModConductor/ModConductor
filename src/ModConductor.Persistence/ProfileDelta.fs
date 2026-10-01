namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open FastRsync.Core
open FastRsync.Delta
open FastRsync.Signature

module internal ProfileDelta =
    let private checkFile (input: Stream) expected length (token: CancellationToken) =
        task {
            if input.Length <> length then
                raise (InvalidDataException "The profile file length does not match its metadata.")

            let! hash = SHA256.HashDataAsync(input, token)
            let digest = Convert.ToHexStringLower hash

            if not (String.Equals(digest, expected, StringComparison.OrdinalIgnoreCase)) then
                raise (InvalidDataException "The profile file does not match its exact source.")

            input.Position <- 0L
        }

    let encode baseFile baseSha edited editedSha editedLength patch token =
        task {
            use basis = File.OpenRead baseFile
            use input = File.OpenRead edited
            do! checkFile basis baseSha basis.Length token
            do! checkFile input editedSha editedLength token

            use signature =
                new FileStream(
                    patch + ".signature",
                    FileMode.CreateNew,
                    FileAccess.ReadWrite,
                    FileShare.None,
                    4096,
                    FileOptions.Asynchronous ||| FileOptions.DeleteOnClose
                )

            let signatures =
                SignatureBuilder(
                    SupportedAlgorithms.Hashing.XxHash3(),
                    SupportedAlgorithms.Checksum.Adler32RollingV3()
                )

            do! signatures.BuildAsync(basis, SignatureWriter(signature), token)
            do! signature.FlushAsync token
            signature.Position <- 0L
            use output = File.Create patch
            let builder = DeltaBuilder()
            let reader = SignatureReader(signature, null)
            let writer = AggregateCopyOperationsDecorator(BinaryDeltaWriter(output))
            do! builder.BuildDeltaAsync(input, reader, writer, token)
        }

    let decode baseFile baseSha patch edited editedSha editedLength token =
        task {
            use basis = File.OpenRead baseFile
            do! checkFile basis baseSha basis.Length token
            use input = File.OpenRead patch
            use output = new FileStream(edited, FileMode.CreateNew, FileAccess.ReadWrite)
            let applier = DeltaApplier(SkipHashCheck = true)
            do! applier.ApplyAsync(basis, BinaryDeltaReader(input, null), output, token)
            do! output.FlushAsync token
            output.Position <- 0L
            do! checkFile output editedSha editedLength token
        }
