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
    {'1': 'SKYRIM_SETUP_PHASE_CANCELLED', '2': 14},
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
    'DRIgChxTS1lSSU1fU0VUVVBfUEhBU0VfQ0FOQ0VMTEVEEA4=');

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
    'FjZUlkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBJDCglzZWxlY3Rpb24YAyABKAsy'
    'JS5tb2Rjb25kdWN0b3IudjEuU2t5cmltU2V0dXBTZWxlY3Rpb25SCXNlbGVjdGlvbhIdCgpwbG'
    'FuX3Rva2VuGAQgASgJUglwbGFuVG9rZW4SMgoVY2hhbmdlX3BsYW5fY29uZmlybWVkGAUgASgI'
    'UhNjaGFuZ2VQbGFuQ29uZmlybWVk');

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

@$core.Deprecated('Use skyrimSetupChangeDescriptor instead')
const SkyrimSetupChange$json = {
  '1': 'SkyrimSetupChange',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'supporting', '3': 4, '4': 1, '5': 8, '10': 'supporting'},
  ],
};

/// Descriptor for `SkyrimSetupChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupChangeDescriptor = $convert.base64Decode(
    'ChFTa3lyaW1TZXR1cENoYW5nZRIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSFgoGZGV0YWlsGAIgAS'
    'gJUgZkZXRhaWwSFgoGc291cmNlGAMgASgJUgZzb3VyY2USHgoKc3VwcG9ydGluZxgEIAEoCFIK'
    'c3VwcG9ydGluZw==');

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
  ],
};

/// Descriptor for `SkyrimSetupComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSetupComponentDescriptor = $convert.base64Decode(
    'ChRTa3lyaW1TZXR1cENvbXBvbmVudBISCgRuYW1lGAEgASgJUgRuYW1lEhYKBnN0YXR1cxgCIA'
    'EoCVIGc3RhdHVzEhYKBmRldGFpbBgDIAEoCVIGZGV0YWlsEhQKBXJlYWR5GAQgASgIUgVyZWFk'
    'eRIWCgZhY3RpdmUYBSABKAhSBmFjdGl2ZRIYCgdibG9ja2VkGAYgASgIUgdibG9ja2VkEg4KAm'
    'lkGAcgASgJUgJpZBIcCglpbnN0YWxsZWQYCCABKAhSCWluc3RhbGxlZA==');

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
    {
      '1': 'selection',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSetupSelection',
      '10': 'selection'
    },
    {'1': 'consent_recorded', '3': 8, '4': 1, '5': 8, '10': 'consentRecorded'},
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
    'IAEoCVIGZGV0YWlsEh0KCnBsYW5fdG9rZW4YBCABKAlSCXBsYW5Ub2tlbhI8CgdjaGFuZ2VzGA'
    'UgAygLMiIubW9kY29uZHVjdG9yLnYxLlNreXJpbVNldHVwQ2hhbmdlUgdjaGFuZ2VzEkUKCmNv'
    'bXBvbmVudHMYBiADKAsyJS5tb2Rjb25kdWN0b3IudjEuU2t5cmltU2V0dXBDb21wb25lbnRSCm'
    'NvbXBvbmVudHMSQwoJc2VsZWN0aW9uGAcgASgLMiUubW9kY29uZHVjdG9yLnYxLlNreXJpbVNl'
    'dHVwU2VsZWN0aW9uUglzZWxlY3Rpb24SKQoQY29uc2VudF9yZWNvcmRlZBgIIAEoCFIPY29uc2'
    'VudFJlY29yZGVkEhsKCWNhbl9zdGFydBgJIAEoCFIIY2FuU3RhcnQSIQoMY2FuX2NvbnRpbnVl'
    'GAogASgIUgtjYW5Db250aW51ZRIWCgZhY3RpdmUYDCABKAhSBmFjdGl2ZRIUCgVyZWFkeRgNIA'
    'EoCFIFcmVhZHkSHQoKY2FuX2NhbmNlbBgOIAEoCFIJY2FuQ2FuY2Vs');
