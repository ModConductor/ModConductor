import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_models.dart';
import 'installation_models.dart';
import 'installation_client.dart' show installationDraft;
import 'fomod_models.dart';
import 'generated/modconductor/v1/fomod.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/archive_installation.pb.dart' as installation;
export 'fomod_models.dart';

abstract interface class FomodClient {
  Future<FomodChoices> open(FomodReference reference, String profileId);
  Future<FomodChoices> read(FomodReference reference);
  Future<FomodChoices> choose(
    FomodReference reference,
    int optionId,
    bool selected,
  );
  Future<FomodChoices> next(FomodReference reference);
  Future<FomodChoices> back(FomodReference reference);
  Future<InstallationDraft> manual(FomodReference reference);
  Future<Uint8List> image(FomodReference reference, List<String> path);
}

class GrpcFomodClient implements FomodClient {
  GrpcFomodClient(ClientChannel channel, CallOptions options)
    : _client = wire.FomodInstallationClient(channel, options: options);
  final wire.FomodInstallationClient _client;
  Future<T> _call<T>(Future<T> future) async {
    try {
      return await future;
    } on GrpcError catch (error) {
      throw ArtifactProblem(error.message ?? 'The installer operation failed.');
    }
  }

  installation.InstallationDraftReference _reference(FomodReference value) =>
      installation.InstallationDraftReference(
        workspaceId: value.workspaceId,
        id: value.id,
        revision: Int64(value.revision),
      );
  FomodChoices _choices(wire.FomodChoices value) => FomodChoices(
    reference: FomodReference(
      value.reference.workspaceId,
      value.reference.id,
      value.reference.revision.toInt(),
    ),
    profileId: value.profileId,
    name: value.name,
    stepName: value.stepName,
    stepNumber: value.stepNumber,
    visibleSteps: value.visibleSteps,
    hasStep: value.hasStep,
    canBack: value.canBack,
    reviewReady: value.reviewReady,
    problem: value.hasProblem() ? value.problem : null,
    reviewedDraft: value.hasReviewedDraft()
        ? installationDraft(value.reviewedDraft)
        : null,
    groups: [
      for (final group in value.groups)
        FomodGroup(
          group.name,
          switch (group.kind) {
            wire.FomodGroupKind.FOMOD_GROUP_KIND_ALL => FomodGroupKind.all,
            wire.FomodGroupKind.FOMOD_GROUP_KIND_AT_LEAST_ONE =>
              FomodGroupKind.atLeastOne,
            wire.FomodGroupKind.FOMOD_GROUP_KIND_AT_MOST_ONE =>
              FomodGroupKind.atMostOne,
            wire.FomodGroupKind.FOMOD_GROUP_KIND_EXACTLY_ONE =>
              FomodGroupKind.exactlyOne,
            _ => FomodGroupKind.any,
          },
          [
            for (final option in group.options)
              FomodOption(
                id: option.id,
                name: option.name,
                description: option.description,
                kind: switch (option.kind) {
                  wire.FomodOptionKind.FOMOD_OPTION_KIND_REQUIRED =>
                    FomodOptionKind.required,
                  wire.FomodOptionKind.FOMOD_OPTION_KIND_RECOMMENDED =>
                    FomodOptionKind.recommended,
                  wire.FomodOptionKind.FOMOD_OPTION_KIND_OPTIONAL =>
                    FomodOptionKind.optional,
                  wire.FomodOptionKind.FOMOD_OPTION_KIND_NOT_USABLE =>
                    FomodOptionKind.notUsable,
                  wire.FomodOptionKind.FOMOD_OPTION_KIND_COULD_BE_USABLE =>
                    FomodOptionKind.couldBeUsable,
                  _ => FomodOptionKind.unknown,
                },
                selected: option.selected,
                canChange: option.canChange,
                image: List.unmodifiable(option.image),
                problem: option.hasProblem() ? option.problem : null,
              ),
          ],
        ),
    ],
    files: [
      for (final file in value.files)
        FomodPlannedFile(
          file.index,
          List.unmodifiable(file.destination),
          List.unmodifiable(file.source),
          file.choice,
          file.bytes.toInt(),
          [for (final source in file.replaces) List.unmodifiable(source.path)],
        ),
    ],
  );
  @override
  Future<FomodChoices> open(FomodReference reference, String profileId) async =>
      _choices(
        await _call(
          _client.openChoices(
            wire.OpenFomodChoices(
              draft: _reference(reference),
              profileId: profileId,
            ),
          ),
        ),
      );
  @override
  Future<FomodChoices> read(FomodReference reference) async =>
      _choices(await _call(_client.readChoices(_reference(reference))));
  @override
  Future<FomodChoices> choose(
    FomodReference reference,
    int optionId,
    bool selected,
  ) async => _choices(
    await _call(
      _client.changeChoice(
        wire.FomodChoiceChange(
          draft: _reference(reference),
          optionId: optionId,
          selected: selected,
        ),
      ),
    ),
  );
  @override
  Future<FomodChoices> next(FomodReference reference) async =>
      _choices(await _call(_client.nextStep(_reference(reference))));
  @override
  Future<FomodChoices> back(FomodReference reference) async =>
      _choices(await _call(_client.previousStep(_reference(reference))));
  @override
  Future<InstallationDraft> manual(FomodReference reference) async =>
      installationDraft(
        await _call(_client.useManualLayout(_reference(reference))),
      );
  @override
  Future<Uint8List> image(FomodReference reference, List<String> path) async =>
      Uint8List.fromList(
        (await _call(
          _client.readChoiceImage(
            wire.FomodImageRequest(draft: _reference(reference), path: path),
          ),
        )).content,
      );
}
