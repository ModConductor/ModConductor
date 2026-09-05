# Mod Conductor provenance

This inventory supports the [development policy](DEVELOPMENT-POLICY.md) and the
final GPL assessment in MC-067. It records provenance, not a legal conclusion or
permission to publish.

## Initial state — MC-001, 2026-09-05

The target was an existing empty Git repository on `main`, without commits,
remotes, or application files. MC-001 adds only the two documents listed below.
At that point, no MO2 code, translated code, assets, or branding had been adopted,
and no application dependencies had been adopted. Planned technologies and package candidates are
not dependencies already incorporated into the project.

### Original MC work

| Paths | Origin and authorship basis | Terms / evidence |
| --- | --- | --- |
| `docs/DEVELOPMENT-POLICY.md`, `docs/PROVENANCE.md` | Newly written MC-001 documentation implementing the human's MC-D-005 direction; not copied or translated from MO2 | No selected project licence; recorded by the MC-001 Git commit |

### Actual third-party adoption

None at MC-001. MC-002 introduces the entries below; all are tied to its Git
commit. No MO2 or Viset code, translated material, assets or branding was adopted.
Notices below apply to their named upstream material, not to original MC work.

| MC paths / dependency | Kind (copy, translation, asset, dependency) | Upstream origin and exact version / commit | Changes or adaptation | Licence and copyright notice evidence / retained location | Introducing MC commit / ticket |
| --- | --- | --- | --- | --- | --- |
| `ui/apps/mod_conductor/linux/`, `windows/`, `.metadata`, generated build/analyzer metadata | Copy / generated scaffold | [Flutter 3.47.2, revision d3b14c876900e553bc736ca19295fc09e3853e8e](https://github.com/flutter/flutter/tree/d3b14c876900e553bc736ca19295fc09e3853e8e/packages/flutter_tools/templates) | `flutter create --empty --platforms=linux,windows`; identifiers substituted by the generator; generic README/demo content removed | BSD-3-Clause; [Flutter notice](third-party/flutter-LICENSE.txt) | MC-002 |
| `windows/runner/resources/app_icon.ico` within the app | Placeholder asset | `flutter_template_images` 5.0.0, used by Flutter 3.47.2 generation; [package origin](https://pub.dev/packages/flutter_template_images/versions/5.0.0) | Unmodified generated default Flutter icon; not final MC branding | BSD-3-Clause; [image notice](third-party/flutter-template-images-LICENSE.txt) | MC-002 |
| Flutter framework / `sky_engine` | SDK dependency | Flutter 3.47.2 / Dart 3.13.2; engine revision `a804b261645ef8c13eb3d5c44a5c2fb0340c5539`; archive pins in [SDK configuration](../.config/flutter-sdk.json) | SDK consumed, not vendored; SDK packages show `0.0.0` in pub lock and resolve through this SDK pin | BSD-3-Clause plus component terms; [Flutter](third-party/flutter-LICENSE.txt), [Dart](third-party/dart-LICENSE.txt), [complete engine notices](third-party/flutter-engine-LICENSE.txt) | MC-002 |
| `FSharp.Core` | Engine dependency | [10.1.400](https://www.nuget.org/packages/FSharp.Core/10.1.400), source `dotnet/dotnet` at `14fbf8d5271c98133561eb55185fdb05b286f578` | Unmodified package; explicit central pin; see SDK alignment below | MIT; [notice](third-party/fsharp-core-LICENSE.txt) | MC-002 |
| .NET SDK/runtime, ILCompiler and ILLink | Build/runtime dependencies | SDK 10.0.400; runtime and compiler/linker packages 10.0.11, source `dotnet/dotnet` at `e2f47b0110ed922f21a1522da67279133ce28f32` for runtime packages | Unmodified; native compiler host packages for linux-x64 and win-x64 appear in the lock; SDK reference/apphost/runtime packs also follow the runtime pin | MIT plus component terms; [runtime licence](third-party/dotnet-runtime-LICENSE.txt), [component notices](third-party/dotnet-NOTICES.txt) | MC-002 |
| Fantomas | Local development tool | [7.0.6](https://www.nuget.org/packages/fantomas/7.0.6), source `fsprojects/fantomas` at `ee160202e7ed5a33fd0f25affe10d1b288c36ce6` | Unmodified tool package; exact local manifest pin; not shipped with MC | Apache-2.0; [notice](third-party/fantomas-LICENSE.txt); bundled tool dependencies are recorded in the package's `tools/net8.0/any/fantomas.deps.json` | MC-002 |
| `characters`, `collection`, `meta`, `vector_math` | Flutter transitive dependencies | pub.dev: [characters 1.4.1](https://pub.dev/packages/characters/versions/1.4.1), [collection 1.19.1](https://pub.dev/packages/collection/versions/1.19.1), [meta 1.18.3](https://pub.dev/packages/meta/versions/1.18.3), [vector_math 2.4.0](https://pub.dev/packages/vector_math/versions/2.4.0) | Unmodified; exact versions and archive hashes in app lock | BSD-3-Clause; [characters](third-party/characters-LICENSE.txt), [collection](third-party/collection-LICENSE.txt), [meta](third-party/meta-LICENSE.txt), [vector_math](third-party/vector_math-LICENSE.txt) | MC-002 |
| `material_color_utilities` | Flutter transitive dependency | [0.13.0 on pub.dev](https://pub.dev/packages/material_color_utilities/versions/0.13.0) | Unmodified Flutter SDK constraint; not a new MC theme/design choice | Apache-2.0; [notice](third-party/material_color_utilities-LICENSE.txt) | MC-002 |
| `flutter_lints`, `lints` | Consumed analyzer tooling | [flutter_lints 6.0.0](https://pub.dev/packages/flutter_lints/versions/6.0.0), [lints 6.1.0](https://pub.dev/packages/lints/versions/6.1.0) | Included by app analysis options; not application features | BSD-3-Clause; [flutter_lints](third-party/flutter_lints-LICENSE.txt), [lints](third-party/lints-LICENSE.txt) | MC-002 |
| `actions/checkout`, `actions/setup-dotnet` | CI tooling references | [checkout v7.0.1 at 3d3c42e5aac5ba805825da76410c181273ba90b1](https://github.com/actions/checkout/tree/3d3c42e5aac5ba805825da76410c181273ba90b1), [setup-dotnet v6.0.0 at a98b56852c35b8e3190ac28c8c2271da59106c68](https://github.com/actions/setup-dotnet/tree/a98b56852c35b8e3190ac28c8c2271da59106c68) | Immutable workflow references; workflow not yet executed | MIT; [checkout](third-party/actions-checkout-LICENSE.txt), [setup-dotnet](third-party/actions-setup-dotnet-LICENSE.txt) | MC-002 |

For new original work, extend the original-work inventory by coherent component
or document group with its authorship basis and introducing ticket/commit. For
adopted material, fill every applicable column above and explain any missing or
uncertain evidence. Link retained notices and lockfiles/manifests when present;
record the resolved version, not only a floating version range. Keep the two
categories distinct, including when an existing component gains translated code.

## MC-002 pins and evidence — refreshed 2026-09-05

- SDK/runtime stable versions were refreshed from Microsoft's
  [10.0 release manifest](https://builds.dotnet.microsoft.com/dotnet/release-metadata/10.0/releases.json).
  The selected SDK reports `FSCorePackageVersion=10.1.400` and derives its default
  `FSharpCoreMaximumMajorVersion` from that version in
  `FSharp/Microsoft.FSharp.Core.NetSdk.props`. The NuGet index also lists stable
  FSharp.Core 11.0.100; MC selects 10.1.400, the latest stable 10.x and the SDK's
  own baseline, rather than changing the SDK-aligned core generation. This does
  not assert that every newer core is incompatible, or that .NET 11 was selected.
- Flutter/Dart versions, release revision and both archive checksums were
  refreshed from the official [Linux](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)
  and [Windows](https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json)
  manifests. The Linux archive checksum was verified before generation/build.
  SDK constraints retain material_color_utilities 0.13.0, meta 1.18.3 and
  vector_math 2.4.0 despite newer registry versions; no dependency override is used.
- Fantomas 7.0.6 and FSharp.Core versions/licence expressions were checked in
  NuGet's version indexes and exact package nuspecs. The Flutter analyzer packages
  were checked against pub.dev metadata and their restored notices. SDK and tool
  packages remain upstream distributions in local caches, not vendored MC code;
  their internal dependency manifests remain part of those distributions.
- Restore authority: [engine lock](../src/ModConductor.Engine/packages.lock.json),
  [app lock](../ui/apps/mod_conductor/pubspec.lock),
  [tool manifest](../.config/dotnet-tools.json) and [SDK pin](../.config/flutter-sdk.json).
  No gRPC, protobuf generator, test framework or unrelated application dependency
  is adopted by this scaffold.
- Retained notices come from the resolved package/SDK archives, except FSharp's
  `src/fsharp/License.txt`, Fantomas's `LICENSE.md`, and the action licences, which
  were fetched from their exact source revisions above. Line endings and trailing
  whitespace are normalized; terms are unchanged. The four compiler/linker
  package notices were identical and share `dotnet-NOTICES.txt`. The engine notice
  file retains upstream component terms rather than relabelling them all BSD.

Newly authored MC-002 work consists of the F# entry point/project configuration,
root build/package/tool policy, SDK bootstrap, CI definition, build/provenance
instructions and replacement blank Dart entry point. Generated platform/template
material is identified separately above; this is not a clean-room claim. Original
MC portions remain unlicensed under the development policy. Third-party licence
files are not a project licence grant.

## MC-003 design artifact — 2026-09-05

- `design/mc-003-workbench/` is a separate, original simulated workbench prototype:
  authored widgets, typed presentation contracts, invented fixtures, behavioral
  checks, review documents and rendered screenshots. No production UI, engine,
  transport, game support or deployment implementation is adopted by this ticket.
- Its Linux/Windows runner scaffold and default icon were generated by the same
  pinned Flutter 3.47.2 templates already identified above. Window titles and
  default size are adapted for the preview. Existing Flutter/image notices apply;
  no MO2 or Viset material is copied or translated.
- The actual new dependency is SDK `flutter_test`, consumed by the behavior and
  rendering harness. Its resolved transitive versions/hashes are in the
  [design pub lock](../design/mc-003-workbench/pubspec.lock); the exact inventory
  and retained notices are in [design dependencies](../design/mc-003-workbench/DEPENDENCIES.md).
  Runtime Flutter packages and flutter_lints reuse the existing baseline, without
  overrides or a new external UI toolkit.
- Captures load SDK-bundled Roboto and Material Icons, with their notices retained
  in the design artifact. Font binaries are not vendored. Original MC design work
  remains unlicensed; no visual/performance approval or publication is inferred.

## Investigation references — not adopted material

- MO2 feature/source investigation baseline:
  [`modorganizer2/modorganizer` at `efe2a02d5dc641946baaa8db1440800f38d07837`](https://github.com/modorganizer2/modorganizer/tree/efe2a02d5dc641946baaa8db1440800f38d07837).
  The inspected [`src/modinfo.cpp` notice](https://github.com/modorganizer2/modorganizer/blob/efe2a02d5dc641946baaa8db1440800f38d07837/src/modinfo.cpp#L1-L18)
  specifies GPL version 3 or later for that file. This is reference evidence, not
  an exhaustive upstream licence inventory or an MC licence declaration.
- Viset was inspected during planning for NativeAOT precedent at commit
  `a5e5880a8f6d7277ca3d8eb1b65a37e9dbbb5fbd`; no Viset source was adopted in MC-001.

The source-informed investigation is not claimed to be clean-room work.
Future reuse must be recorded as reuse rather than inferred to be original merely
because it is rewritten in another language. The initial absence of adoption is
not a prediction about later implementation or a final GPL determination.
