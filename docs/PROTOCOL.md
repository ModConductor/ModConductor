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

Runtime RPCs permit 4 KiB requests and 64 KiB replies. Workspace and mod RPCs
permit 64 KiB requests and 2 MiB replies. Item and content budgets further bound
profile, inventory, and version pages. A continuation cursor means the result is
incomplete. Inventory pages do not promise one atomic snapshot across calls.

Native and logical registration paths are mutually exclusive. The native path is
only a chooser candidate. F# validates it through the same held-root boundary.

Client calls have deadlines. A timeout does not prove that a mutation rolled back.
Refresh state or query its durable identity. Closing stdin requests graceful
shutdown. The engine drains accepted work. A shutdown timeout keeps the owned child
and cancels app exit rather than killing an authenticated engine.

See [Architecture](ARCHITECTURE.md) for revision and recovery semantics and
[Build instructions](BUILDING.md) for native checks.
