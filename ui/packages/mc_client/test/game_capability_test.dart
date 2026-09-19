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
        kind: GameCapabilityKind.optionalLegacy,
        contexts: [],
        disposition: GameCapabilityDisposition.unavailable,
        reason: 'Not available.',
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
        isTrue,
      );
      expect(
        definition.unavailable(GameCapabilityId.individualSaveEditing),
        isFalse,
      );

      final futureId = GameCapabilityId.fromWire('future-capability');
      expect(futureId.value, 'future-capability');
      expect(definition.unavailable(futureId), isFalse);
    },
  );
}
