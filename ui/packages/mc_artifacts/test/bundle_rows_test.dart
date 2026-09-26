import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_artifacts/src/bundle_rows.dart';

const _draft = InstallationDraft(
  id: 'draft',
  workspaceId: 'workspace',
  revision: 1,
  artifactId: 'archive',
  archiveName: 'Archive',
  manifest: InspectedArchive('', '', [], 0),
  root: [],
  files: [],
  name: 'Mod',
  version: '',
  bytes: 0,
  canInstall: false,
);

BundleItem _item(String id) => BundleItem(
  id: id,
  sourceId: 'archive',
  modId: id,
  name: id,
  order: 0,
  archives: const [
    ['mod.7z'],
  ],
  bytes: 1,
  state: BundleItemState.needsReview,
  incompleteArchive: false,
);

BundlePlan _bundle(List<BundleItem> items) => BundlePlan(
  reference: const BundleReference('workspace', 'bundle', 1),
  artifactId: 'archive',
  archiveName: 'Archive',
  items: items,
  temporaryBytes: 0,
);

void main() {
  test('bundle selection follows the item through reorder and removal', () {
    final rows = BundleRows();
    addTearDown(rows.dispose);
    rows.reconcile(null, _bundle([_item('first'), _item('second')]));
    rows.current = rows.displayed.last;

    rows.reconcile(null, _bundle([_item('second'), _item('first')]));
    expect(rows.current?.id, 'second');
    expect(rows.model.selectedId, 'second');

    rows.reconcile(null, _bundle([_item('first')]));
    expect(rows.current?.id, 'first');
  });

  test('new archive discovery clears the previous folder choices', () {
    final rows = BundleRows();
    addTearDown(rows.dispose);
    const archives = [
      BundleArchive(1, ['first.7z'], 1),
      BundleArchive(2, ['second.7z'], 1),
    ];
    const discovery = BundleDiscovery(_draft, archives);
    rows.reconcile(discovery, null);
    rows.selectArchive(rows.displayed.first, true);

    rows.reconcile(discovery, null);
    expect(rows.selectedArchives, [1]);

    rows.reconcile(BundleDiscovery(_draft, archives), null);
    expect(rows.selectedArchives, isEmpty);
  });
}
