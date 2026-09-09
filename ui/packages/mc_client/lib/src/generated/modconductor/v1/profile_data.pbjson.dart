// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_data.proto.

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

@$core.Deprecated('Use initialProfileSavesDescriptor instead')
const InitialProfileSaves$json = {
  '1': 'InitialProfileSaves',
  '2': [
    {'1': 'INITIAL_PROFILE_SAVES_UNSPECIFIED', '2': 0},
    {'1': 'INITIAL_PROFILE_SAVES_EMPTY', '2': 1},
    {'1': 'INITIAL_PROFILE_SAVES_COPY_GLOBAL', '2': 2},
  ],
};

/// Descriptor for `InitialProfileSaves`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List initialProfileSavesDescriptor = $convert.base64Decode(
    'ChNJbml0aWFsUHJvZmlsZVNhdmVzEiUKIUlOSVRJQUxfUFJPRklMRV9TQVZFU19VTlNQRUNJRk'
    'lFRBAAEh8KG0lOSVRJQUxfUFJPRklMRV9TQVZFU19FTVBUWRABEiUKIUlOSVRJQUxfUFJPRklM'
    'RV9TQVZFU19DT1BZX0dMT0JBTBAC');

@$core.Deprecated('Use disabledProfileFilesDescriptor instead')
const DisabledProfileFiles$json = {
  '1': 'DisabledProfileFiles',
  '2': [
    {'1': 'DISABLED_PROFILE_FILES_UNSPECIFIED', '2': 0},
    {'1': 'DISABLED_PROFILE_FILES_KEEP', '2': 1},
    {'1': 'DISABLED_PROFILE_FILES_DELETE', '2': 2},
  ],
};

/// Descriptor for `DisabledProfileFiles`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List disabledProfileFilesDescriptor = $convert.base64Decode(
    'ChREaXNhYmxlZFByb2ZpbGVGaWxlcxImCiJESVNBQkxFRF9QUk9GSUxFX0ZJTEVTX1VOU1BFQ0'
    'lGSUVEEAASHwobRElTQUJMRURfUFJPRklMRV9GSUxFU19LRUVQEAESIQodRElTQUJMRURfUFJP'
    'RklMRV9GSUxFU19ERUxFVEUQAg==');

@$core.Deprecated('Use profileDataProblemKindDescriptor instead')
const ProfileDataProblemKind$json = {
  '1': 'ProfileDataProblemKind',
  '2': [
    {'1': 'PROFILE_DATA_PROBLEM_UNSPECIFIED', '2': 0},
    {'1': 'PROFILE_DATA_PROBLEM_NOT_FOUND', '2': 1},
    {'1': 'PROFILE_DATA_PROBLEM_BUSY', '2': 2},
    {'1': 'PROFILE_DATA_PROBLEM_STALE', '2': 3},
    {'1': 'PROFILE_DATA_PROBLEM_CANCELLED', '2': 4},
    {'1': 'PROFILE_DATA_PROBLEM_INVALID', '2': 5},
    {'1': 'PROFILE_DATA_PROBLEM_UNAVAILABLE', '2': 6},
    {'1': 'PROFILE_DATA_PROBLEM_CONFLICT', '2': 7},
  ],
};

/// Descriptor for `ProfileDataProblemKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List profileDataProblemKindDescriptor = $convert.base64Decode(
    'ChZQcm9maWxlRGF0YVByb2JsZW1LaW5kEiQKIFBST0ZJTEVfREFUQV9QUk9CTEVNX1VOU1BFQ0'
    'lGSUVEEAASIgoeUFJPRklMRV9EQVRBX1BST0JMRU1fTk9UX0ZPVU5EEAESHQoZUFJPRklMRV9E'
    'QVRBX1BST0JMRU1fQlVTWRACEh4KGlBST0ZJTEVfREFUQV9QUk9CTEVNX1NUQUxFEAMSIgoeUF'
    'JPRklMRV9EQVRBX1BST0JMRU1fQ0FOQ0VMTEVEEAQSIAocUFJPRklMRV9EQVRBX1BST0JMRU1f'
    'SU5WQUxJRBAFEiQKIFBST0ZJTEVfREFUQV9QUk9CTEVNX1VOQVZBSUxBQkxFEAYSIQodUFJPRk'
    'lMRV9EQVRBX1BST0JMRU1fQ09ORkxJQ1QQBw==');

@$core.Deprecated('Use profileDataReadRequestDescriptor instead')
const ProfileDataReadRequest$json = {
  '1': 'ProfileDataReadRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `ProfileDataReadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataReadRequestDescriptor =
    $convert.base64Decode(
        'ChZQcm9maWxlRGF0YVJlYWRSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
        'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use profileDataRefDescriptor instead')
const ProfileDataRef$json = {
  '1': 'ProfileDataRef',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'context_id', '3': 3, '4': 1, '5': 9, '10': 'contextId'},
    {'1': 'revision', '3': 4, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `ProfileDataRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataRefDescriptor = $convert.base64Decode(
    'Cg5Qcm9maWxlRGF0YVJlZhIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh0KCn'
    'Byb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBIdCgpjb250ZXh0X2lkGAMgASgJUgljb250ZXh0'
    'SWQSGgoIcmV2aXNpb24YBCABKARSCHJldmlzaW9u');

@$core.Deprecated('Use profileDataOptionsDescriptor instead')
const ProfileDataOptions$json = {
  '1': 'ProfileDataOptions',
  '2': [
    {'1': 'settings', '3': 1, '4': 1, '5': 8, '10': 'settings'},
    {'1': 'saves', '3': 2, '4': 1, '5': 8, '10': 'saves'},
  ],
};

/// Descriptor for `ProfileDataOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataOptionsDescriptor = $convert.base64Decode(
    'ChJQcm9maWxlRGF0YU9wdGlvbnMSGgoIc2V0dGluZ3MYASABKAhSCHNldHRpbmdzEhQKBXNhdm'
    'VzGAIgASgIUgVzYXZlcw==');

@$core.Deprecated('Use profileDataStateDescriptor instead')
const ProfileDataState$json = {
  '1': 'ProfileDataState',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'reference'
    },
    {
      '1': 'options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataOptions',
      '10': 'options'
    },
    {
      '1': 'in_use_profile_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'inUseProfileId',
      '17': true
    },
    {'1': 'settings_path', '3': 4, '4': 1, '5': 9, '10': 'settingsPath'},
    {'1': 'saves_path', '3': 5, '4': 1, '5': 9, '10': 'savesPath'},
    {'1': 'settings_files', '3': 6, '4': 1, '5': 13, '10': 'settingsFiles'},
    {'1': 'save_files', '3': 7, '4': 1, '5': 13, '10': 'saveFiles'},
    {
      '1': 'pending_action_id',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'pendingActionId',
      '17': true
    },
    {
      '1': 'problem',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'pending_profile_change',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'pendingProfileChange'
    },
  ],
  '8': [
    {'1': '_in_use_profile_id'},
    {'1': '_pending_action_id'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `ProfileDataState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataStateDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlRGF0YVN0YXRlEj0KCXJlZmVyZW5jZRgBIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS'
    '5Qcm9maWxlRGF0YVJlZlIJcmVmZXJlbmNlEj0KB29wdGlvbnMYAiABKAsyIy5tb2Rjb25kdWN0'
    'b3IudjEuUHJvZmlsZURhdGFPcHRpb25zUgdvcHRpb25zEi4KEWluX3VzZV9wcm9maWxlX2lkGA'
    'MgASgJSABSDmluVXNlUHJvZmlsZUlkiAEBEiMKDXNldHRpbmdzX3BhdGgYBCABKAlSDHNldHRp'
    'bmdzUGF0aBIdCgpzYXZlc19wYXRoGAUgASgJUglzYXZlc1BhdGgSJQoOc2V0dGluZ3NfZmlsZX'
    'MYBiABKA1SDXNldHRpbmdzRmlsZXMSHQoKc2F2ZV9maWxlcxgHIAEoDVIJc2F2ZUZpbGVzEi8K'
    'EXBlbmRpbmdfYWN0aW9uX2lkGAggASgJSAFSD3BlbmRpbmdBY3Rpb25JZIgBARIdCgdwcm9ibG'
    'VtGAkgASgJSAJSB3Byb2JsZW2IAQESNAoWcGVuZGluZ19wcm9maWxlX2NoYW5nZRgKIAEoCFIU'
    'cGVuZGluZ1Byb2ZpbGVDaGFuZ2VCFAoSX2luX3VzZV9wcm9maWxlX2lkQhQKEl9wZW5kaW5nX2'
    'FjdGlvbl9pZEIKCghfcHJvYmxlbQ==');

@$core.Deprecated('Use profileDataEditRequestDescriptor instead')
const ProfileDataEditRequest$json = {
  '1': 'ProfileDataEditRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {
      '1': 'options',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataOptions',
      '10': 'options'
    },
    {
      '1': 'initial_saves',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InitialProfileSaves',
      '10': 'initialSaves'
    },
    {
      '1': 'disabled_files',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DisabledProfileFiles',
      '10': 'disabledFiles'
    },
  ],
};

/// Descriptor for `ProfileDataEditRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataEditRequestDescriptor = $convert.base64Decode(
    'ChZQcm9maWxlRGF0YUVkaXRSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBI7CghleHBlY3RlZBgCIA'
    'EoCzIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVJlZlIIZXhwZWN0ZWQSPQoHb3B0aW9u'
    'cxgDIAEoCzIjLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YU9wdGlvbnNSB29wdGlvbnMSSQ'
    'oNaW5pdGlhbF9zYXZlcxgEIAEoDjIkLm1vZGNvbmR1Y3Rvci52MS5Jbml0aWFsUHJvZmlsZVNh'
    'dmVzUgxpbml0aWFsU2F2ZXMSTAoOZGlzYWJsZWRfZmlsZXMYBSABKA4yJS5tb2Rjb25kdWN0b3'
    'IudjEuRGlzYWJsZWRQcm9maWxlRmlsZXNSDWRpc2FibGVkRmlsZXM=');

@$core.Deprecated('Use profileDataRestoreRequestDescriptor instead')
const ProfileDataRestoreRequest$json = {
  '1': 'ProfileDataRestoreRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
  ],
};

/// Descriptor for `ProfileDataRestoreRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataRestoreRequestDescriptor =
    $convert.base64Decode(
        'ChlQcm9maWxlRGF0YVJlc3RvcmVSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBI7CghleHBlY3RlZB'
        'gCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVJlZlIIZXhwZWN0ZWQ=');

@$core.Deprecated('Use profileDataActionRequestDescriptor instead')
const ProfileDataActionRequest$json = {
  '1': 'ProfileDataActionRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ProfileDataActionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataActionRequestDescriptor =
    $convert.base64Decode(
        'ChhQcm9maWxlRGF0YUFjdGlvblJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3'
        'BhY2VJZBIOCgJpZBgCIAEoCVICaWQ=');

@$core.Deprecated('Use profileDataActionResultDescriptor instead')
const ProfileDataActionResult$json = {
  '1': 'ProfileDataActionResult',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataState',
      '10': 'state'
    },
    {'1': 'complete', '3': 3, '4': 1, '5': 8, '10': 'complete'},
    {'1': 'completed_files', '3': 4, '4': 1, '5': 13, '10': 'completedFiles'},
    {
      '1': 'problem',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'problem',
      '17': true
    },
  ],
  '8': [
    {'1': '_problem'},
  ],
};

/// Descriptor for `ProfileDataActionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataActionResultDescriptor = $convert.base64Decode(
    'ChdQcm9maWxlRGF0YUFjdGlvblJlc3VsdBIOCgJpZBgBIAEoCVICaWQSNwoFc3RhdGUYAiABKA'
    'syIS5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZURhdGFTdGF0ZVIFc3RhdGUSGgoIY29tcGxldGUY'
    'AyABKAhSCGNvbXBsZXRlEicKD2NvbXBsZXRlZF9maWxlcxgEIAEoDVIOY29tcGxldGVkRmlsZX'
    'MSHQoHcHJvYmxlbRgFIAEoCUgAUgdwcm9ibGVtiAEBQgoKCF9wcm9ibGVt');

@$core.Deprecated('Use profileDataProblemDescriptor instead')
const ProfileDataProblem$json = {
  '1': 'ProfileDataProblem',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileDataProblemKind',
      '10': 'kind'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `ProfileDataProblem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataProblemDescriptor = $convert.base64Decode(
    'ChJQcm9maWxlRGF0YVByb2JsZW0SOwoEa2luZBgBIAEoDjInLm1vZGNvbmR1Y3Rvci52MS5Qcm'
    '9maWxlRGF0YVByb2JsZW1LaW5kUgRraW5kEhYKBmRldGFpbBgCIAEoCVIGZGV0YWls');

@$core.Deprecated('Use profileDataReplyDescriptor instead')
const ProfileDataReply$json = {
  '1': 'ProfileDataReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataState',
      '9': 0,
      '10': 'state'
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ProfileDataReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataReplyDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlRGF0YVJlcGx5EjkKBXN0YXRlGAEgASgLMiEubW9kY29uZHVjdG9yLnYxLlByb2'
    'ZpbGVEYXRhU3RhdGVIAFIFc3RhdGUSPwoHcHJvYmxlbRgCIAEoCzIjLm1vZGNvbmR1Y3Rvci52'
    'MS5Qcm9maWxlRGF0YVByb2JsZW1IAFIHcHJvYmxlbUIICgZyZXN1bHQ=');

@$core.Deprecated('Use profileDataProgressDescriptor instead')
const ProfileDataProgress$json = {
  '1': 'ProfileDataProgress',
  '2': [
    {'1': 'files', '3': 1, '4': 1, '5': 13, '10': 'files'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ProfileDataProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataProgressDescriptor = $convert.base64Decode(
    'ChNQcm9maWxlRGF0YVByb2dyZXNzEhQKBWZpbGVzGAEgASgNUgVmaWxlcxIUCgVieXRlcxgCIA'
    'EoBFIFYnl0ZXM=');

@$core.Deprecated('Use profileDataEventDescriptor instead')
const ProfileDataEvent$json = {
  '1': 'ProfileDataEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'result',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataActionResult',
      '9': 0,
      '10': 'result'
    },
    {
      '1': 'problem',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ProfileDataEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDataEventDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlRGF0YUV2ZW50EkIKCHByb2dyZXNzGAEgASgLMiQubW9kY29uZHVjdG9yLnYxLl'
    'Byb2ZpbGVEYXRhUHJvZ3Jlc3NIAFIIcHJvZ3Jlc3MSQgoGcmVzdWx0GAIgASgLMigubW9kY29u'
    'ZHVjdG9yLnYxLlByb2ZpbGVEYXRhQWN0aW9uUmVzdWx0SABSBnJlc3VsdBI/Cgdwcm9ibGVtGA'
    'MgASgLMiMubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVEYXRhUHJvYmxlbUgAUgdwcm9ibGVtQgcK'
    'BWV2ZW50');
