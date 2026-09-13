# Provenance

Original engine libraries, schemas, typed clients, presentation, tools, tests, and
authored documentation are Mod Conductor work. They remain unlicensed under the
[development policy](DEVELOPMENT-POLICY.md). This inventory is not permission to publish.

## Adopted SDKs, scaffolds, and tooling

| MC paths / dependency | Kind (copy, translation, asset, dependency) | Upstream origin and exact version / commit | Changes or adaptation | Licence and copyright notice evidence / retained location |
| --- | --- | --- | --- | --- |
| `ui/apps/mod_conductor/linux/`, `windows/`, `.metadata`, generated build/analyzer metadata | Copy / generated scaffold | [Flutter 3.47.2, revision d3b14c876900e553bc736ca19295fc09e3853e8e](https://github.com/flutter/flutter/tree/d3b14c876900e553bc736ca19295fc09e3853e8e/packages/flutter_tools/templates) | `flutter create --empty --platforms=linux,windows`; identifiers substituted by the generator; generic README/demo content removed | BSD-3-Clause; [Flutter notice](third-party/flutter-LICENSE.txt) |
| `windows/runner/resources/app_icon.ico` within the app | Placeholder asset | `flutter_template_images` 5.0.0, used by Flutter 3.47.2 generation; [package origin](https://pub.dev/packages/flutter_template_images/versions/5.0.0) | Unmodified generated default Flutter icon; not final MC branding | BSD-3-Clause; [image notice](third-party/flutter-template-images-LICENSE.txt) |
| Flutter framework / `sky_engine` | SDK dependency | Flutter 3.47.2 / Dart 3.13.2; engine revision `a804b261645ef8c13eb3d5c44a5c2fb0340c5539`; archive pins in [SDK configuration](../.config/flutter-sdk.json) | SDK consumed, not vendored; SDK packages show `0.0.0` in pub lock and resolve through this SDK pin | BSD-3-Clause plus component terms; [Flutter](third-party/flutter-LICENSE.txt), [Dart](third-party/dart-LICENSE.txt), [complete engine notices](third-party/flutter-engine-LICENSE.txt) |
| `FSharp.Core` | Engine dependency | [10.1.400](https://www.nuget.org/packages/FSharp.Core/10.1.400), source `dotnet/dotnet` at `14fbf8d5271c98133561eb55185fdb05b286f578` | Unmodified package; explicit central pin; SDK-aligned pin | MIT; [notice](third-party/fsharp-core-LICENSE.txt) |
| .NET SDK/runtime, ILCompiler and ILLink | Build/runtime dependencies | SDK 10.0.400; runtime and compiler/linker packages 10.0.11, source `dotnet/dotnet` at `e2f47b0110ed922f21a1522da67279133ce28f32` for runtime packages | Unmodified; native compiler host packages for linux-x64 and win-x64 appear in the lock; SDK reference/apphost/runtime packs also follow the runtime pin | MIT plus component terms; [runtime licence](third-party/dotnet-runtime-LICENSE.txt), [component notices](third-party/dotnet-NOTICES.txt) |
| Fantomas | Local development tool | [7.0.6](https://www.nuget.org/packages/fantomas/7.0.6), source `fsprojects/fantomas` at `ee160202e7ed5a33fd0f25affe10d1b288c36ce6` | Unmodified tool package; exact local manifest pin; not shipped with MC | Apache-2.0; [notice](third-party/fantomas-LICENSE.txt); bundled tool dependencies are recorded in the package's `tools/net8.0/any/fantomas.deps.json` |
| `characters`, `collection`, `meta`, `vector_math` | Flutter transitive dependencies | pub.dev: [characters 1.4.1](https://pub.dev/packages/characters/versions/1.4.1), [collection 1.19.1](https://pub.dev/packages/collection/versions/1.19.1), [meta 1.18.3](https://pub.dev/packages/meta/versions/1.18.3), [vector_math 2.4.0](https://pub.dev/packages/vector_math/versions/2.4.0) | Unmodified; exact versions and archive hashes in workspace lock | BSD-3-Clause; [characters](third-party/characters-LICENSE.txt), [collection](third-party/collection-LICENSE.txt), [meta](third-party/meta-LICENSE.txt), [vector_math](third-party/vector_math-LICENSE.txt) |
| `material_color_utilities` | Flutter transitive dependency | [0.13.0 on pub.dev](https://pub.dev/packages/material_color_utilities/versions/0.13.0) | Unmodified Flutter SDK constraint; not a new MC theme/design choice | Apache-2.0; [notice](third-party/material_color_utilities-LICENSE.txt) |
| `flutter_lints`, `lints` | Consumed analyzer tooling | [flutter_lints 6.0.0](https://pub.dev/packages/flutter_lints/versions/6.0.0), [lints 6.1.0](https://pub.dev/packages/lints/versions/6.1.0) | Included by app analysis options; not application features | BSD-3-Clause; [flutter_lints](third-party/flutter_lints-LICENSE.txt), [lints](third-party/lints-LICENSE.txt) |
| `actions/checkout`, `actions/setup-dotnet` | CI tooling references | [checkout v7.0.1 at 3d3c42e5aac5ba805825da76410c181273ba90b1](https://github.com/actions/checkout/tree/3d3c42e5aac5ba805825da76410c181273ba90b1), [setup-dotnet v6.0.0 at a98b56852c35b8e3190ac28c8c2271da59106c68](https://github.com/actions/setup-dotnet/tree/a98b56852c35b8e3190ac28c8c2271da59106c68) | Immutable workflow references; identifiers pinned in the workflow | MIT; [checkout](third-party/actions-checkout-LICENSE.txt), [setup-dotnet](third-party/actions-setup-dotnet-LICENSE.txt) |

Resolved versions and integrity hashes are recorded in the NuGet locks,
[`ui/pubspec.lock`](../ui/pubspec.lock), [tool manifest](../.config/dotnet-tools.json),
and [Flutter SDK pin](../.config/flutter-sdk.json). Notices retain upstream terms.
Line endings and trailing whitespace were normalized without changing terms.

The foundation bundles Roboto Regular, Medium, and Bold from the pinned Flutter
SDK's material font archive. Retain its [notice](../ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt).
Material Icons retain their [notice](third-party/MaterialIcons-LICENSE.txt).

[Dependencies](DEPENDENCIES.md) records gRPC, Protobuf, SQLite, and test dependencies.
Generated protocol files retain their generator headers.

## Native folder chooser

Flutter's file_selector provides GTK and Windows shell directory selection.
The umbrella package also resolves other platform implementations. Those packages
do not add supported Mod Conductor platforms.

| Package | Version | Notice |
| --- | --- | --- |
| file_selector | 1.1.0 | [BSD-3-Clause](third-party/file_selector-LICENSE.txt) |
| file_selector_linux | 0.9.4+1 | [BSD-3-Clause](third-party/file_selector_linux-LICENSE.txt) |
| file_selector_windows | 0.9.3+6 | [BSD-3-Clause](third-party/file_selector_windows-LICENSE.txt) |
| file_selector_platform_interface | 2.7.0 | [BSD-3-Clause](third-party/file_selector_platform_interface-LICENSE.txt) |
| cross_file | 0.3.5+5 | [BSD-3-Clause](third-party/cross_file-LICENSE.txt) |
| plugin_platform_interface | 2.1.8 | [BSD-3-Clause](third-party/plugin_platform_interface-LICENSE.txt) |
| file_selector_android | 0.5.2+10 | [BSD-3-Clause and included aFileChooser Apache-2.0 notice](third-party/file_selector_android-LICENSE.txt) |
| file_selector_ios | 0.5.3+6 | [BSD-3-Clause](third-party/file_selector_ios-LICENSE.txt) |
| file_selector_macos | 0.9.5+1 | [BSD-3-Clause](third-party/file_selector_macos-LICENSE.txt) |
| file_selector_web | 0.9.5 | [BSD-3-Clause](third-party/file_selector_web-LICENSE.txt) |


## Synthetic storage fixture

`tests/fixtures/state-v1.db` contains a synthetic runtime result created through
the earlier native store. Its source and database hashes are recorded beside it.
It contains no user data or credentials.

## Investigation references — not adopted material

- MO2 feature/source investigation baseline:
  [`modorganizer2/modorganizer` at `efe2a02d5dc641946baaa8db1440800f38d07837`](https://github.com/modorganizer2/modorganizer/tree/efe2a02d5dc641946baaa8db1440800f38d07837).
  The inspected [`src/modinfo.cpp` notice](https://github.com/modorganizer2/modorganizer/blob/efe2a02d5dc641946baaa8db1440800f38d07837/src/modinfo.cpp#L1-L18)
  specifies GPL version 3 or later for that file. This is reference evidence, not
  an exhaustive upstream licence inventory or an MC licence declaration.
- Viset was inspected during planning for NativeAOT precedent at commit
  `a5e5880a8f6d7277ca3d8eb1b65a37e9dbbb5fbd`; no Viset source is recorded as adopted.

The source-informed investigation is not claimed to be clean-room work.
Future reuse must be recorded as reuse rather than inferred to be original merely
because it is rewritten in another language. This inventory is not a final GPL determination.

## Local archive behavior reference

MC-030 inspected `src/downloadmanager.h` and `src/downloadmanager.cpp` at the MO2
baseline above. The state distinctions, archive metadata, restart scan, and explicit
removal were behavior references. MC uses its own stable IDs and SQLite records;
it does not adopt MO2's session IDs, filename-based sidecars, or orphan deletion.
No MO2 source text was copied into the archive implementation.


MC-031 also inspected the range/resume path in `src/downloadmanager.cpp:1047–1105`
at that baseline. It informed the behavior comparison; the new HttpClient worker
uses strong-ETag and exact-range checks rather than adopting the raw append path.
No MO2 source text was copied into the download implementation.


## Archive reader and synthetic fixtures

MC-032 uses SharpCompress 0.50.4 as a package, not copied parser source. Its MIT
and included component notice are retained in [Dependencies](DEPENDENCIES.md).
Legacy `installationmanager.cpp:729–757` and `archivefiletree.cpp:227–280` informed
metadata-tree behavior; no MO2 reader implementation was copied.

The two compressed/solid RAR5 archives and encrypted RAR5 fixture in
`tests/fixtures/archives` come from libarchive commit
`c719b9b1f56621d92063a85361cc8d114f5575a9`, under its BSD-2-Clause test notice.
The native fixture's numeric payload checks adapt `test_read_format_rar5.c`.
See the [fixture provenance](../tests/fixtures/archives/provenance.json) and
[retained notice](third-party/libarchive-rar-fixtures-NOTICE.txt). These are synthetic
test inputs, not a native libarchive dependency or human archives. The stored RAR5
fixture is MC-generated from the published RAR5 structural specification; ZIP and
7z inputs are generated by the fixture. No proprietary RAR executable is used.

MC-033 inspected the selected-tree mapping and installation completion in
`installationmanager.cpp:253–280,483–565` and `organizercore.cpp:878–916`.
These are behavior references. MC uses its own confirmed manifest, single-pass
payload writes and atomic SQLite publication. No MO2 installer source was copied.

## Credential storage

MC-038 calls the installed Linux libsecret C API dynamically. It does not copy
libsecret source or add a managed D-Bus package. Qualification used libsecret
0.21.7 ([LGPL-2.1-or-later](https://gitlab.gnome.org/GNOME/libsecret/-/blob/0.21.7/COPYING)).
The [upstream API reference](https://gnome.pages.gitlab.gnome.org/libsecret/) reports
0.21.8; this is not the installed qualification version. Distribution must include
the native dependency and its applicable notices. Packaging remains separate work.

Windows uses the operating system Credential Manager API. Windows runtime checks
remain deferred to MC-064. The isolated Linux fixtures use a private D-Bus and
GNOME Keyring, not a human keyring or live provider credentials.

MO2 `settings.cpp:2552–2660` informed the credential-storage comparison. MC does
not adopt MO2 client identifiers, credentials, authentication code or source text.
