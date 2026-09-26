namespace ModConductor.Persistence

open System
open System.Security.Cryptography
open System.Threading
open ModConductor.ProfileGameData
open ModConductor.Workspaces

type internal ProfileMutationServices =
    { Database: StateDatabase
      Access: LibraryAccess
      Recovery: ModConductor.DeploymentRecovery.Recovery
      Repository: IProfileDataRepository }

type internal ProfileMutationRequest =
    { Workspace: Guid
      Expected: int64
      Command: ProfileEdit
      Progress: ProfileCopyProgress -> unit
      Token: CancellationToken
      BeforeCommit: unit -> unit
      CaptureCheckpoint: string -> unit }

module internal ProfileMutationSupport =
    let actionId (context: Guid) (target: Guid) purpose =
        Guid(
            SHA256.HashData(
                Array.concat [ context.ToByteArray(); target.ToByteArray(); [| purpose |] ]
            )
            |> Array.take 16
        )

    let contexts (database: StateDatabase) profile =
        let connection = database.Connection

        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    connection
                    null
                    "SELECT context_id FROM profile_data_profiles WHERE profile_id=$profile ORDER BY context_id"
                    [ "$profile", box (string profile) ]

            use reader = query.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()

            ids
            |> List.map (fun id ->
                ProfileDataRows.context connection null id |> Option.get,
                ProfileDataRows.profile connection null id profile |> Option.get))

    let initial id (context: ProfileDataContext) profile kind =
        { Id = id
          ContextId = context.Id
          ProfileId = profile
          ExpectedRevision = context.Revision
          Kind = kind
          Deletion = None
          CloneTarget = None
          Prepared = false
          WorkspaceStage = None
          DocumentsStage = None
          PluginStage = None
          ChangedProfile = None
          Files = []
          CompletedFiles = 0
          Link = SaveLinkEffect.Unchanged
          LinkRemoved = false
          LinkCreated = None
          Proposed = context.Applied
          Complete = false
          Problem = None }
        : ProfileDataActionRecord

    let claim (repository: IProfileDataRepository) context source id kind =
        task {
            let! action = repository.Claim(context, initial id context source kind)

            return
                { context with
                    Pending = Some action.Id },
                action
        }
