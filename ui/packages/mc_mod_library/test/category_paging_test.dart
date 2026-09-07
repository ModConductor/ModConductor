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
}
