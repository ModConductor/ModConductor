# Deployment generations

Mod Conductor will use immutable mod versions and symlink deployment generations. This is the primary model, not an optimization of whole-collection copies.

The human approved the model. The first game and edition remain **UNSELECTED**. This document proposes the storage and activation rules. It does not establish game support or authorize game-folder changes.

## Versions and shared files

A version receives a stable, opaque `VersionId`. Its immutable manifest maps original logical paths to immutable `PayloadId` references. Each payload contains one file's bytes, length, and integrity digest.

An edit starts in a separate working copy. Publication creates a new version. Unchanged entries retain their payload references. Changed files receive new payloads. Publication never modifies an earlier version or its payloads.

An imported archive remains an input, not a writable deployed mod. Import stores new payloads and reuses unchanged payload references. Later versions do not duplicate those unchanged files. This does not require a full Nix store, global content-addressed deduplication, or a new database schema in MC-010.

A generation receives a stable `GenerationId`. Its immutable manifest records:

- Exact version IDs and the complete mod priority order.
- The selected target naming policy and game context.
- The winning source for each valid target path.
- The required base-file references, external base fingerprints, and writable-path policy.

The generation's tree links to those exact payloads. It never follows a mutable `mod/latest` or profile-selection alias. A later mod update cannot change an earlier generation's mod contents.

Priority resolves intentional overrides at the same target path. File/directory conflicts and ambiguous target names require explicit resolution before publication. Source names are not silently lowercased or renamed.

## Links in the game folder

**Leaf links:** Existing game directories remain real directories. Each managed leaf links to an exact path in the selected generation. The plan lists additions, replacements, and removals.

An overlapping base file needs explicit preservation before replacement. The receipt records it as an external base object, not an automatically adopted MC file. An approved preservation step records its original identity and retains its contents outside the active path.

Removal deletes only the matching owned link. It restores a displaced base file only when the destination and preservation receipt still match. Unrelated base files and foreign changes remain untouched.

An immutable base snapshot must not become updater-writable storage through restoration or a writable hard link. Restoration needs a separate writable file when retained generations still reference that snapshot.

**Directory boundary:** A directory link can expose a complete generation when the selected game layout permits that boundary. An existing directory must first receive an explicit preservation plan.

The generation must expose every required base entry. It must not hide DLC or other base files. Explicitly preserved immutable base snapshots can supply entries. Other entries remain external base objects with exact fingerprints as activation preconditions. A changed prerequisite blocks activation, including rollback to an older generation.

If that complete view is unavailable, select leaf mode in the plan. Do not change modes after an activation failure. This design does not require a retained snapshot or copy of the whole game.

A mixed game directory must not become a directory link merely because replacement is convenient. Same-filesystem preservation and the exact replacement operation need native proof.

## Activation and recovery

Only one generation can be active per physical game installation. The game must be stopped before activation, removal, or rollback. Unknown process state blocks the change.

A per-installation admission guard blocks competing MC activation and launch requests. Each game context must account for launchers, child processes, and external starts. A process scan alone does not exclude an external launch race.

Activation uses this sequence:

1. Build the new generation away from the game folder.
2. Check every pin, winner, target path, required base object, writable path, permission, and space requirement.
3. Acquire the installation guard and check that the game is stopped.
4. Persist the expected installation revision, old/new generation IDs, and each planned path action.
5. Preserve approved base objects and apply the owned link changes.
6. Check the resulting view against the generation and each receipt.
7. Commit the active generation reference and completion receipt, then permit launch.

Each action records intent before its effect and observed identity afterward. Stage links under owned temporary names before replacement. A missing or changed object does not become owned through a matching pathname.

An interrupted activation keeps launch blocked. Recovery compares the actual objects with the receipts. It can finish or reverse only proved owned actions. Otherwise, it preserves the objects and leaves an unresolved receipt.

SQLite rollback does not roll back filesystem changes. An incomplete database reference or one successful link change does not prove complete activation. No multi-path all-or-nothing guarantee is proposed.

Rollback selects a retained generation through the same activation process. It does not revert saves, generated files, or other mutable outputs.

## Atomicity and runtime view

On Linux, `rename` can atomically replace an existing namespace entry within its documented constraints. Open file descriptors remain unaffected. [Linux rename documentation](https://man7.org/linux/man-pages/man2/rename.2.html).

That single-entry guarantee does not establish a transaction across leaf links, crash durability, or a consistent view for a running game. The game remains stopped throughout activation.

Windows needs its own native proof. `MoveFileExW` reports an error when replacement names an existing directory. Do not infer directory-link exchange semantics from Unix rename. [Windows move documentation](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-movefileexw).

The proposed Windows baseline uses recoverable owned steps, not a claimed atomic switch. Those exact steps still need native qualification. The completed view, launch guard, and recovery receipt provide separate guarantees.

## Writable data and retained references

Symlinks do not provide automatic copy-on-write. Writes through a link can affect its target. The Linux documentation describes this target-following behavior. [Linux symlink documentation](https://man7.org/linux/man-pages/man7/symlink.7.html).

Published payloads receive protection against ordinary writes through platform permissions and application rules. The exact protection must pass native write tests. It is not a security boundary against the same user, an administrator, or software that changes permissions.

Known writable paths use separate working copies or output directories. They never target immutable payloads. Working copies record their profile and source version. Another generation must not silently reuse an incompatible working copy. An edit becomes a new version only through explicit publication. Undeclared game writes are a compatibility failure, not a reason to copy the whole collection silently.

Generation immutability covers mod selection, not the contents of working copies or outputs. Saves and outputs have an explicit profile or shared scope. Separate installations can use different generations only when their launch and mutable-data scopes do not conflict.

Retained generations keep every referenced mod version, payload, and explicitly preserved immutable base snapshot available. External base objects remain prerequisites, not owned immutable payloads. Active operations and recovery receipts also retain their dependencies. No automatic garbage collection, retention duration, or deletion policy is selected.

Game updates require deactivation or another qualified update procedure. Unexpected updater or cloud changes stop reconciliation rather than overwrite external data. An earlier generation does not imply restoration of an unpreserved game version.

## Owners and costs

Proposed cohesive F# owners are `ModConductor.ModLibrary` for immutable versions and shared payloads, and `ModConductor.Deployment` for plans and activation. These match the inventory, plan, and deployment slices. Neither belongs in Flutter components or a generic transport framework.

The existing Platform library from MC-008 supplies explicit path policy, containment observations, and native identities. Later writes need held-object checks, not authorization from an earlier preflight snapshot.

The existing Persistence owner from MC-009 will store generation metadata and activation receipts. Its queue, owner lifecycle, and revision checks remain shared. Its fixed identity-file proof does not already implement link reconciliation.

The engine will host these feature libraries through the existing operation boundary. Flutter will remain a thin consumer of shared UI components. No dead API, new project, package, driver, or schema is implemented by this design.

Initial import stores payload bytes. A changed file needs new storage, and a working copy needs writable space. Generations add manifests and links rather than duplicate unchanged payloads. Explicit base preservation, separate writable restoration, and temporary staging also need space.

Generation planning examines effective paths. Leaf activation costs work proportional to the changed links. A directory boundary can reduce visible path changes, but construction and validation still cost time. No performance figure is claimed.

## Support matrix

Infrastructure qualification and game qualification are separate. The following game rows are requirements to fill, not supported combinations.

| Row | Context and filesystem | Current evidence or gap |
|---|---|---|
| Application and core fixtures | Linux x64, native .NET/Flutter, ext4 and tmpfs fixtures | MC-008/009 qualify paths and owned metadata, not generation deployment. |
| Application and core fixtures | Windows x64, retained Windows 11 guest, NTFS | MC-008/009 qualify paths and owned metadata, not generation deployment. |
| Deployment fixtures | Linux x64, explicit owned installation/library roots | Generation, link, permission, activation, and recovery proofs remain unrun. |
| Deployment fixtures | Windows x64, explicit owned NTFS roots | The same proofs remain unrun. Symlink creation prerequisites need qualification. |
| First game | Game/edition **UNSELECTED**, Windows launch context **UNSELECTED** | Executable, store, process architecture, base layout, mutable paths, and filesystem remain unselected. |
| First game through Proton | Game/edition **UNSELECTED**, Linux Steam/Proton context **UNSELECTED** | AppID, Proton/runtime versions, prefix, drive mappings, visible roots, and filesystem remain unselected. |

Linux/Proton is a first-class game row. No unrelated native-Linux game is required. A native-Linux edition receives its own row only if the human selects it.

The MC-008 normal-user Windows fixture reported a symlink privilege refusal. That is not blanket Windows incompatibility. The unprivileged creation flag requires Developer Mode. [Windows symlink documentation](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsymboliclinkw).

The Windows row must record an available creation mode and its permission requirements. This design changes no privilege or system policy. A failed preflight stays unsupported for that context, without a silent copy or junction fallback.

The Proton row must test target visibility through the actual selected launch context, not just the host filesystem. Record exact runtime configuration. [Valve's Proton documentation](https://github.com/ValveSoftware/Proton#runtime-config-options).

Unqualified filesystems, network paths, incompatible launchers, and games that require writes to protected payloads remain unsupported. Application startup or a helper executable does not establish game compatibility.

## Required proofs

Later implementation must first use disposable native fixtures on both operating systems:

- Change one file in a new version. Check shared unchanged payloads and unchanged reads through the older generation.
- Change mod priority. Check the winning bytes and refusal of unresolved target conflicts before game-folder changes.
- Add and remove leaf paths. Check base-file preservation, restoration, and unrelated foreign files.
- Exercise a complete directory boundary. Check all base entries and the platform-specific replacement outcome.
- Terminate before an effect, after an effect, during leaf reconciliation, and before the active-reference commit. Check recovery and blocked launch.
- Attempt activation while the game is running and launch during activation. Check the selected context's process and admission controls.
- Write through deployed paths. Check protected payloads, separate writable data, and explicit publication of edited files.
- Retain two generations, update a mod, and roll back. Check exact pins, referenced contents, and unchanged saves or outputs.
- Change an external base prerequisite. Check that an older generation cannot activate against the changed fingerprint.
- Restore a preserved base file, then modify it as an updater. Check that a retained immutable snapshot remains unchanged.
- Replace an owned link or preserved object externally. Check unresolved recovery without destructive repair.

The named game and edition then need actual lookup, load, write, update, and shutdown tests on the selected Windows and Linux/Proton rows. Real-game writes require a separately approved target.

Record source and artifact hashes, commands, identities, OS/runtime versions, filesystems, privilege mode, process behavior, and observed results. **MC-010 remains incomplete until the human selects the first game/edition and the matrix states its exact contexts and exclusions.**
