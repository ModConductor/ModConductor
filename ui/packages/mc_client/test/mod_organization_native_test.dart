import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  test(
    'authenticated categories and typed queries preserve canonical references and reject stale drafts',
    () async {
      final fixture = await Directory.systemTemp.createTemp('mc-organization-');
      final state = await Directory('${fixture.path}/state').create(),
          root = await Directory('${fixture.path}/root').create();
      final child = await NativeChild.start(executable!, state);
      try {
        final workspace = newOperationId(), profile = newOperationId();
        await child.workspaces().create(workspace, 'Categories', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final client = child.modOrganization(), library = child.modLibrary();
        final parent = newOperationId(), category = newOperationId();
        final initial = await client.categories(workspace);
        final first = await client.createCategory(
          workspace,
          initial.revision,
          parent,
          'Textures',
        );
        final second = await client.createCategory(
          workspace,
          first,
          category,
          'Stone',
          parentId: parent,
        );
        final branch = await client.categories(
          workspace,
          parentId: parent,
          expectedRevision: second,
        );
        expect(branch.entries.single.id, category);
        expect(branch.ancestors.single.id, parent);
        final separator = await library.register(
          workspace,
          newOperationId(),
          const ModMetadata(name: 'Visuals'),
          const SeparatorMod(),
        );
        await Directory('${root.path}/stone').create();
        final registered = await library.register(
          workspace,
          newOperationId(),
          ModMetadata(
            name: 'Stonework',
            notes: 'coarse grit',
            categories: [CategoryReference(category, 'stale label')],
          ),
          const DirectoryMod(ModKind.regular, ['stone']),
        );
        expect(registered.metadata.categories.single.label, 'Stone');
        expect(registered.metadata.categories.single.missing, isFalse);
        final before = await client.query(profile, const ModQuery());
        final filtered = await client.query(
          profile,
          ModQuery(
            text: ' GRIT ',
            view: OrganizationView.groups,
            filters: [
              CategoryFilter(
                CategoryReference(parent, 'Textures'),
                descendants: true,
              ),
              const EnabledFilter(false),
            ],
          ),
          inspectedId: separator.id,
        );
        expect(filtered.entries.single.mod.id, registered.id);
        expect(filtered.context.single.mod.id, separator.id);
        expect(filtered.matchingMods, 1);
        expect(filtered.matchingSeparators, 0);
        expect(filtered.context.single.groupSize!.matching, 1);
        final renamed = await client.updateCategory(
          workspace,
          filtered.catalogueRevision,
          category,
          'Stone surfaces',
          parentId: parent,
        );
        await expectLater(
          library.edit(registered.id, registered.revision, registered.metadata),
          throwsA(
            isA<LibraryException>().having(
              (error) => error.fault,
              'fault',
              LibraryFault.staleRevision,
            ),
          ),
        );
        await client.deleteCategory(workspace, renamed, category);
        final missing = await client.query(
          profile,
          const ModQuery(filters: [MissingCategoryFilter()]),
        );
        expect(
          missing.entries.single.mod.metadata.categories.single.id,
          category,
        );
        expect(
          missing.entries.single.mod.metadata.categories.single.label,
          'Stone surfaces',
        );
        expect(
          missing.entries.single.mod.metadata.categories.single.missing,
          isTrue,
        );
        expect(missing.selectionRevision, before.selectionRevision);
        final otherWorkspace = newOperationId(),
            foreignCategory = newOperationId();
        final otherRoot = await Directory('${fixture.path}/other-root')
            .create();
        await child.workspaces().create(
          otherWorkspace,
          'Other workspace',
          otherRoot.path,
        );
        final otherRevision = (await client.categories(otherWorkspace))
            .revision;
        await client.createCategory(
          otherWorkspace,
          otherRevision,
          foreignCategory,
          'Stone surfaces',
        );
        final beforeRejectedEdit = missing.entries.single.mod;
        await expectLater(
          library.edit(
            beforeRejectedEdit.id,
            beforeRejectedEdit.revision,
            ModMetadata(
              name: 'Must not overwrite',
              categories: [
                CategoryReference(foreignCategory, 'Stone surfaces'),
              ],
            ),
          ),
          throwsA(
            isA<LibraryException>().having(
              (error) => error.fault,
              'fault',
              LibraryFault.identityConflict,
            ),
          ),
        );
        final afterRejectedEdit = (await client.query(
          profile,
          const ModQuery(),
          inspectedId: beforeRejectedEdit.id,
        )).inspected!.mod;
        expect(afterRejectedEdit.revision, beforeRejectedEdit.revision);
        expect(
          afterRejectedEdit.metadata.name,
          beforeRejectedEdit.metadata.name,
        );
        expect(afterRejectedEdit.metadata.categories.single.id, category);

        await expectLater(
          child
              .modOrganization(authenticate: false)
              .createCategory(
                workspace,
                missing.catalogueRevision,
                newOperationId(),
                'Denied',
              ),
          throwsA(
            isA<GrpcError>().having(
              (error) => error.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        final finalState = await client.query(profile, const ModQuery());
        expect(finalState.catalogueRevision, missing.catalogueRevision);
        expect(finalState.selectionRevision, before.selectionRevision);
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
