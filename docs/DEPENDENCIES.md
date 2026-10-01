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
| Grpc.Tools | 2.83.0 | Build-only protoc and C# plugin, PrivateAssets=All; [upstream commit](https://github.com/grpc/grpc/tree/c876f4da50f7da2f331888b88b2a7243514139fe) | Apache-2.0, build-only |
| Bundled protoc | 35.1 | Actual compiler reported by Grpc.Tools; [upstream](https://github.com/protocolbuffers/protobuf/tree/v35.1) | BSD-3-Clause, build-only |
| CSharpier | 1.3.0 | Local formatter for protocol project/central package/solution metadata; [upstream commit](https://github.com/belav/csharpier/tree/c3fe3f22a4f091eaf759e0b5aa8f3b9d3565e51b) | MIT, build-only |
| SharpCompress | 0.50.4 | In-process ZIP/7z/RAR metadata and lazy reads; [tagged source](https://github.com/adamhathcock/sharpcompress/tree/0.50.4), net10.0 asset has no package dependencies | [MIT and component notice](third-party/sharpcompress-NOTICES.txt) |
| Microsoft.AspNetCore.App | 10.0.11 | Slim host/Kestrel runtime, pinned with the existing .NET runtime; [source commit](https://github.com/dotnet/dotnet/tree/e2f47b0110ed922f21a1522da67279133ce28f32) | [MIT](third-party/dotnet-runtime-LICENSE.txt), [component notices](third-party/aspnetcore-NOTICES.txt) |

Package metadata supplies the source commits above. ASP.NET notices come from the
restored 10.0.11 runtime package. Runtime .NET and FSharp.Core notices still apply.
The compiler/SDK licenses do not determine the license for original MC source.

## Flutter and Dart

The application bundle includes generated `data/flutter_assets/NOTICES.Z`.
It contains Flutter, engine, Dart, and runtime pub-package notices, including
Roboto. Packages retain this file instead of duplicate copied notices.
`ui/pubspec.lock` records package versions and archive hashes.

Runtime direct dependencies include grpc 5.1.0 and protobuf 6.0.0.
Build-only protoc_plugin 25.0.0 generates the Dart client.
Generators, analysis tools, and test packages are not redistributed with MC.

The Flutter engine includes FreeType. This software is based in part on the
work of the FreeType Team. Its notice is in generated `NOTICES.Z`.

The copied runner source retains its [Flutter BSD notice](../ui/apps/mod_conductor/notices/Flutter-LICENSE.txt).
The source fonts retain their [Roboto notice](../ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt).
The bundled Material Icons font requires its separate [notice](third-party/MaterialIcons-LICENSE.txt).

## Rust LOOT helper

The helper links pinned libloot 0.29.6 and the transitive crates in
`native/ModConductor.Loot.Helper/Cargo.lock`. The exact source is vendored in
the [same-release source archive](SOURCE.md). The distributed packages retain
[each resolved crate's licence files and manifest declaration](third-party/rust-crates-NOTICES.txt),
not only libloot's top-level GPL text. In particular, esplugin 6.1.4 and
libloadorder 18.8.2 declare `GPL-3.0` in their package manifests, and
option-ext 0.2.0 declares `MPL-2.0`; that does not change the project grant
for original MC-authored material.

## Profile patches

| Component | Version | Source | Notice |
| --- | --- | --- | --- |
| FastRsyncNet | 2.5.0 | [NuGet](https://www.nuget.org/packages/FastRsyncNet/2.5.0), [package source](https://github.com/GrzegorzBlok/FastRsyncNet/tree/e2bec0c2e198b4ff049dfa4a6b82ef77591899d8) | [Apache-2.0](third-party/grpc-dotnet-LICENSE.txt) |
| System.IO.Hashing | 10.0.12 | [NuGet](https://www.nuget.org/packages/System.IO.Hashing/10.0.12), [package source](https://github.com/dotnet/dotnet/tree/95017c711e6afc1085133d440e42b4bd78155701) | [MIT](third-party/dotnet-runtime-LICENSE.txt), [component notices](third-party/dotnet-NOTICES.txt) |

Profile patches use FastRsync in process. The `fastrsync-2.5.0` encoding replaces
the previous profile patch format. Old `.mcprof` exports are not supported;
export a new file from the source profile. There is no migration or fallback.
NuGet locks pin both packages. Their net10.0 assets need no other packages.
FastRsync uses xxHash3 block signatures and Adler32V3 rolling checksums. MC keeps
its existing SHA-256 and length checks for exact profile files.

## Durable operation storage

| Component | Version | Source | Notice |
| --- | --- | --- | --- |
| Microsoft.Data.Sqlite.Core | 10.0.11 | [NuGet](https://www.nuget.org/packages/Microsoft.Data.Sqlite.Core/10.0.11) | [MIT](third-party/microsoft-data-sqlite-LICENSE.txt) |
| SQLitePCLRaw bundle/config/provider/core | 3.0.5 | [Upstream](https://github.com/ericsink/SQLitePCL.raw) | [Apache-2.0](third-party/grpc-dotnet-LICENSE.txt), [attribution](third-party/sqlitepclraw-NOTICE.txt) |
| SQLite native library | 3.53.4 | [NuGet](https://www.nuget.org/packages/SQLite/3.53.4) | [Public domain](https://sqlite.org/copyright.html) |

The Linux x64 native asset SHA-256 is `eddcd4aa561d5b8f252db77e8272e7d1aed96bcab9fda3f177ca542f916290bf`.
The Windows x64 native asset SHA-256 is `6ad8e149f8ce3ed3716402b4b3a2268ebbdc7b64391b5fafed747e03bb1b9418`.
NuGet locks retain the complete closure. These notices do not change the
original Mod Conductor grant.


## Test and build dependencies

The managed tests use FsUnit 7.1.1, NUnit 4.6.1, NUnit3TestAdapter 6.3.0,
and Microsoft.NET.Test.Sdk 18.9.0. These packages do not ship in the native
fixture or application bundle. Their use does not require product notice copies.
Build tools remain pinned in the tool manifests and package locks.

## Shared license texts

ASP.NET Core and the .NET runtime use the same retained
[MIT text](third-party/dotnet-runtime-LICENSE.txt). Their component notices remain separate.
FastRsyncNet, SQLitePCLRaw, and gRPC share the retained [Apache-2.0 text](third-party/grpc-dotnet-LICENSE.txt).
SQLitePCLRaw retains its separate [copyright notice](third-party/sqlitepclraw-NOTICE.txt).
