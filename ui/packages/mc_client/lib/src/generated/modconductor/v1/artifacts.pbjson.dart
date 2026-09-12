// This is a generated file - do not edit.
//
// Generated from modconductor/v1/artifacts.proto.

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

@$core.Deprecated('Use archiveStorageDescriptor instead')
const ArchiveStorage$json = {
  '1': 'ArchiveStorage',
  '2': [
    {'1': 'ARCHIVE_STORAGE_UNSPECIFIED', '2': 0},
    {'1': 'ARCHIVE_STORAGE_REFERENCE', '2': 1},
    {'1': 'ARCHIVE_STORAGE_COPY', '2': 2},
  ],
};

/// Descriptor for `ArchiveStorage`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List archiveStorageDescriptor = $convert.base64Decode(
    'Cg5BcmNoaXZlU3RvcmFnZRIfChtBUkNISVZFX1NUT1JBR0VfVU5TUEVDSUZJRUQQABIdChlBUk'
    'NISVZFX1NUT1JBR0VfUkVGRVJFTkNFEAESGAoUQVJDSElWRV9TVE9SQUdFX0NPUFkQAg==');

@$core.Deprecated('Use archiveStateDescriptor instead')
const ArchiveState$json = {
  '1': 'ArchiveState',
  '2': [
    {'1': 'ARCHIVE_STATE_UNSPECIFIED', '2': 0},
    {'1': 'ARCHIVE_STATE_INCOMPLETE', '2': 1},
    {'1': 'ARCHIVE_STATE_READY', '2': 2},
    {'1': 'ARCHIVE_STATE_DETACHED', '2': 3},
    {'1': 'ARCHIVE_STATE_INSTALLED', '2': 4},
  ],
};

/// Descriptor for `ArchiveState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List archiveStateDescriptor = $convert.base64Decode(
    'CgxBcmNoaXZlU3RhdGUSHQoZQVJDSElWRV9TVEFURV9VTlNQRUNJRklFRBAAEhwKGEFSQ0hJVk'
    'VfU1RBVEVfSU5DT01QTEVURRABEhcKE0FSQ0hJVkVfU1RBVEVfUkVBRFkQAhIaChZBUkNISVZF'
    'X1NUQVRFX0RFVEFDSEVEEAMSGwoXQVJDSElWRV9TVEFURV9JTlNUQUxMRUQQBA==');

@$core.Deprecated('Use artifactProvenanceDescriptor instead')
const ArtifactProvenance$json = {
  '1': 'ArtifactProvenance',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'version_id', '3': 2, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'mod_name', '3': 3, '4': 1, '5': 9, '10': 'modName'},
    {'1': 'version_label', '3': 4, '4': 1, '5': 9, '10': 'versionLabel'},
  ],
};

/// Descriptor for `ArtifactProvenance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactProvenanceDescriptor = $convert.base64Decode(
    'ChJBcnRpZmFjdFByb3ZlbmFuY2USFQoGbW9kX2lkGAEgASgJUgVtb2RJZBIdCgp2ZXJzaW9uX2'
    'lkGAIgASgJUgl2ZXJzaW9uSWQSGQoIbW9kX25hbWUYAyABKAlSB21vZE5hbWUSIwoNdmVyc2lv'
    'bl9sYWJlbBgEIAEoCVIMdmVyc2lvbkxhYmVs');

@$core.Deprecated('Use archiveArtifactDescriptor instead')
const ArchiveArtifact$json = {
  '1': 'ArchiveArtifact',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'original_name', '3': 4, '4': 1, '5': 9, '10': 'originalName'},
    {'1': 'original_path', '3': 5, '4': 1, '5': 9, '10': 'originalPath'},
    {'1': 'path', '3': 6, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'storage',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ArchiveStorage',
      '10': 'storage'
    },
    {
      '1': 'state',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ArchiveState',
      '10': 'state'
    },
    {'1': 'length', '3': 9, '4': 1, '5': 4, '9': 0, '10': 'length', '17': true},
    {
      '1': 'sha256',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'sha256',
      '17': true
    },
    {
      '1': 'problem',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'links',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ArtifactProvenance',
      '10': 'links'
    },
    {'1': 'can_retry', '3': 13, '4': 1, '5': 8, '10': 'canRetry'},
    {'1': 'can_locate', '3': 14, '4': 1, '5': 8, '10': 'canLocate'},
    {'1': 'can_delete_copy', '3': 15, '4': 1, '5': 8, '10': 'canDeleteCopy'},
    {'1': 'can_remove', '3': 16, '4': 1, '5': 8, '10': 'canRemove'},
    {
      '1': 'download',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArchiveDownload',
      '9': 3,
      '10': 'download',
      '17': true
    },
  ],
  '8': [
    {'1': '_length'},
    {'1': '_sha256'},
    {'1': '_problem'},
    {'1': '_download'},
  ],
};

/// Descriptor for `ArchiveArtifact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archiveArtifactDescriptor = $convert.base64Decode(
    'Cg9BcmNoaXZlQXJ0aWZhY3QSDgoCaWQYASABKAlSAmlkEiEKDHdvcmtzcGFjZV9pZBgCIAEoCV'
    'ILd29ya3NwYWNlSWQSGgoIcmV2aXNpb24YAyABKARSCHJldmlzaW9uEiMKDW9yaWdpbmFsX25h'
    'bWUYBCABKAlSDG9yaWdpbmFsTmFtZRIjCg1vcmlnaW5hbF9wYXRoGAUgASgJUgxvcmlnaW5hbF'
    'BhdGgSEgoEcGF0aBgGIAEoCVIEcGF0aBI5CgdzdG9yYWdlGAcgASgOMh8ubW9kY29uZHVjdG9y'
    'LnYxLkFyY2hpdmVTdG9yYWdlUgdzdG9yYWdlEjMKBXN0YXRlGAggASgOMh0ubW9kY29uZHVjdG'
    '9yLnYxLkFyY2hpdmVTdGF0ZVIFc3RhdGUSGwoGbGVuZ3RoGAkgASgESABSBmxlbmd0aIgBARIb'
    'CgZzaGEyNTYYCiABKAlIAVIGc2hhMjU2iAEBEh0KB3Byb2JsZW0YCyABKAlIAlIHcHJvYmxlbY'
    'gBARI5CgVsaW5rcxgMIAMoCzIjLm1vZGNvbmR1Y3Rvci52MS5BcnRpZmFjdFByb3ZlbmFuY2VS'
    'BWxpbmtzEhsKCWNhbl9yZXRyeRgNIAEoCFIIY2FuUmV0cnkSHQoKY2FuX2xvY2F0ZRgOIAEoCF'
    'IJY2FuTG9jYXRlEiYKD2Nhbl9kZWxldGVfY29weRgPIAEoCFINY2FuRGVsZXRlQ29weRIdCgpj'
    'YW5fcmVtb3ZlGBAgASgIUgljYW5SZW1vdmUSQQoIZG93bmxvYWQYESABKAsyIC5tb2Rjb25kdW'
    'N0b3IudjEuQXJjaGl2ZURvd25sb2FkSANSCGRvd25sb2FkiAEBQgkKB19sZW5ndGhCCQoHX3No'
    'YTI1NkIKCghfcHJvYmxlbUILCglfZG93bmxvYWQ=');

@$core.Deprecated('Use artifactLinkPageDescriptor instead')
const ArtifactLinkPage$json = {
  '1': 'ArtifactLinkPage',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ArtifactProvenance',
      '10': 'entries'
    },
    {'1': 'next', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'next', '17': true},
  ],
  '8': [
    {'1': '_next'},
  ],
};

/// Descriptor for `ArtifactLinkPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactLinkPageDescriptor = $convert.base64Decode(
    'ChBBcnRpZmFjdExpbmtQYWdlEj0KB2VudHJpZXMYASADKAsyIy5tb2Rjb25kdWN0b3IudjEuQX'
    'J0aWZhY3RQcm92ZW5hbmNlUgdlbnRyaWVzEhcKBG5leHQYAiABKAlIAFIEbmV4dIgBAUIHCgVf'
    'bmV4dA==');

@$core.Deprecated('Use artifactPageDescriptor instead')
const ArtifactPage$json = {
  '1': 'ArtifactPage',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ArchiveArtifact',
      '10': 'entries'
    },
    {'1': 'next', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'next', '17': true},
  ],
  '8': [
    {'1': '_next'},
  ],
};

/// Descriptor for `ArtifactPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactPageDescriptor = $convert.base64Decode(
    'CgxBcnRpZmFjdFBhZ2USOgoHZW50cmllcxgBIAMoCzIgLm1vZGNvbmR1Y3Rvci52MS5BcmNoaX'
    'ZlQXJ0aWZhY3RSB2VudHJpZXMSFwoEbmV4dBgCIAEoCUgAUgRuZXh0iAEBQgcKBV9uZXh0');

@$core.Deprecated('Use artifactListRequestDescriptor instead')
const ArtifactListRequest$json = {
  '1': 'ArtifactListRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'after', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'after', '17': true},
    {'1': 'refresh', '3': 3, '4': 1, '5': 8, '10': 'refresh'},
  ],
  '8': [
    {'1': '_after'},
  ],
};

/// Descriptor for `ArtifactListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactListRequestDescriptor = $convert.base64Decode(
    'ChNBcnRpZmFjdExpc3RSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSW'
    'QSGQoFYWZ0ZXIYAiABKAlIAFIFYWZ0ZXKIAQESGAoHcmVmcmVzaBgDIAEoCFIHcmVmcmVzaEII'
    'CgZfYWZ0ZXI=');

@$core.Deprecated('Use artifactReadRequestDescriptor instead')
const ArtifactReadRequest$json = {
  '1': 'ArtifactReadRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ArtifactReadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactReadRequestDescriptor = $convert.base64Decode(
    'ChNBcnRpZmFjdFJlYWRSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSW'
    'QSDgoCaWQYAiABKAlSAmlk');

@$core.Deprecated('Use artifactAddRequestDescriptor instead')
const ArtifactAddRequest$json = {
  '1': 'ArtifactAddRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'storage',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ArchiveStorage',
      '10': 'storage'
    },
  ],
};

/// Descriptor for `ArtifactAddRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactAddRequestDescriptor = $convert.base64Decode(
    'ChJBcnRpZmFjdEFkZFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IOCgJpZBgCIAEoCVICaWQSEgoEcGF0aBgDIAEoCVIEcGF0aBI5CgdzdG9yYWdlGAQgASgOMh8u'
    'bW9kY29uZHVjdG9yLnYxLkFyY2hpdmVTdG9yYWdlUgdzdG9yYWdl');

@$core.Deprecated('Use artifactReferenceDescriptor instead')
const ArtifactReference$json = {
  '1': 'ArtifactReference',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `ArtifactReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactReferenceDescriptor = $convert.base64Decode(
    'ChFBcnRpZmFjdFJlZmVyZW5jZRIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEg'
    '4KAmlkGAIgASgJUgJpZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24=');

@$core.Deprecated('Use artifactLocateRequestDescriptor instead')
const ArtifactLocateRequest$json = {
  '1': 'ArtifactLocateRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArtifactReference',
      '10': 'expected'
    },
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `ArtifactLocateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactLocateRequestDescriptor = $convert.base64Decode(
    'ChVBcnRpZmFjdExvY2F0ZVJlcXVlc3QSPgoIZXhwZWN0ZWQYASABKAsyIi5tb2Rjb25kdWN0b3'
    'IudjEuQXJ0aWZhY3RSZWZlcmVuY2VSCGV4cGVjdGVkEhIKBHBhdGgYAiABKAlSBHBhdGg=');

@$core.Deprecated('Use artifactLinkRequestDescriptor instead')
const ArtifactLinkRequest$json = {
  '1': 'ArtifactLinkRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArtifactReference',
      '10': 'expected'
    },
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'version_id', '3': 3, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'remove', '3': 4, '4': 1, '5': 8, '10': 'remove'},
  ],
};

/// Descriptor for `ArtifactLinkRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactLinkRequestDescriptor = $convert.base64Decode(
    'ChNBcnRpZmFjdExpbmtSZXF1ZXN0Ej4KCGV4cGVjdGVkGAEgASgLMiIubW9kY29uZHVjdG9yLn'
    'YxLkFydGlmYWN0UmVmZXJlbmNlUghleHBlY3RlZBIVCgZtb2RfaWQYAiABKAlSBW1vZElkEh0K'
    'CnZlcnNpb25faWQYAyABKAlSCXZlcnNpb25JZBIWCgZyZW1vdmUYBCABKAhSBnJlbW92ZQ==');

@$core.Deprecated('Use artifactRemovedDescriptor instead')
const ArtifactRemoved$json = {
  '1': 'ArtifactRemoved',
};

/// Descriptor for `ArtifactRemoved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactRemovedDescriptor =
    $convert.base64Decode('Cg9BcnRpZmFjdFJlbW92ZWQ=');
