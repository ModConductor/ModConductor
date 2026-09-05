# Build the foundation

This is a build scaffold, not a usable mod manager. The F# executable currently
exits successfully without doing work; the desktop runner opens a blank surface.
Product UI is deferred to MC-003, and generated contracts, gRPC and published
NativeAOT interoperability proof are deferred to MC-005. There are no behavior
tests because no product behavior has been introduced.

The [development policy](DEVELOPMENT-POLICY.md) still applies: these commands are
for local qualification, not publication or external distribution.

## Toolchain

Install the exact .NET SDK specified in [`global.json`](../global.json).
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
not a promise of bit-for-bit reproducible OS toolchains.

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

From `ui/apps/mod_conductor`:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib
flutter build linux --release --no-pub
```

Use `flutter build windows --release --no-pub` on native Windows instead.
Release artifacts are under `src/ModConductor.Engine/bin/Release/net10.0/` and
`ui/apps/mod_conductor/build/<platform>/x64/`. The Linux desktop bundle is
`build/linux/x64/release/bundle/`; keep the bundle together when running locally.

The two committed restore locks are the engine's `packages.lock.json` and the
app's `pubspec.lock`. A deliberate dependency change may update them with
`dotnet restore` / `flutter pub get`, but must also update the
[actual-adoption inventory](PROVENANCE.md). Do not bypass locked restore in CI.
No test framework, unused RPC generator or speculative shared library is included.

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
      pkgs.pcre2 pkgs.libffi pkgs.util-linux pkgs.libselinux pkgs.libsepol ];
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
uploads build artifacts nor publishes anything. Its Linux prerequisite step uses
`apt-get` only on the disposable hosted runner; it is not a developer-host setup
command. Windows relies on the runner's preinstalled C++ workload, and both images
supply Python 3.12 or later. These OS-level prerequisites are distinct from the
repository-local SDK/formatter setup, and the planned `apt-get` step does not
establish MC-002's no-global-tool-install acceptance criterion.

A workflow definition is not a
successful CI run: MC-002 still requires actual clean native Windows and Linux
runner evidence. Local NixOS build evidence does not establish Windows support
or the later NativeAOT cross-language acceptance gate.
