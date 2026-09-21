// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_contexts.proto.

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

@$core.Deprecated('Use gameContextPlatformDescriptor instead')
const GameContextPlatform$json = {
  '1': 'GameContextPlatform',
  '2': [
    {'1': 'GAME_CONTEXT_PLATFORM_UNSPECIFIED', '2': 0},
    {'1': 'GAME_CONTEXT_PLATFORM_WINDOWS', '2': 1},
    {'1': 'GAME_CONTEXT_PLATFORM_PROTON', '2': 2},
  ],
};

/// Descriptor for `GameContextPlatform`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gameContextPlatformDescriptor = $convert.base64Decode(
    'ChNHYW1lQ29udGV4dFBsYXRmb3JtEiUKIUdBTUVfQ09OVEVYVF9QTEFURk9STV9VTlNQRUNJRk'
    'lFRBAAEiEKHUdBTUVfQ09OVEVYVF9QTEFURk9STV9XSU5ET1dTEAESIAocR0FNRV9DT05URVhU'
    'X1BMQVRGT1JNX1BST1RPThAC');

@$core.Deprecated('Use gameCapabilityKindDescriptor instead')
const GameCapabilityKind$json = {
  '1': 'GameCapabilityKind',
  '2': [
    {'1': 'GAME_CAPABILITY_KIND_UNSPECIFIED', '2': 0},
    {'1': 'GAME_CAPABILITY_KIND_CORE_OUTCOME', '2': 1},
    {'1': 'GAME_CAPABILITY_KIND_GAME_ADAPTER', '2': 2},
    {'1': 'GAME_CAPABILITY_KIND_OPTIONAL_LEGACY', '2': 3},
    {'1': 'GAME_CAPABILITY_KIND_OBSOLETE_MECHANISM', '2': 4},
  ],
};

/// Descriptor for `GameCapabilityKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gameCapabilityKindDescriptor = $convert.base64Decode(
    'ChJHYW1lQ2FwYWJpbGl0eUtpbmQSJAogR0FNRV9DQVBBQklMSVRZX0tJTkRfVU5TUEVDSUZJRU'
    'QQABIlCiFHQU1FX0NBUEFCSUxJVFlfS0lORF9DT1JFX09VVENPTUUQARIlCiFHQU1FX0NBUEFC'
    'SUxJVFlfS0lORF9HQU1FX0FEQVBURVIQAhIoCiRHQU1FX0NBUEFCSUxJVFlfS0lORF9PUFRJT0'
    '5BTF9MRUdBQ1kQAxIrCidHQU1FX0NBUEFCSUxJVFlfS0lORF9PQlNPTEVURV9NRUNIQU5JU00Q'
    'BA==');

@$core.Deprecated('Use gameCapabilityDispositionDescriptor instead')
const GameCapabilityDisposition$json = {
  '1': 'GameCapabilityDisposition',
  '2': [
    {'1': 'GAME_CAPABILITY_DISPOSITION_UNSPECIFIED', '2': 0},
    {'1': 'GAME_CAPABILITY_DISPOSITION_AVAILABLE', '2': 1},
    {'1': 'GAME_CAPABILITY_DISPOSITION_UNAVAILABLE', '2': 2},
    {'1': 'GAME_CAPABILITY_DISPOSITION_UNSUPPORTED', '2': 3},
  ],
};

/// Descriptor for `GameCapabilityDisposition`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gameCapabilityDispositionDescriptor = $convert.base64Decode(
    'ChlHYW1lQ2FwYWJpbGl0eURpc3Bvc2l0aW9uEisKJ0dBTUVfQ0FQQUJJTElUWV9ESVNQT1NJVE'
    'lPTl9VTlNQRUNJRklFRBAAEikKJUdBTUVfQ0FQQUJJTElUWV9ESVNQT1NJVElPTl9BVkFJTEFC'
    'TEUQARIrCidHQU1FX0NBUEFCSUxJVFlfRElTUE9TSVRJT05fVU5BVkFJTEFCTEUQAhIrCidHQU'
    '1FX0NBUEFCSUxJVFlfRElTUE9TSVRJT05fVU5TVVBQT1JURUQQAw==');

@$core.Deprecated('Use gameContextFaultCodeDescriptor instead')
const GameContextFaultCode$json = {
  '1': 'GameContextFaultCode',
  '2': [
    {'1': 'GAME_CONTEXT_FAULT_UNSPECIFIED', '2': 0},
    {'1': 'GAME_CONTEXT_FAULT_NOT_FOUND', '2': 1},
    {'1': 'GAME_CONTEXT_FAULT_STALE_REVISION', '2': 2},
    {'1': 'GAME_CONTEXT_FAULT_WORKSPACE_UNAVAILABLE', '2': 3},
    {'1': 'GAME_CONTEXT_FAULT_INVALID_INSTALLATION', '2': 4},
    {'1': 'GAME_CONTEXT_FAULT_BUSY', '2': 5},
  ],
};

/// Descriptor for `GameContextFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gameContextFaultCodeDescriptor = $convert.base64Decode(
    'ChRHYW1lQ29udGV4dEZhdWx0Q29kZRIiCh5HQU1FX0NPTlRFWFRfRkFVTFRfVU5TUEVDSUZJRU'
    'QQABIgChxHQU1FX0NPTlRFWFRfRkFVTFRfTk9UX0ZPVU5EEAESJQohR0FNRV9DT05URVhUX0ZB'
    'VUxUX1NUQUxFX1JFVklTSU9OEAISLAooR0FNRV9DT05URVhUX0ZBVUxUX1dPUktTUEFDRV9VTk'
    'FWQUlMQUJMRRADEisKJ0dBTUVfQ09OVEVYVF9GQVVMVF9JTlZBTElEX0lOU1RBTExBVElPThAE'
    'EhsKF0dBTUVfQ09OVEVYVF9GQVVMVF9CVVNZEAU=');

@$core.Deprecated('Use readGameContextRequestDescriptor instead')
const ReadGameContextRequest$json = {
  '1': 'ReadGameContextRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `ReadGameContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readGameContextRequestDescriptor =
    $convert.base64Decode(
        'ChZSZWFkR2FtZUNvbnRleHRSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
        'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use saveGameContextRequestDescriptor instead')
const SaveGameContextRequest$json = {
  '1': 'SaveGameContextRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'proton',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonSelectionInfo',
      '10': 'proton'
    },
    {'1': 'profile_id', '3': 5, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'game_id', '3': 6, '4': 1, '5': 9, '10': 'gameId'},
  ],
};

/// Descriptor for `SaveGameContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveGameContextRequestDescriptor = $convert.base64Decode(
    'ChZTYXZlR2FtZUNvbnRleHRSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSKwoRZXhwZWN0ZWRfcmV2aXNpb24YAiABKARSEGV4cGVjdGVkUmV2aXNpb24SEgoEcGF0'
    'aBgDIAEoCVIEcGF0aBI8CgZwcm90b24YBCABKAsyJC5tb2Rjb25kdWN0b3IudjEuUHJvdG9uU2'
    'VsZWN0aW9uSW5mb1IGcHJvdG9uEh0KCnByb2ZpbGVfaWQYBSABKAlSCXByb2ZpbGVJZBIXCgdn'
    'YW1lX2lkGAYgASgJUgZnYW1lSWQ=');

@$core.Deprecated('Use refreshGameContextRequestDescriptor instead')
const RefreshGameContextRequest$json = {
  '1': 'RefreshGameContextRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `RefreshGameContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshGameContextRequestDescriptor = $convert.base64Decode(
    'ChlSZWZyZXNoR2FtZUNvbnRleHRSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3'
    'NwYWNlSWQSKwoRZXhwZWN0ZWRfcmV2aXNpb24YAiABKARSEGV4cGVjdGVkUmV2aXNpb24SHQoK'
    'cHJvZmlsZV9pZBgDIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use gameDefinitionInfoDescriptor instead')
const GameDefinitionInfo$json = {
  '1': 'GameDefinitionInfo',
  '2': [
    {'1': 'definition_id', '3': 1, '4': 1, '5': 9, '10': 'definitionId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 13, '10': 'revision'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'storefront', '3': 4, '4': 1, '5': 9, '10': 'storefront'},
    {
      '1': 'declared_steam_app_id',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'declaredSteamAppId'
    },
    {
      '1': 'unavailable_capabilities',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.UnavailableGameCapability',
      '10': 'unavailableCapabilities'
    },
    {
      '1': 'capabilities',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.GameCapabilityInfo',
      '10': 'capabilities'
    },
  ],
};

/// Descriptor for `GameDefinitionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameDefinitionInfoDescriptor = $convert.base64Decode(
    'ChJHYW1lRGVmaW5pdGlvbkluZm8SIwoNZGVmaW5pdGlvbl9pZBgBIAEoCVIMZGVmaW5pdGlvbk'
    'lkEhoKCHJldmlzaW9uGAIgASgNUghyZXZpc2lvbhISCgRuYW1lGAMgASgJUgRuYW1lEh4KCnN0'
    'b3JlZnJvbnQYBCABKAlSCnN0b3JlZnJvbnQSMQoVZGVjbGFyZWRfc3RlYW1fYXBwX2lkGAUgAS'
    'gNUhJkZWNsYXJlZFN0ZWFtQXBwSWQSZQoYdW5hdmFpbGFibGVfY2FwYWJpbGl0aWVzGAYgAygL'
    'MioubW9kY29uZHVjdG9yLnYxLlVuYXZhaWxhYmxlR2FtZUNhcGFiaWxpdHlSF3VuYXZhaWxhYm'
    'xlQ2FwYWJpbGl0aWVzEkcKDGNhcGFiaWxpdGllcxgHIAMoCzIjLm1vZGNvbmR1Y3Rvci52MS5H'
    'YW1lQ2FwYWJpbGl0eUluZm9SDGNhcGFiaWxpdGllcw==');

@$core.Deprecated('Use unavailableGameCapabilityDescriptor instead')
const UnavailableGameCapability$json = {
  '1': 'UnavailableGameCapability',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `UnavailableGameCapability`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unavailableGameCapabilityDescriptor =
    $convert.base64Decode(
        'ChlVbmF2YWlsYWJsZUdhbWVDYXBhYmlsaXR5EhIKBG5hbWUYASABKAlSBG5hbWUSFgoGcmVhc2'
        '9uGAIgASgJUgZyZWFzb24=');

@$core.Deprecated('Use gameCapabilityContextDescriptor instead')
const GameCapabilityContext$json = {
  '1': 'GameCapabilityContext',
  '2': [
    {'1': 'definition_id', '3': 1, '4': 1, '5': 9, '10': 'definitionId'},
    {
      '1': 'platforms',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.modconductor.v1.GameContextPlatform',
      '10': 'platforms'
    },
  ],
};

/// Descriptor for `GameCapabilityContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameCapabilityContextDescriptor = $convert.base64Decode(
    'ChVHYW1lQ2FwYWJpbGl0eUNvbnRleHQSIwoNZGVmaW5pdGlvbl9pZBgBIAEoCVIMZGVmaW5pdG'
    'lvbklkEkIKCXBsYXRmb3JtcxgCIAMoDjIkLm1vZGNvbmR1Y3Rvci52MS5HYW1lQ29udGV4dFBs'
    'YXRmb3JtUglwbGF0Zm9ybXM=');

@$core.Deprecated('Use gameCapabilityInfoDescriptor instead')
const GameCapabilityInfo$json = {
  '1': 'GameCapabilityInfo',
  '2': [
    {'1': 'capability_id', '3': 1, '4': 1, '5': 9, '10': 'capabilityId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 13, '10': 'revision'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.GameCapabilityKind',
      '10': 'kind'
    },
    {
      '1': 'contexts',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.GameCapabilityContext',
      '10': 'contexts'
    },
    {
      '1': 'disposition',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.GameCapabilityDisposition',
      '10': 'disposition'
    },
    {'1': 'reason', '3': 7, '4': 1, '5': 9, '9': 0, '10': 'reason', '17': true},
  ],
  '8': [
    {'1': '_reason'},
  ],
};

/// Descriptor for `GameCapabilityInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameCapabilityInfoDescriptor = $convert.base64Decode(
    'ChJHYW1lQ2FwYWJpbGl0eUluZm8SIwoNY2FwYWJpbGl0eV9pZBgBIAEoCVIMY2FwYWJpbGl0eU'
    'lkEhoKCHJldmlzaW9uGAIgASgNUghyZXZpc2lvbhISCgRuYW1lGAMgASgJUgRuYW1lEjcKBGtp'
    'bmQYBCABKA4yIy5tb2Rjb25kdWN0b3IudjEuR2FtZUNhcGFiaWxpdHlLaW5kUgRraW5kEkIKCG'
    'NvbnRleHRzGAUgAygLMiYubW9kY29uZHVjdG9yLnYxLkdhbWVDYXBhYmlsaXR5Q29udGV4dFII'
    'Y29udGV4dHMSTAoLZGlzcG9zaXRpb24YBiABKA4yKi5tb2Rjb25kdWN0b3IudjEuR2FtZUNhcG'
    'FiaWxpdHlEaXNwb3NpdGlvblILZGlzcG9zaXRpb24SGwoGcmVhc29uGAcgASgJSABSBnJlYXNv'
    'bogBAUIJCgdfcmVhc29u');

@$core.Deprecated('Use gameLocationDescriptor instead')
const GameLocation$json = {
  '1': 'GameLocation',
  '2': [
    {
      '1': 'located',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LocatedGameFolder',
      '9': 0,
      '10': 'located'
    },
    {
      '1': 'unavailable_reason',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'unavailableReason'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `GameLocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameLocationDescriptor = $convert.base64Decode(
    'CgxHYW1lTG9jYXRpb24SPgoHbG9jYXRlZBgBIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5Mb2NhdG'
    'VkR2FtZUZvbGRlckgAUgdsb2NhdGVkEi8KEnVuYXZhaWxhYmxlX3JlYXNvbhgCIAEoCUgAUhF1'
    'bmF2YWlsYWJsZVJlYXNvbkIICgZyZXN1bHQ=');

@$core.Deprecated('Use locatedGameFolderDescriptor instead')
const LocatedGameFolder$json = {
  '1': 'LocatedGameFolder',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'exists', '3': 2, '4': 1, '5': 8, '10': 'exists'},
  ],
};

/// Descriptor for `LocatedGameFolder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locatedGameFolderDescriptor = $convert.base64Decode(
    'ChFMb2NhdGVkR2FtZUZvbGRlchISCgRwYXRoGAEgASgJUgRwYXRoEhYKBmV4aXN0cxgCIAEoCF'
    'IGZXhpc3Rz');

@$core.Deprecated('Use gameExecutableEvidenceDescriptor instead')
const GameExecutableEvidence$json = {
  '1': 'GameExecutableEvidence',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'sha256', '3': 2, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'length', '3': 3, '4': 1, '5': 4, '10': 'length'},
    {'1': 'file_version', '3': 4, '4': 1, '5': 9, '10': 'fileVersion'},
    {'1': 'product_version', '3': 5, '4': 1, '5': 9, '10': 'productVersion'},
  ],
};

/// Descriptor for `GameExecutableEvidence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameExecutableEvidenceDescriptor = $convert.base64Decode(
    'ChZHYW1lRXhlY3V0YWJsZUV2aWRlbmNlEhIKBHBhdGgYASABKAlSBHBhdGgSFgoGc2hhMjU2GA'
    'IgASgJUgZzaGEyNTYSFgoGbGVuZ3RoGAMgASgEUgZsZW5ndGgSIQoMZmlsZV92ZXJzaW9uGAQg'
    'ASgJUgtmaWxlVmVyc2lvbhInCg9wcm9kdWN0X3ZlcnNpb24YBSABKAlSDnByb2R1Y3RWZXJzaW'
    '9u');

@$core.Deprecated('Use gameValidationProblemDescriptor instead')
const GameValidationProblem$json = {
  '1': 'GameValidationProblem',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `GameValidationProblem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameValidationProblemDescriptor = $convert.base64Decode(
    'ChVHYW1lVmFsaWRhdGlvblByb2JsZW0SEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZkZXRhaWwYAi'
    'ABKAlSBmRldGFpbA==');

@$core.Deprecated('Use gameInstallationEvidenceDescriptor instead')
const GameInstallationEvidence$json = {
  '1': 'GameInstallationEvidence',
  '2': [
    {
      '1': 'platform',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.GameContextPlatform',
      '10': 'platform'
    },
    {'1': 'root_path', '3': 2, '4': 1, '5': 9, '10': 'rootPath'},
    {
      '1': 'data_path',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'dataPath',
      '17': true
    },
    {
      '1': 'executable',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameExecutableEvidence',
      '10': 'executable'
    },
    {
      '1': 'launcher_path',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'launcherPath',
      '17': true
    },
    {
      '1': 'documents',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameLocation',
      '10': 'documents'
    },
    {
      '1': 'saves',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameLocation',
      '10': 'saves'
    },
    {
      '1': 'local_app_data',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameLocation',
      '10': 'localAppData'
    },
    {
      '1': 'problems',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.GameValidationProblem',
      '10': 'problems'
    },
    {
      '1': 'checked_at_unix_ms',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'checkedAtUnixMs'
    },
    {'1': 'fingerprint', '3': 11, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'definition_id', '3': 12, '4': 1, '5': 9, '10': 'definitionId'},
    {
      '1': 'definition_revision',
      '3': 13,
      '4': 1,
      '5': 13,
      '10': 'definitionRevision'
    },
    {
      '1': 'proton',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonContextEvidence',
      '10': 'proton'
    },
  ],
  '8': [
    {'1': '_data_path'},
    {'1': '_launcher_path'},
  ],
};

/// Descriptor for `GameInstallationEvidence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameInstallationEvidenceDescriptor = $convert.base64Decode(
    'ChhHYW1lSW5zdGFsbGF0aW9uRXZpZGVuY2USQAoIcGxhdGZvcm0YASABKA4yJC5tb2Rjb25kdW'
    'N0b3IudjEuR2FtZUNvbnRleHRQbGF0Zm9ybVIIcGxhdGZvcm0SGwoJcm9vdF9wYXRoGAIgASgJ'
    'Ughyb290UGF0aBIgCglkYXRhX3BhdGgYAyABKAlIAFIIZGF0YVBhdGiIAQESRwoKZXhlY3V0YW'
    'JsZRgEIAEoCzInLm1vZGNvbmR1Y3Rvci52MS5HYW1lRXhlY3V0YWJsZUV2aWRlbmNlUgpleGVj'
    'dXRhYmxlEigKDWxhdW5jaGVyX3BhdGgYBSABKAlIAVIMbGF1bmNoZXJQYXRoiAEBEjsKCWRvY3'
    'VtZW50cxgGIAEoCzIdLm1vZGNvbmR1Y3Rvci52MS5HYW1lTG9jYXRpb25SCWRvY3VtZW50cxIz'
    'CgVzYXZlcxgHIAEoCzIdLm1vZGNvbmR1Y3Rvci52MS5HYW1lTG9jYXRpb25SBXNhdmVzEkMKDm'
    'xvY2FsX2FwcF9kYXRhGAggASgLMh0ubW9kY29uZHVjdG9yLnYxLkdhbWVMb2NhdGlvblIMbG9j'
    'YWxBcHBEYXRhEkIKCHByb2JsZW1zGAkgAygLMiYubW9kY29uZHVjdG9yLnYxLkdhbWVWYWxpZG'
    'F0aW9uUHJvYmxlbVIIcHJvYmxlbXMSKwoSY2hlY2tlZF9hdF91bml4X21zGAogASgDUg9jaGVj'
    'a2VkQXRVbml4TXMSIAoLZmluZ2VycHJpbnQYCyABKAlSC2ZpbmdlcnByaW50EiMKDWRlZmluaX'
    'Rpb25faWQYDCABKAlSDGRlZmluaXRpb25JZBIvChNkZWZpbml0aW9uX3JldmlzaW9uGA0gASgN'
    'UhJkZWZpbml0aW9uUmV2aXNpb24SPgoGcHJvdG9uGA4gASgLMiYubW9kY29uZHVjdG9yLnYxLl'
    'Byb3RvbkNvbnRleHRFdmlkZW5jZVIGcHJvdG9uQgwKCl9kYXRhX3BhdGhCEAoOX2xhdW5jaGVy'
    'X3BhdGg=');

@$core.Deprecated('Use gameBindingInfoDescriptor instead')
const GameBindingInfo$json = {
  '1': 'GameBindingInfo',
  '2': [
    {'1': 'binding_id', '3': 1, '4': 1, '5': 9, '10': 'bindingId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'evidence',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameInstallationEvidence',
      '10': 'evidence'
    },
    {'1': 'needs_check', '3': 4, '4': 1, '5': 8, '10': 'needsCheck'},
    {
      '1': 'failure',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'failure',
      '17': true
    },
    {
      '1': 'proton',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonSelectionInfo',
      '10': 'proton'
    },
  ],
  '8': [
    {'1': '_failure'},
  ],
};

/// Descriptor for `GameBindingInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameBindingInfoDescriptor = $convert.base64Decode(
    'Cg9HYW1lQmluZGluZ0luZm8SHQoKYmluZGluZ19pZBgBIAEoCVIJYmluZGluZ0lkEhIKBHBhdG'
    'gYAiABKAlSBHBhdGgSRQoIZXZpZGVuY2UYAyABKAsyKS5tb2Rjb25kdWN0b3IudjEuR2FtZUlu'
    'c3RhbGxhdGlvbkV2aWRlbmNlUghldmlkZW5jZRIfCgtuZWVkc19jaGVjaxgEIAEoCFIKbmVlZH'
    'NDaGVjaxIdCgdmYWlsdXJlGAUgASgJSABSB2ZhaWx1cmWIAQESPAoGcHJvdG9uGAYgASgLMiQu'
    'bW9kY29uZHVjdG9yLnYxLlByb3RvblNlbGVjdGlvbkluZm9SBnByb3RvbkIKCghfZmFpbHVyZQ'
    '==');

@$core.Deprecated('Use gameContextStateDescriptor instead')
const GameContextState$json = {
  '1': 'GameContextState',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'definition',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameDefinitionInfo',
      '10': 'definition'
    },
    {
      '1': 'binding',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameBindingInfo',
      '10': 'binding'
    },
    {'1': 'profile_id', '3': 5, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `GameContextState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameContextStateDescriptor = $convert.base64Decode(
    'ChBHYW1lQ29udGV4dFN0YXRlEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSGg'
    'oIcmV2aXNpb24YAiABKARSCHJldmlzaW9uEkMKCmRlZmluaXRpb24YAyABKAsyIy5tb2Rjb25k'
    'dWN0b3IudjEuR2FtZURlZmluaXRpb25JbmZvUgpkZWZpbml0aW9uEjoKB2JpbmRpbmcYBCABKA'
    'syIC5tb2Rjb25kdWN0b3IudjEuR2FtZUJpbmRpbmdJbmZvUgdiaW5kaW5nEh0KCnByb2ZpbGVf'
    'aWQYBSABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use gameContextFaultDescriptor instead')
const GameContextFault$json = {
  '1': 'GameContextFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.GameContextFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
    {
      '1': 'candidate',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameInstallationEvidence',
      '10': 'candidate'
    },
  ],
};

/// Descriptor for `GameContextFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameContextFaultDescriptor = $convert.base64Decode(
    'ChBHYW1lQ29udGV4dEZhdWx0EjkKBGNvZGUYASABKA4yJS5tb2Rjb25kdWN0b3IudjEuR2FtZU'
    'NvbnRleHRGYXVsdENvZGVSBGNvZGUSFgoGZGV0YWlsGAIgASgJUgZkZXRhaWwSRwoJY2FuZGlk'
    'YXRlGAMgASgLMikubW9kY29uZHVjdG9yLnYxLkdhbWVJbnN0YWxsYXRpb25FdmlkZW5jZVIJY2'
    'FuZGlkYXRl');

@$core.Deprecated('Use gameContextReplyDescriptor instead')
const GameContextReply$json = {
  '1': 'GameContextReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameContextState',
      '9': 0,
      '10': 'state'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameContextFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `GameContextReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameContextReplyDescriptor = $convert.base64Decode(
    'ChBHYW1lQ29udGV4dFJlcGx5EjkKBXN0YXRlGAEgASgLMiEubW9kY29uZHVjdG9yLnYxLkdhbW'
    'VDb250ZXh0U3RhdGVIAFIFc3RhdGUSOQoFZmF1bHQYAiABKAsyIS5tb2Rjb25kdWN0b3IudjEu'
    'R2FtZUNvbnRleHRGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');
