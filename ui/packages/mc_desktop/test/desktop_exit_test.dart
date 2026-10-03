import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_desktop/mc_desktop.dart';

class _Waiter implements AppUpdateWaiter {
  bool cancelled = false;

  @override
  Future<bool> cancel() async {
    cancelled = true;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'application requests share owner approval and one terminal exit',
    () async {
      final owner = Completer<bool>();
      final terminal = Completer<AppExitResponse>();
      var closes = 0;
      var exits = 0;
      final quit = DesktopExit(
        close: () {
          closes++;
          return owner.future;
        },
        exitApplication: () {
          exits++;
          return terminal.future;
        },
      );

      final first = quit.request();
      final repeat = quit.request();
      expect(closes, 1);
      expect(exits, 0);
      owner.complete(true);
      await Future<void>.delayed(Duration.zero);
      final duringExit = quit.request();
      expect(closes, 1);
      expect(exits, 1);
      terminal.complete(AppExitResponse.exit);
      expect(
        await Future.wait([first, repeat, duringExit]),
        everyElement(AppExitResponse.exit),
      );
      expect(await quit.request(), AppExitResponse.exit);
      expect(await quit.requestedByPlatform(), AppExitResponse.exit);
      expect(closes, 1);
      expect(exits, 1);
    },
  );

  test('owner refusal allows a later application request to finish', () async {
    final owner = Completer<bool>();
    var closes = 0;
    var exits = 0;
    final quit = DesktopExit(
      close: () {
        closes++;
        return closes == 1 ? owner.future : Future.value(true);
      },
      exitApplication: () async {
        exits++;
        return AppExitResponse.exit;
      },
    );

    final first = quit.request();
    final repeat = quit.request();
    owner.complete(false);
    expect(
      await Future.wait([first, repeat]),
      everyElement(AppExitResponse.cancel),
    );
    expect(closes, 1);
    expect(exits, 0);
    expect(await quit.request(), AppExitResponse.exit);
    expect(closes, 2);
    expect(exits, 1);
  });

  for (final platformFirst in [false, true]) {
    test(
      '${platformFirst ? 'window close' : 'Quit'} joins the other pending request without another native exit',
      () async {
        final owner = Completer<bool>();
        var closes = 0;
        var exits = 0;
        final quit = DesktopExit(
          close: () {
            closes++;
            return owner.future;
          },
          exitApplication: () async {
            exits++;
            return AppExitResponse.exit;
          },
        );

        final first = platformFirst
            ? quit.requestedByPlatform()
            : quit.request();
        final second = platformFirst
            ? quit.request()
            : quit.requestedByPlatform();
        final repeatedClose = quit.requestedByPlatform();
        owner.complete(true);
        expect(
          await Future.wait([first, second, repeatedClose]),
          everyElement(AppExitResponse.exit),
        );
        expect(closes, 1);
        expect(exits, 0);
      },
    );
  }

  test(
    'a refused window close does not suppress a later application exit',
    () async {
      final owner = Completer<bool>();
      var closes = 0;
      var exits = 0;
      final quit = DesktopExit(
        close: () {
          closes++;
          return closes == 1 ? owner.future : Future.value(true);
        },
        exitApplication: () async {
          exits++;
          return AppExitResponse.exit;
        },
      );

      final window = quit.requestedByPlatform();
      final application = quit.request();
      owner.complete(false);
      expect(
        await Future.wait([window, application]),
        everyElement(AppExitResponse.cancel),
      );
      expect(exits, 0);
      expect(await quit.request(), AppExitResponse.exit);
      expect(closes, 2);
      expect(exits, 1);
    },
  );

  test('update handoff shares Quit refusal and can retry without a stranded waiter', () async {
    final owner = Completer<bool>();
    var closes = 0;
    var exits = 0;
    final waiters = <_Waiter>[];
    final quit = DesktopExit(
      close: () {
        closes++;
        return closes == 1 ? owner.future : Future.value(true);
      },
      exitApplication: () async {
        exits++;
        return AppExitResponse.exit;
      },
    );
    final handoff = AppUpdateHandoff(
      checkSafety: () async => null,
      launchWaiter: (_, _) async {
        final waiter = _Waiter();
        waiters.add(waiter);
        return waiter;
      },
      requestQuit: () async => await quit.request() == AppExitResponse.exit,
    );

    final application = quit.request();
    final update = handoff.start(AppUpdateManager.winget, '1.2.4');
    await Future<void>.delayed(Duration.zero);
    owner.complete(false);
    expect(await application, AppExitResponse.cancel);
    expect(await update, isNotNull);
    expect(closes, 1);
    expect(exits, 0);
    expect(waiters.single.cancelled, isTrue);
    expect(await handoff.start(AppUpdateManager.winget, '1.2.4'), isNull);
    expect(closes, 2);
    expect(exits, 1);
    expect(waiters.last.cancelled, isFalse);
  });
}
