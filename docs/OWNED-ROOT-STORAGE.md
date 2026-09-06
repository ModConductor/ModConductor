# Owned-root storage

`OperationStore` owns one state database, bounded queue, and owner lease. Its `WorkspaceRoots` member is the storage boundary for a selected workspace root and its identity file. No workspace command, profile record, UI, or deployment backend uses it yet. The native conformance fixture is its first caller.

## State and revisions

Schema version 2 adds workspace-root metadata and creation receipts to the existing SQLite database. Upgrades use one SQLite transaction. Failure before commit leaves the old schema usable; failure after commit leaves the complete new schema. An unknown schema version is refused. No backup subsystem or receipt deletion policy is added.

A workspace has a stable UUID, selected resolved path, complete native root identity, and revision. Revision is zero until verified creation completes, then becomes one. This is separate from the runtime-check revision and event cursor.

A creation receipt records its owner, marker ID, phase, revision, observed file identity, and unresolved reason. Root and marker device identities are stored independently. IDs are filesystem observations, not content hashes or permanent protection against ID reuse. Credentials and engine session keys are not stored here.

`Prepare` records intent before any file action. Expected workspace revision must be zero for first creation. Repeating the same creation request returns its existing receipt without advancing revisions. A different root cannot reuse that identity. Each later receipt action checks the expected receipt revision. Stale calls cannot overwrite a newer state.

## File action and completion

`Apply` creates only `.mod-conductor-root` under the recorded root. An existing object at that name is not adopted or overwritten. The file contains a bounded versioned record with workspace and marker IDs. It is ownership metadata, not a credential.

The Platform helper opens and validates a directory handle against the recorded root identity. It creates the fixed-name child relative to that handle: Linux [`openat`](https://man7.org/linux/man-pages/man2/open.2.html) with exclusive creation/no-follow flags, or documented Windows user-mode [`NtCreateFile`](https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntcreatefile) with `RootDirectory` and `FILE_CREATE`. It does not require a driver, CMake, or a C# helper. Recovery opens that child without following links and checks its type, complete native identity, and bounded contents.

File I/O runs outside database transactions and the database queue. At most two file checks run per store. Other requests receive Busy rather than an unbounded file-work backlog. Accepted receipt writes await the existing bounded queue. Closing a store while a file check is active fails without releasing its owner; the caller can close it after that check returns.

`Apply` records the observed file identity after a successful write and flush. `Complete` checks that identity and contents, then commits the workspace revision and completed receipt together. Database rollback is not file rollback. These checks record an observed creation result; they do not lock out every external writer or authorize future file changes. A later consumer must validate current state before using it.

## Recovery

Owner-lease recovery marks only abandoned owners' unfinished receipts recoverable. It preserves another live owner's receipts and runtime checks. `Recoverable` lists abandoned receipts and this owner's non-busy receipts. It returns up to 16 IDs after the supplied ID; callers continue with the last returned ID. The list is a snapshot, not a reservation. No receipt is deleted automatically.

`Reconcile` can claim abandoned work, or retry this owner's finished file attempt after a failure. It cannot take another live owner's receipt or overlap a local active file check.

- Intent without a durable file identity remains unresolved. A file found at that name is left unchanged, even if its contents appear to match.
- A durable observed identity can complete only if the root, marker file identity, and contents still match.
- A replaced root, changed file, missing file, or unprovable identity remains unresolved. No foreign file is removed, overwritten, or recursively repaired.

A crash between file creation and recording its identity is deliberately unresolved. The database cannot prove which object is present after restart. An unresolved receipt retains the available evidence and reason. It does not claim that the file was rolled back.

## Native checks

The shared `ModConductor.Native.Fixtures` executable exercises actual native SQLite and file operations. The managed `ModConductor.Native.Tests` project uses the existing FsUnit/NUnit adapter; no custom discovery or XML success gate is used. See [build commands](PATH-PREFLIGHT.md#native-conformance-checks).

The tests copy a synthetic v1 database created by the immutable pre-MC-009 native store. They terminate native processes inside migration and file/receipt boundaries, check restart and stale revisions, preserve live owners, and change owned fixture files through normal filesystem operations. A narrow internal checkpoint allows termination before migration commit and before the observed file ID is saved; it adds no engine command or environment-controlled product behavior.

Qualification uses only disposable roots on native Linux and Windows. It does not qualify game deployment, broad filesystem compatibility, power-loss recovery on all storage hardware, or a full Nix install. The SQLite package closure and NativeAOT warning policy are unchanged.
