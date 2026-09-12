namespace ModConductor.Bain

open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.Platform

type Package =
    { Index: int
      Name: string
      Root: string list
      Files: SelectedFile list
      Bytes: int64 }

type Candidate =
    { Package: int
      Name: string
      File: SelectedFile
      Source: LogicalPath }

type Definition =
    { Root: string list
      Packages: Package list
      Candidates: Map<string, Candidate list>
      Notes: ArchiveEntry option }

type PackageInput =
    { Definition: Definition option
      Problem: string option
      Scripts: LogicalPath list }

type PackageSelection =
    { Definition: Definition
      Selected: Set<int>
      Excluded: Set<string>
      Files: Map<string, ReviewedFile>
      Reviewing: bool }

type PackageChoices =
    { Draft: InstallationDraft
      Input: PackageInput
      Selection: PackageSelection option
      Problem: string option }
