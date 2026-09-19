import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

void main() {
  test(
    'capability decisions use stable identifiers when display names change',
    () {
      const archive = GameCapability(
        id: GameCapabilityId.archiveInspection,
        revision: 1,
        name: 'Files inside game archives',
        kind: GameCapabilityKind.gameAdapter,
        contexts: [],
        disposition: GameCapabilityDisposition.available,
      );
      const definition = GameDefinitionInfo(
        id: 'skyrim-se-steam',
        revision: 1,
        name: 'Skyrim Special Edition',
        storefront: 'Steam',
        declaredSteamAppId: 489830,
        capabilities: [archive],
      );

      expect(
        definition.unavailable(GameCapabilityId.archiveInspection),
        isFalse,
      );
      expect(
        definition.unavailable(GameCapabilityId.individualSaveEditing),
        isFalse,
      );

      final futureId = GameCapabilityId.fromWire('future-capability');
      expect(futureId.value, 'future-capability');
      expect(definition.unavailable(futureId), isFalse);

      const unavailableArchive = GameDefinitionInfo(
        id: 'skyrim-se-steam',
        revision: 1,
        name: 'Skyrim Special Edition',
        storefront: 'Steam',
        declaredSteamAppId: 489830,
        capabilities: [
          GameCapability(
            id: GameCapabilityId.archiveInspection,
            revision: 2,
            name: 'Another display name',
            kind: GameCapabilityKind.gameAdapter,
            contexts: [],
            disposition: GameCapabilityDisposition.unavailable,
          ),
        ],
      );
      expect(
        unavailableArchive.unavailable(GameCapabilityId.archiveInspection),
        isTrue,
      );
    },
  );
}
