# Read-only engine connection

The desktop starts the engine beside its executable and completes a typed runtime
request and a bounded heartbeat stream. It then shows **Connected** in the footer.
No workspace, game or mod operation is available yet.

## Boundary

The sole schema is `contracts/modconductor/v1/engine_probe.proto`. It generates
C# DTOs/service contracts and Dart DTOs/client contracts. Immutable F# records own
the small probe model. `ProbeService.fs` maps those values at the wire boundary.

`InspectRuntime` checks protocol major 1 and reports process architecture and
whether dynamic code is unavailable in the running binary. Qualification requires
the actual published NativeAOT executable, not `dotnet run`.

`WatchHeartbeat` accepts 1..16 items and a non-secret request label. Sequence starts
at 1. Only the final requested item marks completion. RPC cancellation interrupts
the stream without a completion item. The Dart client rejects missing, reordered
or inconsistent terminal items rather than treating partial data as complete.
Messages are bounded to 4096 bytes by the server. Client calls have deadlines.

## Local session

The child binds TLS HTTP/2 to IPv4 loopback on an OS-selected port. It creates
an ephemeral RSA key and self-signed certificate in memory. The certificate names
`localhost` and `127.0.0.1`. Neither the key nor the capability enters a file.

The parent starts its selected installed engine with no arguments. It sends a
random 256-bit capability through private inherited stdin. The engine reads a
fixed 65-byte frame with a startup deadline. Its private stdout returns one
base64 Protobuf `EngineReady` frame: protocol major, port, and public PEM
certificate. The parent bounds the frame to 4096 bytes and ten seconds. It refuses
an incompatible major before it sends an authenticated network request.

Dart trusts only the supplied certificate and checks the `localhost` authority.
It does not merge system trust roots or accept bad certificates. TLS checks the
peer before gRPC sends the `mc-session` metadata. The registered server interceptor
checks every RPC shape with a constant-time capability comparison. Missing,
duplicate, or wrong capabilities return `UNAUTHENTICATED`.

The installed child and its private inherited pipes form the bootstrap trust
boundary. TLS protects against a substituted network endpoint. This does not
identify a malicious replacement of the installed executable or create a
same-user sandbox. MC-061 owns package identity. No network discovery, persistent
endpoint, reusable credential, or certificate store is used.

`EngineOwner` owns one child per desktop host. Concurrent starts share one attempt.
A failed start or crash permits Retry. A late result cannot replace a newer
attempt or a close state. MC-058 owns OS-level second-instance behavior.

Close cancels client calls and closes stdin. EOF requests graceful engine shutdown.
The parent waits up to three seconds for the child after its connection attempt
finishes. Startup and RPC deadlines bound that attempt. A timeout retains the
owned child and cancels app exit. The user can wait and quit again. The parent
never kills an authenticated child to meet that timeout. MC-007 owns durable
operation semantics. No game or mod mutation is available in this version.

## Generation and checks

After locked .NET and pub restore, from the repository root:

```sh
python3 tools/generate-protocol.py --check
```

Omit `--check` to regenerate. The tool uses pinned Grpc.Tools binaries and compiles
the pinned Dart plugin into disposable local scratch. No global protoc or Dart
plugin installation is needed. Both outputs are compared byte-for-byte in check
mode. Generated source stays in generator format; do not hand-edit it.

The actual compiler reports `libprotoc 35.1`. It generates C# for the selected
Google.Protobuf 3.36.1 runtime and Dart through protoc_plugin 25.0.0/protobuf 6.0.0.
See [dependency sources and notices](WIRE-DEPENDENCIES.md).

F# uses the documented `--reflectionfree` compiler flag to avoid generated record
`ToString` methods that call reflective printf. This removes the reachable warning
source; it is not an AOT/trim warning suppression. Domain/wire output uses explicit
fields, not record string formatting. All unexpected trim/AOT warnings fail publish.
See Microsoft's [F# NativeAOT compiler guidance](https://devblogs.microsoft.com/dotnet/announcing-fsharp-7/)
and [gRPC NativeAOT guidance](https://learn.microsoft.com/en-us/aspnet/core/grpc/native-aot?view=aspnetcore-10.0).

## Native qualification

Publish on Linux, then run the client behavior checks:

```sh
dotnet publish src/ModConductor.Engine/ModConductor.Engine.fsproj -c Release -r linux-x64 --self-contained true --no-restore -o .tools/publish/linux-x64
export MC_ENGINE_PATH="$PWD/.tools/publish/linux-x64/ModConductor.Engine"
cd ui/packages/mc_client
flutter test --no-pub
```

The checks require that path. Without it, the wire group reports an explicit skip;
a skip does not pass NativeAOT qualification.

From the root, run the actual native Flutter integration path:

```sh
python3 tools/check-linux-wire.py
```

This requires preinstalled Xvfb and xauth plus Flutter's native dependencies. It
uses a fresh private display/auth file, no TCP listener, no Wayland display and no
host input. A bounded timeout stops its owned check process group. It does not
install prerequisites or prove physical GPU/Wayland behavior.

On Windows, use the existing MSVC linker, libraries and Windows SDK through
`dotnet publish`. No Visual Studio IDE or engine-side CMake is required.
From the repository root, run these commands in PowerShell:

```powershell
dotnet publish src/ModConductor.Engine/ModConductor.Engine.fsproj -c Release -r win-x64 --self-contained true --no-restore -o .tools/publish/win-x64
$env:MC_ENGINE_PATH = "$PWD/.tools/publish/win-x64/ModConductor.Engine.exe"
Push-Location ui/packages/mc_client
flutter test --no-pub
Pop-Location
Push-Location ui/apps/mod_conductor
flutter test integration_test/native_wire_test.dart -d windows --no-pub --dart-define=MC_ENGINE_PATH=$env:MC_ENGINE_PATH
Pop-Location
```

Run native UI checks in an isolated Windows guest, not on the user's desktop.
An ordinary Windows .NET/Flutter build does not prove NativeAOT qualification.
