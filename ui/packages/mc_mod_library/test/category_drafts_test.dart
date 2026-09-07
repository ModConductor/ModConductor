import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/src/mod_dialog.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class CategoriesClient extends Fake implements ModOrganizationClient {
  @override
  Future<CategoriesPage> categories(
    String workspaceId, {
    String? parentId,
    String? afterId,
    int? expectedRevision,
  }) async => const CategoriesPage(
    1,
    [ModCategory('known', 'workspace', null, 'Known', false, 0, false)],
    [],
    null,
  );
}

void main() {
  testWidgets(
    'category chooser applies only to the outer draft and preserves missing references until explicit removal',
    (tester) async {
      final client = CategoriesClient();
      ModDetails? saved;
      final launchFocus = FocusNode();
      addTearDown(launchFocus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                focusNode: launchFocus,
                onPressed: () async {
                  launchFocus.requestFocus();
                  saved = await showDialog<ModDetails>(
                    context: context,
                    builder: (_) => ModDialog(
                      original: const ModMetadata(
                        name: 'Mod',
                        categories: [
                          CategoryReference('missing', 'Legacy', missing: true),
                        ],
                      ),
                      organization: client,
                      workspaceId: 'workspace',
                      initialPath: '/workspace',
                      chooseDirectory: (_) async => null,
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      Future<void> openChoose() async {
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Categories'));
        await tester.pumpAndSettle();
        final known = find.byKey(const ValueKey('known'));
        await tester.tap(
          find.descendant(of: known, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('submit')).last);
        await tester.pumpAndSettle();
      }

      await openChoose();
      expect(saved, isNull);
      await tester.tap(find.widgetWithText(McAction, 'Cancel').last);
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(launchFocus.hasFocus, isTrue);
      await openChoose();
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(
        saved!.metadata.categories.map((value) => value.id),
        unorderedEquals(['missing', 'known']),
      );
      expect(
        saved!.metadata.categories
            .singleWhere((value) => value.id == 'missing')
            .missing,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
