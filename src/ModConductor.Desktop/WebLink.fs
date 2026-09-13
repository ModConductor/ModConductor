namespace ModConductor.Desktop

open System
open System.Diagnostics
open System.Threading
open System.Threading.Tasks

module WebLink =
    let openBrowser (uri: Uri, token: CancellationToken) : Task =
        task {
            token.ThrowIfCancellationRequested()

            if
                not uri.IsAbsoluteUri
                || uri.Scheme <> "https"
                || uri.UserInfo <> ""
                || uri.OriginalString |> Seq.exists Char.IsControl
            then
                invalidArg "uri" "This website address is not supported."

            use browser =
                Process.Start(ProcessStartInfo(uri.AbsoluteUri, UseShellExecute = true))

            ()
        }
