import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'completed_events.dart';
import 'generated/modconductor/v1/profile_data.pbgrpc.dart' as wire;
import 'file_plan_wire.dart' as file_mapping;
import 'profile_data_models.dart';
export 'profile_data_models.dart';

abstract interface class ProfileDataClient {
  Future<ProfileSaveGroupPage> saveGroups(
    String workspaceId,
    String profileId,
    ProfileSaveSource source, {
    String? after,
  });
  Future<ProfileSaveInspection> inspectSave(
    String workspaceId,
    String profileId,
    ProfileSaveSource source,
    String name, {
    String? headersId,
  });
  Future<ProfileSaveActionPreview> previewSaveAction(
    ProfileDataRef expected,
    ProfileSaveAction action,
    List<String> names,
  );
  Stream<ProfileDataEvent> applySaveAction(
    String id,
    String previewId,
    ProfileDataRef expected,
  );
  Future<ProfileSavePage> saveFiles(
    String workspaceId,
    String profileId,
    List<String> path, {
    String? after,
  });
  Future<ProfileDataState> read(String workspaceId, String profileId);
  Future<List<ProfileConfigurationFile>> configurationFiles(
    ProfileDataRef expected,
  );
  Future<ProfileConfigurationDocument> readConfiguration(
    ProfileDataRef expected,
    String name,
  );
  Stream<ProfileDataEvent> saveConfiguration(
    String id,
    String previewId,
    ProfileDataRef expected,
    String name,
    String content,
  );
  Stream<ProfileDataEvent> restoreConfiguration(
    String workspaceId,
    String actionId,
  );
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
  Future<ProfileSaveGroupPage> saveGroups(
    String workspaceId,
    String profileId,
    ProfileSaveSource source, {
    String? after,
  }) async {
    final reply = await _client.listSaveGroups(
      wire.ProfileSaveGroupRequest(
        workspaceId: workspaceId,
        profileId: profileId,
        source: _saveSource(source),
        after: after,
      ),
    );
    return switch (reply.whichResult()) {
      wire.ProfileSaveGroupReply_Result.page => ProfileSaveGroupPage(
        _readSaveSource(reply.page.source),
        _savePath(reply.page.path),
        [for (final entry in reply.page.entries) _saveGroup(entry)],
        reply.page.hasNext() ? reply.page.next : null,
      ),
      wire.ProfileSaveGroupReply_Result.problem =>
        throw decodeProfileDataProblem(reply.problem),
      wire.ProfileSaveGroupReply_Result.notSet => throw const FormatException(
        'The save group page is missing.',
      ),
    };
  }

  @override
  Future<ProfileSaveInspection> inspectSave(
    String workspaceId,
    String profileId,
    ProfileSaveSource source,
    String name, {
    String? headersId,
  }) async {
    final reply = await _client.inspectSave(
      wire.ProfileSaveInspectRequest(
        workspaceId: workspaceId,
        profileId: profileId,
        source: _saveSource(source),
        name: name,
        headersId: headersId,
      ),
    );
    return switch (reply.whichResult()) {
      wire.ProfileSaveInspectReply_Result.inspection => _saveInspection(
        reply.inspection,
      ),
      wire.ProfileSaveInspectReply_Result.problem =>
        throw decodeProfileDataProblem(reply.problem),
      wire.ProfileSaveInspectReply_Result.notSet => throw const FormatException(
        'The save inspection is missing.',
      ),
    };
  }

  @override
  Future<ProfileSaveActionPreview> previewSaveAction(
    ProfileDataRef expected,
    ProfileSaveAction action,
    List<String> names,
  ) async {
    final reply = await _client.previewSaveAction(
      wire.ProfileSaveActionPreviewRequest(
        expected: _reference(expected),
        action: _saveAction(action),
        names: names,
      ),
    );
    return switch (reply.whichResult()) {
      wire.ProfileSaveActionPreviewReply_Result.preview => _savePreview(
        reply.preview,
      ),
      wire.ProfileSaveActionPreviewReply_Result.problem =>
        throw decodeProfileDataProblem(reply.problem),
      wire.ProfileSaveActionPreviewReply_Result.notSet =>
        throw const FormatException('The save action preview is missing.'),
    };
  }

  @override
  Stream<ProfileDataEvent> applySaveAction(
    String id,
    String previewId,
    ProfileDataRef expected,
  ) => _events(
    _client.applySaveAction(
      wire.ProfileSaveActionApplyRequest(
        id: id,
        previewId: previewId,
        expected: _reference(expected),
      ),
    ),
  );
  @override
  Future<ProfileSavePage> saveFiles(
    String workspaceId,
    String profileId,
    List<String> path, {
    String? after,
  }) async {
    final reply = await _client.listProfileSaves(
      wire.ProfileSaveRequest(
        workspaceId: workspaceId,
        profileId: profileId,
        path: path,
        after: after,
      ),
    );
    return switch (reply.whichResult()) {
      wire.ProfileSaveReply_Result.page => ProfileSavePage([
        for (final entry in reply.page.entries)
          ProfileSaveEntry(entry.name, entry.directory, entry.bytes.toInt()),
      ], reply.page.hasNext() ? reply.page.next : null),
      wire.ProfileSaveReply_Result.problem => throw decodeProfileDataProblem(
        reply.problem,
      ),
      wire.ProfileSaveReply_Result.notSet => throw const FormatException(
        'The save file page is missing.',
      ),
    };
  }

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
      wire.ProfileDataReply_Result.problem => throw decodeProfileDataProblem(
        reply.problem,
      ),
      wire.ProfileDataReply_Result.notSet => throw const FormatException(
        'The profile settings state is missing.',
      ),
    };
  }

  @override
  Future<List<ProfileConfigurationFile>> configurationFiles(
    ProfileDataRef expected,
  ) async {
    final reply = await _client.listProfileConfigurations(
      wire.ProfileConfigurationListRequest(expected: _reference(expected)),
    );
    return switch (reply.whichResult()) {
      wire.ProfileConfigurationListReply_Result.files => List.unmodifiable([
        for (final file in reply.files.files)
          ProfileConfigurationFile(file.name, file.exists, file.bytes.toInt()),
      ]),
      wire.ProfileConfigurationListReply_Result.problem =>
        throw decodeProfileDataProblem(reply.problem),
      wire.ProfileConfigurationListReply_Result.notSet =>
        throw const FormatException('The profile file list is missing.'),
    };
  }

  @override
  Future<ProfileConfigurationDocument> readConfiguration(
    ProfileDataRef expected,
    String name,
  ) async {
    final reply = await _client.readProfileConfiguration(
      wire.ProfileConfigurationReadRequest(
        expected: _reference(expected),
        name: name,
      ),
    );
    return switch (reply.whichResult()) {
      wire.ProfileConfigurationReadReply_Result.document =>
        ProfileConfigurationDocument(
          previewId: reply.document.previewId,
          expected: _readReference(reply.document.expected),
          name: reply.document.name,
          exists: reply.document.exists,
          length: reply.document.length.toInt(),
          sha256: reply.document.hasSha256() ? reply.document.sha256 : null,
          document: file_mapping.textDocument(reply.document.document),
        ),
      wire.ProfileConfigurationReadReply_Result.problem =>
        throw decodeProfileDataProblem(reply.problem),
      wire.ProfileConfigurationReadReply_Result.notSet =>
        throw const FormatException('The profile file is missing.'),
    };
  }

  @override
  Stream<ProfileDataEvent> saveConfiguration(
    String id,
    String previewId,
    ProfileDataRef expected,
    String name,
    String content,
  ) => _events(
    _client.saveProfileConfiguration(
      wire.ProfileConfigurationSaveRequest(
        id: id,
        previewId: previewId,
        expected: _reference(expected),
        name: name,
        content: content,
      ),
    ),
  );

  @override
  Stream<ProfileDataEvent> restoreConfiguration(
    String workspaceId,
    String actionId,
  ) => _events(
    _client.restoreProfileConfiguration(
      wire.ProfileConfigurationRestoreRequest(
        workspaceId: workspaceId,
        actionId: actionId,
      ),
    ),
  );

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

wire.ProfileSaveSource _saveSource(ProfileSaveSource value) => switch (value) {
  ProfileSaveSource.global => wire.ProfileSaveSource.PROFILE_SAVE_SOURCE_GLOBAL,
  ProfileSaveSource.profile =>
    wire.ProfileSaveSource.PROFILE_SAVE_SOURCE_PROFILE,
};

ProfileSaveSource _readSaveSource(wire.ProfileSaveSource value) =>
    switch (value) {
      wire.ProfileSaveSource.PROFILE_SAVE_SOURCE_GLOBAL =>
        ProfileSaveSource.global,
      wire.ProfileSaveSource.PROFILE_SAVE_SOURCE_PROFILE =>
        ProfileSaveSource.profile,
      _ => throw const FormatException('The save source is unsupported.'),
    };

ProfileSavePath _savePath(wire.ProfileSavePath value) => ProfileSavePath(
  value.hostPath,
  value.hasWindowsPath() ? value.windowsPath : null,
);

ProfileSaveGroupEntry _saveGroup(wire.ProfileSaveGroupEntry value) =>
    ProfileSaveGroupEntry(
      id: value.id,
      name: value.name,
      kind: switch (value.kind) {
        wire.ProfileSaveEntryKind.PROFILE_SAVE_ENTRY_KIND_SAVE =>
          ProfileSaveEntryKind.save,
        wire.ProfileSaveEntryKind.PROFILE_SAVE_ENTRY_KIND_DIRECTORY =>
          ProfileSaveEntryKind.directory,
        wire.ProfileSaveEntryKind.PROFILE_SAVE_ENTRY_KIND_OTHER =>
          ProfileSaveEntryKind.other,
        _ => throw const FormatException('The save entry kind is unsupported.'),
      },
      bytes: value.bytes.toInt(),
      companion: value.hasCompanion() ? value.companion : null,
      companionBytes: value.companionBytes.toInt(),
      actionable: value.actionable,
      problem: value.hasProblem() ? value.problem : null,
    );

SkyrimSaveMetadata _saveMetadata(wire.SkyrimSaveMetadata value) =>
    SkyrimSaveMetadata(
      headerVersion: value.headerVersion,
      formVersion: value.formVersion,
      compression: switch (value.compression) {
        wire.SkyrimSaveCompression.SKYRIM_SAVE_COMPRESSION_UNCOMPRESSED =>
          SkyrimSaveCompression.uncompressed,
        wire.SkyrimSaveCompression.SKYRIM_SAVE_COMPRESSION_ZLIB =>
          SkyrimSaveCompression.zlib,
        wire.SkyrimSaveCompression.SKYRIM_SAVE_COMPRESSION_LZ4 =>
          SkyrimSaveCompression.lz4,
        _ => throw const FormatException(
          'The save compression is unsupported.',
        ),
      },
      saveNumber: value.saveNumber,
      character: value.character,
      level: value.level,
      location: value.location,
      gameTime: value.gameTime,
      fullPlugins: List.unmodifiable(value.fullPlugins),
      lightPlugins: List.unmodifiable(value.lightPlugins),
    );

ProfileSaveInspection _saveInspection(wire.ProfileSaveInspection value) {
  if (!value.hasPath() || !value.hasEntry()) {
    throw const FormatException('The save inspection is incomplete.');
  }
  return ProfileSaveInspection(
    source: _readSaveSource(value.source),
    path: _savePath(value.path),
    entry: _saveGroup(value.entry),
    metadata: value.hasMetadata() ? _saveMetadata(value.metadata) : null,
    metadataProblem: value.hasMetadataProblem() ? value.metadataProblem : null,
    pluginIssues: [
      for (final issue in value.pluginIssues)
        SavePluginIssue(issue.name, switch (issue.state) {
          wire.SavePluginState.SAVE_PLUGIN_STATE_MISSING =>
            SavePluginState.missing,
          wire.SavePluginState.SAVE_PLUGIN_STATE_INACTIVE =>
            SavePluginState.inactive,
          _ => throw const FormatException(
            'The save plugin state is unsupported.',
          ),
        }, issue.hasSource() ? issue.source : null),
    ],
    pluginCheckProblem: value.hasPluginCheckProblem()
        ? value.pluginCheckProblem
        : null,
  );
}

wire.ProfileSaveAction _saveAction(ProfileSaveAction value) => switch (value) {
  ProfileSaveAction.copyToProfile =>
    wire.ProfileSaveAction.PROFILE_SAVE_ACTION_COPY_TO_PROFILE,
  ProfileSaveAction.deleteFromProfile =>
    wire.ProfileSaveAction.PROFILE_SAVE_ACTION_DELETE_FROM_PROFILE,
};

ProfileSaveAction _readSaveAction(wire.ProfileSaveAction value) =>
    switch (value) {
      wire.ProfileSaveAction.PROFILE_SAVE_ACTION_COPY_TO_PROFILE =>
        ProfileSaveAction.copyToProfile,
      wire.ProfileSaveAction.PROFILE_SAVE_ACTION_DELETE_FROM_PROFILE =>
        ProfileSaveAction.deleteFromProfile,
      _ => throw const FormatException('The save action is unsupported.'),
    };

ProfileSaveActionPreview _savePreview(wire.ProfileSaveActionPreview value) {
  if (!value.hasExpected() || !value.hasSource()) {
    throw const FormatException('The save action preview is incomplete.');
  }
  return ProfileSaveActionPreview(
    id: value.id,
    expected: _readReference(value.expected),
    action: _readSaveAction(value.action),
    source: _savePath(value.source),
    destination: value.hasDestination() ? _savePath(value.destination) : null,
    files: [
      for (final file in value.files)
        ProfileSaveActionFile(file.name, file.bytes.toInt()),
    ],
    bytes: value.bytes.toInt(),
  );
}

ProfileDataRef _readReference(wire.ProfileDataRef value) => ProfileDataRef(
  workspaceId: value.workspaceId,
  profileId: value.profileId,
  contextId: value.contextId,
  revision: value.revision.toInt(),
);

ProfileDataState _state(wire.ProfileDataState value) {
  if (!value.hasReference() || !value.hasOptions()) {
    throw const FormatException('The profile settings state is incomplete.');
  }
  return ProfileDataState(
    reference: _readReference(value.reference),
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
    settingsInitialized: value.settingsInitialized,
    savesInitialized: value.savesInitialized,
    pendingConfiguration: value.hasPendingConfiguration()
        ? value.pendingConfiguration
        : null,
  );
}

ProfileDataProblem decodeProfileDataProblem(wire.ProfileDataProblem value) =>
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
        wire.ProfileDataEvent_Event.problem => throw decodeProfileDataProblem(
          event.problem,
        ),
        wire.ProfileDataEvent_Event.notSet => throw const FormatException(
          'The profile settings event is missing.',
        ),
      },
    );
