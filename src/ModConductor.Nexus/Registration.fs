namespace ModConductor.Nexus

open System

module internal Registration =
    let validate (value: NexusRegistration) =
        let allowed (uri: Uri) =
            uri.IsAbsoluteUri
            && uri.UserInfo = ""
            && uri.Fragment = ""
            && (uri.Scheme = "https" || (uri.Scheme = "http" && uri.Host = "127.0.0.1"))

        let origin (uri: Uri) = uri.GetLeftPart(UriPartial.Authority)

        if
            ([ value.Issuer; value.Authorize; value.Token; value.UserInfo; value.Api ]
             |> List.exists (allowed >> not))
            || ([ value.Authorize; value.Token; value.UserInfo ]
                |> List.exists (fun uri -> origin uri <> origin value.Issuer))
            || String.IsNullOrWhiteSpace value.ClientId
            || value.Scopes.IsEmpty
            || not (value.RedirectPath.StartsWith("/", StringComparison.Ordinal))
            || value.RedirectPath.Contains('?')
            || value.RedirectPath.Contains('#')
            || value.RedirectPort < 0
            || value.RedirectPort > 65535
        then
            invalidArg
                "registration"
                "The approved Nexus endpoint or redirect configuration is invalid."
