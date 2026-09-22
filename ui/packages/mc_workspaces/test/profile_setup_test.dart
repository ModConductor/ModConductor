import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

const game = ProfileSetupGame(
  id: 'skyrim-se-steam',
  name: 'Skyrim Special Edition',
  storefront: 'Steam',
);

SteamInstallationCandidate candidate(String id, String path) =>
    SteamInstallationCandidate(
      id,
      SteamDirectory(path, path, 'identity-$id'),
      const [],
    );

class Discovery implements SteamDiscoveryClient {
  Discovery(this.candidates);

  final List<SteamInstallationCandidate> candidates;
  int searches = 0;
  int cancellations = 0;

  @override
  SteamSearch search(String definitionId, List<String> additionalRoots) {
    searches++;
    return SteamSearch(
      Future.value(
        SteamSearchResult(
          appId: 489830,
          roots: const [],
          candidates: candidates,
          diagnostics: const [],
          limited: false,
        ),
      ),
      () async => cancellations++,
    );
  }
}

Future<void> mount(
  WidgetTester tester, {
  required Discovery discovery,
  required Future<String?> Function(String?) chooseDirectory,
  required ProfileSetupSubmit onSubmit,
  VoidCallback? onCancel,
  VoidCallback? onComplete,
  Size size = const Size(1000, 760),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.light),
      home: Scaffold(
        body: ProfileSetupSurface(
          initialName: '',
          games: const [game],
          discovery: discovery,
          chooseDirectory: chooseDirectory,
          onSubmit: onSubmit,
          actionLabel: 'Create profile',
          canCancel: true,
          onCancel: onCancel,
          onComplete: onComplete,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> findInstallations(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('profile-setup-name')),
    'Northern Roads',
  );
  await tester.tap(find.byKey(const ValueKey('find-profile-installation')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'one discovered installation is selected without another decision',
    (tester) async {
      ProfileSetupSelection? submitted;
      var completed = 0;
      final discovery = Discovery([
        candidate('only', '/games/Skyrim Special Edition'),
      ]);
      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (_) async => null,
        onSubmit: (value) async {
          submitted = value;
          return null;
        },
        onComplete: () => completed++,
      );

      await findInstallations(tester);
      final submit = tester.widget<McAction>(
        find.byKey(const ValueKey('submit-profile-setup')),
      );
      expect(submit.onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();

      expect(submitted?.installation, '/games/Skyrim Special Edition');
      expect(submitted?.name, 'Northern Roads');
      expect(completed, 1);
    },
  );

  testWidgets('several installations require an explicit selection', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    final discovery = Discovery([
      candidate('first', '/games/first'),
      candidate('second', '/games/second'),
    ]);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => null,
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
    );

    await findInstallations(tester);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('submit-profile-setup')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey(('profile-installation', '/games/second'))),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/games/second');
  });

  testWidgets('no discovery result requires a manually selected folder', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    final discovery = Discovery(const []);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => '/manual/skyrim',
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
      size: const Size(480, 820),
    );

    await findInstallations(tester);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('submit-profile-setup')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('choose-profile-game-folder')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-profile-setup')),
    );
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/manual/skyrim');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelling the folder override retains the discovered selection',
    (tester) async {
      ProfileSetupSelection? submitted;
      var initialPath = '';
      final discovery = Discovery([candidate('only', '/games/discovered')]);
      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (path) async {
          initialPath = path ?? '';
          return null;
        },
        onSubmit: (value) async {
          submitted = value;
          return null;
        },
      );

      await findInstallations(tester);
      final override = tester.widget<TextButton>(
        find.byKey(const ValueKey('choose-another-profile-game-folder')),
      );
      override.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();

      expect(initialPath, '/games/discovered');
      expect(submitted?.installation, '/games/discovered');
    },
  );

  testWidgets('the folder override can replace several discovered choices', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    final discovery = Discovery([
      candidate('first', '/games/first'),
      candidate('second', '/games/second'),
    ]);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => '/manual/skyrim',
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
    );

    await findInstallations(tester);
    await tester.tap(
      find.byKey(const ValueKey('choose-another-profile-game-folder')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/manual/skyrim');
  });

  testWidgets('a rejected save retains the draft for retry', (tester) async {
    var submissions = 0;
    var completed = 0;
    final discovery = Discovery([candidate('only', '/games/discovered')]);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => null,
      onSubmit: (_) async {
        submissions++;
        return submissions == 1 ? 'The selected folder is not valid.' : null;
      },
      onComplete: () => completed++,
    );

    await findInstallations(tester);
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();
    expect(completed, 0);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('profile-setup-name')),
          )
          .controller!
          .text,
      'Northern Roads',
    );
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submissions, 2);
    expect(completed, 1);
  });

  testWidgets('cancel exits before discovery or profile submission', (
    tester,
  ) async {
    var cancelled = 0;
    var submissions = 0;
    final discovery = Discovery(const []);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => null,
      onSubmit: (_) async {
        submissions++;
        return null;
      },
      onCancel: () => cancelled++,
    );

    await tester.tap(find.widgetWithText(McAction, 'Cancel'));
    await tester.pump();

    expect(cancelled, 1);
    expect(discovery.searches, 0);
    expect(submissions, 0);
  });
}
