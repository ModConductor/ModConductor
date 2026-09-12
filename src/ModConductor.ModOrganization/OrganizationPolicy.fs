namespace ModConductor.ModOrganization

open System
open System.Security.Cryptography
open System.Text
open ModConductor.ModLibrary

module OrganizationPolicy =
    let contains (value: string) (query: string) =
        value.Contains(query, StringComparison.OrdinalIgnoreCase)

    let compareNames (left: string) (right: string) =
        StringComparer.OrdinalIgnoreCase.Compare(left, right)

    let normalize query =
        if
            isNull query.Text
            || query.Text.Length > 1024
            || query.Text.Contains '\000'
            || query.Filters.Length > 16
        then
            Error LibraryError.LimitExceeded
        elif
            query.Filters
            |> List.exists (function
                | ModFilter.Category(value, _) ->
                    value.Id = Guid.Empty || isNull value.Label || value.Label.Length > 256
                | _ -> false)
        then
            Error LibraryError.InvalidMetadata
        else
            Ok { query with Text = query.Text.Trim() }

    let identity (profile: Guid) query =
        let atom (value: string) = string value.Length + ":" + value

        let filter =
            function
            | ModFilter.Category(value, children) ->
                "category:" + string value.Id + ":" + string children
            | ModFilter.Kind kind ->
                "kind:"
                + (match kind with
                   | ModKind.Regular -> "regular"
                   | ModKind.Separator -> "separator"
                   | ModKind.Backup -> "backup"
                   | ModKind.Unmanaged -> "unmanaged"
                   | ModKind.GeneratedOutput -> "output")
            | ModFilter.Status status ->
                "status:"
                + (match status with
                   | InventoryStatus.Ready -> "ready"
                   | InventoryStatus.Detached -> "detached"
                   | InventoryStatus.Changed -> "changed"
                   | InventoryStatus.Unproved -> "unproved"
                   | InventoryStatus.Publishing -> "publishing"
                   | InventoryStatus.Deleting -> "deleting")
            | ModFilter.Enabled enabled ->
                "enabled:"
                + (match enabled with
                   | None -> "na"
                   | Some true -> "yes"
                   | Some false -> "no")
            | ModFilter.Uncategorized -> "uncategorized"
            | ModFilter.MissingCategory -> "missing"

        [ profile.ToString("N")
          atom query.Text
          (match query.Mode with
           | FilterMode.All -> "all"
           | FilterMode.Any -> "any")
          (match query.View with
           | OrganizationView.Flat -> "flat"
           | OrganizationView.Groups -> "groups")
          (match query.Sort with
           | OrganizationSort.Priority -> "priority"
           | OrganizationSort.Name -> "name")
          query.Filters
          |> List.map filter
          |> List.sort
          |> List.map atom
          |> String.concat "" ]
        |> String.concat "|"
        |> Encoding.UTF8.GetBytes
        |> SHA256.HashData
        |> Convert.ToHexString
