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

@$core.Deprecated('Use deleteModRequestDescriptor instead')
const DeleteModRequest$json = {
  '1': 'DeleteModRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `DeleteModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteModRequestDescriptor = $convert.base64Decode(
    'ChBEZWxldGVNb2RSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSFQ'
    'oGbW9kX2lkGAIgASgJUgVtb2RJZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24=');

@$core.Deprecated('Use modDeletedDescriptor instead')
const ModDeleted$json = {
  '1': 'ModDeleted',
};

/// Descriptor for `ModDeleted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletedDescriptor =
    $convert.base64Decode('CgpNb2REZWxldGVk');

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
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'versions', '3': 5, '4': 1, '5': 13, '10': 'versions'},
    {'1': 'backups', '3': 6, '4': 3, '5': 9, '10': 'backups'},
    {
      '1': 'profiles',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionProfile',
      '10': 'profiles'
    },
    {
      '1': 'deployments',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionDeployment',
      '10': 'deployments'
    },
    {
      '1': 'files',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModDeletionFile',
      '10': 'files'
    },
    {'1': 'external', '3': 10, '4': 3, '5': 9, '10': 'external'},
    {
      '1': 'blocked',
      '3': 11,
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
    'ChJNb2REZWxldGlvblByZXZpZXcSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IVCgZtb2RfaWQYAiABKAlSBW1vZElkEhoKCHJldmlzaW9uGAMgASgEUghyZXZpc2lvbhISCgRu'
    'YW1lGAQgASgJUgRuYW1lEhoKCHZlcnNpb25zGAUgASgNUgh2ZXJzaW9ucxIYCgdiYWNrdXBzGA'
    'YgAygJUgdiYWNrdXBzEj8KCHByb2ZpbGVzGAcgAygLMiMubW9kY29uZHVjdG9yLnYxLk1vZERl'
    'bGV0aW9uUHJvZmlsZVIIcHJvZmlsZXMSSAoLZGVwbG95bWVudHMYCCADKAsyJi5tb2Rjb25kdW'
    'N0b3IudjEuTW9kRGVsZXRpb25EZXBsb3ltZW50UgtkZXBsb3ltZW50cxI2CgVmaWxlcxgJIAMo'
    'CzIgLm1vZGNvbmR1Y3Rvci52MS5Nb2REZWxldGlvbkZpbGVSBWZpbGVzEhoKCGV4dGVybmFsGA'
    'ogAygJUghleHRlcm5hbBIdCgdibG9ja2VkGAsgASgJSABSB2Jsb2NrZWSIAQFCCgoIX2Jsb2Nr'
    'ZWQ=');
