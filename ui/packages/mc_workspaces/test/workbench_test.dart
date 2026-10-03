import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

class _Client extends Fake implements WorkspacesClient {
  static const profile = ProfileInfo('profile', 'Configured profile');
  final page = WorkspacePage(
    const WorkspaceInfo(
      id: 'workspace',
      name: 'Workspace',
      path: '/workspace',
      revision: 0,
      selectedProfile: profile,
    ),
    const [profile],
    null,
  );

  @override
  Future<WorkspaceList> recent({String? after}) async =>
      const WorkspaceList([], null);

  @override
  Future<WorkspacePage> open(String path) async => page;
}

void main() {
  testWidgets(
    'full workbench keeps Help clickable across resize and text scale',
    (tester) async {
      await (FontLoader('packages/mc_ui_foundation/Roboto')..addFont(
            rootBundle.load(
              'packages/mc_ui_foundation/assets/fonts/Roboto-Regular.ttf',
            ),
          ))
          .load();
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = WorkspaceController()..attach(_Client());
      addTearDown(controller.dispose);
      await controller.open('/workspace');
      var optimiseCalls = 0;
      for (final (width, scale, fitsTabs, fitsActions) in [
        (1280.0, 1.0, true, true),
        (1680.0, 1.0, true, true),
        (1920.0, 1.5, true, true),
        (1050.0, 1.0, false, false),
        (800.0, 1.0, false, false),
        (420.0, 1.3, false, false),
      ]) {
        tester.view.physicalSize = Size(width, 1000);
        await tester.pumpWidget(
          MaterialApp(
            theme: mcTheme(Brightness.dark),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: WorkspaceBrowser(
                controller: controller,
                modLibraryBuilder: (_, _, visible) =>
                    Center(child: Text('Mods visible: $visible')),
                discoveryBuilder: (_, _, visible) => const SizedBox.shrink(),
                gameContextBuilder: (_, _) => const SizedBox.shrink(),
                executableBuilder: (_, _) => const SizedBox.shrink(),
                artifactBuilder: (_, _, _) => const SizedBox.shrink(),
                helpBuilder: (_, workspace, actions) => const Center(
                  key: ValueKey('help-content'),
                  child: Text('Help content'),
                ),
                workbenchActions: (_, _) => [
                  SizedBox(
                    width: 190,
                    child: McChoice<String>(
                      key: const ValueKey('workbench-view'),
                      label: 'View',
                      value: 'load-order',
                      choices: const ['load-order'],
                      describe: (_) => 'Load order',
                      onChanged: (_) {},
                    ),
                  ),
                  McAction(
                    key: const ValueKey('workbench-optimise'),
                    label: 'Optimise',
                    icon: Icons.auto_fix_high,
                    emphasis: McActionEmphasis.primary,
                    onPressed: () => optimiseCalls++,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final help = find.byKey(const ValueKey('workspace-help-tab'));
        final tabs = find
            .ancestor(of: help, matching: find.byType(SingleChildScrollView))
            .first;
        final tabViewport = tester.getRect(tabs);
        final helpButton = tester.getRect(
          find.ancestor(of: help, matching: find.byType(TextButton)).first,
        );
        if (fitsTabs) {
          expect(tabViewport.contains(helpButton.topLeft), isTrue);
          expect(helpButton.right, lessThanOrEqualTo(tabViewport.right));
        } else {
          await tester.drag(tabs, const Offset(-1400, 0));
          await tester.pumpAndSettle();
        }
        if (fitsActions) {
          final view = tester.getRect(
            find.byKey(const ValueKey('workbench-view')),
          );
          final optimise = tester.getRect(
            find.byKey(const ValueKey('workbench-optimise')),
          );
          expect(helpButton.right, lessThan(view.left));
          expect(optimise.center.dy, closeTo(helpButton.center.dy, 1));
          await tester.tap(find.byKey(const ValueKey('workbench-optimise')));
          await tester.pumpAndSettle();
        }
        expect(help.hitTestable(), findsOneWidget);
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('help-content')).hitTestable(),
          findsOneWidget,
        );
        expect(find.text('Mods visible: true'), findsNothing);
        expect(tester.takeException(), isNull);
        final mods = find.byKey(const ValueKey('workspace-mods-tab'));
        await tester.ensureVisible(mods);
        await tester.pumpAndSettle();
        await tester.tap(mods);
        await tester.pumpAndSettle();
        expect(find.text('Mods visible: true'), findsOneWidget);
      }
      expect(optimiseCalls, 3);
    },
  );
}
