# Path identity and filesystem preflight

`ModConductor.Platform` is an F# library. It has no engine, UI, database, or wire dependency. Its first consumer is the native filesystem fixture executable.

## Paths and target names

A `LogicalPath` contains name components, not a host path string. Components retain their original spelling and Unicode. A Linux backslash remains part of a name. `HostPath` requires an absolute host path. The library does not lowercase or rename source entries.

The caller selects a `TargetPolicy`: ordinal case-sensitive or ordinal-ignore-case comparison; unchanged Unicode or canonical composition; POSIX or Windows-compatible names. These are explicit comparison rules, not a claim to emulate every filesystem's Unicode table. The supplied Windows policy keeps Unicode unchanged. A Proton/Windows consumer can select that policy on Linux; the host OS does not select it automatically.

Preflight preserves entries and reports target collisions, file/directory conflicts, and invalid target names. Windows-compatible checks include reserved device names, forbidden characters, and trailing dots or spaces. They follow Microsoft's [naming rules](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file). They do not claim that passing these checks proves a later write will succeed.

## Selected roots and containment

`RootSelection.select` resolves the selected directory, including a linked root. The result separates its original host path, resolved path, and identity facts. The scan uses the resolved location.

`PathPreflight.inspect` takes explicit candidate, depth, and diagnostic limits. Candidate limits count failed entries as well as successful entries. Diagnostics remain bounded. A limit produces `LimitExceeded`; partial results are not a complete inventory. The caller can select a candidate budget for a large inventory. Depth is limited to 256 to bound recursive traversal.

The scanner reads namespace metadata. It reads each immediate symbolic-link or Windows junction target before it follows that target. An unselected absolute target or a chain that escapes is refused before target-opening canonicalization. The explicitly selected root spelling and its resolved spelling identify the same selection. Other out-of-root aliases are conservatively refused. Accepted paths receive native canonical-location and identity checks, including ancestor identity cycles. It never reads target file contents or enumerates a directory outside the selected resolved root. Other entry types and unsupported reparse metadata are refused. Canonical path comparisons are ordinal, not globally case-folded.

An entry's identity facts describe its resolved target. `Kind` records whether its original entry was a link; `TargetKind` records the resolved type. Linux FIFO and other special entries are not opened as ordinary files.

These are observations of a changing filesystem. They are not race-free authorization for later writes. A later materializer must hold and validate the appropriate handles and apply its own transaction rules. This library implements no materialization, copy fallback, deployment, or file journal.

## Identity and capabilities

File identity is separate from device identity and optional mount identity. Linux uses the fixed `statx` layout and checks returned availability bits before accepting inode/type/mount fields. Windows uses file ID information from an open metadata handle. Drive letters and lexical path roots are not device IDs. See [Linux statx](https://www.man7.org/linux/man-pages/man2/statx.2.html) and [Windows file ID information](https://learn.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-file_id_info).

Unknown metadata remains unknown. IDs are point-in-time filesystem facts, not permanent content hashes or a guarantee against ID reuse. Same-device identity does not prove hard-link support or identical mount topology.

`CapabilityProbe.passive` does not write. Writability, case behavior, rename, and link support remain untested. `probeOwnedFixture` and `probeOwnedPair` are explicit active calls: the caller must own empty disposable directories. They create only probe files and remove them afterward. They must not be run against a game installation or mod directory.

The active checks exercise write/readback, distinct case variants, a case-only rename through a temporary name, hard-link creation, symbolic-link creation, and a sampled long path. The report states the actual tested path length, not a universal maximum. Case-only rename is an observed two-step operation, not an atomic-rename claim. Cross-device link results come from an actual owned link attempt. Reflink and metadata-preservation support remain untested. Successful probes do not guarantee future access.

## Native conformance checks

The Platform library and `ModConductor.Platform.Fixtures` publish with NativeAOT warnings as errors. Their only package reference is the existing FSharp.Core pin. The fixture executable emits bounded explicit JSON observations through `Utf8JsonWriter`; this is test output, not a product protocol or serializer framework.

Managed F# tests use FsUnit 7.1.1 with NUnit 4.6.1, NUnit3TestAdapter 6.3.0, and Microsoft.NET.Test.Sdk 18.9.0. The supported `dotnet test` runner supplies test discovery, failure exit codes, and TRX results. A minimal FsUnit assertion failed NativeAOT trim analysis in NUnit's reflection-based comparison code, including with NUnit 4.6.1. No warning was suppressed and no production AOT setting was changed. Only the managed assertion runner uses these test packages. See the [NUnit adapter instructions](https://docs.nunit.org/articles/vs-test-adapter/Adapter-Installation.html).

After locked restore, build the solution, publish the native fixture, and run the managed tests against that exact executable:

```sh
dotnet build ModConductor.slnx -c Release --no-restore
dotnet publish tests/ModConductor.Platform.Fixtures/ModConductor.Platform.Fixtures.fsproj -c Release -r linux-x64 --no-restore -o .tools/publish/platform/linux-x64
export MC_PLATFORM_FIXTURE="$PWD/.tools/publish/platform/linux-x64/ModConductor.Platform.Fixtures"
export MC_SECOND_FIXTURE_ROOT=/dev/shm
dotnet test tests/ModConductor.Platform.Tests/ModConductor.Platform.Tests.fsproj -c Release --no-build --no-restore --logger "trx;LogFileName=platform-tests.trx" --results-directory .agent-workspace/test-results
```

On Windows, publish `win-x64` and select the `.exe`. For cross-device qualification, set `MC_SECOND_FIXTURE_ROOT` to an explicitly owned separate virtual volume. Never select a physical game volume merely for a test. Without a second volume, the runner reports that test as skipped; this does not qualify cross-device behavior. CI does not create or format Windows volumes. The retained private Windows VM supplied a disposable NTFS virtual disk for full qualification. Linux uses owned ext4 and tmpfs fixtures.

`MC_PLATFORM_REPORT` can select an output file for the native observations. The managed runner creates unique fixture directories under `.agent-workspace` and the selected second volume. It removes only those owned directories. There is no Flutter rebuild requirement for this library-only change.

## Test dependency notices

The current stable package versions were checked against NuGet's official package indexes. FsUnit uses the MIT license ([tagged source](https://raw.githubusercontent.com/fsprojects/FsUnit/7.1.1/license.txt)); NUnit, its adapter, and the .NET test SDK declare MIT in their exact packages. Notices are retained under `docs/third-party/`.

The NUnit third-party notice covers multiple target frameworks and mentions a legacy System.Runtime.Loader package. That package is not in the selected .NET 10 test closure. The managed test lock records the adapter and SDK dependency closure. Its package licenses are MIT; package notices are retained separately from the application notices. No NUnit or FsUnit assembly is included in the native fixture or application bundle. The Mod Conductor source license remains undecided until MC-067.
