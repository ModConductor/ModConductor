import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'completed_events.dart';

import 'generated/modconductor/v1/workspaces.pbgrpc.dart' as wire;

class ProfileInfo {
  const ProfileInfo(this.id, this.name);
  final String id;
  final String name;
}

enum WorkspaceRootIssueReason {
  incompleteCreation,
  ownershipUnproved,
  identityUnverified,
}

class PendingWorkspaceRoot {
  const PendingWorkspaceRoot(this.revision, this.reason);
  final int revision;
  final WorkspaceRootIssueReason reason;
}

class WorkspaceInfo {
  const WorkspaceInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.revision,
    this.selectedProfile,
    this.pendingRoot,
  });
  final String id;
  final String name;
  final String path;
  final int revision;
  final ProfileInfo? selectedProfile;
  final PendingWorkspaceRoot? pendingRoot;
}

class WorkspacePage {
  const WorkspacePage(this.workspace, this.profiles, this.nextProfile);
  final WorkspaceInfo workspace;
  final List<ProfileInfo> profiles;
  final String? nextProfile;
}

class WorkspaceList {
  const WorkspaceList(this.workspaces, this.nextWorkspace);
  final List<WorkspaceInfo> workspaces;
  final String? nextWorkspace;
}

class ProfileChange {
  const ProfileChange(this.workspace, this.changed, this.deleted);
  final WorkspaceInfo workspace;
  final ProfileInfo? changed;
  final String? deleted;
}

enum WorkspaceFault {
  notFound,
  staleRevision,
  identityConflict,
  selectedProfile,
  invalidName,
  invalidRoot,
  unresolved,
  busy,
  profileData,
}

class WorkspaceException implements Exception {
  const WorkspaceException(this.fault, this.detail);
  final WorkspaceFault fault;
  final String detail;
}

abstract interface class WorkspacesClient {
  Future<WorkspacePage> create(String id, String name, [String? path]);
  Future<WorkspacePage> open(String path);
  Future<WorkspacePage> read(String id, {String? after});
  Future<WorkspacePage> check(String id, int receiptRevision);
  Future<WorkspaceList> recent({String? after});
  Future<ProfileChange> createProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  );
  Future<ProfileChange> cloneProfile(
    String workspace,
    int revision,
    String source,
    ProfileInfo copy,
  );
  Future<ProfileChange> renameProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  );
  Future<ProfileChange> selectProfile(
    String workspace,
    int revision,
    String profile,
  );
  Future<ProfileChange> deleteProfile(
    String workspace,
    int revision,
    String profile,
  );
}

ProfileInfo _profile(wire.ProfileInfo value) =>
    ProfileInfo(value.profileId, value.name);
WorkspaceInfo _workspace(wire.WorkspaceInfo value) => WorkspaceInfo(
  id: value.workspaceId,
  name: value.name,
  path: value.path,
  revision: value.revision.toInt(),
  selectedProfile: value.hasSelectedProfile()
      ? _profile(value.selectedProfile)
      : null,
  pendingRoot: value.hasPendingRoot()
      ? PendingWorkspaceRoot(
          value.pendingRoot.receiptRevision.toInt(),
          switch (value.pendingRoot.reason) {
            wire
                .WorkspaceRootIssueReason
                .WORKSPACE_ROOT_ISSUE_REASON_INCOMPLETE_CREATION =>
              WorkspaceRootIssueReason.incompleteCreation,
            wire
                .WorkspaceRootIssueReason
                .WORKSPACE_ROOT_ISSUE_REASON_OWNERSHIP_UNPROVED =>
              WorkspaceRootIssueReason.ownershipUnproved,
            wire
                .WorkspaceRootIssueReason
                .WORKSPACE_ROOT_ISSUE_REASON_IDENTITY_UNVERIFIED =>
              WorkspaceRootIssueReason.identityUnverified,
            _ => throw const FormatException('Invalid workspace root issue.'),
          },
        )
      : null,
);

Never _reject(wire.WorkspaceFault value) =>
    throw WorkspaceException(switch (value.code) {
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_NOT_FOUND =>
        WorkspaceFault.notFound,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_STALE_REVISION =>
        WorkspaceFault.staleRevision,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_IDENTITY_CONFLICT =>
        WorkspaceFault.identityConflict,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_SELECTED_PROFILE =>
        WorkspaceFault.selectedProfile,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_INVALID_NAME =>
        WorkspaceFault.invalidName,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_INVALID_ROOT =>
        WorkspaceFault.invalidRoot,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_ROOT_UNRESOLVED =>
        WorkspaceFault.unresolved,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_BUSY => WorkspaceFault.busy,
      wire.WorkspaceFaultCode.WORKSPACE_FAULT_CODE_PROFILE_DATA =>
        WorkspaceFault.profileData,
      _ => throw const FormatException('Unsupported workspace failure.'),
    }, value.detail);

WorkspacePage _page(wire.WorkspaceReply reply) =>
    switch (reply.whichOutcome()) {
      wire.WorkspaceReply_Outcome.page => WorkspacePage(
        _workspace(reply.page.workspace),
        List.unmodifiable(reply.page.profiles.map(_profile)),
        reply.page.hasNextProfileId() ? reply.page.nextProfileId : null,
      ),
      wire.WorkspaceReply_Outcome.fault => _reject(reply.fault),
      wire.WorkspaceReply_Outcome.notSet => throw const FormatException(
        'Missing workspace result.',
      ),
    };

sealed class ProfileChangeEvent {
  const ProfileChangeEvent();
}

class ProfileCopyProgress extends ProfileChangeEvent {
  const ProfileCopyProgress(this.files, this.bytes);
  final int files, bytes;
}

class ProfileChangeComplete extends ProfileChangeEvent {
  const ProfileChangeComplete(this.change);
  final ProfileChange change;
}

abstract interface class ProfileChangesClient {
  Stream<ProfileChangeEvent> cloneWithProgress(
    String workspace,
    int revision,
    String source,
    ProfileInfo copy,
  );
  Stream<ProfileChangeEvent> deleteWithProgress(
    String workspace,
    int revision,
    String profile,
  );
  Stream<ProfileChangeEvent> resumeProfileEdit(
    String workspace,
    String actionId,
  );
}

abstract interface class ProfileImagesClient {
  Future<String?> readProfileImage(String workspace, String profile);
  Future<void> setProfileImage(
    String workspace,
    String profile,
    String? sourcePath,
  );
}

class GrpcWorkspacesClient
    implements WorkspacesClient, ProfileChangesClient, ProfileImagesClient {
  GrpcWorkspacesClient(ClientChannel channel, CallOptions options)
    : _wire = wire.WorkspaceOperationsClient(channel, options: options),
      _profileWire = wire.WorkspaceOperationsClient(
        channel,
        options: CallOptions(metadata: options.metadata),
      );
  final wire.WorkspaceOperationsClient _wire, _profileWire;

  @override
  Future<String?> readProfileImage(String workspace, String profile) async {
    final result = await _wire.readProfileImage(
      wire.ReadProfileImageRequest(workspaceId: workspace, profileId: profile),
    );
    return switch (result.whichOutcome()) {
      wire.ProfileImageReply_Outcome.path => result.path,
      wire.ProfileImageReply_Outcome.noImage => null,
      wire.ProfileImageReply_Outcome.fault => _reject(result.fault),
      wire.ProfileImageReply_Outcome.notSet => throw const FormatException(
        'Missing profile image result.',
      ),
    };
  }

  @override
  Future<void> setProfileImage(
    String workspace,
    String profile,
    String? sourcePath,
  ) async {
    final request = wire.SetProfileImageRequest(
      workspaceId: workspace,
      profileId: profile,
    );
    if (sourcePath == null) {
      request.clear_4 = true;
    } else {
      request.sourcePath = sourcePath;
    }
    final result = await _profileWire.setProfileImage(request);
    switch (result.whichOutcome()) {
      case wire.ProfileImageUpdateReply_Outcome.saved:
        return;
      case wire.ProfileImageUpdateReply_Outcome.fault:
        _reject(result.fault);
      case wire.ProfileImageUpdateReply_Outcome.notSet:
        throw const FormatException('Missing profile image result.');
    }
  }

  @override
  Future<WorkspacePage> create(String id, String name, [String? path]) async =>
      _page(
        await _wire.createWorkspace(
          wire.CreateWorkspaceRequest(
            workspaceId: id,
            name: name,
            path: path,
            expectedRevision: Int64.ZERO,
          ),
        ),
      );
  @override
  Future<WorkspacePage> open(String path) async =>
      _page(await _wire.openWorkspace(wire.OpenWorkspaceRequest(path: path)));
  @override
  Future<WorkspacePage> read(String id, {String? after}) async => _page(
    await _wire.readWorkspace(
      wire.ReadWorkspaceRequest(workspaceId: id, afterProfileId: after),
    ),
  );
  @override
  Future<WorkspacePage> check(String id, int receiptRevision) async => _page(
    await _wire.checkWorkspace(
      wire.CheckWorkspaceRequest(
        workspaceId: id,
        expectedReceiptRevision: Int64(receiptRevision),
      ),
    ),
  );
  @override
  Future<WorkspaceList> recent({String? after}) async {
    final result = await _wire.recentWorkspaces(
      wire.RecentWorkspacesRequest(afterWorkspaceId: after),
    );
    return WorkspaceList(
      List.unmodifiable(result.workspaces.map(_workspace)),
      result.hasNextWorkspaceId() ? result.nextWorkspaceId : null,
    );
  }

  wire.ProfileInfo _value(ProfileInfo profile) =>
      wire.ProfileInfo(profileId: profile.id, name: profile.name);
  Future<ProfileChange> _edit(wire.EditProfileRequest request) async {
    return _profileReply(await _profileWire.editProfile(request));
  }

  ProfileChange _profileReply(wire.ProfileReply reply) => switch (reply
      .whichOutcome()) {
    wire.ProfileReply_Outcome.fault => _reject(reply.fault),
    wire.ProfileReply_Outcome.notSet => throw const FormatException(
      'Missing profile result.',
    ),
    wire.ProfileReply_Outcome.change => ProfileChange(
      _workspace(reply.change.workspace),
      reply.change.hasChanged() ? _profile(reply.change.changed) : null,
      reply.change.hasDeletedProfileId() ? reply.change.deletedProfileId : null,
    ),
  };

  Stream<ProfileChangeEvent> _profileEvents(
    Stream<wire.ProfileEditEvent> source,
  ) => completedEvents(
    source,
    (event) => event.hasFinished(),
    (event) => switch (event.whichEvent()) {
      wire.ProfileEditEvent_Event.progress => ProfileCopyProgress(
        event.progress.files,
        event.progress.bytes.toInt(),
      ),
      wire.ProfileEditEvent_Event.finished => ProfileChangeComplete(
        _profileReply(event.finished),
      ),
      wire.ProfileEditEvent_Event.notSet => throw const FormatException(
        'The profile change event is missing.',
      ),
    },
  );

  @override
  Stream<ProfileChangeEvent> cloneWithProgress(
    String workspace,
    int revision,
    String source,
    ProfileInfo copy,
  ) => _profileEvents(
    _profileWire.editProfileWithProgress(
      wire.EditProfileRequest(
        workspaceId: workspace,
        expectedRevision: Int64(revision),
        cloneProfile: wire.CloneProfile(
          sourceProfileId: source,
          copy: _value(copy),
        ),
      ),
    ),
  );
  @override
  Stream<ProfileChangeEvent> deleteWithProgress(
    String workspace,
    int revision,
    String profile,
  ) => _profileEvents(
    _profileWire.editProfileWithProgress(
      wire.EditProfileRequest(
        workspaceId: workspace,
        expectedRevision: Int64(revision),
        deleteProfileId: profile,
      ),
    ),
  );
  @override
  Stream<ProfileChangeEvent> resumeProfileEdit(
    String workspace,
    String actionId,
  ) => _profileEvents(
    _profileWire.resumeProfileEdit(
      wire.ResumeProfileEditRequest(workspaceId: workspace, actionId: actionId),
    ),
  );

  @override
  Future<ProfileChange> createProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  ) => _edit(
    wire.EditProfileRequest(
      workspaceId: workspace,
      expectedRevision: Int64(revision),
      createProfile: _value(profile),
    ),
  );
  @override
  Future<ProfileChange> cloneProfile(
    String workspace,
    int revision,
    String source,
    ProfileInfo copy,
  ) => _edit(
    wire.EditProfileRequest(
      workspaceId: workspace,
      expectedRevision: Int64(revision),
      cloneProfile: wire.CloneProfile(
        sourceProfileId: source,
        copy: _value(copy),
      ),
    ),
  );
  @override
  Future<ProfileChange> renameProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  ) => _edit(
    wire.EditProfileRequest(
      workspaceId: workspace,
      expectedRevision: Int64(revision),
      renameProfile: _value(profile),
    ),
  );
  @override
  Future<ProfileChange> selectProfile(
    String workspace,
    int revision,
    String profile,
  ) => _edit(
    wire.EditProfileRequest(
      workspaceId: workspace,
      expectedRevision: Int64(revision),
      selectProfileId: profile,
    ),
  );
  @override
  Future<ProfileChange> deleteProfile(
    String workspace,
    int revision,
    String profile,
  ) => _edit(
    wire.EditProfileRequest(
      workspaceId: workspace,
      expectedRevision: Int64(revision),
      deleteProfileId: profile,
    ),
  );
}
