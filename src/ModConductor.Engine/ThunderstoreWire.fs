namespace ModConductor.Engine

open System
open ModConductor.Thunderstore
open ModConductor.Persistence
open ModConductor.Protocol.V1

module internal ThunderstoreWire =
    let package (source: PackageReference) =
        ThunderstorePackageReference(
            Community = source.Community,
            Namespace = source.Namespace,
            Name = source.Name
        )

    let readPackage (source: ThunderstorePackageReference) : PackageReference =
        if isNull source then
            { Community = ""
              Namespace = ""
              Name = "" }
        else
            { Community = source.Community
              Namespace = source.Namespace
              Name = source.Name }

    let reference (source: VersionReference) =
        ThunderstoreVersionReference(Package = package source.Package, Version = source.Version)

    let readReference (source: ThunderstoreVersionReference) : VersionReference =
        if isNull source then
            { Package = readPackage null
              Version = "" }
        else
            { Package = readPackage source.Package
              Version = source.Version }

    let workspace (value: string) =
        match Guid.TryParse value with
        | true, id when id <> Guid.Empty -> Some id
        | _ -> None

    let installed (source: InstalledThunderstorePackage) =
        ThunderstoreInstalled(Reference = reference source.Reference, ModId = string source.ModId)

    let failure source =
        let value = ThunderstoreFailure(Message = Problem.message source)

        match source with
        | Problem.RateLimited(Some at) -> value.RetryAtUnixMs <- at.ToUnixTimeMilliseconds()
        | _ -> ()

        value

    let preview (source: PackagePreview) versions =
        let value =
            ThunderstorePackagePreview(
                Package = package source.Package,
                Description = source.Description,
                Deprecated = source.Deprecated
            )

        source.Icon |> Option.iter (fun uri -> value.IconUrl <- uri.AbsoluteUri)
        value.Installed.AddRange(versions |> List.map installed)
        value

    let details (source: PackageDetails) latest versions existing =
        let value =
            ThunderstorePackageDetails(
                Reference = reference source.Reference,
                LatestVersion = latest,
                Description = source.Description,
                Deprecated = source.Deprecated,
                Bytes = uint64 source.Bytes
            )

        source.Icon |> Option.iter (fun uri -> value.IconUrl <- uri.AbsoluteUri)
        value.Categories.AddRange source.Categories
        value.Versions.AddRange versions
        value.Installed.AddRange(existing |> List.map installed)
        value

    let progress (source: ThunderstoreProgress) =
        let value =
            ThunderstoreAcquisition(
                Reference = reference source.Reference,
                Stage = source.Stage,
                Bytes = uint64 source.Bytes,
                Completed = source.Completed,
                Packages = source.Packages
            )

        source.Total |> Option.iter (fun total -> value.Total <- uint64 total)
        source.ModId |> Option.iter (fun id -> value.ModId <- string id)
        value
