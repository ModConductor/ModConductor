// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_deletion.proto.

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

@$core.Deprecated('Use modDeletionFileKindDescriptor instead')
const ModDeletionFileKind$json = {
  '1': 'ModDeletionFileKind',
  '2': [
    {'1': 'MOD_DELETION_FILE_KIND_PAYLOAD', '2': 0},
    {'1': 'MOD_DELETION_FILE_KIND_ARCHIVE', '2': 1},
    {'1': 'MOD_DELETION_FILE_KIND_TEMPORARY', '2': 2},
    {'1': 'MOD_DELETION_FILE_KIND_GENERATION_LINK', '2': 3},
  ],
};

/// Descriptor for `ModDeletionFileKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modDeletionFileKindDescriptor = $convert.base64Decode(
    'ChNNb2REZWxldGlvbkZpbGVLaW5kEiIKHk1PRF9ERUxFVElPTl9GSUxFX0tJTkRfUEFZTE9BRB'
    'AAEiIKHk1PRF9ERUxFVElPTl9GSUxFX0tJTkRfQVJDSElWRRABEiQKIE1PRF9ERUxFVElPTl9G'
    'SUxFX0tJTkRfVEVNUE9SQVJZEAISKgomTU9EX0RFTEVUSU9OX0ZJTEVfS0lORF9HRU5FUkFUSU'
    '9OX0xJTksQAw==');

@$core.Deprecated('Use modDeletionPhaseDescriptor instead')
const ModDeletionPhase$json = {
  '1': 'ModDeletionPhase',
  '2': [
    {'1': 'MOD_DELETION_PHASE_RUNNING', '2': 0},
    {'1': 'MOD_DELETION_PHASE_INCOMPLETE', '2': 1},
    {'1': 'MOD_DELETION_PHASE_COMPLETE', '2': 2},
  ],
};

/// Descriptor for `ModDeletionPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modDeletionPhaseDescriptor = $convert.base64Decode(
    'ChBNb2REZWxldGlvblBoYXNlEh4KGk1PRF9ERUxFVElPTl9QSEFTRV9SVU5OSU5HEAASIQodTU'
    '9EX0RFTEVUSU9OX1BIQVNFX0lOQ09NUExFVEUQARIfChtNT0RfREVMRVRJT05fUEhBU0VfQ09N'
    'UExFVEUQAg==');

@$core.Deprecated('Use prepareModDeletionRequestDescriptor instead')
const PrepareModDeletionRequest$json = {
  '1': 'PrepareModDeletionRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `PrepareModDeletionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareModDeletionRequestDescriptor = $convert.base64Decode(
    'ChlQcmVwYXJlTW9kRGVsZXRpb25SZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3'
    'NwYWNlSWQSFQoGbW9kX2lkGAIgASgJUgVtb2RJZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNp'
    'b24=');

@$core.Deprecated('Use modDeletionReferenceDescriptor instead')
const ModDeletionReference$json = {
  '1': 'ModDeletionReference',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ModDeletionReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionReferenceDescriptor = $convert.base64Decode(
    'ChRNb2REZWxldGlvblJlZmVyZW5jZRIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lkEg4KAmlkGAIgASgJUgJpZA==');

@$core.Deprecated('Use modDeletionWorkspaceDescriptor instead')
const ModDeletionWorkspace$json = {
  '1': 'ModDeletionWorkspace',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
  ],
};

/// Descriptor for `ModDeletionWorkspace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionWorkspaceDescriptor = $convert.base64Decode(
    'ChRNb2REZWxldGlvbldvcmtzcGFjZRIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lk');

@$core.Deprecated('Use modDeletionPreviewClosedDescriptor instead')
const ModDeletionPreviewClosed$json = {
  '1': 'ModDeletionPreviewClosed',
};

/// Descriptor for `ModDeletionPreviewClosed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionPreviewClosedDescriptor =
    $convert.base64Decode('ChhNb2REZWxldGlvblByZXZpZXdDbG9zZWQ=');

@$core.Deprecated('Use startModDeletionRequestDescriptor instead')
const StartModDeletionRequest$json = {
  '1': 'StartModDeletionRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'preview_id', '3': 2, '4': 1, '5': 9, '10': 'previewId'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `StartModDeletionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startModDeletionRequestDescriptor = $convert.base64Decode(
    'ChdTdGFydE1vZERlbGV0aW9uUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcG'
    'FjZUlkEh0KCnByZXZpZXdfaWQYAiABKAlSCXByZXZpZXdJZBIOCgJpZBgDIAEoCVICaWQ=');

@$core.Deprecated('Use modDeletionFileDescriptor instead')
const ModDeletionFile$json = {
  '1': 'ModDeletionFile',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModDeletionFileKind',
      '10': 'kind'
    },
    {'1': 'bytes', '3': 3, '4': 1, '5': 4, '9': 0, '10': 'bytes', '17': true},
    {'1': 'shared', '3': 4, '4': 1, '5': 8, '10': 'shared'},
  ],
  '8': [
    {'1': '_bytes'},
  ],
};

/// Descriptor for `ModDeletionFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionFileDescriptor = $convert.base64Decode(
    'Cg9Nb2REZWxldGlvbkZpbGUSFAoFbGFiZWwYASABKAlSBWxhYmVsEjgKBGtpbmQYAiABKA4yJC'
    '5tb2Rjb25kdWN0b3IudjEuTW9kRGVsZXRpb25GaWxlS2luZFIEa2luZBIZCgVieXRlcxgDIAEo'
    'BEgAUgVieXRlc4gBARIWCgZzaGFyZWQYBCABKAhSBnNoYXJlZEIICgZfYnl0ZXM=');

@$core.Deprecated('Use modDeletionProfileDescriptor instead')
const ModDeletionProfile$json = {
  '1': 'ModDeletionProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ModDeletionProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionProfileDescriptor = $convert.base64Decode(
    'ChJNb2REZWxldGlvblByb2ZpbGUSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbW'
    'U=');

@$core.Deprecated('Use modDeletionDeploymentDescriptor instead')
const ModDeletionDeployment$json = {
  '1': 'ModDeletionDeployment',
  '2': [
    {'1': 'context_id', '3': 1, '4': 1, '5': 9, '10': 'contextId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'prepared_at_unix_ms',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'preparedAtUnixMs',
      '17': true
    },
    {'1': 'active', '3': 5, '4': 1, '5': 8, '10': 'active'},
  ],
  '8': [
    {'1': '_prepared_at_unix_ms'},
  ],
};

/// Descriptor for `ModDeletionDeployment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionDeploymentDescriptor = $convert.base64Decode(
    'ChVNb2REZWxldGlvbkRlcGxveW1lbnQSHQoKY29udGV4dF9pZBgBIAEoCVIJY29udGV4dElkEg'
    '4KAmlkGAIgASgJUgJpZBISCgRuYW1lGAMgASgJUgRuYW1lEjIKE3ByZXBhcmVkX2F0X3VuaXhf'
    'bXMYBCABKANIAFIQcHJlcGFyZWRBdFVuaXhNc4gBARIWCgZhY3RpdmUYBSABKAhSBmFjdGl2ZU'
    'IWChRfcHJlcGFyZWRfYXRfdW5peF9tcw==');

@$core.Deprecated('Use modDeletionPreviewDescriptor instead')
const ModDeletionPreview$json = {
  '1': 'ModDeletionPreview',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 3, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 4, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'versions', '3': 6, '4': 1, '5': 13, '10': 'versions'},
    {'1': 'backups', '3': 7, '4': 3, '5': 9, '10': 'backups'},
    {
      '1': 'profiles',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionProfile',
      '10': 'profiles'
    },
    {
      '1': 'deployments',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionDeployment',
      '10': 'deployments'
    },
    {
      '1': 'files',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionFile',
      '10': 'files'
    },
    {'1': 'external', '3': 11, '4': 3, '5': 9, '10': 'external'},
    {
      '1': 'blocked',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'blocked',
      '17': true
    },
  ],
  '8': [
    {'1': '_blocked'},
  ],
};

/// Descriptor for `ModDeletionPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionPreviewDescriptor = $convert.base64Decode(
    'ChJNb2REZWxldGlvblByZXZpZXcSDgoCaWQYASABKAlSAmlkEiEKDHdvcmtzcGFjZV9pZBgCIA'
    'EoCVILd29ya3NwYWNlSWQSFQoGbW9kX2lkGAMgASgJUgVtb2RJZBIaCghyZXZpc2lvbhgEIAEo'
    'BFIIcmV2aXNpb24SEgoEbmFtZRgFIAEoCVIEbmFtZRIaCgh2ZXJzaW9ucxgGIAEoDVIIdmVyc2'
    'lvbnMSGAoHYmFja3VwcxgHIAMoCVIHYmFja3VwcxI/Cghwcm9maWxlcxgIIAMoCzIjLm1vZGNv'
    'bmR1Y3Rvci52MS5Nb2REZWxldGlvblByb2ZpbGVSCHByb2ZpbGVzEkgKC2RlcGxveW1lbnRzGA'
    'kgAygLMiYubW9kY29uZHVjdG9yLnYxLk1vZERlbGV0aW9uRGVwbG95bWVudFILZGVwbG95bWVu'
    'dHMSNgoFZmlsZXMYCiADKAsyIC5tb2Rjb25kdWN0b3IudjEuTW9kRGVsZXRpb25GaWxlUgVmaW'
    'xlcxIaCghleHRlcm5hbBgLIAMoCVIIZXh0ZXJuYWwSHQoHYmxvY2tlZBgMIAEoCUgAUgdibG9j'
    'a2VkiAEBQgoKCF9ibG9ja2Vk');

@$core.Deprecated('Use modDeletionStatusDescriptor instead')
const ModDeletionStatus$json = {
  '1': 'ModDeletionStatus',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 3, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'phase',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModDeletionPhase',
      '10': 'phase'
    },
    {'1': 'remaining', '3': 6, '4': 1, '5': 13, '10': 'remaining'},
    {
      '1': 'problem',
      '3': 7,
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

/// Descriptor for `ModDeletionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionStatusDescriptor = $convert.base64Decode(
    'ChFNb2REZWxldGlvblN0YXR1cxIOCgJpZBgBIAEoCVICaWQSIQoMd29ya3NwYWNlX2lkGAIgAS'
    'gJUgt3b3Jrc3BhY2VJZBIVCgZtb2RfaWQYAyABKAlSBW1vZElkEhIKBG5hbWUYBCABKAlSBG5h'
    'bWUSNwoFcGhhc2UYBSABKA4yIS5tb2Rjb25kdWN0b3IudjEuTW9kRGVsZXRpb25QaGFzZVIFcG'
    'hhc2USHAoJcmVtYWluaW5nGAYgASgNUglyZW1haW5pbmcSHQoHcHJvYmxlbRgHIAEoCUgAUgdw'
    'cm9ibGVtiAEBQgoKCF9wcm9ibGVt');

@$core.Deprecated('Use modDeletionListDescriptor instead')
const ModDeletionList$json = {
  '1': 'ModDeletionList',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionStatus',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ModDeletionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletionListDescriptor = $convert.base64Decode(
    'Cg9Nb2REZWxldGlvbkxpc3QSPAoHZW50cmllcxgBIAMoCzIiLm1vZGNvbmR1Y3Rvci52MS5Nb2'
    'REZWxldGlvblN0YXR1c1IHZW50cmllcw==');
