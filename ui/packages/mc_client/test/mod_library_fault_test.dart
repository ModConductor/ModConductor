import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_client/src/generated/modconductor/v1/mod_library.pb.dart'
    as wire;
import 'package:mc_client/src/mod_library_wire.dart' as mapping;

void main() {
  test(
    'busy faults retain the existing receipt identity and supported actions',
    () {
      final fault = wire.ModLibraryFault(
        code: wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_BUSY,
        detail: 'A library change is still in progress.',
        activeOperation: wire.ModLibraryOperation(
          operationId: '11111111111111111111111111111111',
          workspaceId: '22222222222222222222222222222222',
          kind:
              wire.ModLibraryOperationKind.MOD_LIBRARY_OPERATION_KIND_DELETION,
          actions: [
            wire.ModLibraryOperationAction.MOD_LIBRARY_OPERATION_ACTION_RESUME,
          ],
        ),
      );

      expect(
        () => mapping.reject(fault),
        throwsA(
          isA<LibraryException>()
              .having(
                (error) => error.activeOperation?.id,
                'operation ID',
                fault.activeOperation.operationId,
              )
              .having(
                (error) => error.activeOperation?.kind,
                'operation type',
                LibraryOperationKind.deletion,
              )
              .having((error) => error.activeOperation?.actions, 'actions', [
                LibraryOperationAction.resume,
              ]),
        ),
      );
    },
  );
}
