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
actual native fixture. Missing native paths do not count as passes.
For local Windows package verification, pass
`-p:ModConductorLocalPublishVerificationOnly=true` to the engine publish. This
does not authorize product publication.

`MC_SECOND_FIXTURE_ROOT` selects an owned second-volume fixture location for
cross-device tests. Do not select a physical game volume. `MC_NATIVE_REPORT`
selects an optional observation file.

For an optional cross-platform runner, select one existing fixture scope. The
output directory must be new. Commands, stdout, stderr, the fixture report,
binary hash, exit codes, and elapsed times are retained there:

```sh
python3 tools/check-native.py --scope executables --fixture "$MC_NATIVE_FIXTURE" --output .agent-workspace/check-executables
python3 tools/check-native.py --scope storage --fixture "$MC_NATIVE_FIXTURE" --test-filter 'FullyQualifiedName~StorageTests' --build-tests --output .agent-workspace/check-storage
```

Use `--publish` instead of `--fixture` to run normal locked restore and NativeAOT
publication for the current OS. No SDK, package version, cache location, or
system setting is changed. Do not restore native projects with
`PublishAot=false`: that produces a different lock graph. Managed diagnostics
must use isolated restore outputs or reuse the native restore with `--no-restore`.
The runner does not interpret every report field as an assertion. The existing
fixture or NUnit tests determine success. It retains fixture data for inspection;
remove only those owned test directories after the results are retained.

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

## Local Windows x64 packages

Build the pinned Windows Flutter release and local-verification NativeAOT engine
as above. Build the LOOT helper with the pinned Rust 1.89 toolchain and locked
dependencies (`cargo +1.89.0 build --locked --release --target
x86_64-pc-windows-msvc` in `native/ModConductor.Loot.Helper`). Install the
official NSIS 3.12 tool locally; no optional plugins are used. The official
NSIS archive SHA-256 is
`56581f90db321581c5381193d796fffcf2d24b2f8fed2160a6c6a3baa67f2c4f`.

From the repository root on Windows:

```powershell
python tools/package-windows.py `
  --loot-helper native/ModConductor.Loot.Helper/target/x86_64-pc-windows-msvc/release/modconductor-loot-helper.exe `
  --output .tools/packages/windows-x64
```

Use a new output directory for each build. The script requires the real
Flutter, NativeAOT, SQLite, static-web-assets, and LOOT helper outputs; it
does not silently omit a missing native asset. It creates an unsigned per-user
NSIS installer and portable ZIP from one payload, with bundled third-party
notices. Adjacent files record payload hashes, artifact checksums, locked
dependency manifests, an SPDX file inventory, and local build provenance.
They are evidence for review, not a signing attestation or a licence grant.

The installer writes under the current user's LocalAppData Programs directory,
adds current-user Start Menu and desktop shortcuts, and supports upgrade and
uninstall. The portable ZIP can be extracted and run without installation;
replace the extracted binary directory to upgrade and remove it to uninstall.
User state is under the user's LocalAppData `ModConductor` directory, and mods
remain in the chosen workspace, not the binary directory. Test both formats in
an isolated Windows user profile before release. Do not use a physical game
installation for package smoke tests. Other Windows architectures, MSIX,
system-wide installation, file associations, signing, and publication are not
selected. MC-064 retains real-game qualification; MC-067 retains licence review.

## Local Linux x64 desktop payload

The Linux package hook builds inside an Ubuntu 24.04 FHS container. Docker builds
the tool image from `tools/linux-package/` only; it bind-mounts this checkout and
does not copy the checkout into the image. It checks the exact .NET 10.0.400,
Flutter 3.47.4/Dart 3.13.3, and Rust 1.89.0 toolchains before building.
Existing `.tools/flutter` must match the pin. If another SDK is installed there,
pass `--flutter-sdk` with the path to the pinned SDK inside this checkout.

```sh
python3 tools/publish-linux.py \
  --rid linux-x64 --version 0.1.0 --revision "$(git rev-parse HEAD)" \
  --publish-directory .tools/packages/linux-x64
python3 tools/smoke-linux-package.py \
  .tools/packages/linux-x64/bin/modconductor --version 0.1.0
```

Use a new output directory for each build. The payload contains the Flutter
bundle, NativeAOT engine, SQLite library, and pinned LOOT helper. Its launcher
uses paths relative to the extracted directory. Notices, dependency locks,
payload checksums, SPDX file inventory, and unsigned local provenance are in
`share/doc/modconductor`. The shared package workflow uses this Python hook to
make the Linux x64 tar archive; it restores execute modes for the launcher and
all three child executables after artifact transfer. The archive checksum is a
separate release artifact.

The tar payload expects system GTK 3, libsecret, EGL/OpenGL, GSettings schemas,
Fontconfig, fonts, and `xdg-utils`. Ubuntu 24.04 is the measured build and smoke
environment, not a selected minimum Linux version. The existing Nix package remains a
store-bound build; it is not the source of this portable payload. The packaging
workflow does not publish a release or install the product. MC-064 retains
real-game and target-system qualification; MC-067 retains the source licence
decision.

`python3 tools/check-linux-wire.py` runs the native Flutter connection check on a
private Xvfb display. It requires Xvfb and xauth. Its `--workspaces` mode also
requires xdotool for the isolated folder chooser. Use `--collections` for the
profile, mod, and saved-file journey with synthetic in-process input.
`--profile-mods` checks real profile enablement and multi-selection moves.
`--organization` checks category drafts, typed filters, and group context.
`MC_ENGINE_PATH` selects a previously published engine for these Linux UI checks. Use only an isolated guest for
Windows UI checks. Never direct test input to the user's desktop.

The [development policy](DEVELOPMENT-POLICY.md) governs local builds and
publication. These commands do not authorize distribution.

For focused native selection checks, set `MC_NATIVE_SCOPE=selection` and run the
NUnit runner with `--filter 'FullyQualifiedName~SelectionTests'`. Leave this
variable unset for the full fixture suite. The fixture includes a version-4
database created through real engine calls for transactional migration checks.

For focused category/query checks, use `MC_NATIVE_SCOPE=organization` with
`--filter 'FullyQualifiedName~OrganizationTests'`. Its version-5 database fixture
comes from real native engine registrations and profile edits. Migration checks
use the database itself, not the original workspace folders.
