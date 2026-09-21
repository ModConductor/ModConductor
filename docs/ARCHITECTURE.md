# Architecture

## Ownership

| Library | Responsibility |
| --- | --- |
| `ModConductor.Operations` | Runtime-check requests, durable outcomes, and coordination |
| `ModConductor.Platform` | Native path identity, held-directory access, and filesystem preflight |
| `ModConductor.Workspaces` | Workspace and profile lifecycle |
| `ModConductor.GameContexts` | Game definitions, installation checks, and context evidence |
| `ModConductor.SteamDiscovery` | Read-only Steam library, app and compatibility-tool metadata |
| `ModConductor.ProtonContexts` | Chosen Proton installation, prefix and Windows user-path checks |
| `ModConductor.ArchiveInspection` | Read-only archive metadata and scoped lazy entry reads |
| `ModConductor.HttpDownloads` | Engine-owned HTTP workers, range validation, retries, and integrity checks |
| `ModConductor.ArtifactLibrary` | Archive identity, availability, and manual installed-version provenance |
| `ModConductor.ModLibrary` | Mod identity, metadata, and immutable file versions |
| `ModConductor.ModSelection` | Per-profile enablement, saved precedence, and batch rules |
| `ModConductor.ModOrganization` | Workspace categories, typed filters, and grouping contracts |
| `ModConductor.Persistence` | SQLite adapters, bounded queue, owner leases, and file receipts |
| `ModConductor.Engine` | Process bootstrap and authenticated service adapters |
| `mc_client` | Typed Dart transport and child-process lifecycle |

The Flutter app binds presentation libraries to typed clients. Domain decisions
remain in F#. [Protocol](PROTOCOL.md) describes the process boundary.
[Desktop components](UI-COMPONENTS.md) describes presentation ownership.

## State and concurrency

The engine stores `ModConductor/state/state.db` under local application data.
`--state-directory <absolute-path>` selects another state directory. Workspace
folders do not contain separate databases.

The first-release schema is created directly in one SQLite transaction. Incompatible
pre-release databases are refused with a reset instruction; they are not upgraded.
Forward schema upgrades begin only after the first public release. Database schema
versions, protocol majors, metadata revisions, and feed cursors have separate meanings.

Each engine holds an owner lease. Recovery claims abandoned work, not work owned
by another live engine. The shared queue bounds database work. File operations run
outside database transactions. A database rollback does not roll back files.

Runtime-check IDs fix their complete request. Admission and commit compare the
expected result revision. Replay returns a committed result without another side
effect. Cancellation before commit records cancellation. Cancellation after
commit preserves the result. Disconnection does not cancel accepted work.

Feed cursors identify changes, not result revisions. Feed pages and snapshots are
bounded. An unavailable cursor requests resynchronization. Clients query known
operation IDs omitted from a recent snapshot.

## Workspaces and profiles

A workspace has a stable ID, name, registered root, profiles, and current profile.
Creating one records intent before it creates `.mod-conductor-root` through a held
directory. Completion records the observed identity and checks its contents.
Existing files are not adopted or overwritten.

Opening a workspace requires this installation's registration, the recorded root
identity, and its original marker. Copying a marker does not import a workspace.
An unobserved file effect remains unresolved after a crash. **Check again** checks
recorded evidence. It does not infer ownership from a filename.

Profiles have stable IDs, names, and their own mod selection. The first profile
becomes current. Clone copies enabled states and saved order in the same
transaction as the new profile. It does not copy mod files. A current profile
must be replaced before deletion. Profile edits check the workspace revision and
commit all metadata together. Stale edits change nothing.

Workspace pages include the current profile even outside the loaded page. Clients
must not merge profile pages from different workspace revisions. Closing a page
changes navigation, not the status of accepted mutations.

## Paths and immutable mod files

`HostPath` represents an absolute native path. `LogicalPath` preserves original
name components and Unicode. A Linux backslash remains part of a name. Target
comparison and naming rules are explicit policies, not source renaming rules.

Filesystem preflight reports bounded observations. It does not authorize a later
write. Native identities are observed facts, not permanent hashes. Active
capability probes require caller-owned disposable directories, never game folders.

Mod registration accepts a directory inside a registered workspace. Native chooser
paths are candidates. F# converts them to logical components, then held-root checks
validate ancestry and identity. Links, outside directories, and the library itself
are not accepted. Original source contents and permissions stay unchanged.

Profiles share their workspace's inventory. Mod IDs survive rename. Missing,
replaced, and unproved sources are not automatically adopted or deleted. Metadata
edits check a per-mod revision, separate from the workspace revision.

A version maps original paths to payload IDs, lengths, and SHA-256 digests.
Publication reuses verified unchanged payloads. Changed files receive new payload
IDs. Older versions retain their contents. A backup pins one exact version.
Separators have metadata only. Unmanaged sources and generated output are
read-only observations.

Publication records intent before file effects and observed identity before the
atomic manifest/current-version commit. Only committed versions are readable.
Recovery can complete an observed manifest after identity, content, and revision
checks. Unobserved effects remain unresolved. A continuously edited source is not
promised an atomic snapshot.

Payload protection prevents ordinary writes, not hostile same-user or administrator
changes. Reads reject changed identity or content. No garbage collection,
archive installation or game deployment is implemented.

## Profile mods

Regular mods and separators have contiguous saved priorities per profile. Higher
priority numbers follow lower numbers in the saved order. Checkboxes change
regular-mod enablement. Separators can move but cannot be enabled. Backups,
unmanaged entries, and generated output cannot change profile selection.

Each selected run moves across one neighboring unselected entry. Moves use the
global saved order, not filtered row indices. The engine preserves the relative
order of selected and unselected entries. Display sorting does not write priority.

A batch checks the profile-selection revision and commits all changes together.
Stale or unsupported batches change nothing. Every accepted batch advances the
revision once, including a boundary move that leaves the order unchanged.

New regular mods append disabled to each profile. Separators append without an
enabled state. Every inventory registration invalidates profile-page continuation,
including registration of a locked entry. New profiles initialize existing entries
in stable ID order. Profile deletion removes its selection relation atomically.

Mod queries pin the catalogue and profile-selection revisions. Each response reads
stored metadata, selection, counts, and group context in one SQLite snapshot.
A continuation rejects changed state or a different query. The catalogue counter
invalidates reads; it does not have the selection command's one-increment rule.
It does not observe external file changes until an existing scan or publication
records them. A failed reload does not undo a committed registration.

## Categories and filters

Category definitions and mod memberships belong to a workspace, not a profile.
A mod can have several categories. The category tree cannot contain cycles or
cross-workspace parents. Moving a category preserves its ID and memberships.
Names are exact values: case, spaces, and Unicode normalization do not merge them.
Legacy nonempty category strings become separate root categories per workspace.
Whitespace-only legacy labels remain visible and can be renamed.

Only leaf categories can be deleted. Deletion keeps assigned references with the
stable category ID and last known label. Unrelated mod edits preserve missing
references. Explicit removal or reassignment can replace them. Mod details and
category assignments commit together under the mod revision. Definition changes
advance affected mod revisions, so old details drafts cannot overwrite a rename
or deletion. A known category ID from another workspace is refused.

Text search is a trimmed, case-insensitive literal substring across the mod's
name, version, source, notes, comment, and category labels. It has no query syntax.
Text must match alongside the typed filters. **All** requires every typed filter;
**Any** requires at least one. An empty typed filter list matches all entries.
Category filters include descendants only when explicitly selected. Descendants
use the current live tree; a missing reference can still match its own ID. Other filters
select kind, status, enabled state, no categories, or missing category references.

Groups follow global saved priority: each separator owns following regular mods
until the next separator. Leading mods and locked entries remain at the root.
Adjacent and trailing separators can form empty groups. A filter retains a group
header when the header or a child matches, without revealing other children.
Grouped name sorting orders children within each group. Moves require the flat
priority view. Selecting a separator never selects or enables its children.

## Deployment planning

`ModConductor.DeploymentPlanning` computes a pure plan from declared complete
profile, version-manifest, and read-only source snapshots. Callers must assemble
all pages and verify source availability; the planner does not read files or
resolve current/latest versions. Plans retain exact version and payload IDs.

Base layers precede secondary layers, which precede enabled mods. Higher numeric
priority wins within each tier. Each winner retains its alternatives and reason.
Source-prefix mappings compare exact components; the longest match applies.
Target roots use their declared case, Unicode, and naming policy. Root IDs are
logical namespaces, not proof that physical directories are separate.

Equivalent target names across ordered layers are ordinary overrides. Same-layer
aliases, competing priority ties, invalid names, and file/directory conflicts
block a plan. Shared directories use the highest-precedence spelling; an unresolved
spelling tie also blocks. Archive annotations retain container and capability
identity, but do not expand archive members or select an archive reader.

Explicit writable file or subtree declarations consume matching targets into a
separate initial-seed projection. Seeds retain immutable winners and alternatives;
they are not also read-only file winners. Empty sinks have no seed. Overlapping
sink ownership and structural conflicts block the plan. Directory entries describe
structure, not writable-content ownership. The planner does not copy, reseed, or
roll back mutable outputs.

The SHA-256 fingerprint covers semantic input identities, revisions, content,
precedence, mappings, policies, annotations, and sinks. Unordered input enumeration
is canonicalized. Mod display names, categories, and UI filters are not planner inputs.
`checkCurrent` rejects changed or unresolved supplied inputs without replacing a
retained plan. It does not observe external changes or authorize activation.

## Game installations

Each workspace selects one installation. Profiles share that binding. Several
workspaces can refer to the same installation. Selection does not change mods,
versions, profile order, or enablement.

Save checks the explicit folder and its expected binding revision before commit.
The validator reads declared installation entries through held directories. It
reads fixed PE version resources and hashes the same read-only executable handle.
It does not launch the executable or write game files. Evidence is not publisher
or Steam ownership verification.

Failed replacement leaves the previous binding intact. Failed Refresh retains
its last checked facts with a failure reason. Restart requires a new check.
External changes do not form an atomic filesystem snapshot.

The Skyrim Special Edition Steam definition declares Data and Windows target-name
rules. Windows user locations use actual Known Folders without creation. Linux
path-only bindings remain partial until a Proton context is selected. Game launch
and deployment are separate from these checks.

`SteamDiscovery` reads bounded library and app manifests from platform-default or
explicit Steam folders. It follows declared directory links, rejects unsafe
manifest installation paths, and merges installation identities while retaining
all observed origins. A broken library does not hide valid results. Search limits
and per-root problems remain explicit. No account scan or Steam write occurs.

The Game form uses the shared installation table to choose a search result into
its draft. Additional search folders last only for that form session. Choose does
not save a binding; Save repeats the normal installation checks. Discovery facts
are observations, not persisted Steam verification or entitlement evidence.

Linux Proton selections belong to the same workspace binding. They retain the
AppID, Steam or explicit manual association, existing compatdata folder, and
installed runtime folder/tool ID. Save validates the game and context together.
An identified conflicting AppID is refused, including a manually selected alias.
Refresh checks only the saved choice; it does not choose a replacement or start
Steam, Proton, Wine, or prefix setup.

The runtime manifest owns its relative installation path. Runtime version and
launcher identity are distinct from the prefix's last-use version. Steam per-game
and global mappings are metadata, not active-runtime proof; a global mapping is
only a suggestion. An installed tool can be selected directly when it is absent
from the bounded Steam search. No process-environment scan is used.

Prefix registry reads use only the declared Windows user-folder values. Path walks
use held, no-follow directories and relative link reads. Internal redirects can be
resolved; outside-prefix redirects, ambiguous names and unknown variables remain
unavailable without a host-folder fallback. Missing leaves are not created. Windows
native contexts do not use the Proton resolver. Restarting requires recheck.

## Planned loose files

`FilePlanning` acquires the checked Skyrim Data folder and complete, pinned mod
manifests. It uses `DeploymentPlanning` for target identity, precedence and original
collision guards. The game folder is observed content, not a verified pristine
installation. BSA files are opaque files; archive members are not inspected.

Explicit Load or Refresh streams real content hashes through held read-only
handles. Session-only observations are bounded and cancellable. Cached reuse and
Hide check the metadata inventory without hashing all content again. Files that
change without detectable metadata changes, or after a check, are not covered by
an atomic snapshot guarantee. Link/reparse entries are refused in this observed
Data view; deployed-link ownership is not inferred.

Persistence stores shared workspace exclusions for an exact mod, saved version
and manifest path, together with each accepted change's before/after state and
fingerprints. Hide selects the next eligible source; no eligible source means the
target is absent. Unhide restores eligibility. Neither operation changes payloads,
source folders, profile order or enablement. New full versions do not inherit old
exclusions. Historical rules remain readable, and profile clone/delete does not
remove them. These views do not activate or deploy files.

## Local archives

Archives belong to a workspace but remain separate from installed mod payloads.
Reference adoption leaves the original file in place. Explicit copies use the
existing identity-checked library folder with separate `artifact-*.partial` and
`artifact-*.archive` names. SQLite retains the original filename and path, stable
artifact ID, observed file identity, length, digest, and manual mod/version links.
No archive format is parsed by this feature.

Known rows reconcile on the first list request of an engine session and on explicit
Refresh. Direct reads also check an archive before its first use in that session. Observed complete copies can finish their no-replace rename after restart.
Incomplete bytes and missing files remain unavailable. Detached metadata and linked
provenance are not removed automatically. A digest describes observed bytes, not
archive validity or installability.

Manual links select an existing mod and its current saved version in the same
workspace. Later filename, path, or mod-name changes do not change those IDs.
Deleting an owned copy retains its links and changes availability to File not found.
Removing an unlinked list entry never deletes an external archive. All file work
uses the existing library admission and database owner lease, not another journal.

## HTTP downloads

Downloads use the same artifact ID, owner lease, and staging files as local
archives. Schema 15 adds transfer metadata to those rows, not a second inventory.
Two engine-owned workers run outside the shared file-admission gate. At most 32
items can wait. Closing a view cancels its observation only. Engine shutdown drains
the workers before the artifact store and database close. Saved unfinished work
returns Paused after restart; only a user action starts the network again.

Each checkpoint flushes bytes before saving their length. Reconciliation truncates
only an uncommitted tail. Reopening a partial file uses the held directory's
non-truncating, identity-checked read/write handle on Linux and Windows. Completion
uses the existing observed-file phase and no-replace promotion.

Resume requires the same effective source, strong ETag, and exact byte range and
total. Requests use the stored representation without automatic decompression.
An incompatible response retains the prefix and requires explicit Restart.
Mirrors can change automatically only before any bytes are saved. Restart can
select the next mirror and discard the partial copy without changing the artifact
ID or its links.

A user run permits three attempts, with 1- and 2-second retry delays and any longer
Retry-After deadline. Saved deadlines release workers rather than occupying them.
Connect timeout is 10 seconds; response-header and read-idle timeouts are 30 seconds.
Expected length and an optional supplied SHA-256 must match before availability.
A computed digest without a supplied checksum is not an independent integrity
check. Neither case validates the archive format or proves installability.

Source URLs are retained for resume. User information and fragments are refused;
cookies are disabled. Display and error text omit URL queries and response bodies.


## Archive inspection

Read contents obtains a verified read handle from the existing artifact owner.
The held-file identity and saved length/digest are checked before parsing. The
claim and stream last only for that read. Metadata inspection does not scan file
payloads or change archive availability, provenance, or bytes. Its complete result
is retained only by the current UI view; no new database schema or inventory exists.

Logical names use portable Windows naming rules and case-insensitive canonical
Unicode collision keys, while preserving original spelling. Links, devices,
redirections, duplicate paths and file/folder conflicts are refused. Implied
folders count toward the 20,000-node limit. Other limits are 32 levels, 1,024
characters per path, 2 MiB total names, 16 GiB per file, 64 GiB expanded bytes and
a 1,000:1 ratio. Nested archives remain leaf files; they are not opened recursively.

`Inspection.WithContents` keeps lazy entry reads in the same verified stream scope
for the installation consumer. Solid entry reads account for decoded preceding
entries. Listing metadata does not prove every payload can be decoded. Reader
exceptions reach the normal operation error path; known corrupt input asks for a
fresh download. Password and unsupported cases are distinct. MC does not constrain
dependency-internal allocations or CPU use before metadata/bytes return. There is
no parser helper, fork, header validator or corruption recovery system.
