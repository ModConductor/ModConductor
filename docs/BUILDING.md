# Build and check

## Prerequisites

Use the .NET SDK in [`global.json`](../global.json) and runtime/package pins in
[`Directory.Build.props`](../Directory.Build.props) and
[`Directory.Packages.props`](../Directory.Packages.props). Install local SDKs under
ignored `.tools/`, not system directories.

Run `python3 tools/bootstrap-flutter.py` to install the pinned Flutter SDK. Reuse
an existing installation. Put `.tools/flutter/bin` on the current shell's PATH.
Use its bundled Dart SDK. Python 3.12 or later is required.

Linux needs Clang, pkg-config, CMake, Ninja, GTK 3 development libraries, Fontconfig, zlib,
the OpenSSL runtime, and the pinned Rust 1.89 toolchain. Windows needs standalone Microsoft C++ Build Tools,
the Windows SDK, and Flutter's CMake tools. The Visual Studio IDE is not required.
Flutter plugin builds require symbolic-link creation privileges on Windows.

CMake is used by Flutter and native dependencies. The bundle command builds the
LOOT helper with locked dependencies. Use `dotnet` to publish the engine.
An ordinary managed build is not a NativeAOT publication.

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

The approved application icon source is
`ui/packages/mc_ui_foundation/assets/brand/modconductor.svg`. Regenerate the
committed Flutter PNG, Linux hicolor PNGs, and Windows ICO with
`python3 tools/generate-app-icons.py`. This needs `rsvg-convert` from librsvg,
which the Nix development shell provides. The normal app build uses the
committed images and does not need librsvg.

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
bash tools/assemble-development.sh
```

Use `flutter build windows --release --no-pub` on Windows. The bundle tool builds
the pinned LOOT helper and copies it with the engine, SQLite library, and static
web assets beside Flutter. Keep that bundle intact.
The executables are under `ui/apps/mod_conductor/build/linux/x64/release/bundle/`
and `ui/apps/mod_conductor/build/windows/x64/runner/Release/`.

## Local Windows x64 packages

The top-level Windows package command builds the Flutter release, NativeAOT
engine, and pinned LOOT helper. It obtains NSIS 3.12 locally. No optional
plugins are used. The official
NSIS archive SHA-256 is
`56581f90db321581c5381193d796fffcf2d24b2f8fed2160a6c6a3baa67f2c4f`.

From the repository root on Windows:

```powershell
./tools/publish-desktop.ps1 -Rid win-x64 -Version 0.1.0 `
  -Revision (git rev-parse HEAD) -PublishDirectory .tools/packages/windows-x64
```

Use a new output directory for each build. The package step requires the real
Flutter, NativeAOT, SQLite, static-web-assets, and LOOT helper outputs; it
does not silently omit a missing native asset. It creates an unsigned per-user
NSIS installer and portable ZIP from one payload, with bundled third-party
notices. Adjacent files record payload hashes, artifact checksums, locked
dependency manifests, an SPDX file inventory, and local build provenance.
They are evidence for review, not a signing attestation or publication approval.

The installer writes under the current user's LocalAppData Programs directory,
adds current-user Start Menu and desktop shortcuts, and supports upgrade and
uninstall. The portable ZIP can be extracted and run without installation;
replace the extracted binary directory to upgrade and remove it to uninstall.
User state is under the user's LocalAppData `ModConductor` directory, and mods
remain in the chosen workspace, not the binary directory. Test both formats in
an isolated Windows user profile before release. Do not use a physical game
installation for package smoke tests. Other Windows architectures, MSIX,
system-wide installation, file associations, signing, and publication are not
selected. MC-064 retains real-game qualification; MC-067 retains compliance review.

The desktop package workflow uses `tools/publish-desktop.sh` on Linux and
`tools/publish-desktop.ps1` on Windows. The Windows script builds the NativeAOT engine,
Flutter app, and LOOT helper once, then calls `tools/package-windows.ps1`. It
checks the .NET 10.0.400, Flutter 3.47.4, Rust 1.89.0, and NSIS 3.12 pins.
The output contains the complete `payload/`, the NSIS installer, and the local
portable ZIP. The shared archive step makes the release ZIP from that same
payload. `tools/finalize-desktop-release.sh` adds the installer to release
assets and writes Scoop, Chocolatey, and WinGet metadata from the archive and
installer checksums. It also checks both platform provenance revisions and
adds `modconductor-v<VERSION>-source.tar.gz` from that exact Git commit and the
vendored Cargo.lock source closure. The source archive checksum is appended to
the same release checksum list; [source directions](SOURCE.md) are copied into
the platform payloads. These are local, unsigned artifacts. The package
workflow does not publish or submit them. WinGet metadata names the selected
project licence; package/runtime qualification remains separate.

## Local Linux x64 desktop payload

The Linux package hook builds inside an Ubuntu 24.04 FHS container. Docker builds
the tool image from `tools/linux-package/` only; it bind-mounts this checkout and
does not copy the checkout into the image. It checks the exact .NET 10.0.400,
Flutter 3.47.4/Dart 3.13.3, and Rust 1.89.0 toolchains before building.
The script installs the pinned SDK in `.tools/flutter` if it is absent.

```sh
bash tools/publish-desktop.sh \
  --rid linux-x64 --version 0.1.0 --revision "$(git rev-parse HEAD)" \
  --publish-directory .tools/packages/linux-x64
bash tools/smoke-desktop-package.sh \
  .tools/packages/linux-x64/bin/modconductor --version 0.1.0
```

Use a new output directory for each build. The payload contains the Flutter
bundle, NativeAOT engine, SQLite library, and pinned LOOT helper. Its launcher
uses paths relative to the extracted directory. Notices, dependency locks,
payload checksums, SPDX file inventory, and unsigned local provenance are in
`share/doc/modconductor`. The shared package workflow uses this shell script to
make the Linux x64 tar archive; it restores execute modes for the launcher and
all three child executables after artifact transfer. The archive checksum is a
separate release artifact.

The tar payload expects system GTK 3, libsecret, EGL/OpenGL, GSettings schemas
and the `gsettings` command, Fontconfig, fonts, and `xdg-utils`. Ubuntu 24.04 is
the selected Linux baseline. The existing Nix package remains a store-bound
build; it is not the source of this portable payload.

The shared package workflow also builds an Ubuntu 24.04 amd64 DEB from the same
tar archive. To build all Linux release formats from an assembled archive:

```sh
bash tools/finalize-linux-release.sh 0.1.0 artifacts/release artifacts/package-metadata
```

The DEB installs `modconductor` in `/usr/bin`, its desktop files in
`/usr/share/applications`, and the application under `/usr/lib/modconductor`.
Its dependencies include `libglib2.0-bin` because the folder chooser uses
`gsettings`. The desktop entry accepts NXM links but does not change the
user's default NXM handler. The launcher also works with no arguments. Secure
storage needs an available, unlocked Secret Service provider in the user's
desktop session; installing the package does not create or unlock a keyring.
Upgrade and removal leave user state under the user's home directory intact.

The same release hook builds a Fedora 44 x86_64 RPM from that archive.

The RPM installs the same application, `/usr/bin/modconductor` launcher, and
desktop entry as the DEB. Its Fedora dependencies include GTK 3, libsecret,
GSettings, fonts, graphics libraries, and `xdg-utils`. Fedora 44 x86_64 is the
RPM test target; this is not a claim of support for other RPM distributions.
The RPM is unsigned and local-only. It does not register itself as the default
NXM handler. Install, upgrade, and remove it in an isolated Fedora 44 guest;
do not install it on the host for package tests.

The same release archive also produces a Linux x64 AppImage and a Linux-only
Homebrew cask for that AppImage. To build only the AppImage from that archive:

```sh
bash tools/package-appimage.sh \
  artifacts/release/modconductor-v0.1.0-linux-x64.tar.gz \
  artifacts/release/modconductor-0.1.0-linux-x64.AppImage 0.1.0
```

The generator checks pinned appimagetool 1.9.1, linuxdeploy
1-alpha-20251107-1, GTK plugin commit
`7a3fbc31a9e5075073ff8790f26effbac5f84453`, and type-2 runtime
20251108 before use. It builds from the Ubuntu 24.04 archive in a small
container; the runtime is embedded from the pinned file, not downloaded by
appimagetool. The AppImage includes GTK 3 libraries, GSettings schemas,
`gsettings`, libsecret, Fontconfig, DejaVu fonts, and `xdg-utils` commands.
It uses host glibc, graphics drivers, X11 or XWayland, and an available
Secret Service provider. The package records bundled Ubuntu package versions
and notices in `usr/lib/modconductor/share/doc/modconductor/third-party`.
The GTK plugin currently selects X11. Test the AppImage on Ubuntu 24.04 and
Fedora 44 before release. If FUSE is unavailable in a test container, use
`--appimage-extract-and-run`; that does not prove direct FUSE mounting.

The cask links this exact AppImage on Linux and checks its SHA-256. It does
not target macOS. Do not publish the cask or enable a package repository until
the licence-compliance, hosting, and signing decisions are complete. An AppImage NXM
handler uses the stable AppImage path, not its temporary mount path.
Check an installed cask AppImage on a private Xvfb display:

```sh
bash tools/smoke-desktop-package.sh "$HOME/Applications/modconductor-0.1.0-linux-x64.AppImage" \
  --version 0.1.0 --appimage --close-window
```

This mode extracts the AppImage under checkout-owned scratch and does not test
FUSE mounting. It needs Xvfb and xdotool.
The optional shared Linux cask test uses this command after Homebrew installs
the cask. The shared publisher needs an explicit existing tap repository and
`publish_homebrew=true`; this project does not set either one yet.

Test installation, upgrade, and removal in an isolated Ubuntu 24.04 guest.
The package workflow does not publish a release or install the product on the
host. MC-064 retains real-game qualification; MC-067 retains the remaining
compliance review.

## Local Arch package

`tools/generate-aur-package.sh` uses the assembled Linux x64 tar archive to
write `modconductor-bin.PKGBUILD` and `modconductor-bin.SRCINFO`. It uses the
pinned Arch `base-devel` image to generate `.SRCINFO`. It does not rebuild the
desktop binaries. The release finalizer adds both files to the checksum list.
The recipe installs the payload under `/usr/lib/modconductor` and uses the same
installed launcher as the DEB and RPM packages.

For a local check, pass the archive, output directory, and version in that order.
Use a new output directory in `.agent-workspace/`:

```sh
bash tools/generate-aur-package.sh \
  artifacts/release/modconductor-v0.1.0-linux-x64.tar.gz \
  .agent-workspace/aur-check 0.1.0
```

The AUR recipe points at the matching release archive. Local verification can
substitute a `file://` URL for that same archive. Build with `makepkg` as a
non-root user, then install the resulting package in an isolated Arch system.
The original project material is GPL-3.0-or-later; mixed-payload package
metadata and remaining compliance still need review. Do not submit the recipe
to the public AUR or publish the package before MC-067 is complete.

## Nix local package

On x86-64 Linux, `nix build .#modconductor` builds the Flutter application,
engine, and pinned LOOT helper as one local package. `nix run .#modconductor`
runs that package. Neither command needs a separate helper build. Do not
publish the result before the remaining MC-067 compliance review.

## UI checks

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
