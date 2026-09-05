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

The child binds HTTP/2 to IPv4 loopback on an OS-selected port. Its private stdout
pipe announces that endpoint once. The endpoint parser has a size/startup bound.
No credential appears in arguments, output or settings. **This is not authenticated
bootstrap.** Loopback and process ownership are not a security boundary against
other local processes. Authentication, executable identity and full lifecycle
hardening belong to later work. Do not use this proof for sensitive operations.

The parent owns the child and closes its stdin at shutdown. EOF stops the slim
host. Client disposal cancels active calls and waits for the child, with a bounded
kill fallback. There is no reconnect manager or durable operation framework.

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

The Windows engine NativeAOT gate is still pending explicit linker authority.
Ordinary Windows .NET/Flutter builds are not a substitute. There is no Windows
engine publish step in CI under the current Flutter-only MSVC exception.
