# Build and check

## Prerequisites

Use the .NET SDK in [`global.json`](../global.json) and runtime/package pins in
[`Directory.Build.props`](../Directory.Build.props) and
[`Directory.Packages.props`](../Directory.Packages.props). Install local SDKs under
ignored `.tools/`, not system directories.

Run `python3 tools/bootstrap-flutter.py` to install the pinned Flutter SDK. Reuse
an existing installation. Put `.tools/flutter/bin` on the current shell's PATH.
Use its bundled Dart SDK. Python 3.12 or later is required.

Linux needs Clang, pkg-config, CMake, Ninja, GTK 3 development libraries, zlib,
and the OpenSSL runtime. Windows needs standalone Microsoft C++ Build Tools,
the Windows SDK, and Flutter's CMake tools. The Visual Studio IDE is not required.
Flutter plugin builds require symbolic-link creation privileges on Windows.

CMake belongs only to Flutter native integration. Use `dotnet` to build and publish
the engine. An ordinary managed build is not a NativeAOT publication.

Optional `DOTNET_CLI_HOME`, `NUGET_PACKAGES`, and `PUB_CACHE` paths can isolate
caches under `.tools/`. Set them before restore. Keep
`DOTNET_GENERATE_ASPNET_CERTIFICATE=false` for an isolated CLI home.

## Restore and generate

From the repository root:

```sh
dotnet tool restore
dotnet restore ModConductor.slnx --locked-mode
cd ui
flutter pub get --enforce-lockfile
cd ..
python3 tools/generate-protocol.py --check
dotnet tool run fantomas --check src tests
dotnet build ModConductor.slnx -c Release --no-restore
```

Omit `--check` to regenerate [the protocol](PROTOCOL.md). Restore locks are
committed. Do not bypass them to hide an unintended dependency change.

## Native engine and tests

On Linux, from the root:

```sh
dotnet publish src/ModConductor.Engine -c Release -r linux-x64 --no-restore -o .tools/publish/linux-x64
export MC_ENGINE_PATH="$PWD/.tools/publish/linux-x64/ModConductor.Engine"
cd ui/packages/mc_client
flutter test --no-pub
cd ../../..
dotnet publish tests/ModConductor.Native.Fixtures -c Release -r linux-x64 --no-restore -o .tools/publish/native-fixtures/linux-x64
export MC_NATIVE_FIXTURE="$PWD/.tools/publish/native-fixtures/linux-x64/ModConductor.Native.Fixtures"
dotnet test tests/ModConductor.Native.Tests -c Release --no-build --no-restore
```

On Windows, use `win-x64` and the `.exe` paths. Set environment variables with
PowerShell's `$env:NAME = 'value'`. The managed FsUnit/NUnit runner consumes the
actual native fixture. Missing native paths cause explicit test skips, not passes.

`MC_SECOND_FIXTURE_ROOT` selects an owned second-volume fixture location for
cross-device tests. Do not select a physical game volume. `MC_NATIVE_REPORT`
selects an optional observation file.

## Desktop

From `ui/`:

```sh
flutter analyze --no-pub
cd packages/mc_ui_collections
flutter test --no-pub
cd ../mc_mod_library
flutter test --no-pub
cd ../mc_workspaces
flutter test --no-pub
cd ../../apps/mod_conductor
flutter test --no-pub test
flutter build linux --release --no-pub
cd ../../..
python3 tools/assemble-development.py
```

Use `flutter build windows --release --no-pub` on Windows. The bundle tool copies
the published engine and SQLite library beside Flutter. Keep that bundle intact.
The executables are under `ui/apps/mod_conductor/build/linux/x64/release/bundle/`
and `ui/apps/mod_conductor/build/windows/x64/runner/Release/`.

`python3 tools/check-linux-wire.py` runs the native Flutter connection check on a
private Xvfb display. It requires Xvfb and xauth. Its `--workspaces` mode also
requires xdotool for the isolated folder chooser. Use `--collections` for the
profile, mod, and saved-file journey with synthetic in-process input. Use only an isolated guest for
Windows UI checks. Never direct test input to the user's desktop.

The [development policy](DEVELOPMENT-POLICY.md) governs local builds and
publication. These commands do not authorize distribution.
