import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_desktop/mc_desktop.dart';

class _Source implements AppUpdateSource {
  String version = '1.2.3';
  AppRelease? latest;
  AppUpdateManager? channel;
  bool failCheck = false;
  bool failOpen = false;
  int checks = 0;
  int channelChecks = 0;
  Uri? opened;

  @override
  Future<String> installedVersion() async => version;

  @override
  Future<AppRelease?> latestRelease() async {
    checks++;
    if (failCheck) throw const FormatException('Network failed');
    return latest;
  }

  @override
  Future<AppUpdateManager?> installedManager(String installedVersion) async {
    expect(installedVersion, version);
    channelChecks++;
    return channel;
  }

  @override
  Future<void> openReleasePage(Uri page) async {
    if (failOpen) throw const FormatException('Browser failed');
    opened = page;
  }
}

class _Waiter implements AppUpdateWaiter {
  bool cancelled = false;
  bool cancelSucceeds = true;
  @override
  Future<bool> cancel() async {
    cancelled = true;
    return cancelSucceeds;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('installed version uses the runner build version', () async {
    const channel = MethodChannel('test/app-version');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'state');
      return {'version': '2.4.1+37'};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    expect(
      await DesktopAppUpdateSource(channel: channel).installedVersion(),
      '2.4.1',
    );
  });

  test(
    'one enabled startup check and manual check after disabled startup',
    () async {
      final source = _Source()..latest = const AppRelease('1.2.4', true);
      final enabled = AppUpdatesController(source, windows: true);
      addTearDown(enabled.dispose);
      await enabled.checkOnStartup(true);
      await enabled.checkOnStartup(true);
      expect(source.checks, 1);
      expect(enabled.updateAvailable, isTrue);

      final disabledSource = _Source()
        ..latest = const AppRelease('1.2.4', true);
      final disabled = AppUpdatesController(disabledSource, windows: true);
      addTearDown(disabled.dispose);
      await disabled.checkOnStartup(false);
      expect(disabledSource.checks, 0);
      await disabled.check();
      expect(disabledSource.checks, 1);
      expect(disabled.updateAvailable, isTrue);
    },
  );

  test(
    'unchanged, incompatible and unpublished releases offer no update',
    () async {
      final source = _Source();
      final updates = AppUpdatesController(source, windows: true);
      addTearDown(updates.dispose);
      await updates.loadVersion();
      source.latest = const AppRelease('1.2.3', true);
      await updates.check();
      expect(updates.updateAvailable, isFalse);
      source.latest = const AppRelease('1.3.0', false);
      await updates.check();
      expect(updates.updateAvailable, isFalse);
      source.latest = null;
      await updates.check();
      expect(updates.updateAvailable, isFalse);
      expect(updates.checked, isTrue);
      expect(updates.release, isNull);
      expect(source.channelChecks, 0);
    },
  );

  test('release parser needs a compatible Windows asset', () {
    final release = parseWindowsRelease({
      'tag_name': 'v1.2.4',
      'assets': [
        {'name': 'ModConductor-1.2.4-win-x64-setup.exe'},
      ],
    });
    expect(release.version, '1.2.4');
    expect(release.compatible, isTrue);
    expect(
      parseWindowsRelease({
        'tag_name': 'v1.2.4',
        'assets': [
          {'name': 'modconductor-v1.2.4-linux-x64.tar.gz'},
        ],
      }).compatible,
      isFalse,
    );
  });

  test('WinGet evidence requires the exact installed ID, version and source', () {
    const listing =
        'Name              Id                       Version  Available  Source\n'
        'Mod Conductor     alsi-lawr.ModConductor   1.2.3    1.2.4      winget\n';
    expect(wingetListsInstalledVersion(listing, '1.2.3'), isTrue);
    expect(wingetListsInstalledVersion(listing, '1.2.4'), isFalse);
    expect(
      wingetListsInstalledVersion(
        'Mod Conductor  someone.Else  1.2.3  winget\n',
        '1.2.3',
      ),
      isFalse,
    );
    expect(
      wingetListsInstalledVersion(
        'Mod Conductor  alsi-lawr.ModConductor  1.2.3  private\n',
        '1.2.3',
      ),
      isFalse,
    );
  });

  test(
    'network failure is actionable and unknown channel opens release page',
    () async {
      final source = _Source()
        ..failCheck = true
        ..latest = const AppRelease('1.2.4', true);
      final updates = AppUpdatesController(source, windows: true);
      addTearDown(updates.dispose);
      await updates.loadVersion();
      await updates.check();
      expect(updates.problem, contains('connection'));
      expect(updates.updateAvailable, isFalse);
      source.failCheck = false;
      await updates.check();
      expect(updates.manager, isNull);
      await updates.openReleasePage();
      expect(
        source.opened.toString(),
        'https://github.com/alsi-lawr/ModConductor/releases/tag/v1.2.4',
      );
    },
  );

  test(
    'identified manager is selected only for newer compatible release',
    () async {
      final source = _Source()
        ..latest = const AppRelease('2.0.0', true)
        ..channel = AppUpdateManager.winget;
      final updates = AppUpdatesController(source, windows: true);
      addTearDown(updates.dispose);
      await updates.checkOnStartup(true);
      expect(updates.manager, AppUpdateManager.winget);
      expect(source.channelChecks, 1);
    },
  );

  test('Nix does not check releases or enter Windows handoff', () async {
    final source = _Source()..latest = const AppRelease('2.0.0', true);
    final updates = AppUpdatesController(source, windows: false);
    addTearDown(updates.dispose);
    await updates.checkOnStartup(true);
    await updates.check();
    expect(updates.installedVersion, '1.2.3');
    expect(source.checks, 0);
    expect(source.channelChecks, 0);
    expect(updates.updateAvailable, isFalse);
  });

  test('handoff refuses active work without starting a manager', () async {
    var launches = 0;
    var quits = 0;
    final handoff = AppUpdateHandoff(
      checkSafety: () async => 'Close the managed game first.',
      launchWaiter: (_) async {
        launches++;
        return _Waiter();
      },
      requestQuit: () async {
        quits++;
        return true;
      },
    );
    expect(await handoff.start(AppUpdateManager.winget), contains('managed'));
    expect(launches, 0);
    expect(quits, 0);
  });

  test('handoff cancels waiting manager when quit is refused', () async {
    final waiter = _Waiter();
    final handoff = AppUpdateHandoff(
      checkSafety: () async => null,
      launchWaiter: (manager) async {
        expect(manager, AppUpdateManager.scoop);
        return waiter;
      },
      requestQuit: () async => false,
    );
    expect(
      await handoff.start(AppUpdateManager.scoop),
      contains('did not quit'),
    );
    expect(waiter.cancelled, isTrue);
  });

  test('failed console cancellation warns before a later quit', () async {
    final waiter = _Waiter()..cancelSucceeds = false;
    var launches = 0;
    final handoff = AppUpdateHandoff(
      checkSafety: () async => null,
      launchWaiter: (_) async {
        launches++;
        return waiter;
      },
      requestQuit: () async => false,
    );
    expect(
      await handoff.start(AppUpdateManager.scoop),
      contains('Close it before you quit'),
    );
    expect(waiter.cancelled, isTrue);
    expect(
      await handoff.start(AppUpdateManager.winget),
      contains('existing update console'),
    );
    expect(launches, 1);
  });

  test(
    'handoff starts once and does not cancel after successful quit',
    () async {
      final quit = Completer<bool>();
      final waiter = _Waiter();
      var launches = 0;
      final handoff = AppUpdateHandoff(
        checkSafety: () async => null,
        launchWaiter: (_) async {
          launches++;
          return waiter;
        },
        requestQuit: () => quit.future,
      );
      final pending = handoff.start(AppUpdateManager.chocolatey);
      await Future<void>.delayed(Duration.zero);
      expect(
        await handoff.start(AppUpdateManager.winget),
        contains('already open'),
      );
      quit.complete(true);
      expect(await pending, isNull);
      expect(launches, 1);
      expect(waiter.cancelled, isFalse);
    },
  );

  test(
    'Windows console boundary receives a wait-then-manager command',
    () async {
      const channel = MethodChannel('test/update-console');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'cancelUpdateWaiter') {
          expect(call.arguments, 9274);
          return true;
        }
        expect(call.method, 'launchUpdateWaiter');
        final encoded = (call.arguments as Map)['command'] as String;
        final bytes = base64Decode(encoded);
        final units = <int>[
          for (var i = 0; i < bytes.length; i += 2)
            bytes[i] | (bytes[i + 1] << 8),
        ];
        final command = String.fromCharCodes(units);
        expect(command, contains('Wait-Process -Id 7312'));
        expect(
          command,
          contains('winget.exe upgrade --id alsi-lawr.ModConductor'),
        );
        expect(command, contains('No update was started.'));
        return 9274;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final waiter = await launchAppUpdateWaiter(
        AppUpdateManager.winget,
        channel: channel,
        parentProcessId: 7312,
      );
      expect(waiter, isA<PowerShellUpdateWaiter>());
      expect(await waiter.cancel(), isTrue);
    },
  );
}
