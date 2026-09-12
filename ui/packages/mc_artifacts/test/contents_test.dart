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
}
