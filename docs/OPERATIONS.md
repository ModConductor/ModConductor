# Runtime-check operations

The existing connection check now persists its result. It does not modify game
files or save preferences. The desktop still shows Connected after the check.

## Ownership

`ModConductor.Operations` owns typed requests, outcomes, and coordination.
`ModConductor.Persistence` owns the SQLite adapter, schema, and state-directory
leases. The engine maps these records to Protobuf. `mc_client` maps the replies
to typed client state. The Flutter application remains a thin consumer.

The default database is `ModConductor/state/state.db` under local application
data. The engine accepts `--state-directory <absolute path>` for an explicitly
selected state directory. Native tests use isolated directories. Ownership leases
are under that directory's `owners/` subdirectory. They contain no credentials.

Each engine reserves and holds its own file lease before it accepts work. Startup
marks only abandoned owners' unfinished operations Interrupted. It preserves live
owners. This does not impose a global application-instance restriction.

## Identity, revision, and commit

Protocol package `modconductor.v2` replaces the incompatible read-only v1 proof.
The private bootstrap rejects a different major before network authentication.
Operation IDs are UUIDs without separators. Each ID fixes the expected revision
and requested heartbeat count. The count remains bounded to 1..16.

Revision means the version of committed runtime-check results. The initial value
is zero. Admission and final commit compare the expected revision. Concurrent
work that loses that comparison cannot overwrite the newer result.

The atomic side effect is the SQLite transaction that stores the runtime result
and advances the revision. A replay returns the stored result before it checks
the current global revision. It does not run the check again or advance a cursor.
A different request cannot reuse an existing ID.

Explicit cancellation before commit stores Cancelled without a result revision.
Cancellation after commit returns the completed result unchanged. Disconnect,
reader cancellation, navigation, and graceful app close do not cancel the work.
Graceful shutdown drains accepted checks. Abrupt termination leaves a recoverable
owner lease. Recovery does not repeat a committed result or invent success.

These guarantees cover the runtime-check transaction. They do not prove atomic
game-file transactions. Workspace metadata and file receipts extend the same
persistence owner in later tickets.

## Bounded delivery

The cursor counts durable operation changes, not committed results. Storage keeps
the latest 128 changes. A feed page contains at most 16 changes. A reconnect
returns the current snapshot and cursor. An unavailable or future cursor sets
`resync_required` explicitly.

A snapshot contains only the latest 16 operations, not complete history. Older
IDs remain queryable and replayable. The client queries its known operation when
that ID falls outside the snapshot. It applies changes to current state instead
of replaying all history on every update.

The database admits at most 16 unfinished checks. Each engine has a 64-entry
I/O queue and at most eight active feed readers. Public queue overflow fails
explicitly. The bounded accepted jobs await space for internal progress and
terminal writes. Slow stream readers do not hold database transactions.

If a job cannot persist even its interrupted outcome, the coordinator stops its
engine owner. A failed retirement retains the lease for the next recovery. It
does not leave an unobserved worker failure under a live owner.

## SQLite and native builds

The adapter uses Microsoft.Data.Sqlite.Core 10.0.11 and SQLitePCLRaw 3.0.5 with
SQLite 3.53.4. Both native RID assets passed NativeAOT transaction/restart probes
before adoption. SQL mapping is explicit. There is no ORM or JSON serializer.
SQLite I/O runs synchronously behind the bounded queue, not on the UI thread.

The published engine needs `libe_sqlite3.so` on Linux or `e_sqlite3.dll` on Windows.
The development bundle tool copies that exact published library beside the engine.
[Dependency sources and notices](WIRE-DEPENDENCIES.md) record the adoption.
