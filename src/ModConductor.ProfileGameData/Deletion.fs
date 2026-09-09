namespace ModConductor.ProfileGameData

open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

module internal ProfileDeletion =
    let prepare (trees: SaveTree list) (roots: ProfileDataDirectoryRemoval list) =
        let directories =
            trees
            |> List.collect (fun tree ->
                let parents = tree.Directories |> Map.ofList |> Map.add [] tree.Root

                tree.Directories
                |> List.rev
                |> List.map (fun (parts, root) ->
                    { Parent = parents[List.take (parts.Length - 1) parts]
                      Name = List.last parts
                      Identity = root.Identity }))

        { Files = trees |> List.collect (fun tree -> tree.Files |> List.map snd)
          Directories = directories @ roots
          CompletedFiles = 0
          CompletedDirectories = 0 }
        : ProfileDataDeletion

    let run
        (initial: ProfileDataActionRecord)
        (save: ProfileDataActionRecord -> Task<unit>)
        (token: CancellationToken)
        progress
        =
        task {
            let mutable action = initial
            let mutable deletion = action.Deletion.Value

            for file in deletion.Files |> List.skip deletion.CompletedFiles do
                token.ThrowIfCancellationRequested()
                use parent = HeldDirectory.Open(file.Root.Path, file.Root.Identity)

                match DataFiles.observe parent file.Name token with
                | None -> ()
                | Some actual when actual = file.File ->
                    parent.RemoveFile(file.Name, file.File.Identity)
                | Some _ -> DataFiles.fail (file.Name + " changed. It was left untouched.")

                deletion <-
                    { deletion with
                        CompletedFiles = deletion.CompletedFiles + 1 }

                action <- { action with Deletion = Some deletion }
                do! save action

                progress
                    { Files = deletion.CompletedFiles
                      Bytes = 0L }

            for directory in deletion.Directories |> List.skip deletion.CompletedDirectories do
                token.ThrowIfCancellationRequested()
                use parent = HeldDirectory.Open(directory.Parent.Path, directory.Parent.Identity)

                match parent.InspectEntry directory.Name with
                | None -> ()
                | Some entry when
                    entry.Kind = EntryKind.Directory && entry.Identity = directory.Identity
                    ->
                    parent.RemoveDirectory(directory.Name, directory.Identity)
                | Some _ -> DataFiles.fail (directory.Name + " changed. It was left untouched.")

                deletion <-
                    { deletion with
                        CompletedDirectories = deletion.CompletedDirectories + 1 }

                action <- { action with Deletion = Some deletion }
                do! save action

            return action
        }
