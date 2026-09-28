# Source for a distributed Mod Conductor binary

The Linux and Windows release archives, installers, DEB, RPM, and AppImage
contain executable Mod Conductor code. The corresponding MC source archive is
`modconductor-v<VERSION>-source.tar.gz` on **the same version's release page**:

`https://github.com/alsi-lawr/ModConductor/releases/download/v<VERSION>/modconductor-v<VERSION>-source.tar.gz`

Replace `<VERSION>` with the release version. The release's
`checksums_sha256.txt` records the archive hash. Compare `SOURCE-REVISION` in
the archive with `source_revision` in `share/doc/modconductor/provenance.json`
(Linux) or `modconductor-v<VERSION>-win-x64-provenance.json` (Windows sidecar).
The source archive is a Git export of that revision plus the complete vendored
Cargo.lock source closure, including the pinned libloot revision. Its
`.cargo/config.toml` makes the Rust helper dependencies available offline.
The source archive includes the MC build, packaging, installation, and release
scripts, project licence, dependency locks, and third-party notices. The
`docs/BUILDING.md` procedure in that archive describes platform toolchains and
commands. Use `cargo +1.89.0 build --locked --offline` in
`native/ModConductor.Loot.Helper` to build the helper from the vendored Rust
sources. `docs/DEVELOPMENT-POLICY.md` states the
GPL-3.0-or-later grant for MC-authored material; separately licensed files
retain their own notices.

The source archive is the matching MC source offer; an arbitrary checkout of
the default branch is **not** a substitute. An installed Nix package records
its exact `source_revision` in `share/doc/modconductor/provenance.json`; obtain
that revision from the public Git repository and use the Nix expression and
`flake.lock` from that revision. The Nix store output does not include a source
archive or a private source cache.

## Exact external sources and build inputs

- The Rust helper's libloot 0.29.6 Git revision is
  [`136f3983c3eec7d377f83a7e7e0b0129aa5c8fe1`](https://github.com/loot/libloot/tree/136f3983c3eec7d377f83a7e7e0b0129aa5c8fe1).
  It and its locked crates are included in the same-release MC source archive;
  `native/ModConductor.Loot.Helper/Cargo.lock` identifies the full closure.
  The binary package retains the resolved crates' manifest declarations and
  licence/notice files in `rust-crates-NOTICES.txt` beside this document.
- The bundled .NET 10.0.11 runtime/ASP.NET/NativeAOT material is from
  [`dotnet/dotnet` at `e2f47b0110ed922f21a1522da67279133ce28f32`](https://github.com/dotnet/dotnet/tree/e2f47b0110ed922f21a1522da67279133ce28f32).
  NuGet package identities and exact package hashes are recorded in the committed
  `packages.lock.json` files; `docs/DEPENDENCIES.md` in the source archive
  links adopted packages and retained notices. `dotnet restore --locked-mode`
  retrieves the selected packages. .NET SDK 10.0.400 is a build tool, not an
  extra copy inside the binary package.
- Flutter 3.47.4/Dart 3.13.3 use engine revision
  [`06a2e2a110089dff50fe635cffd2a61e1b24fbcd`](https://github.com/flutter/engine/tree/06a2e2a110089dff50fe635cffd2a61e1b24fbcd).
  The complete engine component notices are in
  `docs/third-party/flutter-engine-LICENSE.txt`. The exact Flutter SDK
  download is pinned by `.config/flutter-sdk.json`; Dart package archive
  hashes are in `ui/pubspec.lock`. `flutter pub get --enforce-lockfile`
  retrieves these sources before the pinned Flutter build. The Flutter SDK
  itself is a build tool; engine/plugin material embedded in the app is not.
- The bundled xdelta3 executable is the upstream
  [3.2.0 release](https://github.com/jmacd/xdelta/releases/tag/v3.2.0).
  `third_party/xdelta3/README.md` pins both platform binaries and the
  matching upstream source archive by SHA-256. Its release build statically
  links [XZ Utils liblzma v5.8.3](https://github.com/tukaani-project/xz/tree/v5.8.3)
  and [BLAKE3 1.8.5](https://github.com/BLAKE3-team/BLAKE3/tree/1.8.5);
  their terms and source routes are recorded there. The two upstream sources
  are not modified or claimed as MC-authored code.
- The AppImage also embeds Ubuntu 24.04 libraries and resources beyond the
  portable tar payload. Its
  `share/doc/modconductor/third-party/ubuntu-24.04/bundled-ubuntu-packages.tsv`
  records each deployed library's binary package and version, the matching
  **source package** and version, and source path. Resource packages have a
  `.` path entry. Matching Ubuntu copyright files sit beside the manifest.
  Obtain exact Ubuntu source packages through
  [Ubuntu's package archive](https://launchpad.net/ubuntu/noble/+source) or
  `apt source <source-package>=<source-version>` with Ubuntu 24.04 `deb-src`
  entries enabled. AppImage type-2 runtime `20251108` comes from its
  [tagged source](https://github.com/AppImage/type2-runtime/tree/20251108),
  and the bundled linuxdeploy GTK plugin comes from
  [`7a3fbc31a9e5075073ff8790f26effbac5f84453`](https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/tree/7a3fbc31a9e5075073ff8790f26effbac5f84453).
  `tools/bootstrap-appimage-tools.py` pins their distributed binary/script
  hashes. Appimagetool and linuxdeploy are packaging tools, not copied into
  the AppImage.

System libraries required but **not included** in a portable tar, DEB, RPM,
Windows package, or Nix output are identified by that format's dependency
metadata. The source routes above do not replace each third party's own
licence terms and are not a claim of exhaustive legal clearance. Do not
publish a candidate until its actual binary, source archive, hashes, and
format-specific notices have been checked together.
