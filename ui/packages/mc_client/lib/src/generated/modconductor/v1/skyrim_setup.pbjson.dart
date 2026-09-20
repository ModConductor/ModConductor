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

@$core.Deprecated('Use skyrimSetupPhaseDescriptor instead')
const SkyrimSetupPhase$json = {
  '1': 'SkyrimSetupPhase',
  '2': [
    {'1': 'SKYRIM_SETUP_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'SKYRIM_SETUP_PHASE_UNAVAILABLE', '2': 1},
    {'1': 'SKYRIM_SETUP_PHASE_NEEDS_CONSENT', '2': 2},
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
  ],
};

/// Descriptor for `SkyrimSetupPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skyrimSetupPhaseDescriptor = $convert.base64Decode(
    'ChBTa3lyaW1TZXR1cFBoYXNlEiIKHlNLWVJJTV9TRVRVUF9QSEFTRV9VTlNQRUNJRklFRBAAEi'
    'IKHlNLWVJJTV9TRVRVUF9QSEFTRV9VTkFWQUlMQUJMRRABEiQKIFNLWVJJTV9TRVRVUF9QSEFT'
    'RV9ORUVEU19DT05TRU5UEAISKwonU0tZUklNX1NFVFVQX1BIQVNFX1BSRVBBUklOR19ERVBMT1'
    'lNRU5UEAMSJgoiU0tZUklNX1NFVFVQX1BIQVNFX1NFVFRJTkdfVVBfU0tTRRAEEicKI1NLWVJJ'
    'TV9TRVRVUF9QSEFTRV9XQUlUSU5HX0ZPUl9TS1NFEAUSLgoqU0tZUklNX1NFVFVQX1BIQVNFX1'
    'dBSVRJTkdfRk9SX0VOQl9BUkNISVZFEAYSJQohU0tZUklNX1NFVFVQX1BIQVNFX1NFVFRJTkdf'
    'VVBfRU5CEAcSJgoiU0tZUklNX1NFVFVQX1BIQVNFX1NFVFRJTkdfVVBfRk5JUxAIEiEKHVNLWV'
    'JJTV9TRVRVUF9QSEFTRV9GTklTX1NUQUxFEAkSIwofU0tZUklNX1NFVFVQX1BIQVNFX0ZOSVNf'
    'UlVOTklORxAKEhwKGFNLWVJJTV9TRVRVUF9QSEFTRV9SRUFEWRALEigKJFNLWVJJTV9TRVRVUF'
    '9QSEFTRV9SRUNPVkVSWV9SRVFVSVJFRBAMEh0KGVNLWVJJTV9TRVRVUF9QSEFTRV9GQUlMRUQQ'
    'DQ==');

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
    {'1': 'include_fnis', '3': 3, '4': 1, '5': 8, '10': 'includeFnis'},
  ],
};

/// Descriptor for `ReadSkyrimSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readSkyrimSetupRequestDescriptor = $convert.base64Decode(
    'ChZSZWFkU2t5cmltU2V0dXBSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEiEKDGluY2x1ZGVfZm5pcxgDIAEo'
    'CFILaW5jbHVkZUZuaXM=');

@$core.Deprecated('Use startSkyrimSetupRequestDescriptor instead')
const StartSkyrimSetupRequest$json = {
  '1': 'StartSkyrimSetupRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'include_fnis', '3': 3, '4': 1, '5': 8, '10': 'includeFnis'},
    {'1': 'plan_token', '3': 4, '4': 1, '5': 9, '10': 'planToken'},
    {
      '1': 'change_plan_confirmed',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'changePlanConfirmed'
    },
  ],
};

/// Descriptor for `StartSkyrimSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startSkyrimSetupRequestDescriptor = $convert.base64Decode(
    'ChdTdGFydFNreXJpbVNldHVwUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcG'
    'FjZUlkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBIhCgxpbmNsdWRlX2ZuaXMYAyAB'
    'KAhSC2luY2x1ZGVGbmlzEh0KCnBsYW5fdG9rZW4YBCABKAlSCXBsYW5Ub2tlbhIyChVjaGFuZ2'
    'VfcGxhbl9jb25maXJtZWQYBSABKAhSE2NoYW5nZVBsYW5Db25maXJtZWQ=');

@$core.Deprecated('Use skyrimSetupArchiveRequestDescriptor instead')
const SkyrimSetupArchiveRequest$json = {
  '1': 'SkyrimSetupArchiveRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'operation_id', '3': 3, '4': 1, '5': 9, '10': 'operationId'},
    {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `SkyrimSetupArchiveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupArchiveRequestDescriptor = $convert.base64Decode(
    'ChlTa3lyaW1TZXR1cEFyY2hpdmVSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3'
    'NwYWNlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEiEKDG9wZXJhdGlvbl9pZBgD'
    'IAEoCVILb3BlcmF0aW9uSWQSEgoEcGF0aBgEIAEoCVIEcGF0aA==');

@$core.Deprecated('Use skyrimSetupChangeDescriptor instead')
const SkyrimSetupChange$json = {
  '1': 'SkyrimSetupChange',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `SkyrimSetupChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupChangeDescriptor = $convert.base64Decode(
    'ChFTa3lyaW1TZXR1cENoYW5nZRIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSFgoGZGV0YWlsGAIgAS'
    'gJUgZkZXRhaWw=');

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
  ],
};

/// Descriptor for `SkyrimSetupComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupComponentDescriptor = $convert.base64Decode(
    'ChRTa3lyaW1TZXR1cENvbXBvbmVudBISCgRuYW1lGAEgASgJUgRuYW1lEhYKBnN0YXR1cxgCIA'
    'EoCVIGc3RhdHVzEhYKBmRldGFpbBgDIAEoCVIGZGV0YWlsEhQKBXJlYWR5GAQgASgIUgVyZWFk'
    'eRIWCgZhY3RpdmUYBSABKAhSBmFjdGl2ZRIYCgdibG9ja2VkGAYgASgIUgdibG9ja2Vk');

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
    {'1': 'plan_token', '3': 4, '4': 1, '5': 9, '10': 'planToken'},
    {
      '1': 'changes',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupChange',
      '10': 'changes'
    },
    {
      '1': 'components',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupComponent',
      '10': 'components'
    },
    {'1': 'include_fnis', '3': 7, '4': 1, '5': 8, '10': 'includeFnis'},
    {'1': 'consent_recorded', '3': 8, '4': 1, '5': 8, '10': 'consentRecorded'},
    {'1': 'can_start', '3': 9, '4': 1, '5': 8, '10': 'canStart'},
    {'1': 'can_continue', '3': 10, '4': 1, '5': 8, '10': 'canContinue'},
    {
      '1': 'can_select_enb_archive',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'canSelectEnbArchive'
    },
    {'1': 'active', '3': 12, '4': 1, '5': 8, '10': 'active'},
    {'1': 'ready', '3': 13, '4': 1, '5': 8, '10': 'ready'},
  ],
};

/// Descriptor for `SkyrimSetupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupStateDescriptor = $convert.base64Decode(
    'ChBTa3lyaW1TZXR1cFN0YXRlEjcKBXBoYXNlGAEgASgOMiEubW9kY29uZHVjdG9yLnYxLlNreX'
    'JpbVNldHVwUGhhc2VSBXBoYXNlEhYKBnN0YXR1cxgCIAEoCVIGc3RhdHVzEhYKBmRldGFpbBgD'
    'IAEoCVIGZGV0YWlsEh0KCnBsYW5fdG9rZW4YBCABKAlSCXBsYW5Ub2tlbhI8CgdjaGFuZ2VzGA'
    'UgAygLMiIubW9kY29uZHVjdG9yLnYxLlNreXJpbVNldHVwQ2hhbmdlUgdjaGFuZ2VzEkUKCmNv'
    'bXBvbmVudHMYBiADKAsyJS5tb2Rjb25kdWN0b3IudjEuU2t5cmltU2V0dXBDb21wb25lbnRSCm'
    'NvbXBvbmVudHMSIQoMaW5jbHVkZV9mbmlzGAcgASgIUgtpbmNsdWRlRm5pcxIpChBjb25zZW50'
    'X3JlY29yZGVkGAggASgIUg9jb25zZW50UmVjb3JkZWQSGwoJY2FuX3N0YXJ0GAkgASgIUghjYW'
    '5TdGFydBIhCgxjYW5fY29udGludWUYCiABKAhSC2NhbkNvbnRpbnVlEjMKFmNhbl9zZWxlY3Rf'
    'ZW5iX2FyY2hpdmUYCyABKAhSE2NhblNlbGVjdEVuYkFyY2hpdmUSFgoGYWN0aXZlGAwgASgIUg'
    'ZhY3RpdmUSFAoFcmVhZHkYDSABKAhSBXJlYWR5');
