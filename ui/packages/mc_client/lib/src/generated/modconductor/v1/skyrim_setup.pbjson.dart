// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skyrim_setup.proto.

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

@$core.Deprecated('Use skyrimSetupActionDescriptor instead')
const SkyrimSetupAction$json = {
  '1': 'SkyrimSetupAction',
  '2': [
    {'1': 'SKYRIM_SETUP_ACTION_UNCHANGED', '2': 0},
    {'1': 'SKYRIM_SETUP_ACTION_INSTALL', '2': 1},
    {'1': 'SKYRIM_SETUP_ACTION_REMOVE', '2': 2},
    {'1': 'SKYRIM_SETUP_ACTION_UPDATE', '2': 3},
  ],
};

/// Descriptor for `SkyrimSetupAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skyrimSetupActionDescriptor = $convert.base64Decode(
    'ChFTa3lyaW1TZXR1cEFjdGlvbhIhCh1TS1lSSU1fU0VUVVBfQUNUSU9OX1VOQ0hBTkdFRBAAEh'
    '8KG1NLWVJJTV9TRVRVUF9BQ1RJT05fSU5TVEFMTBABEh4KGlNLWVJJTV9TRVRVUF9BQ1RJT05f'
    'UkVNT1ZFEAISHgoaU0tZUklNX1NFVFVQX0FDVElPTl9VUERBVEUQAw==');

@$core.Deprecated('Use skyrimSetupPhaseDescriptor instead')
const SkyrimSetupPhase$json = {
  '1': 'SkyrimSetupPhase',
  '2': [
    {'1': 'SKYRIM_SETUP_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'SKYRIM_SETUP_PHASE_UNAVAILABLE', '2': 1},
    {'1': 'SKYRIM_SETUP_PHASE_AVAILABLE', '2': 2},
    {'1': 'SKYRIM_SETUP_PHASE_PREPARING_DEPLOYMENT', '2': 3},
    {'1': 'SKYRIM_SETUP_PHASE_SETTING_UP_SKSE', '2': 4},
    {'1': 'SKYRIM_SETUP_PHASE_WAITING_FOR_SKSE', '2': 5},
    {'1': 'SKYRIM_SETUP_PHASE_WAITING_FOR_ENB_ARCHIVE', '2': 6},
    {'1': 'SKYRIM_SETUP_PHASE_SETTING_UP_ENB', '2': 7},
    {'1': 'SKYRIM_SETUP_PHASE_SETTING_UP_FNIS', '2': 8},
    {'1': 'SKYRIM_SETUP_PHASE_FNIS_STALE', '2': 9},
    {'1': 'SKYRIM_SETUP_PHASE_FNIS_RUNNING', '2': 10},
    {'1': 'SKYRIM_SETUP_PHASE_READY', '2': 11},
    {'1': 'SKYRIM_SETUP_PHASE_RECOVERY_REQUIRED', '2': 12},
    {'1': 'SKYRIM_SETUP_PHASE_FAILED', '2': 13},
    {'1': 'SKYRIM_SETUP_PHASE_CANCELLED', '2': 14},
  ],
};

/// Descriptor for `SkyrimSetupPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skyrimSetupPhaseDescriptor = $convert.base64Decode(
    'ChBTa3lyaW1TZXR1cFBoYXNlEiIKHlNLWVJJTV9TRVRVUF9QSEFTRV9VTlNQRUNJRklFRBAAEi'
    'IKHlNLWVJJTV9TRVRVUF9QSEFTRV9VTkFWQUlMQUJMRRABEiAKHFNLWVJJTV9TRVRVUF9QSEFT'
    'RV9BVkFJTEFCTEUQAhIrCidTS1lSSU1fU0VUVVBfUEhBU0VfUFJFUEFSSU5HX0RFUExPWU1FTl'
    'QQAxImCiJTS1lSSU1fU0VUVVBfUEhBU0VfU0VUVElOR19VUF9TS1NFEAQSJwojU0tZUklNX1NF'
    'VFVQX1BIQVNFX1dBSVRJTkdfRk9SX1NLU0UQBRIuCipTS1lSSU1fU0VUVVBfUEhBU0VfV0FJVE'
    'lOR19GT1JfRU5CX0FSQ0hJVkUQBhIlCiFTS1lSSU1fU0VUVVBfUEhBU0VfU0VUVElOR19VUF9F'
    'TkIQBxImCiJTS1lSSU1fU0VUVVBfUEhBU0VfU0VUVElOR19VUF9GTklTEAgSIQodU0tZUklNX1'
    'NFVFVQX1BIQVNFX0ZOSVNfU1RBTEUQCRIjCh9TS1lSSU1fU0VUVVBfUEhBU0VfRk5JU19SVU5O'
    'SU5HEAoSHAoYU0tZUklNX1NFVFVQX1BIQVNFX1JFQURZEAsSKAokU0tZUklNX1NFVFVQX1BIQV'
    'NFX1JFQ09WRVJZX1JFUVVJUkVEEAwSHQoZU0tZUklNX1NFVFVQX1BIQVNFX0ZBSUxFRBANEiAK'
    'HFNLWVJJTV9TRVRVUF9QSEFTRV9DQU5DRUxMRUQQDg==');

@$core.Deprecated('Use skyrimSetupPageRequestDescriptor instead')
const SkyrimSetupPageRequest$json = {
  '1': 'SkyrimSetupPageRequest',
  '2': [
    {'1': 'component_id', '3': 1, '4': 1, '5': 9, '10': 'componentId'},
  ],
};

/// Descriptor for `SkyrimSetupPageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupPageRequestDescriptor =
    $convert.base64Decode(
        'ChZTa3lyaW1TZXR1cFBhZ2VSZXF1ZXN0EiEKDGNvbXBvbmVudF9pZBgBIAEoCVILY29tcG9uZW'
        '50SWQ=');

@$core.Deprecated('Use skyrimSetupPageReplyDescriptor instead')
const SkyrimSetupPageReply$json = {
  '1': 'SkyrimSetupPageReply',
  '2': [
    {'1': 'opened', '3': 1, '4': 1, '5': 8, '10': 'opened'},
  ],
};

/// Descriptor for `SkyrimSetupPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupPageReplyDescriptor =
    $convert.base64Decode(
        'ChRTa3lyaW1TZXR1cFBhZ2VSZXBseRIWCgZvcGVuZWQYASABKAhSBm9wZW5lZA==');

@$core.Deprecated('Use skyrimSetupRequestDescriptor instead')
const SkyrimSetupRequest$json = {
  '1': 'SkyrimSetupRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `SkyrimSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupRequestDescriptor = $convert.base64Decode(
    'ChJTa3lyaW1TZXR1cFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQ=');

@$core.Deprecated('Use readSkyrimSetupRequestDescriptor instead')
const ReadSkyrimSetupRequest$json = {
  '1': 'ReadSkyrimSetupRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'selection',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupSelection',
      '10': 'selection'
    },
  ],
};

/// Descriptor for `ReadSkyrimSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readSkyrimSetupRequestDescriptor = $convert.base64Decode(
    'ChZSZWFkU2t5cmltU2V0dXBSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEkMKCXNlbGVjdGlvbhgDIAEoCzIl'
    'Lm1vZGNvbmR1Y3Rvci52MS5Ta3lyaW1TZXR1cFNlbGVjdGlvblIJc2VsZWN0aW9u');

@$core.Deprecated('Use startSkyrimSetupRequestDescriptor instead')
const StartSkyrimSetupRequest$json = {
  '1': 'StartSkyrimSetupRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'selection',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupSelection',
      '10': 'selection'
    },
    {
      '1': 'skse_choice',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SkseReleaseChoice',
      '10': 'skseChoice'
    },
  ],
};

/// Descriptor for `StartSkyrimSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startSkyrimSetupRequestDescriptor = $convert.base64Decode(
    'ChdTdGFydFNreXJpbVNldHVwUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcG'
    'FjZUlkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBJDCglzZWxlY3Rpb24YAyABKAsy'
    'JS5tb2Rjb25kdWN0b3IudjEuU2t5cmltU2V0dXBTZWxlY3Rpb25SCXNlbGVjdGlvbhJDCgtza3'
    'NlX2Nob2ljZRgEIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5Ta3NlUmVsZWFzZUNob2ljZVIKc2tz'
    'ZUNob2ljZQ==');

@$core.Deprecated('Use skseReleaseChoiceDescriptor instead')
const SkseReleaseChoice$json = {
  '1': 'SkseReleaseChoice',
  '2': [
    {'1': 'file_id', '3': 1, '4': 1, '5': 3, '10': 'fileId'},
    {
      '1': 'component_version',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'componentVersion'
    },
    {'1': 'game_version', '3': 3, '4': 1, '5': 9, '10': 'gameVersion'},
    {'1': 'game_sha256', '3': 4, '4': 1, '5': 9, '10': 'gameSha256'},
    {
      '1': 'allow_incompatible',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'allowIncompatible'
    },
  ],
};

/// Descriptor for `SkseReleaseChoice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skseReleaseChoiceDescriptor = $convert.base64Decode(
    'ChFTa3NlUmVsZWFzZUNob2ljZRIXCgdmaWxlX2lkGAEgASgDUgZmaWxlSWQSKwoRY29tcG9uZW'
    '50X3ZlcnNpb24YAiABKAlSEGNvbXBvbmVudFZlcnNpb24SIQoMZ2FtZV92ZXJzaW9uGAMgASgJ'
    'UgtnYW1lVmVyc2lvbhIfCgtnYW1lX3NoYTI1NhgEIAEoCVIKZ2FtZVNoYTI1NhItChJhbGxvd1'
    '9pbmNvbXBhdGlibGUYBSABKAhSEWFsbG93SW5jb21wYXRpYmxl');

@$core.Deprecated('Use skseReleaseReviewDescriptor instead')
const SkseReleaseReview$json = {
  '1': 'SkseReleaseReview',
  '2': [
    {'1': 'compatible', '3': 1, '4': 1, '5': 8, '10': 'compatible'},
    {'1': 'game_version', '3': 2, '4': 1, '5': 9, '10': 'gameVersion'},
    {'1': 'game_sha256', '3': 3, '4': 1, '5': 9, '10': 'gameSha256'},
    {'1': 'file_id', '3': 4, '4': 1, '5': 3, '10': 'fileId'},
    {
      '1': 'component_version',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'componentVersion'
    },
    {
      '1': 'supported_runtime',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'supportedRuntime'
    },
    {'1': 'problem', '3': 7, '4': 1, '5': 9, '10': 'problem'},
  ],
};

/// Descriptor for `SkseReleaseReview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skseReleaseReviewDescriptor = $convert.base64Decode(
    'ChFTa3NlUmVsZWFzZVJldmlldxIeCgpjb21wYXRpYmxlGAEgASgIUgpjb21wYXRpYmxlEiEKDG'
    'dhbWVfdmVyc2lvbhgCIAEoCVILZ2FtZVZlcnNpb24SHwoLZ2FtZV9zaGEyNTYYAyABKAlSCmdh'
    'bWVTaGEyNTYSFwoHZmlsZV9pZBgEIAEoA1IGZmlsZUlkEisKEWNvbXBvbmVudF92ZXJzaW9uGA'
    'UgASgJUhBjb21wb25lbnRWZXJzaW9uEisKEXN1cHBvcnRlZF9ydW50aW1lGAYgASgJUhBzdXBw'
    'b3J0ZWRSdW50aW1lEhgKB3Byb2JsZW0YByABKAlSB3Byb2JsZW0=');

@$core.Deprecated('Use skyrimSetupSelectionDescriptor instead')
const SkyrimSetupSelection$json = {
  '1': 'SkyrimSetupSelection',
  '2': [
    {
      '1': 'skse',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SkyrimSetupAction',
      '10': 'skse'
    },
    {
      '1': 'enb',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SkyrimSetupAction',
      '10': 'enb'
    },
    {
      '1': 'fnis',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SkyrimSetupAction',
      '10': 'fnis'
    },
    {'1': 'enb_archive_path', '3': 4, '4': 1, '5': 9, '10': 'enbArchivePath'},
  ],
};

/// Descriptor for `SkyrimSetupSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupSelectionDescriptor = $convert.base64Decode(
    'ChRTa3lyaW1TZXR1cFNlbGVjdGlvbhI2CgRza3NlGAEgASgOMiIubW9kY29uZHVjdG9yLnYxLl'
    'NreXJpbVNldHVwQWN0aW9uUgRza3NlEjQKA2VuYhgCIAEoDjIiLm1vZGNvbmR1Y3Rvci52MS5T'
    'a3lyaW1TZXR1cEFjdGlvblIDZW5iEjYKBGZuaXMYAyABKA4yIi5tb2Rjb25kdWN0b3IudjEuU2'
    't5cmltU2V0dXBBY3Rpb25SBGZuaXMSKAoQZW5iX2FyY2hpdmVfcGF0aBgEIAEoCVIOZW5iQXJj'
    'aGl2ZVBhdGg=');

@$core.Deprecated('Use skyrimSetupComponentDescriptor instead')
const SkyrimSetupComponent$json = {
  '1': 'SkyrimSetupComponent',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'detail', '3': 3, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'ready', '3': 4, '4': 1, '5': 8, '10': 'ready'},
    {'1': 'active', '3': 5, '4': 1, '5': 8, '10': 'active'},
    {'1': 'blocked', '3': 6, '4': 1, '5': 8, '10': 'blocked'},
    {'1': 'id', '3': 7, '4': 1, '5': 9, '10': 'id'},
    {'1': 'installed', '3': 8, '4': 1, '5': 8, '10': 'installed'},
    {'1': 'update_version', '3': 9, '4': 1, '5': 9, '10': 'updateVersion'},
  ],
};

/// Descriptor for `SkyrimSetupComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupComponentDescriptor = $convert.base64Decode(
    'ChRTa3lyaW1TZXR1cENvbXBvbmVudBISCgRuYW1lGAEgASgJUgRuYW1lEhYKBnN0YXR1cxgCIA'
    'EoCVIGc3RhdHVzEhYKBmRldGFpbBgDIAEoCVIGZGV0YWlsEhQKBXJlYWR5GAQgASgIUgVyZWFk'
    'eRIWCgZhY3RpdmUYBSABKAhSBmFjdGl2ZRIYCgdibG9ja2VkGAYgASgIUgdibG9ja2VkEg4KAm'
    'lkGAcgASgJUgJpZBIcCglpbnN0YWxsZWQYCCABKAhSCWluc3RhbGxlZBIlCg51cGRhdGVfdmVy'
    'c2lvbhgJIAEoCVINdXBkYXRlVmVyc2lvbg==');

@$core.Deprecated('Use skyrimSetupStateDescriptor instead')
const SkyrimSetupState$json = {
  '1': 'SkyrimSetupState',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SkyrimSetupPhase',
      '10': 'phase'
    },
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'detail', '3': 3, '4': 1, '5': 9, '10': 'detail'},
    {
      '1': 'components',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupComponent',
      '10': 'components'
    },
    {
      '1': 'selection',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupSelection',
      '10': 'selection'
    },
    {'1': 'can_start', '3': 9, '4': 1, '5': 8, '10': 'canStart'},
    {'1': 'can_continue', '3': 10, '4': 1, '5': 8, '10': 'canContinue'},
    {'1': 'active', '3': 12, '4': 1, '5': 8, '10': 'active'},
    {'1': 'ready', '3': 13, '4': 1, '5': 8, '10': 'ready'},
    {'1': 'can_cancel', '3': 14, '4': 1, '5': 8, '10': 'canCancel'},
  ],
};

/// Descriptor for `SkyrimSetupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupStateDescriptor = $convert.base64Decode(
    'ChBTa3lyaW1TZXR1cFN0YXRlEjcKBXBoYXNlGAEgASgOMiEubW9kY29uZHVjdG9yLnYxLlNreX'
    'JpbVNldHVwUGhhc2VSBXBoYXNlEhYKBnN0YXR1cxgCIAEoCVIGc3RhdHVzEhYKBmRldGFpbBgD'
    'IAEoCVIGZGV0YWlsEkUKCmNvbXBvbmVudHMYBiADKAsyJS5tb2Rjb25kdWN0b3IudjEuU2t5cm'
    'ltU2V0dXBDb21wb25lbnRSCmNvbXBvbmVudHMSQwoJc2VsZWN0aW9uGAcgASgLMiUubW9kY29u'
    'ZHVjdG9yLnYxLlNreXJpbVNldHVwU2VsZWN0aW9uUglzZWxlY3Rpb24SGwoJY2FuX3N0YXJ0GA'
    'kgASgIUghjYW5TdGFydBIhCgxjYW5fY29udGludWUYCiABKAhSC2NhbkNvbnRpbnVlEhYKBmFj'
    'dGl2ZRgMIAEoCFIGYWN0aXZlEhQKBXJlYWR5GA0gASgIUgVyZWFkeRIdCgpjYW5fY2FuY2VsGA'
    '4gASgIUgljYW5DYW5jZWw=');
