# Mod library

The engine and typed Dart client support workspace inventory, mod metadata and
immutable file versions. The desktop inventory UI is a separate feature.

## Ownership and input

`ModConductor.ModLibrary` owns the feature types, actions and source-file policy.
`ModConductor.Persistence` stores inventory, manifests and publication receipts in
the existing SQLite database and queue. Schema 4 extends workspace/profile schema
3 in one SQLite transaction. Runtime operations and their revisions stay separate.
`ModConductor.Platform` supplies held-directory operations. The engine maps the
feature to authenticated protobuf RPCs; `mc_client` exposes typed results, not policy.

Register an existing source directory **inside a registered workspace**. This is
an explicit read/publication input, not ownership of its original files. The
engine does not change source contents or permissions. A directory outside that
workspace, a link, or the library itself is not an accepted source. This boundary
is not a restriction on future archive imports or working copies.

Registration records the source's actual directory identity. A missing source is
detached. A replacement at the same path is not adopted. Unregistered top-level
entries remain unmanaged observations. Unknown, detached and unproved files are
not deleted. Mod IDs do not depend on a display name or source directory name.

Each workspace has one opaque library directory. Its creation intent precedes the
file effect; its complete native identity is then recorded. A directory whose
creation was not observed durably stays unproved. A matching filename or prefix
alone does not establish ownership.

## Versions and metadata

Mod names, notes, comments, version text, source text and categories are metadata.
A metadata edit checks the mod revision and commits all fields together. Every
profile queries its workspace's shared inventory; rename does not rewrite stable
references. Profile enablement and precedence are not part of this feature.

A published version maps original logical path components to payload IDs, byte
lengths and SHA-256 digests. A Linux backslash filename stays one component. No
Windows target naming policy is imposed on Linux source files. A future deployment
plan must validate its selected target policy separately.

Publication reuses an unchanged file's verified payload from the preceding version.
Changed files get new opaque payload IDs. Older versions and their bytes do not
change. A backup entry refers to one exact published version in the same workspace.
There is no garbage collection, detached-file deletion or archive installation.

Regular entries can publish and edit metadata. Separators have editable metadata
but no files. Backups can read their pinned version but cannot publish or edit.
Registered unmanaged sources and generated output are read-only observations.
Generated output is not promoted to a regular mod by a scan.

## Publication and interruption

A version ID also identifies its publication receipt. Intent commits before new
payload files are created. File copies, flushes, identity checks and write
protection run outside database transactions. New files are created exclusively
under held directories; original source paths are never destination filenames.
The engine checks the source again after capture. It does not promise a snapshot
of a source that another application continuously edits.

The observed receipt precedes the atomic manifest/current-version commit. Only a
committed version is visible to version readers. Replay of a committed ID does not
publish again or move the current version backwards. Inventory replies show current
metadata, not a historical copy of the publication response.

An explicit cancellation request prevents a later commit. The file worker can
still be closing its current file. Disconnecting an RPC or leaving a screen does
not cancel publication. Cancellation after commit does not undo that commit.

Recovery claims only abandoned work. Another live engine keeps its active receipt.
After a crash, a fully observed manifest can complete only after its recorded files
pass identity and content checks and the expected revision still matches. A file
effect without a durable identity stays unresolved. Recovery does not infer file
rollback from a database rollback, adopt replacements or remove unproved files.

Payloads use owner-read permissions on Linux and the read-only attribute on
Windows. These prevent ordinary writes, not permission changes, deletion by the
same user, administrators or hostile programs. Reads check the recorded identity
and digest and refuse changed data.

## Bounds and verification

Inventory pages contain at most 32 entries. Version pages contain at most 64
manifest entries. Both also use a conservative 512 KiB content budget, so long
names or large notes can produce shorter pages. Payload reads return at most 64 KiB. Scans accept a candidate
budget from 1 to 100,000 and return a bounded summary, not a full history. Publication
currently accepts at most 100,000 source candidates and a depth of 128. Files are
streamed in 64 KiB buffers; accepted file jobs use the existing bounded database
queue without holding a database transaction during file I/O.

Run the existing native fixture with `dotnet test` as described in
[the build guide](BUILDING.md). The `LibraryTests` suite consumes the actual
NativeAOT fixture. Run `flutter test --no-pub test/mod_library_native_test.dart`
from `ui/packages/mc_client` with `MC_ENGINE_PATH` set to the native engine.
All fixture directories are disposable and owned by the test.

The native directory adapter uses supported
[Windows handle-relative creation](https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntcreatefile),
[Windows handle-based directory enumeration](https://learn.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-file_id_both_dir_info),
and [Linux directory streams](https://www.man7.org/linux/man-pages/man3/opendir.3.html).
Protection uses the .NET handle overloads of
[SetUnixFileMode](https://learn.microsoft.com/en-us/dotnet/api/system.io.file.setunixfilemode?view=net-10.0)
and [SetAttributes](https://learn.microsoft.com/en-us/dotnet/api/system.io.file.setattributes?view=net-10.0).
No driver, CMake target, TLS change or additional package is required.
