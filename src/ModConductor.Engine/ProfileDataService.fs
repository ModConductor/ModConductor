namespace ModConductor.Engine

open System
open System.Threading.Channels
open ModConductor
open ModConductor.ProfileGameData

type ProfileDataService(profiles: IProfileGameData) =
    inherit Protocol.V1.ProfileDataOperations.ProfileDataOperationsBase()

    let send context output action =
        ProfileActionStream.send
            context
            output
            (fun (value: ProfileDataProgress) ->
                Protocol.V1.ProfileDataEvent(
                    Progress =
                        Protocol.V1.ProfileDataProgress(
                            Files = uint32 value.Files,
                            Bytes = uint64 value.Bytes
                        )
                ))
            ProfileDataWire.finished
            action

    override _.ReadProfileData(request, _) =
        task {
            let! result =
                profiles.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId
                )

            return ProfileDataWire.reply result
        }

    override _.EditProfileData(request, output, context) =
        if isNull request.Options then
            ModLibraryWire.reject "Choose the profile options."

        let initial =
            match request.InitialSaves with
            | Protocol.V1.InitialProfileSaves.Empty -> InitialSaves.Empty
            | Protocol.V1.InitialProfileSaves.CopyGlobal -> InitialSaves.CopyGlobal
            | _ -> ModLibraryWire.reject "Choose how the local saves start."

        let disabled =
            match request.DisabledFiles with
            | Protocol.V1.DisabledProfileFiles.Keep -> DisabledFiles.Keep
            | Protocol.V1.DisabledProfileFiles.Delete -> DisabledFiles.Delete
            | _ -> ModLibraryWire.reject "Choose whether to keep the local files."

        let edit =
            { Id = ModLibraryWire.id request.Id
              Expected = ProfileDataWire.readReference request.Expected
              Options =
                { Settings = request.Options.Settings
                  Saves = request.Options.Saves }
              InitialSaves = initial
              DisabledFiles = disabled }

        send context output (fun progress ->
            profiles.Edit(edit, progress, context.CancellationToken))

    override _.RestoreProfileData(request, output, context) =
        let id = ModLibraryWire.id request.Id
        let expected = ProfileDataWire.readReference request.Expected
        send context output (fun _ -> profiles.Restore(id, expected, context.CancellationToken))

    override _.ResumeProfileData(request, output, context) =
        let workspace, id =
            ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id

        send context output (fun _ -> profiles.Resume(workspace, id, context.CancellationToken))
