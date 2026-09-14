// This is a generated file - do not edit.
//
// Generated from modconductor/v1/executables.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use executableRunPhaseDescriptor instead')
const ExecutableRunPhase$json = {
  '1': 'ExecutableRunPhase',
  '2': [
    {'1': 'EXECUTABLE_RUN_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'EXECUTABLE_RUN_PHASE_STARTING', '2': 1},
    {'1': 'EXECUTABLE_RUN_PHASE_RUNNING', '2': 2},
    {'1': 'EXECUTABLE_RUN_PHASE_WAITING_FOR_CHILDREN', '2': 3},
    {'1': 'EXECUTABLE_RUN_PHASE_FINISHED', '2': 4},
    {'1': 'EXECUTABLE_RUN_PHASE_FAILED', '2': 5},
    {'1': 'EXECUTABLE_RUN_PHASE_DETACHED', '2': 6},
    {'1': 'EXECUTABLE_RUN_PHASE_TRACKING_UNAVAILABLE', '2': 7},
    {'1': 'EXECUTABLE_RUN_PHASE_CANCELLED', '2': 8},
  ],
};

/// Descriptor for `ExecutableRunPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List executableRunPhaseDescriptor = $convert.base64Decode(
    'ChJFeGVjdXRhYmxlUnVuUGhhc2USJAogRVhFQ1VUQUJMRV9SVU5fUEhBU0VfVU5TUEVDSUZJRU'
    'QQABIhCh1FWEVDVVRBQkxFX1JVTl9QSEFTRV9TVEFSVElORxABEiAKHEVYRUNVVEFCTEVfUlVO'
    'X1BIQVNFX1JVTk5JTkcQAhItCilFWEVDVVRBQkxFX1JVTl9QSEFTRV9XQUlUSU5HX0ZPUl9DSE'
    'lMRFJFThADEiEKHUVYRUNVVEFCTEVfUlVOX1BIQVNFX0ZJTklTSEVEEAQSHwobRVhFQ1VUQUJM'
    'RV9SVU5fUEhBU0VfRkFJTEVEEAUSIQodRVhFQ1VUQUJMRV9SVU5fUEhBU0VfREVUQUNIRUQQBh'
    'ItCilFWEVDVVRBQkxFX1JVTl9QSEFTRV9UUkFDS0lOR19VTkFWQUlMQUJMRRAHEiIKHkVYRUNV'
    'VEFCTEVfUlVOX1BIQVNFX0NBTkNFTExFRBAI');

@$core.Deprecated('Use executableProblemCodeDescriptor instead')
const ExecutableProblemCode$json = {
  '1': 'ExecutableProblemCode',
  '2': [
    {'1': 'EXECUTABLE_PROBLEM_CODE_UNSPECIFIED', '2': 0},
    {'1': 'EXECUTABLE_PROBLEM_CODE_NOT_FOUND', '2': 1},
    {'1': 'EXECUTABLE_PROBLEM_CODE_STALE_REVISION', '2': 2},
    {'1': 'EXECUTABLE_PROBLEM_CODE_IDENTITY_CONFLICT', '2': 3},
    {'1': 'EXECUTABLE_PROBLEM_CODE_CAPACITY', '2': 4},
    {'1': 'EXECUTABLE_PROBLEM_CODE_INVALID', '2': 5},
    {'1': 'EXECUTABLE_PROBLEM_CODE_UNAVAILABLE', '2': 6},
  ],
};

/// Descriptor for `ExecutableProblemCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List executableProblemCodeDescriptor = $convert.base64Decode(
    'ChVFeGVjdXRhYmxlUHJvYmxlbUNvZGUSJwojRVhFQ1VUQUJMRV9QUk9CTEVNX0NPREVfVU5TUE'
    'VDSUZJRUQQABIlCiFFWEVDVVRBQkxFX1BST0JMRU1fQ09ERV9OT1RfRk9VTkQQARIqCiZFWEVD'
    'VVRBQkxFX1BST0JMRU1fQ09ERV9TVEFMRV9SRVZJU0lPThACEi0KKUVYRUNVVEFCTEVfUFJPQk'
    'xFTV9DT0RFX0lERU5USVRZX0NPTkZMSUNUEAMSJAogRVhFQ1VUQUJMRV9QUk9CTEVNX0NPREVf'
    'Q0FQQUNJVFkQBBIjCh9FWEVDVVRBQkxFX1BST0JMRU1fQ09ERV9JTlZBTElEEAUSJwojRVhFQ1'
    'VUQUJMRV9QUk9CTEVNX0NPREVfVU5BVkFJTEFCTEUQBg==');

@$core.Deprecated('Use gamePreparationPhaseDescriptor instead')
const GamePreparationPhase$json = {
  '1': 'GamePreparationPhase',
  '2': [
    {'1': 'GAME_PREPARATION_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'GAME_PREPARATION_PHASE_PREPARING', '2': 1},
    {'1': 'GAME_PREPARATION_PHASE_APPLYING', '2': 2},
    {'1': 'GAME_PREPARATION_PHASE_READY', '2': 3},
    {'1': 'GAME_PREPARATION_PHASE_PROFILE_DATA', '2': 4},
  ],
};

/// Descriptor for `GamePreparationPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gamePreparationPhaseDescriptor = $convert.base64Decode(
    'ChRHYW1lUHJlcGFyYXRpb25QaGFzZRImCiJHQU1FX1BSRVBBUkFUSU9OX1BIQVNFX1VOU1BFQ0'
    'lGSUVEEAASJAogR0FNRV9QUkVQQVJBVElPTl9QSEFTRV9QUkVQQVJJTkcQARIjCh9HQU1FX1BS'
    'RVBBUkFUSU9OX1BIQVNFX0FQUExZSU5HEAISIAocR0FNRV9QUkVQQVJBVElPTl9QSEFTRV9SRU'
    'FEWRADEicKI0dBTUVfUFJFUEFSQVRJT05fUEhBU0VfUFJPRklMRV9EQVRBEAQ=');

@$core.Deprecated('Use executableEnvironmentSettingDescriptor instead')
const ExecutableEnvironmentSetting$json = {
  '1': 'ExecutableEnvironmentSetting',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'value', '17': true},
  ],
  '8': [
    {'1': '_value'},
  ],
};

/// Descriptor for `ExecutableEnvironmentSetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableEnvironmentSettingDescriptor =
    $convert.base64Decode(
        'ChxFeGVjdXRhYmxlRW52aXJvbm1lbnRTZXR0aW5nEhIKBG5hbWUYASABKAlSBG5hbWUSGQoFdm'
        'FsdWUYAiABKAlIAFIFdmFsdWWIAQFCCAoGX3ZhbHVl');

@$core.Deprecated('Use executablePresetDescriptor instead')
const ExecutablePreset$json = {
  '1': 'ExecutablePreset',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'executable', '3': 5, '4': 1, '5': 9, '10': 'executable'},
    {
      '1': 'working_directory',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'workingDirectory'
    },
    {'1': 'arguments', '3': 7, '4': 3, '5': 9, '10': 'arguments'},
    {
      '1': 'environment',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ExecutableEnvironmentSetting',
      '10': 'environment'
    },
  ],
};

/// Descriptor for `ExecutablePreset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executablePresetDescriptor = $convert.base64Decode(
    'ChBFeGVjdXRhYmxlUHJlc2V0Eg4KAmlkGAEgASgJUgJpZBIhCgx3b3Jrc3BhY2VfaWQYAiABKA'
    'lSC3dvcmtzcGFjZUlkEhoKCHJldmlzaW9uGAMgASgEUghyZXZpc2lvbhISCgRuYW1lGAQgASgJ'
    'UgRuYW1lEh4KCmV4ZWN1dGFibGUYBSABKAlSCmV4ZWN1dGFibGUSKwoRd29ya2luZ19kaXJlY3'
    'RvcnkYBiABKAlSEHdvcmtpbmdEaXJlY3RvcnkSHAoJYXJndW1lbnRzGAcgAygJUglhcmd1bWVu'
    'dHMSTwoLZW52aXJvbm1lbnQYCCADKAsyLS5tb2Rjb25kdWN0b3IudjEuRXhlY3V0YWJsZUVudm'
    'lyb25tZW50U2V0dGluZ1ILZW52aXJvbm1lbnQ=');

@$core.Deprecated('Use executablePageRequestDescriptor instead')
const ExecutablePageRequest$json = {
  '1': 'ExecutablePageRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'after_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'afterId',
      '17': true
    },
  ],
  '8': [
    {'1': '_after_id'},
  ],
};

/// Descriptor for `ExecutablePageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executablePageRequestDescriptor = $convert.base64Decode(
    'ChVFeGVjdXRhYmxlUGFnZVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBIeCghhZnRlcl9pZBgCIAEoCUgAUgdhZnRlcklkiAEBQgsKCV9hZnRlcl9pZA==');

@$core.Deprecated('Use executablePresetRefDescriptor instead')
const ExecutablePresetRef$json = {
  '1': 'ExecutablePresetRef',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ExecutablePresetRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executablePresetRefDescriptor = $convert.base64Decode(
    'ChNFeGVjdXRhYmxlUHJlc2V0UmVmEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSW'
    'QSDgoCaWQYAiABKAlSAmlk');

@$core.Deprecated('Use deleteExecutablePresetRequestDescriptor instead')
const DeleteExecutablePresetRequest$json = {
  '1': 'DeleteExecutablePresetRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'expected_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
  ],
};

/// Descriptor for `DeleteExecutablePresetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteExecutablePresetRequestDescriptor =
    $convert.base64Decode(
        'Ch1EZWxldGVFeGVjdXRhYmxlUHJlc2V0UmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3'
        'dvcmtzcGFjZUlkEg4KAmlkGAIgASgJUgJpZBIrChFleHBlY3RlZF9yZXZpc2lvbhgDIAEoBFIQ'
        'ZXhwZWN0ZWRSZXZpc2lvbg==');

@$core.Deprecated('Use executableRunRequestDescriptor instead')
const ExecutableRunRequest$json = {
  '1': 'ExecutableRunRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'workspace_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'workspaceRevision'
    },
    {'1': 'preset_id', '3': 4, '4': 1, '5': 9, '10': 'presetId'},
    {'1': 'preset_revision', '3': 5, '4': 1, '5': 4, '10': 'presetRevision'},
  ],
};

/// Descriptor for `ExecutableRunRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableRunRequestDescriptor = $convert.base64Decode(
    'ChRFeGVjdXRhYmxlUnVuUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSIQoMd29ya3NwYWNlX2lkGA'
    'IgASgJUgt3b3Jrc3BhY2VJZBItChJ3b3Jrc3BhY2VfcmV2aXNpb24YAyABKARSEXdvcmtzcGFj'
    'ZVJldmlzaW9uEhsKCXByZXNldF9pZBgEIAEoCVIIcHJlc2V0SWQSJwoPcHJlc2V0X3JldmlzaW'
    '9uGAUgASgEUg5wcmVzZXRSZXZpc2lvbg==');

@$core.Deprecated('Use executableRunRefDescriptor instead')
const ExecutableRunRef$json = {
  '1': 'ExecutableRunRef',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ExecutableRunRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableRunRefDescriptor = $convert.base64Decode(
    'ChBFeGVjdXRhYmxlUnVuUmVmEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSDg'
    'oCaWQYAiABKAlSAmlk');

@$core.Deprecated('Use executableRunDescriptor instead')
const ExecutableRun$json = {
  '1': 'ExecutableRun',
  '2': [
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableRunRequest',
      '10': 'request'
    },
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'preset',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutablePreset',
      '10': 'preset'
    },
    {
      '1': 'profile_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'profileId',
      '17': true
    },
    {
      '1': 'profile_name',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'profileName',
      '17': true
    },
    {'1': 'requested_at', '3': 6, '4': 1, '5': 9, '10': 'requestedAt'},
    {
      '1': 'phase',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ExecutableRunPhase',
      '10': 'phase'
    },
    {
      '1': 'process_id',
      '3': 8,
      '4': 1,
      '5': 13,
      '9': 2,
      '10': 'processId',
      '17': true
    },
    {'1': 'scope', '3': 9, '4': 1, '5': 9, '9': 3, '10': 'scope', '17': true},
    {
      '1': 'root_exit_code',
      '3': 10,
      '4': 1,
      '5': 5,
      '9': 4,
      '10': 'rootExitCode',
      '17': true
    },
    {
      '1': 'observed_process_count',
      '3': 11,
      '4': 1,
      '5': 13,
      '9': 5,
      '10': 'observedProcessCount',
      '17': true
    },
    {
      '1': 'problem',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'game',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameRunInfo',
      '10': 'game'
    },
  ],
  '8': [
    {'1': '_profile_id'},
    {'1': '_profile_name'},
    {'1': '_process_id'},
    {'1': '_scope'},
    {'1': '_root_exit_code'},
    {'1': '_observed_process_count'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `ExecutableRun`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableRunDescriptor = $convert.base64Decode(
    'Cg1FeGVjdXRhYmxlUnVuEj8KB3JlcXVlc3QYASABKAsyJS5tb2Rjb25kdWN0b3IudjEuRXhlY3'
    'V0YWJsZVJ1blJlcXVlc3RSB3JlcXVlc3QSGgoIcmV2aXNpb24YAiABKARSCHJldmlzaW9uEjkK'
    'BnByZXNldBgDIAEoCzIhLm1vZGNvbmR1Y3Rvci52MS5FeGVjdXRhYmxlUHJlc2V0UgZwcmVzZX'
    'QSIgoKcHJvZmlsZV9pZBgEIAEoCUgAUglwcm9maWxlSWSIAQESJgoMcHJvZmlsZV9uYW1lGAUg'
    'ASgJSAFSC3Byb2ZpbGVOYW1liAEBEiEKDHJlcXVlc3RlZF9hdBgGIAEoCVILcmVxdWVzdGVkQX'
    'QSOQoFcGhhc2UYByABKA4yIy5tb2Rjb25kdWN0b3IudjEuRXhlY3V0YWJsZVJ1blBoYXNlUgVw'
    'aGFzZRIiCgpwcm9jZXNzX2lkGAggASgNSAJSCXByb2Nlc3NJZIgBARIZCgVzY29wZRgJIAEoCU'
    'gDUgVzY29wZYgBARIpCg5yb290X2V4aXRfY29kZRgKIAEoBUgEUgxyb290RXhpdENvZGWIAQES'
    'OQoWb2JzZXJ2ZWRfcHJvY2Vzc19jb3VudBgLIAEoDUgFUhRvYnNlcnZlZFByb2Nlc3NDb3VudI'
    'gBARIdCgdwcm9ibGVtGAwgASgJSAZSB3Byb2JsZW2IAQESMAoEZ2FtZRgNIAEoCzIcLm1vZGNv'
    'bmR1Y3Rvci52MS5HYW1lUnVuSW5mb1IEZ2FtZUINCgtfcHJvZmlsZV9pZEIPCg1fcHJvZmlsZV'
    '9uYW1lQg0KC19wcm9jZXNzX2lkQggKBl9zY29wZUIRCg9fcm9vdF9leGl0X2NvZGVCGQoXX29i'
    'c2VydmVkX3Byb2Nlc3NfY291bnRCCgoIX3Byb2JsZW0=');

@$core.Deprecated('Use executableProblemDescriptor instead')
const ExecutableProblem$json = {
  '1': 'ExecutableProblem',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ExecutableProblemCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `ExecutableProblem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableProblemDescriptor = $convert.base64Decode(
    'ChFFeGVjdXRhYmxlUHJvYmxlbRI6CgRjb2RlGAEgASgOMiYubW9kY29uZHVjdG9yLnYxLkV4ZW'
    'N1dGFibGVQcm9ibGVtQ29kZVIEY29kZRIWCgZkZXRhaWwYAiABKAlSBmRldGFpbA==');

@$core.Deprecated('Use executablePresetReplyDescriptor instead')
const ExecutablePresetReply$json = {
  '1': 'ExecutablePresetReply',
  '2': [
    {
      '1': 'preset',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutablePreset',
      '9': 0,
      '10': 'preset'
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ExecutablePresetReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executablePresetReplyDescriptor = $convert.base64Decode(
    'ChVFeGVjdXRhYmxlUHJlc2V0UmVwbHkSOwoGcHJlc2V0GAEgASgLMiEubW9kY29uZHVjdG9yLn'
    'YxLkV4ZWN1dGFibGVQcmVzZXRIAFIGcHJlc2V0Ej4KB3Byb2JsZW0YAiABKAsyIi5tb2Rjb25k'
    'dWN0b3IudjEuRXhlY3V0YWJsZVByb2JsZW1IAFIHcHJvYmxlbUIICgZyZXN1bHQ=');

@$core.Deprecated('Use executableMutationReplyDescriptor instead')
const ExecutableMutationReply$json = {
  '1': 'ExecutableMutationReply',
  '2': [
    {
      '1': 'problem',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableProblem',
      '9': 0,
      '10': 'problem',
      '17': true
    },
  ],
  '8': [
    {'1': '_problem'},
  ],
};

/// Descriptor for `ExecutableMutationReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableMutationReplyDescriptor =
    $convert.base64Decode(
        'ChdFeGVjdXRhYmxlTXV0YXRpb25SZXBseRJBCgdwcm9ibGVtGAEgASgLMiIubW9kY29uZHVjdG'
        '9yLnYxLkV4ZWN1dGFibGVQcm9ibGVtSABSB3Byb2JsZW2IAQFCCgoIX3Byb2JsZW0=');

@$core.Deprecated('Use executablePresetPageReplyDescriptor instead')
const ExecutablePresetPageReply$json = {
  '1': 'ExecutablePresetPageReply',
  '2': [
    {
      '1': 'presets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ExecutablePreset',
      '10': 'presets'
    },
    {
      '1': 'next_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextId',
      '17': true
    },
    {
      '1': 'problem',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableProblem',
      '9': 1,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'latest_runs',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ExecutableRun',
      '10': 'latestRuns'
    },
  ],
  '8': [
    {'1': '_next_id'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `ExecutablePresetPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executablePresetPageReplyDescriptor = $convert.base64Decode(
    'ChlFeGVjdXRhYmxlUHJlc2V0UGFnZVJlcGx5EjsKB3ByZXNldHMYASADKAsyIS5tb2Rjb25kdW'
    'N0b3IudjEuRXhlY3V0YWJsZVByZXNldFIHcHJlc2V0cxIcCgduZXh0X2lkGAIgASgJSABSBm5l'
    'eHRJZIgBARJBCgdwcm9ibGVtGAMgASgLMiIubW9kY29uZHVjdG9yLnYxLkV4ZWN1dGFibGVQcm'
    '9ibGVtSAFSB3Byb2JsZW2IAQESPwoLbGF0ZXN0X3J1bnMYBCADKAsyHi5tb2Rjb25kdWN0b3Iu'
    'djEuRXhlY3V0YWJsZVJ1blIKbGF0ZXN0UnVuc0IKCghfbmV4dF9pZEIKCghfcHJvYmxlbQ==');

@$core.Deprecated('Use executableRunReplyDescriptor instead')
const ExecutableRunReply$json = {
  '1': 'ExecutableRunReply',
  '2': [
    {
      '1': 'run',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableRun',
      '9': 0,
      '10': 'run'
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ExecutableRunReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableRunReplyDescriptor = $convert.base64Decode(
    'ChJFeGVjdXRhYmxlUnVuUmVwbHkSMgoDcnVuGAEgASgLMh4ubW9kY29uZHVjdG9yLnYxLkV4ZW'
    'N1dGFibGVSdW5IAFIDcnVuEj4KB3Byb2JsZW0YAiABKAsyIi5tb2Rjb25kdWN0b3IudjEuRXhl'
    'Y3V0YWJsZVByb2JsZW1IAFIHcHJvYmxlbUIICgZyZXN1bHQ=');

@$core.Deprecated('Use executableRunPageReplyDescriptor instead')
const ExecutableRunPageReply$json = {
  '1': 'ExecutableRunPageReply',
  '2': [
    {
      '1': 'runs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ExecutableRun',
      '10': 'runs'
    },
    {
      '1': 'next_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextId',
      '17': true
    },
    {
      '1': 'problem',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableProblem',
      '9': 1,
      '10': 'problem',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_id'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `ExecutableRunPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableRunPageReplyDescriptor = $convert.base64Decode(
    'ChZFeGVjdXRhYmxlUnVuUGFnZVJlcGx5EjIKBHJ1bnMYASADKAsyHi5tb2Rjb25kdWN0b3Iudj'
    'EuRXhlY3V0YWJsZVJ1blIEcnVucxIcCgduZXh0X2lkGAIgASgJSABSBm5leHRJZIgBARJBCgdw'
    'cm9ibGVtGAMgASgLMiIubW9kY29uZHVjdG9yLnYxLkV4ZWN1dGFibGVQcm9ibGVtSAFSB3Byb2'
    'JsZW2IAQFCCgoIX25leHRfaWRCCgoIX3Byb2JsZW0=');

@$core.Deprecated('Use gameRunRequestDescriptor instead')
const GameRunRequest$json = {
  '1': 'GameRunRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'workspace_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'workspaceRevision'
    },
    {'1': 'profile_id', '3': 4, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'context_revision', '3': 5, '4': 1, '5': 4, '10': 'contextRevision'},
    {'1': 'source_token', '3': 6, '4': 1, '5': 9, '10': 'sourceToken'},
  ],
};

/// Descriptor for `GameRunRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameRunRequestDescriptor = $convert.base64Decode(
    'Cg5HYW1lUnVuUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSIQoMd29ya3NwYWNlX2lkGAIgASgJUg'
    't3b3Jrc3BhY2VJZBItChJ3b3Jrc3BhY2VfcmV2aXNpb24YAyABKARSEXdvcmtzcGFjZVJldmlz'
    'aW9uEh0KCnByb2ZpbGVfaWQYBCABKAlSCXByb2ZpbGVJZBIpChBjb250ZXh0X3JldmlzaW9uGA'
    'UgASgEUg9jb250ZXh0UmV2aXNpb24SIQoMc291cmNlX3Rva2VuGAYgASgJUgtzb3VyY2VUb2tl'
    'bg==');

@$core.Deprecated('Use gameRunFilesDescriptor instead')
const GameRunFiles$json = {
  '1': 'GameRunFiles',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 9, '10': 'receiptId'},
    {'1': 'generation_id', '3': 2, '4': 1, '5': 9, '10': 'generationId'},
    {'1': 'fingerprint', '3': 3, '4': 1, '5': 9, '10': 'fingerprint'},
  ],
};

/// Descriptor for `GameRunFiles`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameRunFilesDescriptor = $convert.base64Decode(
    'CgxHYW1lUnVuRmlsZXMSHQoKcmVjZWlwdF9pZBgBIAEoCVIJcmVjZWlwdElkEiMKDWdlbmVyYX'
    'Rpb25faWQYAiABKAlSDGdlbmVyYXRpb25JZBIgCgtmaW5nZXJwcmludBgDIAEoCVILZmluZ2Vy'
    'cHJpbnQ=');

@$core.Deprecated('Use gameRunProfileDataDescriptor instead')
const GameRunProfileData$json = {
  '1': 'GameRunProfileData',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 9, '10': 'receiptId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'completed_files', '3': 3, '4': 1, '5': 13, '10': 'completedFiles'},
    {'1': 'complete', '3': 4, '4': 1, '5': 8, '10': 'complete'},
  ],
};

/// Descriptor for `GameRunProfileData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameRunProfileDataDescriptor = $convert.base64Decode(
    'ChJHYW1lUnVuUHJvZmlsZURhdGESHQoKcmVjZWlwdF9pZBgBIAEoCVIJcmVjZWlwdElkEhoKCH'
    'JldmlzaW9uGAIgASgEUghyZXZpc2lvbhInCg9jb21wbGV0ZWRfZmlsZXMYAyABKA1SDmNvbXBs'
    'ZXRlZEZpbGVzEhoKCGNvbXBsZXRlGAQgASgIUghjb21wbGV0ZQ==');

@$core.Deprecated('Use gameRunInfoDescriptor instead')
const GameRunInfo$json = {
  '1': 'GameRunInfo',
  '2': [
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameRunRequest',
      '10': 'request'
    },
    {'1': 'context_id', '3': 2, '4': 1, '5': 9, '10': 'contextId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'game_directory', '3': 4, '4': 1, '5': 9, '10': 'gameDirectory'},
    {'1': 'runtime', '3': 5, '4': 1, '5': 9, '10': 'runtime'},
    {'1': 'executable', '3': 6, '4': 1, '5': 9, '10': 'executable'},
    {'1': 'arguments', '3': 7, '4': 3, '5': 9, '10': 'arguments'},
    {
      '1': 'working_directory',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'workingDirectory'
    },
    {
      '1': 'environment',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ExecutableEnvironmentSetting',
      '10': 'environment'
    },
    {
      '1': 'preparation',
      '3': 10,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.GamePreparationPhase',
      '10': 'preparation'
    },
    {'1': 'completed', '3': 11, '4': 1, '5': 13, '10': 'completed'},
    {'1': 'total', '3': 12, '4': 1, '5': 13, '10': 'total'},
    {
      '1': 'files',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameRunFiles',
      '10': 'files'
    },
    {
      '1': 'profile_data_revision',
      '3': 14,
      '4': 1,
      '5': 4,
      '10': 'profileDataRevision'
    },
    {
      '1': 'profile_data',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameRunProfileData',
      '10': 'profileData'
    },
  ],
};

/// Descriptor for `GameRunInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameRunInfoDescriptor = $convert.base64Decode(
    'CgtHYW1lUnVuSW5mbxI5CgdyZXF1ZXN0GAEgASgLMh8ubW9kY29uZHVjdG9yLnYxLkdhbWVSdW'
    '5SZXF1ZXN0UgdyZXF1ZXN0Eh0KCmNvbnRleHRfaWQYAiABKAlSCWNvbnRleHRJZBISCgRuYW1l'
    'GAMgASgJUgRuYW1lEiUKDmdhbWVfZGlyZWN0b3J5GAQgASgJUg1nYW1lRGlyZWN0b3J5EhgKB3'
    'J1bnRpbWUYBSABKAlSB3J1bnRpbWUSHgoKZXhlY3V0YWJsZRgGIAEoCVIKZXhlY3V0YWJsZRIc'
    'Cglhcmd1bWVudHMYByADKAlSCWFyZ3VtZW50cxIrChF3b3JraW5nX2RpcmVjdG9yeRgIIAEoCV'
    'IQd29ya2luZ0RpcmVjdG9yeRJPCgtlbnZpcm9ubWVudBgJIAMoCzItLm1vZGNvbmR1Y3Rvci52'
    'MS5FeGVjdXRhYmxlRW52aXJvbm1lbnRTZXR0aW5nUgtlbnZpcm9ubWVudBJHCgtwcmVwYXJhdG'
    'lvbhgKIAEoDjIlLm1vZGNvbmR1Y3Rvci52MS5HYW1lUHJlcGFyYXRpb25QaGFzZVILcHJlcGFy'
    'YXRpb24SHAoJY29tcGxldGVkGAsgASgNUgljb21wbGV0ZWQSFAoFdG90YWwYDCABKA1SBXRvdG'
    'FsEjMKBWZpbGVzGA0gASgLMh0ubW9kY29uZHVjdG9yLnYxLkdhbWVSdW5GaWxlc1IFZmlsZXMS'
    'MgoVcHJvZmlsZV9kYXRhX3JldmlzaW9uGA4gASgEUhNwcm9maWxlRGF0YVJldmlzaW9uEkYKDH'
    'Byb2ZpbGVfZGF0YRgPIAEoCzIjLm1vZGNvbmR1Y3Rvci52MS5HYW1lUnVuUHJvZmlsZURhdGFS'
    'C3Byb2ZpbGVEYXRh');
