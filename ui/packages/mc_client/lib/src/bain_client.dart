import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_models.dart';
import 'installation_models.dart';
import 'installation_client.dart' show installationDraft;
import 'installation_review_client.dart';
import 'bain_models.dart';
import 'generated/modconductor/v1/bain.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/archive_installation.pb.dart' as installation;
export 'bain_models.dart';

abstract interface class BainClient {
  Future<BainChoices> open(InstallationDraftReference reference);
  Future<BainChoices> choose(
    InstallationDraftReference reference,
    int index,
    bool selected,
  );
  Future<BainChoices> chooseAll(
    InstallationDraftReference reference,
    bool selected,
  );
  Future<BainChoices> include(
    InstallationDraftReference reference,
    List<String> path,
    bool included,
  );
  Future<BainChoices> review(InstallationDraftReference reference);
  Future<BainChoices> back(InstallationDraftReference reference);
  Future<List<InstallationReviewedFile>> folder(
    InstallationDraftReference reference,
    int index,
  );
  Future<String> notes(InstallationDraftReference reference);
  Future<InstallationDraft> useInstaller(
    InstallationDraftReference reference,
    InstallationMode mode,
  );
}

class GrpcBainClient implements BainClient {
  GrpcBainClient(ClientChannel channel, CallOptions options)
    : _client = wire.BainInstallationClient(channel, options: options);
  final wire.BainInstallationClient _client;
  Future<T> _call<T>(Future<T> future) async {
    try {
      return await future;
    } on GrpcError catch (error) {
      throw ArtifactProblem(error.message ?? 'The package operation failed.');
    }
  }

  installation.InstallationDraftReference _reference(
    InstallationDraftReference value,
  ) => installation.InstallationDraftReference(
    workspaceId: value.workspaceId,
    id: value.id,
    revision: Int64(value.revision),
  );
  BainChoices _choices(wire.BainChoices value) => BainChoices(
    reference: InstallationDraftReference(
      value.reference.workspaceId,
      value.reference.id,
      value.reference.revision.toInt(),
    ),
    packages: [
      for (final p in value.packages)
        BainPackage(p.index, p.name, p.files, p.bytes.toInt(), p.selected),
    ],
    files: [
      for (final f in value.files) reviewedFile(f.file, included: f.included),
    ],
    reviewing: value.reviewing,
    hasNotes: value.hasNotes,
    problem: value.hasProblem() ? value.problem : null,
    reviewedDraft: value.hasReviewedDraft()
        ? installationDraft(value.reviewedDraft)
        : null,
  );
  @override
  Future<BainChoices> open(InstallationDraftReference reference) async =>
      _choices(await _call(_client.openPackageChoices(_reference(reference))));
  @override
  Future<BainChoices> choose(
    InstallationDraftReference reference,
    int index,
    bool selected,
  ) async => _choices(
    await _call(
      _client.selectPackageFolder(
        wire.BainFolderSelection(
          reference: _reference(reference),
          index: index,
          selected: selected,
        ),
      ),
    ),
  );
  @override
  Future<BainChoices> chooseAll(
    InstallationDraftReference reference,
    bool selected,
  ) async => _choices(
    await _call(
      _client.selectAllPackageFolders(
        wire.BainAllFoldersSelection(
          reference: _reference(reference),
          selected: selected,
        ),
      ),
    ),
  );
  @override
  Future<BainChoices> include(
    InstallationDraftReference reference,
    List<String> path,
    bool included,
  ) async => _choices(
    await _call(
      _client.includePackageFile(
        wire.BainFileSelection(
          reference: _reference(reference),
          path: path,
          included: included,
        ),
      ),
    ),
  );
  @override
  Future<BainChoices> review(InstallationDraftReference reference) async =>
      _choices(await _call(_client.reviewPackageFiles(_reference(reference))));
  @override
  Future<BainChoices> back(InstallationDraftReference reference) async =>
      _choices(
        await _call(_client.backToPackageFolders(_reference(reference))),
      );
  @override
  Future<List<InstallationReviewedFile>> folder(
    InstallationDraftReference reference,
    int index,
  ) async => [
    for (final f in (await _call(
      _client.readPackageFolder(
        wire.BainFolderReference(
          reference: _reference(reference),
          index: index,
        ),
      ),
    )).files)
      reviewedFile(f),
  ];
  @override
  Future<String> notes(InstallationDraftReference reference) async =>
      (await _call(_client.readPackageNotes(_reference(reference)))).text;
  @override
  Future<InstallationDraft> useInstaller(
    InstallationDraftReference reference,
    InstallationMode mode,
  ) async => installationDraft(
    await _call(
      _client.selectArchiveInstaller(
        wire.ArchiveInstallerChange(
          reference: _reference(reference),
          installer: switch (mode) {
            InstallationMode.manual =>
              installation.ArchiveInstaller.ARCHIVE_INSTALLER_MANUAL,
            InstallationMode.fomod =>
              installation.ArchiveInstaller.ARCHIVE_INSTALLER_FOMOD,
            InstallationMode.bain =>
              installation.ArchiveInstaller.ARCHIVE_INSTALLER_BAIN,
          },
        ),
      ),
    ),
  );
}
