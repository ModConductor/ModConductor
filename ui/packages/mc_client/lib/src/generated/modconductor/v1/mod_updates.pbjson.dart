// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_updates.proto.

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

@$core.Deprecated('Use modUpdateModeDescriptor instead')
const ModUpdateMode$json = {
  '1': 'ModUpdateMode',
  '2': [
    {'1': 'MOD_UPDATE_MODE_MERGE', '2': 0},
    {'1': 'MOD_UPDATE_MODE_REPLACE', '2': 1},
  ],
};

/// Descriptor for `ModUpdateMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modUpdateModeDescriptor = $convert.base64Decode(
    'Cg1Nb2RVcGRhdGVNb2RlEhkKFU1PRF9VUERBVEVfTU9ERV9NRVJHRRAAEhsKF01PRF9VUERBVE'
    'VfTU9ERV9SRVBMQUNFEAE=');

@$core.Deprecated('Use modUpdateChangeDescriptor instead')
const ModUpdateChange$json = {
  '1': 'ModUpdateChange',
  '2': [
    {'1': 'MOD_UPDATE_CHANGE_ADD', '2': 0},
    {'1': 'MOD_UPDATE_CHANGE_REPLACE', '2': 1},
    {'1': 'MOD_UPDATE_CHANGE_REMOVE', '2': 2},
    {'1': 'MOD_UPDATE_CHANGE_KEEP', '2': 3},
  ],
};

/// Descriptor for `ModUpdateChange`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modUpdateChangeDescriptor = $convert.base64Decode(
    'Cg9Nb2RVcGRhdGVDaGFuZ2USGQoVTU9EX1VQREFURV9DSEFOR0VfQUREEAASHQoZTU9EX1VQRE'
    'FURV9DSEFOR0VfUkVQTEFDRRABEhwKGE1PRF9VUERBVEVfQ0hBTkdFX1JFTU9WRRACEhoKFk1P'
    'RF9VUERBVEVfQ0hBTkdFX0tFRVAQAw==');

@$core.Deprecated('Use prepareModUpdateRequestDescriptor instead')
const PrepareModUpdateRequest$json = {
  '1': 'PrepareModUpdateRequest',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'mode',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModUpdateMode',
      '10': 'mode'
    },
    {
      '1': 'keep',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'keep'
    },
    {'1': 'version', '3': 6, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `PrepareModUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareModUpdateRequestDescriptor = $convert.base64Decode(
    'ChdQcmVwYXJlTW9kVXBkYXRlUmVxdWVzdBJBCgVkcmFmdBgBIAEoCzIrLm1vZGNvbmR1Y3Rvci'
    '52MS5JbnN0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIFZHJhZnQSFQoGbW9kX2lkGAIgASgJUgVt'
    'b2RJZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24SMgoEbW9kZRgEIAEoDjIeLm1vZGNvbm'
    'R1Y3Rvci52MS5Nb2RVcGRhdGVNb2RlUgRtb2RlEjMKBGtlZXAYBSADKAsyHy5tb2Rjb25kdWN0'
    'b3IudjEuTW9kTG9naWNhbFBhdGhSBGtlZXASGAoHdmVyc2lvbhgGIAEoCVIHdmVyc2lvbg==');

@$core.Deprecated('Use modUpdateFileDescriptor instead')
const ModUpdateFile$json = {
  '1': 'ModUpdateFile',
  '2': [
    {
      '1': 'path',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
    {
      '1': 'change',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModUpdateChange',
      '10': 'change'
    },
    {
      '1': 'existing_bytes',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'existingBytes',
      '17': true
    },
    {
      '1': 'incoming_bytes',
      '3': 4,
      '4': 1,
      '5': 4,
      '9': 1,
      '10': 'incomingBytes',
      '17': true
    },
    {
      '1': 'existing_paths',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'existingPaths'
    },
    {'1': 'has_incoming', '3': 6, '4': 1, '5': 8, '10': 'hasIncoming'},
  ],
  '8': [
    {'1': '_existing_bytes'},
    {'1': '_incoming_bytes'},
  ],
};

/// Descriptor for `ModUpdateFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modUpdateFileDescriptor = $convert.base64Decode(
    'Cg1Nb2RVcGRhdGVGaWxlEjMKBHBhdGgYASABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG9naW'
    'NhbFBhdGhSBHBhdGgSOAoGY2hhbmdlGAIgASgOMiAubW9kY29uZHVjdG9yLnYxLk1vZFVwZGF0'
    'ZUNoYW5nZVIGY2hhbmdlEioKDmV4aXN0aW5nX2J5dGVzGAMgASgESABSDWV4aXN0aW5nQnl0ZX'
    'OIAQESKgoOaW5jb21pbmdfYnl0ZXMYBCABKARIAVINaW5jb21pbmdCeXRlc4gBARJGCg5leGlz'
    'dGluZ19wYXRocxgFIAMoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dpY2FsUGF0aFINZXhpc3'
    'RpbmdQYXRocxIhCgxoYXNfaW5jb21pbmcYBiABKAhSC2hhc0luY29taW5nQhEKD19leGlzdGlu'
    'Z19ieXRlc0IRCg9faW5jb21pbmdfYnl0ZXM=');

@$core.Deprecated('Use modUpdatePreviewDescriptor instead')
const ModUpdatePreview$json = {
  '1': 'ModUpdatePreview',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 3, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'current_version', '3': 5, '4': 1, '5': 9, '10': 'currentVersion'},
    {'1': 'next_version', '3': 6, '4': 1, '5': 9, '10': 'nextVersion'},
    {
      '1': 'mode',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModUpdateMode',
      '10': 'mode'
    },
    {
      '1': 'files',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModUpdateFile',
      '10': 'files'
    },
    {
      '1': 'keep',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'keep'
    },
    {'1': 'required_bytes', '3': 10, '4': 1, '5': 4, '10': 'requiredBytes'},
    {'1': 'source_notices', '3': 11, '4': 3, '5': 9, '10': 'sourceNotices'},
  ],
};

/// Descriptor for `ModUpdatePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modUpdatePreviewDescriptor = $convert.base64Decode(
    'ChBNb2RVcGRhdGVQcmV2aWV3Eg4KAmlkGAEgASgJUgJpZBIhCgx3b3Jrc3BhY2VfaWQYAiABKA'
    'lSC3dvcmtzcGFjZUlkEhUKBm1vZF9pZBgDIAEoCVIFbW9kSWQSEgoEbmFtZRgEIAEoCVIEbmFt'
    'ZRInCg9jdXJyZW50X3ZlcnNpb24YBSABKAlSDmN1cnJlbnRWZXJzaW9uEiEKDG5leHRfdmVyc2'
    'lvbhgGIAEoCVILbmV4dFZlcnNpb24SMgoEbW9kZRgHIAEoDjIeLm1vZGNvbmR1Y3Rvci52MS5N'
    'b2RVcGRhdGVNb2RlUgRtb2RlEjQKBWZpbGVzGAggAygLMh4ubW9kY29uZHVjdG9yLnYxLk1vZF'
    'VwZGF0ZUZpbGVSBWZpbGVzEjMKBGtlZXAYCSADKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG9n'
    'aWNhbFBhdGhSBGtlZXASJQoOcmVxdWlyZWRfYnl0ZXMYCiABKARSDXJlcXVpcmVkQnl0ZXMSJQ'
    'oOc291cmNlX25vdGljZXMYCyADKAlSDXNvdXJjZU5vdGljZXM=');

@$core.Deprecated('Use startModUpdateRequestDescriptor instead')
const StartModUpdateRequest$json = {
  '1': 'StartModUpdateRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'preview_id', '3': 2, '4': 1, '5': 9, '10': 'previewId'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `StartModUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startModUpdateRequestDescriptor = $convert.base64Decode(
    'ChVTdGFydE1vZFVwZGF0ZVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBIdCgpwcmV2aWV3X2lkGAIgASgJUglwcmV2aWV3SWQSDgoCaWQYAyABKAlSAmlk');
