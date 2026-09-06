# Build the foundation

The desktop bundle opens Welcome and Preferences. It does not perform
sensitive operations or change game files. Preferences apply only until the app
closes. A bundled engine persists a typed runtime-check result. Both native
platforms require the published NativeAOT engine, not an ordinary .NET build.

The [development policy](DEVELOPMENT-POLICY.md) still applies: these commands are
for local qualification, not publication or external distribution.

## Toolchain

Use the exact .NET SDK specified in [`global.json`](../global.json). For a local
SDK installation, use ignored `.tools/dotnet` rather than a system directory
and add it to the current shell's PATH. CI installs there explicitly, as described
below; it does not rely on setup-dotnet's shared default installation location.
[`Directory.Build.props`](../Directory.Build.props) pins the runtime and enables
warnings-as-errors and restore locks. Package versions belong in
[`Directory.Packages.props`](../Directory.Packages.props), not individual projects.
F# is the authored engine default. `PublishAot` declares the engine's intended
publication mode; an ordinary Release build does not prove native publication.

Use Python 3.12 or later to install the pinned official Flutter SDK locally:

```sh
python tools/bootstrap-flutter.py
```

On systems naming Python `python3`, use that name instead. The bootstrap uses
[the SDK pin and archive hashes](../.config/flutter-sdk.json), checks the archive
before extraction and installs only under ignored `.tools/`. It intentionally
refuses to overwrite an existing `.tools/flutter`; reuse the existing SDK or
explicitly remove that SDK directory before reinstalling. No global Flutter,
Dart, formatter or package-manager tool installation is required. The current
SDK archives and desktop build targets are Linux x64 and Windows x64.

Put `.tools/flutter/bin` on the current shell's PATH (on Windows it contains
`flutter.bat` and `dart.bat`). Use the Dart SDK bundled with this Flutter release.
The app's exact SDK constraints must continue to agree with the SDK pin.

Linux needs Clang, CMake, Ninja, pkg-config and GTK 3 development libraries.
Windows needs Visual Studio's **Desktop development with C++** workload, including
its Windows SDK and CMake tools. See the official [Linux](https://docs.flutter.dev/platform-integration/linux/setup)
and [Windows](https://docs.flutter.dev/platform-integration/windows/setup) setup
guides. OS native build prerequisites come from the host/runner image; this is
not a promise of bit-for-bit reproducible OS toolchains. CI checks the Linux tools
with `command -v` and runs `pkg-config --print-errors --cflags --libs gtk+-3.0`
to check GTK development metadata and its dependency closure. Missing tools or
unusable metadata fail the job clearly; there is no installation fallback.
A successful preflight is not a compiler/linker or clean-build proof.

CMake is confined to Flutter's Linux/Windows native runners and required native
plugin/asset integration, including the separate design preview. Keep it minimal
and close to Flutter's scaffolding. It must not orchestrate the F#/.NET engine,
domain logic, protocol generation or project-wide builds/releases. Do not add
Makefiles or a replacement native build framework. Normal builds use the direct
`dotnet` and `flutter` commands below; no runner CMake changes are needed here.

## Restore, format and build

From the repository root:

```sh
dotnet tool restore
dotnet restore ModConductor.slnx --locked-mode
dotnet tool run fantomas --check src
dotnet build ModConductor.slnx --configuration Release --no-restore
```

Fantomas is resolved from [the local tool manifest](../.config/dotnet-tools.json).
Its tool runtime may roll forward to the installed .NET 10 runtime; the formatter
package version does not float. To apply formatting, omit `--check`.

From `ui/`, check all three workspace members with one dependency resolution:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed apps/mod_conductor/lib apps/mod_conductor/test packages/mc_ui_foundation/lib apps/mod_conductor/integration_test packages/mc_client/lib/mc_client.dart packages/mc_client/lib/src/engine_session.dart packages/mc_client/lib/src/engine_owner.dart packages/mc_client/lib/src/operations_client.dart packages/mc_client/test
cd apps/mod_conductor
flutter test --no-pub test
flutter build linux --release --no-pub
```

Before the desktop build, follow the [wire proof guide](WIRE-PROOF.md) to publish
the engine and check generated contracts. After both builds, from the root:

```sh
python3 tools/assemble-development.py
```

This copies the published engine and its SQLite native library into `engine/`
beside the Flutter executable. It does not run dotnet from CMake or build the engine implicitly.
Missing engine files produce a connection error rather than a false ready state.

Run the Linux bundle with `build/linux/x64/release/bundle/mod_conductor`.
On Windows, run `build\windows\x64\runner\Release\mod_conductor.exe`.
The app has a visible **Quit** button. No tray service is required.
[The component catalog](UI-COMPONENTS.md) records the shared components and controls.

Use `flutter build windows --release --no-pub` on native Windows instead.
Release artifacts are under `src/ModConductor.Engine/bin/Release/net10.0/` and
`ui/apps/mod_conductor/build/<platform>/x64/`. The Linux desktop bundle is
`build/linux/x64/release/bundle/`; keep the bundle together when running locally.

Committed restore locks belong to the engine, the protocol project and the UI
workspace (`ui/pubspec.lock`). A deliberate dependency change may update them with
`dotnet restore` / `flutter pub get`, but must also update the
[actual-adoption inventory](PROVENANCE.md). Do not bypass locked restore in CI.
The app uses `flutter_test` for interaction checks. The schema-generated protocol and typed client are included. The design mockup remains separate from the production workspace.

## NixOS local qualification

Do not modify `~/.nix` or install a profile for this scaffold. On the observed
NixOS host, nix-ld already supported the official SDK's binaries. The following
bounded shell supplied missing native development dependencies and the loader
search path needed by the official prebuilt Flutter engine:

```sh
nix develop --impure --expr '
  let pkgs = import <nixpkgs> {}; in pkgs.mkShell {
    packages = [ pkgs.pkg-config pkgs.cmake pkgs.ninja pkgs.clang ];
    buildInputs = [ pkgs.atk pkgs.cairo pkgs.gdk-pixbuf pkgs.glib pkgs.gtk3
      pkgs.harfbuzz pkgs.libepoxy pkgs.pango pkgs.libx11 pkgs.libdeflate
      pkgs.xorgproto pkgs.zlib pkgs.libsysprof-capture pkgs.fontconfig
      pkgs.pcre2 pkgs.libffi pkgs.util-linux pkgs.libselinux pkgs.libsepol
      pkgs.libthai pkgs.libdatrie ];
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libepoxy pkgs.fontconfig ];
  }'
```

This uses the host's Nixpkgs, not a new global configuration or a pinned Nix
platform. Check `pkg-config --modversion gtk+-3.0 sysprof-capture-4`, then run the
same Flutter commands above inside the shell. Other hosts may need different
native prerequisites; this command does not provision nix-ld.

To isolate caches for local qualification, set `NUGET_PACKAGES`,
`DOTNET_CLI_HOME`, `PUB_CACHE` and, if desired, `HOME` to separate absolute paths
under ignored `.tools/` **before** restore. Set
`DOTNET_GENERATE_ASPNET_CERTIFICATE=false` for isolated CLI-home checks. This avoids
using or repairing another project's cached tools or packages.

## Verification boundary

The [CI skeleton](../.github/workflows/ci.yml) defines locked restore, formatting,
analysis and native builds on Ubuntu 24.04 and Windows Server 2025. It neither
uploads build artifacts nor publishes anything. Its read-only Linux prerequisite
check runs before SDK setup and **never provisions OS tools or libraries**.
Windows relies on the runner's preinstalled C++ workload, and both images must
supply Python 3.12 or later. GTK development readiness is checked on the actual
Linux host, not inferred from its Ubuntu label or a tools inventory. A stock
hosted image is not claimed to satisfy that check.

SDK setup and CLI/package state use these paths relative to the checkout:

| Purpose | Workspace-local destination |
| --- | --- |
| .NET SDK, via `DOTNET_INSTALL_DIR` | `.tools/dotnet` |
| .NET CLI state, via `DOTNET_CLI_HOME` | `.tools/dotnet-cli` |
| NuGet packages, via `NUGET_PACKAGES` | `.tools/nuget/packages` |
| Flutter SDK, via the existing pinned bootstrap | `.tools/flutter` |
| Dart/pub packages, via `PUB_CACHE` | `.tools/pub-cache` |

The pinned setup-dotnet action documents the
[`DOTNET_INSTALL_DIR` override](https://github.com/actions/setup-dotnet/blob/a98b56852c35b8e3190ac28c8c2271da59106c68/README.md#environment-variables)
and adds the installed SDK to PATH. The workflow keeps ASP.NET certificate
generation disabled with `DOTNET_GENERATE_ASPNET_CERTIFICATE=false`. These local
SDK/cache settings do not provide missing native OS prerequisites.

A workflow definition is not a successful hosted CI run. Both platforms publish
the NativeAOT engine and check the actual Flutter connection. Windows uses the
existing MSVC linker, libraries and Windows SDK through `dotnet publish`. This
requires no Visual Studio IDE or engine-side CMake. The workflow does not install
OS prerequisites. See [native qualification commands](WIRE-PROOF.md#native-qualification).

## Native path preflight

The F# Platform library has a separate native fixture and managed assertion runner.
See [Path preflight](PATH-PREFLIGHT.md) for the exact commands and owned cross-volume fixtures.
Run `dotnet tool run fantomas --check src tests` when checking F# formatting.

[Owned-root storage](OWNED-ROOT-STORAGE.md) describes schema migration and native file-receipt checks. The shared native fixture tests both filesystem preflight and storage.
