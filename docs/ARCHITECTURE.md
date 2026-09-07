# Architecture

## Ownership

| Library | Responsibility |
| --- | --- |
| `ModConductor.Operations` | Runtime-check requests, durable outcomes, and coordination |
| `ModConductor.Platform` | Native path identity, held-directory access, and filesystem preflight |
| `ModConductor.Workspaces` | Workspace and profile lifecycle |
| `ModConductor.ModLibrary` | Mod identity, metadata, and immutable file versions |
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

Profiles currently contain IDs and names. The first profile becomes current.
Clone creates a new profile identity, not copies of mod files. A current profile
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
archive installation, mod enablement, precedence, or game deployment is implemented.
