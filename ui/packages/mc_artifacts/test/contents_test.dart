import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/src/contents_view.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class _Client extends Fake implements ArtifactsClient {
  final reads = <Completer<InspectedArchive>>[];
  final cancelled = <int>[];
  @override
  @override
  FilePreviewRead previewEntry(
    Artifact expected,
    InspectedArchive manifest,
    InspectedEntry entry,
    FilePreviewRepresentation representation,
  ) {
    final source = QualifiedArchiveEntryPreviewSource(
      workspaceId: expected.workspaceId,
      artifactId: expected.id,
      artifactRevision: expected.revision,
      archiveSha256: manifest.sha256,
      format: manifest.format,
      index: entry.index,
      sourcePath: entry.components,
      length: entry.size,
    );
    return FilePreviewRead(
      Future.value(
        FilePreviewResult(
          source: source,
          standing: FileSourceStanding.selected,
          target: source.target,
          status: FilePreviewStatus.ready,
          content: const FilePreviewText(
            '<script>inert()</script>',
            'UTF-8',
            1,
          ),
        ),
      ),
      () async {},
    );
  }

  @override
  ArchiveRead readContents(Artifact expected) {
    final index = reads.length;
    final result = Completer<InspectedArchive>();
    reads.add(result);
    return ArchiveRead(result.future, () async {
      cancelled.add(index);
    });
  }
}

class _Artifact extends Fake implements Artifact {
  @override
  String get originalName => 'fixture.zip';
  @override
  String get workspaceId => 'workspace';
  @override
  String get id => 'archive';
  @override
  int get revision => 1;
}

InspectedArchive manifest(String path) => InspectedArchive('digest', 'ZIP', [
  InspectedEntry(0, [path], false, 12, 10),
], 12);

void main() {
  testWidgets('cancelled contents cannot replace a newer read', (tester) async {
    final client = _Client();
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: ArchiveContentsView(
          artifact: _Artifact(),
          client: client,
          onBack: () {},
        ),
      ),
    );
    McCollection collection() => tester.widget<McCollection>(
      find.byWidgetPredicate((w) => w is McCollection),
    );
    collection().onCancel!();
    await tester.pump();
    expect(client.cancelled, [0]);
    collection().onRefresh!();
    await tester.pump();
    client.reads[1].complete(manifest('current.txt'));
    await tester.pumpAndSettle();
    client.reads[0].complete(manifest('old.txt'));
    await tester.pumpAndSettle();
    expect(collection().model.ids.toList(), ['current.txt']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'archive entries reuse the source inspector and render markup only as selectable text',
    (tester) async {
      final client = _Client();
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: SizedBox(
            width: 1400,
            child: ArchiveContentsView(
              artifact: _Artifact(),
              client: client,
              onBack: () {},
            ),
          ),
        ),
      );
      client.reads.single.complete(manifest('page.html'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('page.html'));
      await tester.pumpAndSettle();
      expect(find.text('File sources'), findsOneWidget);
      await tester.tap(find.text('File details'));
      await tester.pumpAndSettle();
      expect(find.text('ZIP archive entry'), findsOneWidget);
      expect(find.text('<script>inert()</script>'), findsOneWidget);
      expect(find.textContaining('qualified reader revision'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'closing the narrow archive inspector restores collection focus',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 781));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _Client();
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: ArchiveContentsView(
            artifact: _Artifact(),
            client: client,
            onBack: () {},
          ),
        ),
      );
      client.reads.single.complete(manifest('notes.txt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('notes.txt'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold)).isEndDrawerOpen,
        isTrue,
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).closeEndDrawer();
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Archive contents',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
