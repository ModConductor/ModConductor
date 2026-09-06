# Workspaces and profiles

Create a workspace in a folder that you choose. Mod Conductor registers that folder and creates one identity file. Existing files stay unchanged. Open a workspace by choosing its registered folder, or select it from **Saved workspaces**.

A workspace has a stable ID, a display name, profiles, and a selected profile. A profile currently contains a stable ID and display name. The first profile becomes selected. You can rename a selected profile. Select another profile before you delete it. Clone creates a new profile ID with the requested name. It does not copy mods or files. Delete removes only that workspace's profile row.

## Storage and ownership

`ModConductor.Workspaces` owns feature types and profile policy. The adapter in `ModConductor.Persistence` uses the existing database queue, owner leases, and owned-root receipts. The engine service maps typed Protobuf requests and results. `mc_client` owns authenticated transport; `mc_workspaces` owns presentation state and page composition.

Schema 3 adds workspace and profile metadata to the central `state.db`. It does not create a database in each workspace. Opening a folder requires its registration in this installation's state store, its recorded directory identity, and its original identity file. Copying the folder or its marker does not import it into another store. Moving the registered folder is not a relocation workflow. Unregistered, replaced, or unavailable roots are refused. No Windows registry entries are used.

Workspace creation records its name and root intent in one database transaction. File creation occurs outside that transaction through the existing handle-relative root helper. The observed file identity and completed receipt follow the file effect. A crash can leave a pending receipt. **Check again** checks that receipt; it does not adopt a file whose ownership is unproved. Unresolved creation blocks profile changes, but does not prevent leaving the workspace. The UI distinguishes an incomplete creation from an unproved creation and an identity that cannot currently be verified. An unproved creation requires another folder for a new workspace; it does not prove that a foreign file exists. An observed receipt can be checked again if access returns. Raw OS error text is not sent as a workspace status.

Profile changes are metadata-only transactions. Each request carries the workspace's expected revision. A successful change increments that revision once. A stale request changes nothing. Clone and deletion are scoped to both workspace and profile IDs. These transactions do not change the runtime-check revision or root-receipt revision. They do not authorize future deployment writes.

A workspace page contains at most 32 profiles and a cursor. Its selected profile is supplied even when it is outside that page. Saved-workspace pages contain at most eight entries. These lists are bounded windows, not claims of a complete inventory. Profile pages from different revisions cannot be combined.

Closing the page changes navigation only. It does not cancel an accepted request. A disconnected mutation can have an unknown result: refresh the workspace rather than treating the missing reply as rollback. Workspace creation retries retain their ID while that client session remains alive; persisted pending roots remain available through saved workspaces after restart.

## Folder selection

The shared `WorkspaceDialog` uses `file_selector` to open the native directory chooser on Linux and Windows. Cancel leaves the form unchanged. The returned path is only a candidate; F# validates its native identity. The app shows the complete selected path. This picker is the reusable directory-selection owner for later desktop features.

## Checks

The existing native fixture and FsUnit/NUnit runner cover schema migration, restart, scoped profile edits, stale revisions, selected deletion, changed roots, foreign-file preservation, and interruption before and after actual file and metadata commits. Native client checks exercise the authenticated service and paging against the published engine.

`integration_test/workspaces_native_test.dart` runs the real Flutter composition, native folder chooser, and engine on owned temporary roots. Its driver selects only fixture paths. On Linux, run `python3 tools/check-linux-wire.py --workspaces --output <receipt-directory>` after publishing the engine. This requires preinstalled Xvfb, xauth, and xdotool, plus the GTK runtime and settings schemas. The driver uses its own authenticated display and disables host portals. It never sends input to the host session. Windows qualification uses an isolated guest desktop.
