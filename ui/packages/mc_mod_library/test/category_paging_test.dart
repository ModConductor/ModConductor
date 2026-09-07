import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/src/category_controller.dart';

class PagedCategories extends Fake implements ModOrganizationClient {
  final requests = <({String? parent, String? after, int? revision})>[];
  final replies = <Completer<CategoriesPage>>[];
  @override
  Future<CategoriesPage> categories(
    String workspaceId, {
    String? parentId,
    String? afterId,
    int? expectedRevision,
  }) {
    requests.add((
      parent: parentId,
      after: afterId,
      revision: expectedRevision,
    ));
    final reply = Completer<CategoriesPage>();
    replies.add(reply);
    return reply.future;
  }
}

void main() {
  test('failed category pages retry their cursor without losing the assignment draft', () async {
    final client = PagedCategories();
    final controller = CategoryController(
      client,
      'workspace',
      initial: const [
        CategoryReference('missing', 'Old category', missing: true),
      ],
      multiple: true,
    );
    addTearDown(controller.dispose);
    client.replies.first.completeError(Exception('connection lost'));
    await Future<void>.delayed(Duration.zero);
    final firstRetry = controller.more();
    client.replies.last.complete(
      const CategoriesPage(
        7,
        [ModCategory('a', 'workspace', null, 'Alpha', false, 0, false)],
        [],
        'a',
      ),
    );
    await firstRetry;
    controller.model.select('a', toggle: true);
    final continuation = controller.more();
    client.replies.last.completeError(Exception('connection lost'));
    await continuation;
    final retry = controller.more();
    expect(client.requests.last, (parent: null, after: 'a', revision: 7));
    client.replies.last.complete(
      const CategoriesPage(
        7,
        [ModCategory('b', 'workspace', null, 'Beta', false, 0, false)],
        [],
        null,
      ),
    );
    await retry;
    expect(
      controller.selected.map((row) => row.id),
      unorderedEquals(['missing', 'a']),
    );
    expect(controller.model['b']?.id, 'b');
    expect(controller.problem, isNull);
    expect(controller.canLoad, isFalse);
  });
  test('nested initial selection loads the first page of its expanded ancestors without expanding siblings', () async {
    final client = PagedCategories();
    final controller = CategoryController(
      client,
      'workspace',
      initial: const [
        CategoryReference('b', 'Birch'),
        CategoryReference('e', 'Elm'),
      ],
      multiple: true,
    );
    addTearDown(controller.dispose);
    const a = ModCategory('a', 'workspace', null, 'Trees', false, 0, true);
    const b = ModCategory('b', 'workspace', 'a', 'Birch', false, 0, false);
    const c = ModCategory('c', 'workspace', 'a', 'Cedar', false, 0, true);
    const d = ModCategory('d', 'workspace', null, 'Woods', false, 0, true);
    const e = ModCategory('e', 'workspace', 'd', 'Elm', false, 0, false);
    const f = ModCategory('f', 'workspace', 'd', 'Fir', false, 0, false);
    client.replies.first.complete(const CategoriesPage(7, [a, d], [], null));
    await Future<void>.delayed(Duration.zero);
    expect(client.requests.last.parent, 'b');
    client.replies.last.completeError(Exception('child page unavailable'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.problem, isNotNull);
    final retry = controller.more();
    expect(client.requests.last.parent, 'b');
    client.replies.last.complete(const CategoriesPage(7, [], [a, b], null));
    await retry;
    await Future<void>.delayed(Duration.zero);
    expect(client.requests.last.parent, 'e');
    client.replies.last.complete(const CategoriesPage(7, [], [d, e], null));
    await Future<void>.delayed(Duration.zero);
    expect(client.requests.last.parent, 'a');
    client.replies.last.complete(const CategoriesPage(7, [b, c], [a], 'c'));
    await Future<void>.delayed(Duration.zero);
    expect(client.requests.last.parent, 'd');
    client.replies.last.complete(const CategoriesPage(7, [e, f], [d], null));
    await Future<void>.delayed(Duration.zero);
    expect(controller.model.expanded('a'), isTrue);
    expect(controller.model.expanded('d'), isTrue);
    expect(controller.model.visible, ['a', 'b', 'c', 'd', 'e', 'f']);
    expect(
      controller.selected.map((row) => row.id),
      unorderedEquals(['b', 'e']),
    );
    expect(controller.canLoad, isTrue);
    expect(client.requests.where((request) => request.parent == 'c'), isEmpty);
  });
}
