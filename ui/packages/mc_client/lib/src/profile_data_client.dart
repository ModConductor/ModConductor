import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'completed_events.dart';
import 'generated/modconductor/v1/profile_data.pbgrpc.dart' as wire;
import 'profile_data_models.dart';
export 'profile_data_models.dart';

abstract interface class ProfileDataClient {
  Future<ProfileDataState> read(String workspaceId, String profileId);
  Stream<ProfileDataEvent> edit(
    String id,
    ProfileDataRef expected,
    ProfileDataOptions options, {
    required InitialProfileSaves initialSaves,
    required DisabledProfileFiles disabledFiles,
  });
  Stream<ProfileDataEvent> restore(String id, ProfileDataRef expected);
  Stream<ProfileDataEvent> resume(String workspaceId, String id);
}

class GrpcProfileDataClient implements ProfileDataClient {
  GrpcProfileDataClient(ClientChannel channel, CallOptions options)
    : _client = wire.ProfileDataOperationsClient(channel, options: options);
  final wire.ProfileDataOperationsClient _client;
  @override
  Future<ProfileDataState> read(String workspaceId, String profileId) async {
    final reply = await _client.readProfileData(
      wire.ProfileDataReadRequest(
        workspaceId: workspaceId,
        profileId: profileId,
      ),
    );
    return switch (reply.whichResult()) {
      wire.ProfileDataReply_Result.state => _state(reply.state),
      wire.ProfileDataReply_Result.problem => throw _problem(reply.problem),
      wire.ProfileDataReply_Result.notSet => throw const FormatException(
        'The profile settings state is missing.',
      ),
    };
  }

  @override
  Stream<ProfileDataEvent> edit(
    String id,
    ProfileDataRef expected,
    ProfileDataOptions options, {
    required InitialProfileSaves initialSaves,
    required DisabledProfileFiles disabledFiles,
  }) => _events(
    _client.editProfileData(
      wire.ProfileDataEditRequest(
        id: id,
        expected: _reference(expected),
        options: wire.ProfileDataOptions(
          settings: options.settings,
          saves: options.saves,
        ),
        initialSaves: switch (initialSaves) {
          InitialProfileSaves.empty =>
            wire.InitialProfileSaves.INITIAL_PROFILE_SAVES_EMPTY,
          InitialProfileSaves.copyGlobal =>
            wire.InitialProfileSaves.INITIAL_PROFILE_SAVES_COPY_GLOBAL,
        },
        disabledFiles: switch (disabledFiles) {
          DisabledProfileFiles.keep =>
            wire.DisabledProfileFiles.DISABLED_PROFILE_FILES_KEEP,
          DisabledProfileFiles.delete =>
            wire.DisabledProfileFiles.DISABLED_PROFILE_FILES_DELETE,
        },
      ),
    ),
  );
  @override
  Stream<ProfileDataEvent> restore(String id, ProfileDataRef expected) =>
      _events(
        _client.restoreProfileData(
          wire.ProfileDataRestoreRequest(
            id: id,
            expected: _reference(expected),
          ),
        ),
      );
  @override
  Stream<ProfileDataEvent> resume(String workspaceId, String id) => _events(
    _client.resumeProfileData(
      wire.ProfileDataActionRequest(workspaceId: workspaceId, id: id),
    ),
  );
}

wire.ProfileDataRef _reference(ProfileDataRef value) => wire.ProfileDataRef(
  workspaceId: value.workspaceId,
  profileId: value.profileId,
  contextId: value.contextId,
  revision: Int64(value.revision),
);

ProfileDataState _state(wire.ProfileDataState value) {
  if (!value.hasReference() || !value.hasOptions()) {
    throw const FormatException('The profile settings state is incomplete.');
  }
  return ProfileDataState(
    reference: ProfileDataRef(
      workspaceId: value.reference.workspaceId,
      profileId: value.reference.profileId,
      contextId: value.reference.contextId,
      revision: value.reference.revision.toInt(),
    ),
    options: ProfileDataOptions(
      settings: value.options.settings,
      saves: value.options.saves,
    ),
    settingsPath: value.settingsPath,
    savesPath: value.savesPath,
    settingsFiles: value.settingsFiles,
    saveFiles: value.saveFiles,
    inUseProfileId: value.hasInUseProfileId() ? value.inUseProfileId : null,
    pendingActionId: value.hasPendingActionId() ? value.pendingActionId : null,
    problem: value.hasProblem() ? value.problem : null,
    pendingProfileChange: value.pendingProfileChange,
  );
}

ProfileDataProblem _problem(wire.ProfileDataProblem value) =>
    ProfileDataProblem(switch (value.kind) {
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_NOT_FOUND =>
        ProfileDataProblemKind.notFound,
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_BUSY =>
        ProfileDataProblemKind.busy,
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_STALE =>
        ProfileDataProblemKind.stale,
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_CANCELLED =>
        ProfileDataProblemKind.cancelled,
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_INVALID =>
        ProfileDataProblemKind.invalid,
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_UNAVAILABLE =>
        ProfileDataProblemKind.unavailable,
      wire.ProfileDataProblemKind.PROFILE_DATA_PROBLEM_CONFLICT =>
        ProfileDataProblemKind.conflict,
      _ => throw const FormatException(
        'The profile settings problem is unsupported.',
      ),
    }, value.detail);
Stream<ProfileDataEvent> _events(Stream<wire.ProfileDataEvent> stream) =>
    completedEvents(
      stream,
      (event) => event.hasResult() || event.hasProblem(),
      (event) => switch (event.whichEvent()) {
        wire.ProfileDataEvent_Event.progress => ProfileDataProgress(
          event.progress.files,
          event.progress.bytes.toInt(),
        ),
        wire.ProfileDataEvent_Event.result => ProfileDataResult(
          id: event.result.id,
          state: _state(event.result.state),
          complete: event.result.complete,
          completedFiles: event.result.completedFiles,
          problem: event.result.hasProblem() ? event.result.problem : null,
        ),
        wire.ProfileDataEvent_Event.problem => throw _problem(event.problem),
        wire.ProfileDataEvent_Event.notSet => throw const FormatException(
          'The profile settings event is missing.',
        ),
      },
    );
