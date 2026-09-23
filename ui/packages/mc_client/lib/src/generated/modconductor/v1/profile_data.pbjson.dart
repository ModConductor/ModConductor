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

@$core.Deprecated('Use profileSaveSourceDescriptor instead')
const ProfileSaveSource$json = {
  '1': 'ProfileSaveSource',
  '2': [
    {'1': 'PROFILE_SAVE_SOURCE_UNSPECIFIED', '2': 0},
    {'1': 'PROFILE_SAVE_SOURCE_GLOBAL', '2': 1},
    {'1': 'PROFILE_SAVE_SOURCE_PROFILE', '2': 2},
  ],
};

/// Descriptor for `ProfileSaveSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List profileSaveSourceDescriptor = $convert.base64Decode(
    'ChFQcm9maWxlU2F2ZVNvdXJjZRIjCh9QUk9GSUxFX1NBVkVfU09VUkNFX1VOU1BFQ0lGSUVEEA'
    'ASHgoaUFJPRklMRV9TQVZFX1NPVVJDRV9HTE9CQUwQARIfChtQUk9GSUxFX1NBVkVfU09VUkNF'
    'X1BST0ZJTEUQAg==');

@$core.Deprecated('Use profileSaveEntryKindDescriptor instead')
const ProfileSaveEntryKind$json = {
  '1': 'ProfileSaveEntryKind',
  '2': [
    {'1': 'PROFILE_SAVE_ENTRY_KIND_UNSPECIFIED', '2': 0},
    {'1': 'PROFILE_SAVE_ENTRY_KIND_SAVE', '2': 1},
    {'1': 'PROFILE_SAVE_ENTRY_KIND_DIRECTORY', '2': 2},
    {'1': 'PROFILE_SAVE_ENTRY_KIND_OTHER', '2': 3},
  ],
};

/// Descriptor for `ProfileSaveEntryKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List profileSaveEntryKindDescriptor = $convert.base64Decode(
    'ChRQcm9maWxlU2F2ZUVudHJ5S2luZBInCiNQUk9GSUxFX1NBVkVfRU5UUllfS0lORF9VTlNQRU'
    'NJRklFRBAAEiAKHFBST0ZJTEVfU0FWRV9FTlRSWV9LSU5EX1NBVkUQARIlCiFQUk9GSUxFX1NB'
    'VkVfRU5UUllfS0lORF9ESVJFQ1RPUlkQAhIhCh1QUk9GSUxFX1NBVkVfRU5UUllfS0lORF9PVE'
    'hFUhAD');

@$core.Deprecated('Use skyrimSaveCompressionDescriptor instead')
const SkyrimSaveCompression$json = {
  '1': 'SkyrimSaveCompression',
  '2': [
    {'1': 'SKYRIM_SAVE_COMPRESSION_UNSPECIFIED', '2': 0},
    {'1': 'SKYRIM_SAVE_COMPRESSION_UNCOMPRESSED', '2': 1},
    {'1': 'SKYRIM_SAVE_COMPRESSION_ZLIB', '2': 2},
    {'1': 'SKYRIM_SAVE_COMPRESSION_LZ4', '2': 3},
  ],
};

/// Descriptor for `SkyrimSaveCompression`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skyrimSaveCompressionDescriptor = $convert.base64Decode(
    'ChVTa3lyaW1TYXZlQ29tcHJlc3Npb24SJwojU0tZUklNX1NBVkVfQ09NUFJFU1NJT05fVU5TUE'
    'VDSUZJRUQQABIoCiRTS1lSSU1fU0FWRV9DT01QUkVTU0lPTl9VTkNPTVBSRVNTRUQQARIgChxT'
    'S1lSSU1fU0FWRV9DT01QUkVTU0lPTl9aTElCEAISHwobU0tZUklNX1NBVkVfQ09NUFJFU1NJT0'
    '5fTFo0EAM=');

@$core.Deprecated('Use savePluginStateDescriptor instead')
const SavePluginState$json = {
  '1': 'SavePluginState',
  '2': [
    {'1': 'SAVE_PLUGIN_STATE_UNSPECIFIED', '2': 0},
    {'1': 'SAVE_PLUGIN_STATE_MISSING', '2': 1},
    {'1': 'SAVE_PLUGIN_STATE_INACTIVE', '2': 2},
  ],
};

/// Descriptor for `SavePluginState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List savePluginStateDescriptor = $convert.base64Decode(
    'Cg9TYXZlUGx1Z2luU3RhdGUSIQodU0FWRV9QTFVHSU5fU1RBVEVfVU5TUEVDSUZJRUQQABIdCh'
    'lTQVZFX1BMVUdJTl9TVEFURV9NSVNTSU5HEAESHgoaU0FWRV9QTFVHSU5fU1RBVEVfSU5BQ1RJ'
    'VkUQAg==');

@$core.Deprecated('Use profileSaveActionDescriptor instead')
const ProfileSaveAction$json = {
  '1': 'ProfileSaveAction',
  '2': [
    {'1': 'PROFILE_SAVE_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'PROFILE_SAVE_ACTION_COPY_TO_PROFILE', '2': 1},
    {'1': 'PROFILE_SAVE_ACTION_DELETE_FROM_PROFILE', '2': 2},
  ],
};

/// Descriptor for `ProfileSaveAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List profileSaveActionDescriptor = $convert.base64Decode(
    'ChFQcm9maWxlU2F2ZUFjdGlvbhIjCh9QUk9GSUxFX1NBVkVfQUNUSU9OX1VOU1BFQ0lGSUVEEA'
    'ASJwojUFJPRklMRV9TQVZFX0FDVElPTl9DT1BZX1RPX1BST0ZJTEUQARIrCidQUk9GSUxFX1NB'
    'VkVfQUNUSU9OX0RFTEVURV9GUk9NX1BST0ZJTEUQAg==');

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
    {
      '1': 'settings_initialized',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'settingsInitialized'
    },
    {
      '1': 'saves_initialized',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'savesInitialized'
    },
    {
      '1': 'pending_configuration',
      '3': 13,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'pendingConfiguration',
      '17': true
    },
  ],
  '8': [
    {'1': '_in_use_profile_id'},
    {'1': '_pending_action_id'},
    {'1': '_problem'},
    {'1': '_pending_configuration'},
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
    'cGVuZGluZ1Byb2ZpbGVDaGFuZ2USMQoUc2V0dGluZ3NfaW5pdGlhbGl6ZWQYCyABKAhSE3NldH'
    'RpbmdzSW5pdGlhbGl6ZWQSKwoRc2F2ZXNfaW5pdGlhbGl6ZWQYDCABKAhSEHNhdmVzSW5pdGlh'
    'bGl6ZWQSOAoVcGVuZGluZ19jb25maWd1cmF0aW9uGA0gASgJSANSFHBlbmRpbmdDb25maWd1cm'
    'F0aW9uiAEBQhQKEl9pbl91c2VfcHJvZmlsZV9pZEIUChJfcGVuZGluZ19hY3Rpb25faWRCCgoI'
    'X3Byb2JsZW1CGAoWX3BlbmRpbmdfY29uZmlndXJhdGlvbg==');

@$core.Deprecated('Use profileConfigurationFileDescriptor instead')
const ProfileConfigurationFile$json = {
  '1': 'ProfileConfigurationFile',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'exists', '3': 2, '4': 1, '5': 8, '10': 'exists'},
    {'1': 'bytes', '3': 3, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ProfileConfigurationFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationFileDescriptor =
    $convert.base64Decode(
        'ChhQcm9maWxlQ29uZmlndXJhdGlvbkZpbGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIWCgZleGlzdH'
        'MYAiABKAhSBmV4aXN0cxIUCgVieXRlcxgDIAEoBFIFYnl0ZXM=');

@$core.Deprecated('Use profileConfigurationListRequestDescriptor instead')
const ProfileConfigurationListRequest$json = {
  '1': 'ProfileConfigurationListRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
  ],
};

/// Descriptor for `ProfileConfigurationListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationListRequestDescriptor =
    $convert.base64Decode(
        'Ch9Qcm9maWxlQ29uZmlndXJhdGlvbkxpc3RSZXF1ZXN0EjsKCGV4cGVjdGVkGAEgASgLMh8ubW'
        '9kY29uZHVjdG9yLnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZA==');

@$core.Deprecated('Use profileConfigurationListDescriptor instead')
const ProfileConfigurationList$json = {
  '1': 'ProfileConfigurationList',
  '2': [
    {
      '1': 'files',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileConfigurationFile',
      '10': 'files'
    },
  ],
};

/// Descriptor for `ProfileConfigurationList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationListDescriptor =
    $convert.base64Decode(
        'ChhQcm9maWxlQ29uZmlndXJhdGlvbkxpc3QSPwoFZmlsZXMYASADKAsyKS5tb2Rjb25kdWN0b3'
        'IudjEuUHJvZmlsZUNvbmZpZ3VyYXRpb25GaWxlUgVmaWxlcw==');

@$core.Deprecated('Use profileConfigurationListReplyDescriptor instead')
const ProfileConfigurationListReply$json = {
  '1': 'ProfileConfigurationListReply',
  '2': [
    {
      '1': 'files',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileConfigurationList',
      '9': 0,
      '10': 'files'
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

/// Descriptor for `ProfileConfigurationListReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationListReplyDescriptor = $convert.base64Decode(
    'Ch1Qcm9maWxlQ29uZmlndXJhdGlvbkxpc3RSZXBseRJBCgVmaWxlcxgBIAEoCzIpLm1vZGNvbm'
    'R1Y3Rvci52MS5Qcm9maWxlQ29uZmlndXJhdGlvbkxpc3RIAFIFZmlsZXMSPwoHcHJvYmxlbRgC'
    'IAEoCzIjLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVByb2JsZW1IAFIHcHJvYmxlbUIICg'
    'ZyZXN1bHQ=');

@$core.Deprecated('Use profileConfigurationReadRequestDescriptor instead')
const ProfileConfigurationReadRequest$json = {
  '1': 'ProfileConfigurationReadRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ProfileConfigurationReadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationReadRequestDescriptor =
    $convert.base64Decode(
        'Ch9Qcm9maWxlQ29uZmlndXJhdGlvblJlYWRSZXF1ZXN0EjsKCGV4cGVjdGVkGAEgASgLMh8ubW'
        '9kY29uZHVjdG9yLnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZBISCgRuYW1lGAIgASgJUgRu'
        'YW1l');

@$core.Deprecated('Use profileConfigurationDocumentDescriptor instead')
const ProfileConfigurationDocument$json = {
  '1': 'ProfileConfigurationDocument',
  '2': [
    {'1': 'preview_id', '3': 1, '4': 1, '5': 9, '10': 'previewId'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'exists', '3': 4, '4': 1, '5': 8, '10': 'exists'},
    {'1': 'length', '3': 5, '4': 1, '5': 4, '10': 'length'},
    {'1': 'sha256', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'sha256', '17': true},
    {
      '1': 'document',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.TextDocument',
      '10': 'document'
    },
  ],
  '8': [
    {'1': '_sha256'},
  ],
};

/// Descriptor for `ProfileConfigurationDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationDocumentDescriptor = $convert.base64Decode(
    'ChxQcm9maWxlQ29uZmlndXJhdGlvbkRvY3VtZW50Eh0KCnByZXZpZXdfaWQYASABKAlSCXByZX'
    'ZpZXdJZBI7CghleHBlY3RlZBgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVJl'
    'ZlIIZXhwZWN0ZWQSEgoEbmFtZRgDIAEoCVIEbmFtZRIWCgZleGlzdHMYBCABKAhSBmV4aXN0cx'
    'IWCgZsZW5ndGgYBSABKARSBmxlbmd0aBIbCgZzaGEyNTYYBiABKAlIAFIGc2hhMjU2iAEBEjkK'
    'CGRvY3VtZW50GAcgASgLMh0ubW9kY29uZHVjdG9yLnYxLlRleHREb2N1bWVudFIIZG9jdW1lbn'
    'RCCQoHX3NoYTI1Ng==');

@$core.Deprecated('Use profileConfigurationReadReplyDescriptor instead')
const ProfileConfigurationReadReply$json = {
  '1': 'ProfileConfigurationReadReply',
  '2': [
    {
      '1': 'document',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileConfigurationDocument',
      '9': 0,
      '10': 'document'
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

/// Descriptor for `ProfileConfigurationReadReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationReadReplyDescriptor = $convert.base64Decode(
    'Ch1Qcm9maWxlQ29uZmlndXJhdGlvblJlYWRSZXBseRJLCghkb2N1bWVudBgBIAEoCzItLm1vZG'
    'NvbmR1Y3Rvci52MS5Qcm9maWxlQ29uZmlndXJhdGlvbkRvY3VtZW50SABSCGRvY3VtZW50Ej8K'
    'B3Byb2JsZW0YAiABKAsyIy5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZURhdGFQcm9ibGVtSABSB3'
    'Byb2JsZW1CCAoGcmVzdWx0');

@$core.Deprecated('Use profileConfigurationSaveRequestDescriptor instead')
const ProfileConfigurationSaveRequest$json = {
  '1': 'ProfileConfigurationSaveRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'preview_id', '3': 2, '4': 1, '5': 9, '10': 'previewId'},
    {
      '1': 'expected',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'content', '3': 5, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `ProfileConfigurationSaveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationSaveRequestDescriptor =
    $convert.base64Decode(
        'Ch9Qcm9maWxlQ29uZmlndXJhdGlvblNhdmVSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIdCgpwcm'
        'V2aWV3X2lkGAIgASgJUglwcmV2aWV3SWQSOwoIZXhwZWN0ZWQYAyABKAsyHy5tb2Rjb25kdWN0'
        'b3IudjEuUHJvZmlsZURhdGFSZWZSCGV4cGVjdGVkEhIKBG5hbWUYBCABKAlSBG5hbWUSGAoHY2'
        '9udGVudBgFIAEoCVIHY29udGVudA==');

@$core.Deprecated('Use profileConfigurationRestoreRequestDescriptor instead')
const ProfileConfigurationRestoreRequest$json = {
  '1': 'ProfileConfigurationRestoreRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'action_id', '3': 2, '4': 1, '5': 9, '10': 'actionId'},
  ],
};

/// Descriptor for `ProfileConfigurationRestoreRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileConfigurationRestoreRequestDescriptor =
    $convert.base64Decode(
        'CiJQcm9maWxlQ29uZmlndXJhdGlvblJlc3RvcmVSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIA'
        'EoCVILd29ya3NwYWNlSWQSGwoJYWN0aW9uX2lkGAIgASgJUghhY3Rpb25JZA==');

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
    {'1': 'no_change', '3': 6, '4': 1, '5': 8, '10': 'noChange'},
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
    'MSHQoHcHJvYmxlbRgFIAEoCUgAUgdwcm9ibGVtiAEBEhsKCW5vX2NoYW5nZRgGIAEoCFIIbm9D'
    'aGFuZ2VCCgoIX3Byb2JsZW0=');

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

@$core.Deprecated('Use profileSaveRequestDescriptor instead')
const ProfileSaveRequest$json = {
  '1': 'ProfileSaveRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'path', '3': 3, '4': 3, '5': 9, '10': 'path'},
    {'1': 'after', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'after', '17': true},
  ],
  '8': [
    {'1': '_after'},
  ],
};

/// Descriptor for `ProfileSaveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveRequestDescriptor = $convert.base64Decode(
    'ChJQcm9maWxlU2F2ZVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQSEgoEcGF0aBgDIAMoCVIEcGF0aBIZCgVh'
    'ZnRlchgEIAEoCUgAUgVhZnRlcogBAUIICgZfYWZ0ZXI=');

@$core.Deprecated('Use profileSaveEntryDescriptor instead')
const ProfileSaveEntry$json = {
  '1': 'ProfileSaveEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'directory', '3': 2, '4': 1, '5': 8, '10': 'directory'},
    {'1': 'bytes', '3': 3, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ProfileSaveEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveEntryDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlU2F2ZUVudHJ5EhIKBG5hbWUYASABKAlSBG5hbWUSHAoJZGlyZWN0b3J5GAIgAS'
    'gIUglkaXJlY3RvcnkSFAoFYnl0ZXMYAyABKARSBWJ5dGVz');

@$core.Deprecated('Use profileSavePageDescriptor instead')
const ProfileSavePage$json = {
  '1': 'ProfileSavePage',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveEntry',
      '10': 'entries'
    },
    {'1': 'next', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'next', '17': true},
  ],
  '8': [
    {'1': '_next'},
  ],
};

/// Descriptor for `ProfileSavePage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSavePageDescriptor = $convert.base64Decode(
    'Cg9Qcm9maWxlU2F2ZVBhZ2USOwoHZW50cmllcxgBIAMoCzIhLm1vZGNvbmR1Y3Rvci52MS5Qcm'
    '9maWxlU2F2ZUVudHJ5UgdlbnRyaWVzEhcKBG5leHQYAiABKAlIAFIEbmV4dIgBAUIHCgVfbmV4'
    'dA==');

@$core.Deprecated('Use profileSaveReplyDescriptor instead')
const ProfileSaveReply$json = {
  '1': 'ProfileSaveReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSavePage',
      '9': 0,
      '10': 'page'
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

/// Descriptor for `ProfileSaveReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveReplyDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlU2F2ZVJlcGx5EjYKBHBhZ2UYASABKAsyIC5tb2Rjb25kdWN0b3IudjEuUHJvZm'
    'lsZVNhdmVQYWdlSABSBHBhZ2USPwoHcHJvYmxlbRgCIAEoCzIjLm1vZGNvbmR1Y3Rvci52MS5Q'
    'cm9maWxlRGF0YVByb2JsZW1IAFIHcHJvYmxlbUIICgZyZXN1bHQ=');

@$core.Deprecated('Use profileSavePathDescriptor instead')
const ProfileSavePath$json = {
  '1': 'ProfileSavePath',
  '2': [
    {'1': 'host_path', '3': 1, '4': 1, '5': 9, '10': 'hostPath'},
    {
      '1': 'windows_path',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'windowsPath',
      '17': true
    },
  ],
  '8': [
    {'1': '_windows_path'},
  ],
};

/// Descriptor for `ProfileSavePath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSavePathDescriptor = $convert.base64Decode(
    'Cg9Qcm9maWxlU2F2ZVBhdGgSGwoJaG9zdF9wYXRoGAEgASgJUghob3N0UGF0aBImCgx3aW5kb3'
    'dzX3BhdGgYAiABKAlIAFILd2luZG93c1BhdGiIAQFCDwoNX3dpbmRvd3NfcGF0aA==');

@$core.Deprecated('Use profileSaveGroupRequestDescriptor instead')
const ProfileSaveGroupRequest$json = {
  '1': 'ProfileSaveGroupRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveSource',
      '10': 'source'
    },
    {'1': 'after', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'after', '17': true},
  ],
  '8': [
    {'1': '_after'},
  ],
};

/// Descriptor for `ProfileSaveGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveGroupRequestDescriptor = $convert.base64Decode(
    'ChdQcm9maWxlU2F2ZUdyb3VwUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcG'
    'FjZUlkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBI6CgZzb3VyY2UYAyABKA4yIi5t'
    'b2Rjb25kdWN0b3IudjEuUHJvZmlsZVNhdmVTb3VyY2VSBnNvdXJjZRIZCgVhZnRlchgEIAEoCU'
    'gAUgVhZnRlcogBAUIICgZfYWZ0ZXI=');

@$core.Deprecated('Use profileSaveGroupEntryDescriptor instead')
const ProfileSaveGroupEntry$json = {
  '1': 'ProfileSaveGroupEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveEntryKind',
      '10': 'kind'
    },
    {'1': 'bytes', '3': 4, '4': 1, '5': 4, '10': 'bytes'},
    {
      '1': 'companion',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'companion',
      '17': true
    },
    {'1': 'companion_bytes', '3': 6, '4': 1, '5': 4, '10': 'companionBytes'},
    {'1': 'actionable', '3': 7, '4': 1, '5': 8, '10': 'actionable'},
    {
      '1': 'problem',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'problem',
      '17': true
    },
  ],
  '8': [
    {'1': '_companion'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `ProfileSaveGroupEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveGroupEntryDescriptor = $convert.base64Decode(
    'ChVQcm9maWxlU2F2ZUdyb3VwRW50cnkSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG'
    '5hbWUSOQoEa2luZBgDIAEoDjIlLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlU2F2ZUVudHJ5S2lu'
    'ZFIEa2luZBIUCgVieXRlcxgEIAEoBFIFYnl0ZXMSIQoJY29tcGFuaW9uGAUgASgJSABSCWNvbX'
    'BhbmlvbogBARInCg9jb21wYW5pb25fYnl0ZXMYBiABKARSDmNvbXBhbmlvbkJ5dGVzEh4KCmFj'
    'dGlvbmFibGUYByABKAhSCmFjdGlvbmFibGUSHQoHcHJvYmxlbRgIIAEoCUgBUgdwcm9ibGVtiA'
    'EBQgwKCl9jb21wYW5pb25CCgoIX3Byb2JsZW0=');

@$core.Deprecated('Use profileSaveGroupPageDescriptor instead')
const ProfileSaveGroupPage$json = {
  '1': 'ProfileSaveGroupPage',
  '2': [
    {
      '1': 'source',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveSource',
      '10': 'source'
    },
    {
      '1': 'path',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSavePath',
      '10': 'path'
    },
    {
      '1': 'entries',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveGroupEntry',
      '10': 'entries'
    },
    {'1': 'next', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'next', '17': true},
  ],
  '8': [
    {'1': '_next'},
  ],
};

/// Descriptor for `ProfileSaveGroupPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveGroupPageDescriptor = $convert.base64Decode(
    'ChRQcm9maWxlU2F2ZUdyb3VwUGFnZRI6CgZzb3VyY2UYASABKA4yIi5tb2Rjb25kdWN0b3Iudj'
    'EuUHJvZmlsZVNhdmVTb3VyY2VSBnNvdXJjZRI0CgRwYXRoGAIgASgLMiAubW9kY29uZHVjdG9y'
    'LnYxLlByb2ZpbGVTYXZlUGF0aFIEcGF0aBJACgdlbnRyaWVzGAMgAygLMiYubW9kY29uZHVjdG'
    '9yLnYxLlByb2ZpbGVTYXZlR3JvdXBFbnRyeVIHZW50cmllcxIXCgRuZXh0GAQgASgJSABSBG5l'
    'eHSIAQFCBwoFX25leHQ=');

@$core.Deprecated('Use profileSaveGroupReplyDescriptor instead')
const ProfileSaveGroupReply$json = {
  '1': 'ProfileSaveGroupReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveGroupPage',
      '9': 0,
      '10': 'page'
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

/// Descriptor for `ProfileSaveGroupReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveGroupReplyDescriptor = $convert.base64Decode(
    'ChVQcm9maWxlU2F2ZUdyb3VwUmVwbHkSOwoEcGFnZRgBIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS'
    '5Qcm9maWxlU2F2ZUdyb3VwUGFnZUgAUgRwYWdlEj8KB3Byb2JsZW0YAiABKAsyIy5tb2Rjb25k'
    'dWN0b3IudjEuUHJvZmlsZURhdGFQcm9ibGVtSABSB3Byb2JsZW1CCAoGcmVzdWx0');

@$core.Deprecated('Use skyrimSaveMetadataDescriptor instead')
const SkyrimSaveMetadata$json = {
  '1': 'SkyrimSaveMetadata',
  '2': [
    {'1': 'header_version', '3': 1, '4': 1, '5': 13, '10': 'headerVersion'},
    {'1': 'form_version', '3': 2, '4': 1, '5': 13, '10': 'formVersion'},
    {
      '1': 'compression',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SkyrimSaveCompression',
      '10': 'compression'
    },
    {'1': 'save_number', '3': 4, '4': 1, '5': 13, '10': 'saveNumber'},
    {'1': 'character', '3': 5, '4': 1, '5': 9, '10': 'character'},
    {'1': 'level', '3': 6, '4': 1, '5': 13, '10': 'level'},
    {'1': 'location', '3': 7, '4': 1, '5': 9, '10': 'location'},
    {'1': 'game_time', '3': 8, '4': 1, '5': 9, '10': 'gameTime'},
    {'1': 'full_plugins', '3': 9, '4': 3, '5': 9, '10': 'fullPlugins'},
    {'1': 'light_plugins', '3': 10, '4': 3, '5': 9, '10': 'lightPlugins'},
  ],
};

/// Descriptor for `SkyrimSaveMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skyrimSaveMetadataDescriptor = $convert.base64Decode(
    'ChJTa3lyaW1TYXZlTWV0YWRhdGESJQoOaGVhZGVyX3ZlcnNpb24YASABKA1SDWhlYWRlclZlcn'
    'Npb24SIQoMZm9ybV92ZXJzaW9uGAIgASgNUgtmb3JtVmVyc2lvbhJICgtjb21wcmVzc2lvbhgD'
    'IAEoDjImLm1vZGNvbmR1Y3Rvci52MS5Ta3lyaW1TYXZlQ29tcHJlc3Npb25SC2NvbXByZXNzaW'
    '9uEh8KC3NhdmVfbnVtYmVyGAQgASgNUgpzYXZlTnVtYmVyEhwKCWNoYXJhY3RlchgFIAEoCVIJ'
    'Y2hhcmFjdGVyEhQKBWxldmVsGAYgASgNUgVsZXZlbBIaCghsb2NhdGlvbhgHIAEoCVIIbG9jYX'
    'Rpb24SGwoJZ2FtZV90aW1lGAggASgJUghnYW1lVGltZRIhCgxmdWxsX3BsdWdpbnMYCSADKAlS'
    'C2Z1bGxQbHVnaW5zEiMKDWxpZ2h0X3BsdWdpbnMYCiADKAlSDGxpZ2h0UGx1Z2lucw==');

@$core.Deprecated('Use savePluginIssueDescriptor instead')
const SavePluginIssue$json = {
  '1': 'SavePluginIssue',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SavePluginState',
      '10': 'state'
    },
    {'1': 'source', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'source', '17': true},
  ],
  '8': [
    {'1': '_source'},
  ],
};

/// Descriptor for `SavePluginIssue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savePluginIssueDescriptor = $convert.base64Decode(
    'Cg9TYXZlUGx1Z2luSXNzdWUSEgoEbmFtZRgBIAEoCVIEbmFtZRI2CgVzdGF0ZRgCIAEoDjIgLm'
    '1vZGNvbmR1Y3Rvci52MS5TYXZlUGx1Z2luU3RhdGVSBXN0YXRlEhsKBnNvdXJjZRgDIAEoCUgA'
    'UgZzb3VyY2WIAQFCCQoHX3NvdXJjZQ==');

@$core.Deprecated('Use profileSaveInspectRequestDescriptor instead')
const ProfileSaveInspectRequest$json = {
  '1': 'ProfileSaveInspectRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveSource',
      '10': 'source'
    },
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'headers_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'headersId',
      '17': true
    },
  ],
  '8': [
    {'1': '_headers_id'},
  ],
};

/// Descriptor for `ProfileSaveInspectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveInspectRequestDescriptor = $convert.base64Decode(
    'ChlQcm9maWxlU2F2ZUluc3BlY3RSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3'
    'NwYWNlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEjoKBnNvdXJjZRgDIAEoDjIi'
    'Lm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlU2F2ZVNvdXJjZVIGc291cmNlEhIKBG5hbWUYBCABKA'
    'lSBG5hbWUSIgoKaGVhZGVyc19pZBgFIAEoCUgAUgloZWFkZXJzSWSIAQFCDQoLX2hlYWRlcnNf'
    'aWQ=');

@$core.Deprecated('Use profileSaveInspectionDescriptor instead')
const ProfileSaveInspection$json = {
  '1': 'ProfileSaveInspection',
  '2': [
    {
      '1': 'source',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveSource',
      '10': 'source'
    },
    {
      '1': 'path',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSavePath',
      '10': 'path'
    },
    {
      '1': 'entry',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveGroupEntry',
      '10': 'entry'
    },
    {
      '1': 'metadata',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SkyrimSaveMetadata',
      '9': 0,
      '10': 'metadata',
      '17': true
    },
    {
      '1': 'metadata_problem',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'metadataProblem',
      '17': true
    },
    {
      '1': 'plugin_issues',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SavePluginIssue',
      '10': 'pluginIssues'
    },
    {
      '1': 'plugin_check_problem',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'pluginCheckProblem',
      '17': true
    },
  ],
  '8': [
    {'1': '_metadata'},
    {'1': '_metadata_problem'},
    {'1': '_plugin_check_problem'},
  ],
};

/// Descriptor for `ProfileSaveInspection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveInspectionDescriptor = $convert.base64Decode(
    'ChVQcm9maWxlU2F2ZUluc3BlY3Rpb24SOgoGc291cmNlGAEgASgOMiIubW9kY29uZHVjdG9yLn'
    'YxLlByb2ZpbGVTYXZlU291cmNlUgZzb3VyY2USNAoEcGF0aBgCIAEoCzIgLm1vZGNvbmR1Y3Rv'
    'ci52MS5Qcm9maWxlU2F2ZVBhdGhSBHBhdGgSPAoFZW50cnkYAyABKAsyJi5tb2Rjb25kdWN0b3'
    'IudjEuUHJvZmlsZVNhdmVHcm91cEVudHJ5UgVlbnRyeRJECghtZXRhZGF0YRgEIAEoCzIjLm1v'
    'ZGNvbmR1Y3Rvci52MS5Ta3lyaW1TYXZlTWV0YWRhdGFIAFIIbWV0YWRhdGGIAQESLgoQbWV0YW'
    'RhdGFfcHJvYmxlbRgFIAEoCUgBUg9tZXRhZGF0YVByb2JsZW2IAQESRQoNcGx1Z2luX2lzc3Vl'
    'cxgGIAMoCzIgLm1vZGNvbmR1Y3Rvci52MS5TYXZlUGx1Z2luSXNzdWVSDHBsdWdpbklzc3Vlcx'
    'I1ChRwbHVnaW5fY2hlY2tfcHJvYmxlbRgHIAEoCUgCUhJwbHVnaW5DaGVja1Byb2JsZW2IAQFC'
    'CwoJX21ldGFkYXRhQhMKEV9tZXRhZGF0YV9wcm9ibGVtQhcKFV9wbHVnaW5fY2hlY2tfcHJvYm'
    'xlbQ==');

@$core.Deprecated('Use profileSaveInspectReplyDescriptor instead')
const ProfileSaveInspectReply$json = {
  '1': 'ProfileSaveInspectReply',
  '2': [
    {
      '1': 'inspection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveInspection',
      '9': 0,
      '10': 'inspection'
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

/// Descriptor for `ProfileSaveInspectReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveInspectReplyDescriptor = $convert.base64Decode(
    'ChdQcm9maWxlU2F2ZUluc3BlY3RSZXBseRJICgppbnNwZWN0aW9uGAEgASgLMiYubW9kY29uZH'
    'VjdG9yLnYxLlByb2ZpbGVTYXZlSW5zcGVjdGlvbkgAUgppbnNwZWN0aW9uEj8KB3Byb2JsZW0Y'
    'AiABKAsyIy5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZURhdGFQcm9ibGVtSABSB3Byb2JsZW1CCA'
    'oGcmVzdWx0');

@$core.Deprecated('Use profileSaveActionFileDescriptor instead')
const ProfileSaveActionFile$json = {
  '1': 'ProfileSaveActionFile',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ProfileSaveActionFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveActionFileDescriptor = $convert.base64Decode(
    'ChVQcm9maWxlU2F2ZUFjdGlvbkZpbGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIUCgVieXRlcxgCIA'
    'EoBFIFYnl0ZXM=');

@$core.Deprecated('Use profileSaveActionPreviewRequestDescriptor instead')
const ProfileSaveActionPreviewRequest$json = {
  '1': 'ProfileSaveActionPreviewRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {
      '1': 'action',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveAction',
      '10': 'action'
    },
    {'1': 'names', '3': 3, '4': 3, '5': 9, '10': 'names'},
  ],
};

/// Descriptor for `ProfileSaveActionPreviewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveActionPreviewRequestDescriptor =
    $convert.base64Decode(
        'Ch9Qcm9maWxlU2F2ZUFjdGlvblByZXZpZXdSZXF1ZXN0EjsKCGV4cGVjdGVkGAEgASgLMh8ubW'
        '9kY29uZHVjdG9yLnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZBI6CgZhY3Rpb24YAiABKA4y'
        'Ii5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZVNhdmVBY3Rpb25SBmFjdGlvbhIUCgVuYW1lcxgDIA'
        'MoCVIFbmFtZXM=');

@$core.Deprecated('Use profileSaveActionPreviewDescriptor instead')
const ProfileSaveActionPreview$json = {
  '1': 'ProfileSaveActionPreview',
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
      '1': 'action',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileSaveAction',
      '10': 'action'
    },
    {
      '1': 'source',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSavePath',
      '10': 'source'
    },
    {
      '1': 'destination',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSavePath',
      '9': 0,
      '10': 'destination',
      '17': true
    },
    {
      '1': 'files',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveActionFile',
      '10': 'files'
    },
    {'1': 'bytes', '3': 7, '4': 1, '5': 4, '10': 'bytes'},
  ],
  '8': [
    {'1': '_destination'},
  ],
};

/// Descriptor for `ProfileSaveActionPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveActionPreviewDescriptor = $convert.base64Decode(
    'ChhQcm9maWxlU2F2ZUFjdGlvblByZXZpZXcSDgoCaWQYASABKAlSAmlkEjsKCGV4cGVjdGVkGA'
    'IgASgLMh8ubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZBI6CgZhY3Rp'
    'b24YAyABKA4yIi5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZVNhdmVBY3Rpb25SBmFjdGlvbhI4Cg'
    'Zzb3VyY2UYBCABKAsyIC5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZVNhdmVQYXRoUgZzb3VyY2US'
    'RwoLZGVzdGluYXRpb24YBSABKAsyIC5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZVNhdmVQYXRoSA'
    'BSC2Rlc3RpbmF0aW9uiAEBEjwKBWZpbGVzGAYgAygLMiYubW9kY29uZHVjdG9yLnYxLlByb2Zp'
    'bGVTYXZlQWN0aW9uRmlsZVIFZmlsZXMSFAoFYnl0ZXMYByABKARSBWJ5dGVzQg4KDF9kZXN0aW'
    '5hdGlvbg==');

@$core.Deprecated('Use profileSaveActionPreviewReplyDescriptor instead')
const ProfileSaveActionPreviewReply$json = {
  '1': 'ProfileSaveActionPreviewReply',
  '2': [
    {
      '1': 'preview',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileSaveActionPreview',
      '9': 0,
      '10': 'preview'
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

/// Descriptor for `ProfileSaveActionPreviewReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveActionPreviewReplyDescriptor = $convert.base64Decode(
    'Ch1Qcm9maWxlU2F2ZUFjdGlvblByZXZpZXdSZXBseRJFCgdwcmV2aWV3GAEgASgLMikubW9kY2'
    '9uZHVjdG9yLnYxLlByb2ZpbGVTYXZlQWN0aW9uUHJldmlld0gAUgdwcmV2aWV3Ej8KB3Byb2Js'
    'ZW0YAiABKAsyIy5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZURhdGFQcm9ibGVtSABSB3Byb2JsZW'
    '1CCAoGcmVzdWx0');

@$core.Deprecated('Use profileSaveActionApplyRequestDescriptor instead')
const ProfileSaveActionApplyRequest$json = {
  '1': 'ProfileSaveActionApplyRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'preview_id', '3': 2, '4': 1, '5': 9, '10': 'previewId'},
    {
      '1': 'expected',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
  ],
};

/// Descriptor for `ProfileSaveActionApplyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSaveActionApplyRequestDescriptor =
    $convert.base64Decode(
        'Ch1Qcm9maWxlU2F2ZUFjdGlvbkFwcGx5UmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSHQoKcHJldm'
        'lld19pZBgCIAEoCVIJcHJldmlld0lkEjsKCGV4cGVjdGVkGAMgASgLMh8ubW9kY29uZHVjdG9y'
        'LnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZA==');
