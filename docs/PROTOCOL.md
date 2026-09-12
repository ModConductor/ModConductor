# Engine protocol

## Schemas and generation

All production schemas use `modconductor.v1` and C# namespace
`ModConductor.Protocol.V1`. A protocol major change requires explicit human
instruction. Preserve field identities and reserve removed fields.

| Schema under `contracts/modconductor/v1/` | Purpose |
| --- | --- |
| `bootstrap.proto` | `EngineReady` descriptor on the private stdout pipe |
| `operations.proto` | Runtime checks, cancellation, replay, and change feeds |
| `workspaces.proto` | Workspace roots and profile lifecycle |
| `mod_library.proto` | Mod inventory, metadata, publication, and saved files |
| `profile_mods.proto` | Per-profile enablement and precedence changes |
| `mod_organization.proto` | Workspace category edits and revision-pinned mod queries |
| `game_contexts.proto` | Workspace installation selection and checked evidence |
| `steam_discovery.proto` | Read-only Steam installation search and per-origin observations |
| `proton_contexts.proto` | Existing prefix/runtime choices, mapping observations and Windows user paths |
| `file_plans.proto` | Observed Data files, planned sources, exact-copy visibility and history |
| `generated_outputs.proto` | Context-owned output locations, checked files, immutable promotion and durable review results |
| `deployments.proto` | Current and saved deployment views, preparation, activation and receipt recovery |

After locked restores, run `python3 tools/generate-protocol.py`. Use `--check` to
compare both generated boundaries without changing source. The tool compiles all
schemas with the pinned Grpc.Tools and Dart plugin. Do not edit generated files.

F# owns domain types and policy. Services map typed requests and results to the
wire. `mc_client` exposes typed Dart models, not generated DTOs to presentation.

## Session authentication

The desktop starts its installed engine. It sends a random 256-bit capability
through inherited stdin. The engine reads a bounded frame with a startup deadline.
Its stdout returns one base64 `EngineReady` frame with protocol major 1, an
OS-selected loopback port, and the public certificate.

The client rejects a different major before authentication. It trusts only the
supplied certificate and checks the `localhost` authority. TLS HTTP/2 protects
transport. Every RPC requires the capability in `mc-session` metadata. Missing,
duplicate, and incorrect credentials are refused.

The child creates a fresh TLS key and certificate for each session. Linux keeps
the key in memory. Windows uses a user-scoped CNG key with a held ownership lease.
Normal shutdown removes the key. Recovery removes abandoned keys, not live ones.
Capabilities are not persisted. No system trust entry is installed.

The installed executable and its inherited pipes form the bootstrap trust
boundary. This does not protect against a malicious replacement executable or
provide a same-user sandbox.

## Bounds and lifetime

Game-context RPCs permit 64 KiB requests and 2 MiB replies. Save compares a workspace
binding revision and returns either the committed state or a typed failure.
Invalid candidates include check details. Declared Steam identity is not observed
Steam evidence. An optional Proton selection is saved atomically with the game
folder, using the same revision. Its association is explicitly manual or Steam.
Proton searches allow 80 KiB requests and 512 KiB replies; content budgets retain
complete records and mark limited results. They do not initialize a prefix or
execute runtime commands. Refresh retains the last successful evidence if its new check fails.

Runtime RPCs permit 4 KiB requests and 64 KiB replies. Workspace and mod RPCs
permit 64 KiB requests and 2 MiB replies. Item and content budgets further bound
profile, inventory, and version pages. A continuation cursor means the result is
incomplete. Mod queries return at most 32 matching source rows, 32 separator
context rows, and one inspected detail. The byte budget can return fewer complete
rows. Context and inspected details do not count as matches or loaded source rows.
Continuations pin catalogue revision, selection revision, and query identity.
Category pages contain 32 siblings and ancestor paths of at most 16 levels.
Optional revision fields use presence, not zero as a sentinel.

Profile-mod changes accept at most 512 stable IDs and return all affected
selection rows in one delta. A one-step move changes at most 1024 rows. Mod queries
include authoritative selection constraints and an optional inspected mod outside
the matching page. Metadata has its own revision. Category references replace the
old scalar metadata field; field 6 is reserved. Up to 32 references fit one mod,
and a query accepts up to 16 typed filters.

Native and logical registration paths are mutually exclusive. The native path is
only a chooser candidate. F# validates it through the same held-root boundary.

A timeout does not prove that a mutation rolled back.
Refresh state or query its durable identity. Closing stdin requests graceful
shutdown. The engine drains accepted work. A shutdown timeout keeps the owned child
and cancels app exit rather than killing an authenticated engine.

See [Architecture](ARCHITECTURE.md) for revision and recovery semantics and
[Build instructions](BUILDING.md) for native checks.

File acquisition streams coalesced progress and one final result. Stream
cancellation stops the read; it does not publish a partial observation. File pages
carry an opaque query cursor and a snapshot ID. Visibility-only changes return a
new snapshot while preserving path-query continuation when membership and order
are unchanged. Other input changes invalidate continuation. An inspected saved
copy can be returned as separate focused context outside the sources page.

Output observation and deployment calls have no inherited short unary deadline.
Progress is coalesced; clients drain the final RPC response before decoding its
terminal outcome. Cancellation of observation or preparation does not authorize
undoing a completed publication or deployment. Output pages contain complete
records; selections and replies have separate bounded service envelopes.


Download commands and observation use `v1/downloads.proto`. The artifact snapshot
imports the shared `v1/download_models.proto`; transfer records are not duplicated.
Start fixes its request to the supplied artifact ID. Repeating that request does
not start another transfer. Pause, Resume, and Restart act on the saved artifact.
Watch observes up to 64 supplied IDs and coalesces changed revisions every 500 ms.
Canceling Watch does not cancel a download. Artifact and download services allow
128 KiB requests and 2 MiB replies, with additional source-count and row bounds.


`v1/archive_inspection.proto` exposes one metadata inspection of an exact artifact
revision. Its 8 MiB response contains a complete bounded manifest, not a success
prefix or pagination cursor. The source digest identifies the observed archive;
entry indices stay internal to the reader boundary. Request cancellation cancels
this read, not the artifact or its download. Payload bytes are not sent by this RPC.
