import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppUpdateManager { winget, scoop, chocolatey }

extension AppUpdateManagerName on AppUpdateManager {
  String get label => switch (this) {
    AppUpdateManager.winget => 'WinGet',
    AppUpdateManager.scoop => 'Scoop',
    AppUpdateManager.chocolatey => 'Chocolatey',
  };
}

class AppRelease {
  const AppRelease(this.version, this.compatible);
  final String version;
  final bool compatible;
  Uri get page =>
      Uri.https('github.com', '/alsi-lawr/ModConductor/releases/tag/v$version');
}

AppRelease parseWindowsRelease(Object? body) {
  if (body is! Map<String, dynamic>) {
    throw const FormatException('Invalid release response.');
  }
  final tag = body['tag_name'];
  if (tag is! String || !RegExp(r'^v\d+\.\d+\.\d+$').hasMatch(tag)) {
    throw const FormatException('Invalid release version.');
  }
  final version = tag.substring(1);
  final assets = body['assets'];
  if (assets is! List) throw const FormatException('Missing release assets.');
  final compatible = assets.whereType<Map<String, dynamic>>().any(
    (asset) =>
        asset['name'] == 'ModConductor-$version-win-x64-setup.exe' ||
        asset['name'] == 'modconductor-v$version-win-x64.zip',
  );
  return AppRelease(version, compatible);
}

bool wingetListsInstalledVersion(String output, String version) =>
    output.split(RegExp(r'\r?\n')).any((line) {
      final cells = line.trim().split(RegExp(r'\s{2,}'));
      return cells.length >= 4 &&
          cells[1] == 'alsi-lawr.ModConductor' &&
          cells[2] == version &&
          cells.last == 'winget';
    });

abstract interface class AppUpdateSource {
  Future<String> installedVersion();
  Future<AppRelease?> latestRelease();
  Future<AppUpdateManager?> installedManager(String installedVersion);
  Future<void> openReleasePage(Uri page);
}

class AppUpdatesController extends ChangeNotifier {
  AppUpdatesController(this.source, {required this.windows});

  final AppUpdateSource source;
  final bool windows;
  String? installedVersion;
  AppRelease? release;
  AppUpdateManager? manager;
  String? problem;
  bool checking = false;
  bool checked = false;
  bool _started = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _loadingVersion;

  bool get updateAvailable =>
      windows &&
      release?.compatible == true &&
      installedVersion != null &&
      compareAppVersions(release!.version, installedVersion!) > 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadVersion() => _loadingVersion ??= _loadVersion().whenComplete(
    () => _loadingVersion = null,
  );

  Future<void> _loadVersion() async {
    try {
      installedVersion = await source.installedVersion();
    } on Exception {
      problem = 'Could not read the installed version.';
    }
    _notify();
  }

  Future<void> checkOnStartup(bool enabled) async {
    if (_started) return;
    _started = true;
    if (installedVersion == null) await loadVersion();
    if (windows && enabled) await check();
  }

  Future<void> check() async {
    if (!windows || checking || installedVersion == null) return;
    final generation = ++_generation;
    checking = true;
    problem = null;
    _notify();
    try {
      final found = await source.latestRelease();
      if (_disposed || generation != _generation) return;
      final channel =
          found != null &&
              found.compatible &&
              compareAppVersions(found.version, installedVersion!) > 0
          ? await source.installedManager(installedVersion!)
          : null;
      if (_disposed || generation != _generation) return;
      release = found;
      manager = channel;
      checked = true;
    } on Exception {
      if (!_disposed && generation == _generation) {
        release = null;
        manager = null;
        checked = false;
        problem = 'Could not check for updates. Check your connection.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        checking = false;
        _notify();
      }
    }
  }

  Future<void> openReleasePage() async {
    final selected = release;
    if (!updateAvailable || selected == null) return;
    try {
      await source.openReleasePage(selected.page);
      problem = null;
    } on Exception {
      problem = 'Could not open the release page. Try again.';
    }
    _notify();
  }

  void handoffFailed(String detail) {
    problem = detail;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }
}

int compareAppVersions(String left, String right) {
  List<int> parts(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+\d+)?$')
        .firstMatch(version);
    if (match == null) throw const FormatException('Invalid app version.');
    return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
  }

  final a = parts(left), b = parts(right);
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

class DesktopAppUpdateSource implements AppUpdateSource {
  DesktopAppUpdateSource({
    MethodChannel channel = const MethodChannel('dev.modconductor/desktop'),
  }) : _channel = channel;

  final MethodChannel _channel;
  static final _releaseEndpoint = Uri.https(
    'api.github.com',
    '/repos/alsi-lawr/ModConductor/releases/latest',
  );

  @override
  Future<String> installedVersion() async {
    final state = await _channel.invokeMapMethod<String, Object?>('state');
    final value = state?['version'];
    if (value is! String || value.isEmpty) {
      throw const FormatException('Installed version is unavailable.');
    }
    final match = RegExp(r'^(\d+\.\d+\.\d+)(?:\+\d+)?$').firstMatch(value);
    if (match == null)
      throw const FormatException('Invalid installed version.');
    return match.group(1)!;
  }

  @override
  Future<AppRelease?> latestRelease() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(_releaseEndpoint);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'ModConductor');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == HttpStatus.notFound) return null;
      if (response.statusCode != HttpStatus.ok) {
        throw const HttpException('Release check failed.');
      }
      final bytes = await response.fold<List<int>>(<int>[], (all, chunk) {
        if (all.length + chunk.length > 1024 * 1024) {
          throw const FormatException('Release response is too large.');
        }
        all.addAll(chunk);
        return all;
      });
      return parseWindowsRelease(jsonDecode(utf8.decode(bytes)));
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<AppUpdateManager?> installedManager(String installedVersion) async {
    if (!Platform.isWindows) return null;
    final executable = File(Platform.resolvedExecutable).absolute.path
        .toLowerCase();
    final matches = <AppUpdateManager>[];
    final scoopRoot =
        Platform.environment['SCOOP'] ??
        '${Platform.environment['USERPROFILE'] ?? ''}\\scoop';
    final scoopPackage = Directory('$scoopRoot\\apps\\modconductor');
    final scoopShim = File('$scoopRoot\\shims\\scoop.ps1');
    if (executable.startsWith(
          '${scoopPackage.absolute.path.toLowerCase()}\\',
        ) &&
        await scoopPackage.exists() &&
        await scoopShim.exists()) {
      matches.add(AppUpdateManager.scoop);
    }
    final chocoRoot =
        Platform.environment['ChocolateyInstall'] ??
        '${Platform.environment['ProgramData'] ?? ''}\\chocolatey';
    final chocoPackage = File(
      '$chocoRoot\\lib\\modconductor\\modconductor.nuspec',
    );
    final chocoExecutable = File('$chocoRoot\\bin\\choco.exe');
    if (executable.startsWith(
          '$chocoRoot\\lib\\modconductor\\'.toLowerCase(),
        ) &&
        await chocoPackage.exists() &&
        await chocoExecutable.exists()) {
      matches.add(AppUpdateManager.chocolatey);
    }
    final installed = await Process.run('reg.exe', [
      'query',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor',
      '/v',
      'InstallLocation',
    ]).catchError((Object _) => ProcessResult(0, 1, '', ''));
    final match = RegExp(r'InstallLocation\s+REG_SZ\s+([^\r\n]+)')
        .firstMatch(installed.stdout as String);
    final location = match?.group(1)?.trim().toLowerCase();
    if (location != null &&
        File('$location\\mod_conductor.exe').absolute.path.toLowerCase() ==
            executable) {
      final result = await Process.run('winget.exe', [
        'list',
        '--id',
        'alsi-lawr.ModConductor',
        '--exact',
        '--source',
        'winget',
        '--disable-interactivity',
      ]).catchError((Object _) => ProcessResult(0, 1, '', ''));
      if (result.exitCode == 0 &&
          wingetListsInstalledVersion(
            result.stdout as String,
            installedVersion.split('+').first,
          )) {
        matches.add(AppUpdateManager.winget);
      }
    }
    return matches.length == 1 ? matches.single : null;
  }

  @override
  Future<void> openReleasePage(Uri page) async {
    if (!Platform.isWindows) return;
    await Process.start('explorer.exe', [
      page.toString(),
    ], mode: ProcessStartMode.detached);
  }
}

abstract interface class AppUpdateWaiter {
  Future<bool> cancel();
}

typedef UpdateWaiterLauncher = Future<AppUpdateWaiter> Function(
  AppUpdateManager,
);
typedef UpdateQuitRequest = Future<bool> Function();
typedef UpdateSafetyCheck = Future<String?> Function();

class AppUpdateHandoff {
  AppUpdateHandoff({
    required this.checkSafety,
    required this.launchWaiter,
    required this.requestQuit,
  });

  final UpdateSafetyCheck checkSafety;
  final UpdateWaiterLauncher launchWaiter;
  final UpdateQuitRequest requestQuit;
  bool _active = false;
  bool _uncancelled = false;

  Future<String?> start(AppUpdateManager manager) async {
    if (_active) return 'An update handoff is already open.';
    if (_uncancelled) {
      return 'Close the existing update console before you quit.';
    }
    _active = true;
    try {
      AppUpdateWaiter? waiter;
      String? failure;
      try {
        final problem = await checkSafety();
        if (problem != null) return problem;
        waiter = await launchWaiter(manager);
        if (await requestQuit()) return null;
        failure = 'Mod Conductor did not quit. No update was started.';
      } on Exception {
        failure = 'Could not start the update handoff.';
      }
      if (waiter == null) return failure;
      try {
        if (await waiter.cancel()) return failure;
      } on Exception {
        // Report the cancellation failure below.
      }
      _uncancelled = true;
      return 'Could not stop the update console. Close it before you quit.';
    } finally {
      _active = false;
    }
  }
}

class PowerShellUpdateWaiter implements AppUpdateWaiter {
  PowerShellUpdateWaiter(this.processId, this.channel);
  final int processId;
  final MethodChannel channel;
  @override
  Future<bool> cancel() async =>
      await channel.invokeMethod<bool>('cancelUpdateWaiter', processId) ??
      false;
}

Future<AppUpdateWaiter> launchAppUpdateWaiter(
  AppUpdateManager manager, {
  MethodChannel channel = const MethodChannel('dev.modconductor/desktop'),
  int? parentProcessId,
}) async {
  String quote(String path) => "'${path.replaceAll("'", "''")}'";
  final scoopRoot =
      Platform.environment['SCOOP'] ??
      '${Platform.environment['USERPROFILE'] ?? ''}\\scoop';
  final chocoRoot =
      Platform.environment['ChocolateyInstall'] ??
      '${Platform.environment['ProgramData'] ?? ''}\\chocolatey';
  final command = switch (manager) {
    AppUpdateManager.winget => "& winget.exe upgrade --id alsi-lawr.ModConductor --exact --source winget",
    AppUpdateManager.scoop =>
      '& ${quote('$scoopRoot\\shims\\scoop.ps1')} update modconductor',
    AppUpdateManager.chocolatey =>
      '& ${quote('$chocoRoot\\bin\\choco.exe')} upgrade modconductor',
  };
  final target = parentProcessId ?? pid;
  final script =
      "if (Get-Process -Id $target -ErrorAction SilentlyContinue) { "
      "try { Wait-Process -Id $target -Timeout 120 -ErrorAction Stop } "
      "catch { if (Get-Process -Id $target -ErrorAction SilentlyContinue) { "
      "Write-Host 'Mod Conductor did not quit. No update was started.'; return } } }; "
      "$command; if (\$LASTEXITCODE -ne 0) { "
      "Write-Host 'The package manager did not complete the update.' }";
  final bytes = <int>[];
  for (final unit in script.codeUnits) {
    bytes.add(unit & 0xff);
    bytes.add(unit >> 8);
  }
  final processId = await channel.invokeMethod<int>('launchUpdateWaiter', {
    'command': base64Encode(bytes),
  });
  if (processId == null || processId <= 0) {
    throw const FormatException('Update console did not start.');
  }
  return PowerShellUpdateWaiter(processId, channel);
}
