import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

List<List<String>> parseQuotedCsv(List<int> bytes) {
  expect(bytes.take(3), isNot([0xef, 0xbb, 0xbf]));
  final text = utf8.decode(bytes);
  expect(text.endsWith('\r\n'), isTrue);
  expect(text.replaceAll('\r\n', '').contains('\n'), isFalse);
  final rows = <List<String>>[];
  var row = <String>[], value = StringBuffer(), quoted = false;
  for (var index = 0; index < text.length; index++) {
    final character = text[index];
    if (quoted) {
      if (character == '"') {
        if (index + 1 < text.length && text[index + 1] == '"') {
          value.write('"');
          index++;
        } else {
          quoted = false;
        }
      } else {
        value.write(character);
      }
    } else if (character == '"' && value.isEmpty) {
      quoted = true;
    } else if (character == ',') {
      row.add(value.toString());
      value = StringBuffer();
    } else if (character == '\r' &&
        index + 1 < text.length &&
        text[index + 1] == '\n') {
      row.add(value.toString());
      rows.add(row);
      row = [];
      value = StringBuffer();
      index++;
    } else {
      fail('The CSV file is not quote-all CSV.');
    }
  }
  expect(quoted, isFalse);
  expect(row, isEmpty);
  return rows;
}

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  test(
    'authenticated export drains profile order and writes portable CSV without changing a refused destination',
    () async {
      final fixture = await Directory.systemTemp.createTemp('mc-export-wire-');
      final state = await Directory('${fixture.path}/state').create();
      final root = await Directory('${fixture.path}/root').create();
      final output = await Directory('${fixture.path}/output').create();
      final child = await NativeChild.start(executable!, state);
      try {
        expect((await child.operations().check()).runtime.nativeAot, isTrue);
        final workspaceId = newOperationId(), profileId = newOperationId();
        await child.workspaces().create(workspaceId, 'Export', root.path);
        final profile = await child.workspaces().createProfile(
          workspaceId,
          0,
          ProfileInfo(profileId, 'Everyday'),
        );
        final library = child.modLibrary();
        final ids = <String>[];
        for (var index = 0; index < 35; index++) {
          final path = 'mod-$index';
          await Directory('${root.path}/$path').create();
          final entry = await library.register(
            workspaceId,
            newOperationId(),
            ModMetadata(
              name: index == 0 ? ' =SUM(A1), Café' : 'Mod $index',
              notes: index == 0 ? 'first\r\nsecond' : '',
              comment: index == 0 ? 'say "yes"' : '',
              source: index == 1 ? '@remote' : 'local',
            ),
            DirectoryMod(index == 34 ? ModKind.unmanaged : ModKind.regular, [
              path,
            ]),
          );
          ids.add(entry.id);
        }
        await library.register(
          workspaceId,
          newOperationId(),
          const ModMetadata(name: 'Needle separator'),
          const SeparatorMod(),
        );

        var page = await child.modOrganization().query(
          profileId,
          const ModQuery(),
        );
        final changed = await child.profileMods().enable(
          profileId,
          page.selectionRevision,
          ids.take(2),
          true,
        );
        page = await child.modOrganization().query(profileId, const ModQuery());
        expect(page.selectionRevision, changed.revision);
        final exports = child.inventoryExports();

        InventoryExportCapture capture(
          InventoryExportScope scope,
          ModQuery query,
          ModQueryPage queryPage, {
          List<String> selected = const [],
          List<InventoryExportField> fields = const [
            InventoryExportField.name,
            InventoryExportField.modId,
          ],
        }) => InventoryExportCapture(
          workspaceId: workspaceId,
          workspaceRevision: profile.workspace.revision,
          profileId: profileId,
          scope: scope,
          selectedModIds: selected,
          query: query,
          queryIdentity: queryPage.queryIdentity,
          catalogueRevision: queryPage.catalogueRevision,
          selectionRevision: queryPage.selectionRevision,
          fields: fields,
        );

        final selected = await exports.prepare(
          capture(
            InventoryExportScope.selected,
            const ModQuery(),
            page,
            selected: [ids[33], ids[0]],
          ),
        );
        expect(selected.rowCount, 2);
        final selectedPath = '${output.path}/selected.csv';
        final selectedDestination = await exports.inspect(
          selected.id,
          selectedPath,
        );
        await exports
            .write(selected.id, selectedDestination.id, replaceExisting: false)
            .drain<void>();
        final selectedRows = parseQuotedCsv(
          await File(selectedPath).readAsBytes(),
        );
        expect(selectedRows.skip(1).map((row) => row[1]), [
          "'=SUM(A1), Café",
          'Mod 33',
        ]);

        final enabled = await exports.prepare(
          capture(InventoryExportScope.enabled, const ModQuery(), page),
        );
        expect(enabled.rowCount, 2);
        await exports.discard(enabled.id);

        const filteredQuery = ModQuery(text: 'Needle');
        final filteredPage = await child.modOrganization().query(
          profileId,
          filteredQuery,
        );
        final filtered = await exports.prepare(
          capture(
            InventoryExportScope.currentQuery,
            filteredQuery,
            filteredPage,
          ),
        );
        expect(filtered.rowCount, 1);
        await exports.discard(filtered.id);

        final all = await exports.prepare(
          capture(
            InventoryExportScope.all,
            const ModQuery(),
            page,
            fields: const [
              InventoryExportField.comment,
              InventoryExportField.source,
              InventoryExportField.notes,
              InventoryExportField.enabled,
              InventoryExportField.priority,
              InventoryExportField.name,
              InventoryExportField.modId,
              InventoryExportField.kind,
            ],
          ),
        );
        expect(all.rowCount, 36);
        final path = '${output.path}/mods.csv';
        final destination = await exports.inspect(all.id, path);
        final events = await exports
            .write(all.id, destination.id, replaceExisting: false)
            .toList();
        expect(
          events.whereType<InventoryExportCompleted>().single.rowCount,
          36,
        );
        final rows = parseQuotedCsv(await File(path).readAsBytes());
        expect(rows.length, 37);
        expect(rows.first, [
          'mod_id',
          'name',
          'kind',
          'priority',
          'enabled',
          'source',
          'notes',
          'comment',
        ]);
        expect(rows[1][1], "'=SUM(A1), Café");
        expect(rows[1][6], 'first\r\nsecond');
        expect(rows[1][7], 'say "yes"');
        expect(rows[2][5], "'@remote");
        final unmanaged = rows.singleWhere((row) => row[1] == 'Mod 34');
        expect(unmanaged[2], 'unmanaged');
        expect(unmanaged[3], isEmpty);
        expect(unmanaged[4], isEmpty);
        expect(
          rows.singleWhere((row) => row[1] == 'Needle separator')[2],
          'separator',
        );

        await File(path).writeAsString('keep');
        final replacement = await exports.prepare(
          capture(
            InventoryExportScope.selected,
            const ModQuery(),
            page,
            selected: [ids[0]],
          ),
        );
        final existing = await exports.inspect(replacement.id, path);
        await expectLater(
          exports.write(replacement.id, existing.id, replaceExisting: false),
          emitsError(
            isA<InventoryExportException>().having(
              (error) => error.fault,
              'fault',
              InventoryExportFault.replacementRequired,
            ),
          ),
        );
        expect(await File(path).readAsString(), 'keep');

        final stale = await exports.prepare(
          capture(
            InventoryExportScope.selected,
            const ModQuery(),
            page,
            selected: [ids[0]],
          ),
        );
        final stalePath = '${output.path}/stale.csv';
        final staleDestination = await exports.inspect(stale.id, stalePath);
        final first = page.entries
            .singleWhere((row) => row.mod.id == ids[0])
            .mod;
        await library.edit(
          first.id,
          first.revision,
          ModMetadata(name: first.metadata.name, notes: 'changed'),
        );
        await expectLater(
          exports.write(stale.id, staleDestination.id, replaceExisting: false),
          emitsError(
            isA<InventoryExportException>().having(
              (error) => error.fault,
              'fault',
              InventoryExportFault.stale,
            ),
          ),
        );
        expect(await File(stalePath).exists(), isFalse);

        await expectLater(
          child
              .inventoryExports(authenticate: false)
              .prepare(
                capture(
                  InventoryExportScope.selected,
                  const ModQuery(),
                  page,
                  selected: [ids[0]],
                ),
              ),
          throwsA(
            isA<GrpcError>().having(
              (error) => error.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
      } finally {
        await child.close();
        await fixture.delete(recursive: true);
      }
    },
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
  );
}
