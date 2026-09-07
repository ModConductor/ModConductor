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

Schema upgrades commit in one SQLite transaction. Unsupported schema versions are
refused. Database schema versions, protocol majors, metadata revisions, and feed
cursors have separate meanings.

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
native contexts do not use the Proton resolver. Schema migration preserves older
path-only selections and their evidence; restarting still requires recheck.
