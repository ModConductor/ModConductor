# Dependencies

The committed NuGet and pub locks pin resolved versions and integrity hashes.
Original MC-authored code, documentation, and artwork are GPL-3.0-or-later under
the [project licence](../LICENSE) and [development policy](DEVELOPMENT-POLICY.md).
These notices apply only to adopted third-party material and do not relicense it.

## .NET and generators

| Component | Selected version | Actual use and source | Notice |
| --- | --- | --- | --- |
| Grpc.AspNetCore.Server, Grpc.Net.Common, Grpc.Core.Api | 2.83.0 | Server/contract runtime; [upstream commit](https://github.com/grpc/grpc-dotnet/tree/4301104498e53898a452e8fb2fea6c0b1492b755) | [Apache-2.0](third-party/grpc-dotnet-LICENSE.txt) |
| Google.Protobuf | 3.36.1 | Generated C# message runtime; [upstream commit](https://github.com/protocolbuffers/protobuf/tree/f377bfefc5e2cfab68b816903c25b23e091c439d) | [BSD-3-Clause](third-party/google-protobuf-LICENSE.txt) |
| Grpc.Tools | 2.83.0 | Build-only protoc and C# plugin, PrivateAssets=All; [upstream commit](https://github.com/grpc/grpc/tree/c876f4da50f7da2f331888b88b2a7243514139fe) | [Apache-2.0](third-party/grpc-tools-LICENSE.txt) |
| Bundled protoc | 35.1 | Actual compiler reported by Grpc.Tools; [upstream](https://github.com/protocolbuffers/protobuf/tree/v35.1) | [BSD-3-Clause](third-party/protoc-LICENSE.txt) |
| CSharpier | 1.3.0 | Local formatter for protocol project/central package/solution metadata; [upstream commit](https://github.com/belav/csharpier/tree/c3fe3f22a4f091eaf759e0b5aa8f3b9d3565e51b) | [MIT](third-party/csharpier-LICENSE.txt) |
| SharpCompress | 0.50.4 | In-process ZIP/7z/RAR metadata and lazy reads; [tagged source](https://github.com/adamhathcock/sharpcompress/tree/0.50.4), net10.0 asset has no package dependencies | [MIT and component notice](third-party/sharpcompress-NOTICES.txt) |
| Microsoft.AspNetCore.App | 10.0.11 | Slim host/Kestrel runtime, pinned with the existing .NET runtime; [source commit](https://github.com/dotnet/dotnet/tree/e2f47b0110ed922f21a1522da67279133ce28f32) | [MIT](third-party/aspnetcore-LICENSE.txt), [component notices](third-party/aspnetcore-NOTICES.txt) |

Package metadata supplies the source commits above. ASP.NET notices come from the
restored 10.0.11 runtime package. Existing .NET/FSharp.Core/ILCompiler notices still
apply. The compiler/SDK licences do not determine the licence for original MC source.

## Dart

Runtime direct dependencies are grpc 5.1.0 and protobuf 6.0.0. The workspace's
build-only protoc_plugin 25.0.0 generates Dart using the pinned SDK. The SDK
integration_test/flutter_driver packages drive the native Flutter check. Their
Flutter/Dart notices are already retained in the main provenance inventory.


The table lists hosted resolutions, including generator and test
transitives. Each notice is retained from its resolved package archive. Existing
hosted packages keep their previous notices. `ui/pubspec.lock` is authoritative
for archive SHA-256 hashes.

| Package | Version | Source archive | Retained notice |
| --- | --- | --- | --- |
| _fe_analyzer_shared | 107.0.0 | [pub.dev](https://pub.dev/packages/_fe_analyzer_shared/versions/107.0.0) | [notice](third-party/_fe_analyzer_shared-LICENSE.txt) |
| analyzer | 14.3.0 | [pub.dev](https://pub.dev/packages/analyzer/versions/14.3.0) | [notice](third-party/analyzer-LICENSE.txt) |
| args | 2.7.0 | [pub.dev](https://pub.dev/packages/args/versions/2.7.0) | [notice](third-party/args-LICENSE.txt) |
| convert | 3.1.2 | [pub.dev](https://pub.dev/packages/convert/versions/3.1.2) | [notice](third-party/convert-LICENSE.txt) |
| crypto | 3.0.7 | [pub.dev](https://pub.dev/packages/crypto/versions/3.0.7) | [notice](third-party/crypto-LICENSE.txt) |
| dart_style | 3.1.13 | [pub.dev](https://pub.dev/packages/dart_style/versions/3.1.13) | [notice](third-party/dart_style-LICENSE.txt) |
| file | 7.0.1 | [pub.dev](https://pub.dev/packages/file/versions/7.0.1) | [notice](third-party/file-LICENSE.txt) |
| fixnum | 1.1.1 | [pub.dev](https://pub.dev/packages/fixnum/versions/1.1.1) | [notice](third-party/fixnum-LICENSE.txt) |
| glob | 2.2.0 | [pub.dev](https://pub.dev/packages/glob/versions/2.2.0) | [notice](third-party/glob-LICENSE.txt) |
| google_cloud | 0.5.0 | [pub.dev](https://pub.dev/packages/google_cloud/versions/0.5.0) | [notice](third-party/google_cloud-LICENSE.txt) |
| google_identity_services_web | 0.3.3+1 | [pub.dev](https://pub.dev/packages/google_identity_services_web/versions/0.3.3+1) | [notice](third-party/google_identity_services_web-LICENSE.txt) |
| googleapis_auth | 2.3.3 | [pub.dev](https://pub.dev/packages/googleapis_auth/versions/2.3.3) | [notice](third-party/googleapis_auth-LICENSE.txt) |
| grpc | 5.1.0 | [pub.dev](https://pub.dev/packages/grpc/versions/5.1.0) | [notice](third-party/grpc-LICENSE.txt) |
| http | 1.6.0 | [pub.dev](https://pub.dev/packages/http/versions/1.6.0) | [notice](third-party/http-LICENSE.txt) |
| http2 | 2.3.1 | [pub.dev](https://pub.dev/packages/http2/versions/2.3.1) | [notice](third-party/http2-LICENSE.txt) |
| http_parser | 4.1.2 | [pub.dev](https://pub.dev/packages/http_parser/versions/4.1.2) | [notice](third-party/http_parser-LICENSE.txt) |
| package_config | 3.0.0 | [pub.dev](https://pub.dev/packages/package_config/versions/3.0.0) | [notice](third-party/package_config-LICENSE.txt) |
| platform | 3.1.6 | [pub.dev](https://pub.dev/packages/platform/versions/3.1.6) | [notice](third-party/platform-LICENSE.txt) |
| process | 5.0.6 | [pub.dev](https://pub.dev/packages/process/versions/5.0.6) | [notice](third-party/process-LICENSE.txt) |
| protobuf | 6.0.0 | [pub.dev](https://pub.dev/packages/protobuf/versions/6.0.0) | [notice](third-party/protobuf-LICENSE.txt) |
| protoc_plugin | 25.0.0 | [pub.dev](https://pub.dev/packages/protoc_plugin/versions/25.0.0) | [notice](third-party/protoc_plugin-LICENSE.txt) |
| pub_semver | 2.2.1 | [pub.dev](https://pub.dev/packages/pub_semver/versions/2.2.1) | [notice](third-party/pub_semver-LICENSE.txt) |
| sync_http | 0.3.1 | [pub.dev](https://pub.dev/packages/sync_http/versions/0.3.1) | [notice](third-party/sync_http-LICENSE.txt) |
| typed_data | 1.4.0 | [pub.dev](https://pub.dev/packages/typed_data/versions/1.4.0) | [notice](third-party/typed_data-LICENSE.txt) |
| watcher | 1.2.1 | [pub.dev](https://pub.dev/packages/watcher/versions/1.2.1) | [notice](third-party/watcher-LICENSE.txt) |
| web | 1.1.1 | [pub.dev](https://pub.dev/packages/web/versions/1.1.1) | [notice](third-party/web-LICENSE.txt) |
| webdriver | 3.1.0 | [pub.dev](https://pub.dev/packages/webdriver/versions/3.1.0) | [notice](third-party/webdriver-LICENSE.txt) |
| yaml | 3.1.4 | [pub.dev](https://pub.dev/packages/yaml/versions/3.1.4) | [notice](third-party/yaml-LICENSE.txt) |

Notice line endings/trailing whitespace are normalized without changing terms.
The GPL selection does not complete the remaining compliance review or publication decision.

### Flutter tests

The production widget and interaction tests use SDK `flutter_test`. The table
records its adopted hosted dependencies. `ui/pubspec.lock` retains the exact
versions and archive hashes. These dependencies do not require committed design
previews.

| Test dependency | Upstream terms |
| --- | --- |
| [stream_channel 2.1.4](https://pub.dev/packages/stream_channel/versions/2.1.4) | [Retained notice](third-party/stream_channel-LICENSE.txt) |
| [async 2.13.1](https://pub.dev/packages/async/versions/2.13.1) | [Retained notice](third-party/async-LICENSE.txt) |
| [leak_tracker_flutter_testing 3.0.10](https://pub.dev/packages/leak_tracker_flutter_testing/versions/3.0.10) | [Retained notice](third-party/leak_tracker_flutter_testing-LICENSE.txt) |
| [matcher 0.12.20](https://pub.dev/packages/matcher/versions/0.12.20) | [Retained notice](third-party/matcher-LICENSE.txt) |
| [test_api 0.7.12](https://pub.dev/packages/test_api/versions/0.7.12) | [Retained notice](third-party/test_api-LICENSE.txt) |
| [term_glyph 1.2.2](https://pub.dev/packages/term_glyph/versions/1.2.2) | [Retained notice](third-party/term_glyph-LICENSE.txt) |
| [string_scanner 1.4.1](https://pub.dev/packages/string_scanner/versions/1.4.1) | [Retained notice](third-party/string_scanner-LICENSE.txt) |
| [source_span 1.10.2](https://pub.dev/packages/source_span/versions/1.10.2) | [Retained notice](third-party/source_span-LICENSE.txt) |
| [path 1.9.1](https://pub.dev/packages/path/versions/1.9.1) | [Retained notice](third-party/path-LICENSE.txt) |
| [stack_trace 1.12.2](https://pub.dev/packages/stack_trace/versions/1.12.2) | [Retained notice](third-party/stack_trace-LICENSE.txt) |
| [boolean_selector 2.1.2](https://pub.dev/packages/boolean_selector/versions/2.1.2) | [Retained notice](third-party/boolean_selector-LICENSE.txt) |
| [leak_tracker_testing 3.0.2](https://pub.dev/packages/leak_tracker_testing/versions/3.0.2) | [Retained notice](third-party/leak_tracker_testing-LICENSE.txt) |
| [leak_tracker 11.0.2](https://pub.dev/packages/leak_tracker/versions/11.0.2) | [Retained notice](third-party/leak_tracker-LICENSE.txt) |
| [vm_service 15.3.0](https://pub.dev/packages/vm_service/versions/15.3.0) | [Retained notice](third-party/vm_service-LICENSE.txt) |
| [clock 1.1.3](https://pub.dev/packages/clock/versions/1.1.3) | [Retained notice](third-party/clock-LICENSE.txt) |
| [fake_async 1.3.3](https://pub.dev/packages/fake_async/versions/1.3.3) | [Retained notice](third-party/fake_async-LICENSE.txt) |

SDK Material Icons retain their [notice](third-party/MaterialIcons-LICENSE.txt).
The foundation retains the [Roboto notice](../ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt).

## Durable operation storage

| Component | Version | Source | Notice |
| --- | --- | --- | --- |
| Microsoft.Data.Sqlite.Core | 10.0.11 | [NuGet](https://www.nuget.org/packages/Microsoft.Data.Sqlite.Core/10.0.11) | [MIT](third-party/microsoft-data-sqlite-LICENSE.txt) |
| SQLitePCLRaw bundle/config/provider/core | 3.0.5 | [Upstream](https://github.com/ericsink/SQLitePCL.raw) | [Apache-2.0](third-party/sqlitepclraw-LICENSE.txt), [attribution](third-party/sqlitepclraw-NOTICE.txt) |
| SQLite native library | 3.53.4 | [NuGet](https://www.nuget.org/packages/SQLite/3.53.4) | [Public-domain notice](third-party/sqlite-native-LICENSE.txt) |

The Linux x64 native asset SHA-256 is `eddcd4aa561d5b8f252db77e8272e7d1aed96bcab9fda3f177ca542f916290bf`.
The Windows x64 native asset SHA-256 is `6ad8e149f8ce3ed3716402b4b3a2268ebbdc7b64391b5fafed747e03bb1b9418`.
NuGet locks retain the complete closure. These notices do not change the
original Mod Conductor grant.


## Native test runner

The managed assertion runner uses FsUnit 7.1.1, NUnit 4.6.1,
NUnit3TestAdapter 6.3.0, and Microsoft.NET.Test.Sdk 18.9.0 under MIT terms.
Retain the [FsUnit license](third-party/fsunit-LICENSE.txt),
[NUnit license](third-party/nunit-LICENSE.txt), [NUnit component notices](third-party/nunit-THIRD_PARTY_NOTICES.md),
and [adapter/runner package notices](third-party/platform-tests/).
These packages are not included in the native fixture or application bundle.
