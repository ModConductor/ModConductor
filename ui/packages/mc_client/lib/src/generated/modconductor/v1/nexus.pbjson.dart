// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus.proto.

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

@$core.Deprecated('Use nexusStatusRequestDescriptor instead')
const NexusStatusRequest$json = {
  '1': 'NexusStatusRequest',
};

/// Descriptor for `NexusStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusStatusRequestDescriptor =
    $convert.base64Decode('ChJOZXh1c1N0YXR1c1JlcXVlc3Q=');

@$core.Deprecated('Use nexusPersonalApiKeyRequestDescriptor instead')
const NexusPersonalApiKeyRequest$json = {
  '1': 'NexusPersonalApiKeyRequest',
  '2': [
    {'1': 'api_key', '3': 1, '4': 1, '5': 9, '10': 'apiKey'},
  ],
};

/// Descriptor for `NexusPersonalApiKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusPersonalApiKeyRequestDescriptor =
    $convert.base64Decode(
        'ChpOZXh1c1BlcnNvbmFsQXBpS2V5UmVxdWVzdBIXCgdhcGlfa2V5GAEgASgJUgZhcGlLZXk=');

@$core.Deprecated('Use nexusFailureDescriptor instead')
const NexusFailure$json = {
  '1': 'NexusFailure',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'retry_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'retryAtUnixMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_retry_at_unix_ms'},
  ],
};

/// Descriptor for `NexusFailure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusFailureDescriptor = $convert.base64Decode(
    'CgxOZXh1c0ZhaWx1cmUSEgoEY29kZRgBIAEoCVIEY29kZRIYCgdtZXNzYWdlGAIgASgJUgdtZX'
    'NzYWdlEiwKEHJldHJ5X2F0X3VuaXhfbXMYAyABKANIAFINcmV0cnlBdFVuaXhNc4gBAUITChFf'
    'cmV0cnlfYXRfdW5peF9tcw==');

@$core.Deprecated('Use nexusAccountStatusDescriptor instead')
const NexusAccountStatus$json = {
  '1': 'NexusAccountStatus',
  '2': [
    {'1': 'configured', '3': 1, '4': 1, '5': 8, '10': 'configured'},
    {'1': 'waiting', '3': 2, '4': 1, '5': 8, '10': 'waiting'},
    {
      '1': 'account_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'accountName',
      '17': true
    },
    {
      '1': 'premium',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'premium',
      '17': true
    },
    {
      '1': 'failure',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusFailure',
      '9': 2,
      '10': 'failure',
      '17': true
    },
    {
      '1': 'profile_image_url',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'profileImageUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_account_name'},
    {'1': '_premium'},
    {'1': '_failure'},
    {'1': '_profile_image_url'},
  ],
};

/// Descriptor for `NexusAccountStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusAccountStatusDescriptor = $convert.base64Decode(
    'ChJOZXh1c0FjY291bnRTdGF0dXMSHgoKY29uZmlndXJlZBgBIAEoCFIKY29uZmlndXJlZBIYCg'
    'd3YWl0aW5nGAIgASgIUgd3YWl0aW5nEiYKDGFjY291bnRfbmFtZRgDIAEoCUgAUgthY2NvdW50'
    'TmFtZYgBARIdCgdwcmVtaXVtGAQgASgISAFSB3ByZW1pdW2IAQESPAoHZmFpbHVyZRgFIAEoCz'
    'IdLm1vZGNvbmR1Y3Rvci52MS5OZXh1c0ZhaWx1cmVIAlIHZmFpbHVyZYgBARIvChFwcm9maWxl'
    'X2ltYWdlX3VybBgGIAEoCUgDUg9wcm9maWxlSW1hZ2VVcmyIAQFCDwoNX2FjY291bnRfbmFtZU'
    'IKCghfcHJlbWl1bUIKCghfZmFpbHVyZUIUChJfcHJvZmlsZV9pbWFnZV91cmw=');

@$core.Deprecated('Use nexusModRequestDescriptor instead')
const NexusModRequest$json = {
  '1': 'NexusModRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 3, '10': 'modId'},
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `NexusModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusModRequestDescriptor = $convert.base64Decode(
    'Cg9OZXh1c01vZFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBIVCg'
    'Ztb2RfaWQYAiABKANSBW1vZElkEh0KCnByb2ZpbGVfaWQYAyABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use nexusFileInfoDescriptor instead')
const NexusFileInfo$json = {
  '1': 'NexusFileInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    {'1': 'category', '3': 4, '4': 1, '5': 9, '10': 'category'},
    {'1': 'description', '3': 5, '4': 1, '5': 9, '10': 'description'},
    {'1': 'bytes', '3': 6, '4': 1, '5': 3, '9': 0, '10': 'bytes', '17': true},
  ],
  '8': [
    {'1': '_bytes'},
  ],
};

/// Descriptor for `NexusFileInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusFileInfoDescriptor = $convert.base64Decode(
    'Cg1OZXh1c0ZpbGVJbmZvEg4KAmlkGAEgASgDUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhgKB3'
    'ZlcnNpb24YAyABKAlSB3ZlcnNpb24SGgoIY2F0ZWdvcnkYBCABKAlSCGNhdGVnb3J5EiAKC2Rl'
    'c2NyaXB0aW9uGAUgASgJUgtkZXNjcmlwdGlvbhIZCgVieXRlcxgGIAEoA0gAUgVieXRlc4gBAU'
    'IICgZfYnl0ZXM=');

@$core.Deprecated('Use nexusModInfoDescriptor instead')
const NexusModInfo$json = {
  '1': 'NexusModInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'summary', '3': 3, '4': 1, '5': 9, '10': 'summary'},
    {
      '1': 'files',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.NexusFileInfo',
      '10': 'files'
    },
    {'1': 'author', '3': 5, '4': 1, '5': 9, '10': 'author'},
    {'1': 'category', '3': 6, '4': 1, '5': 9, '10': 'category'},
    {
      '1': 'picture_url',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'pictureUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_picture_url'},
  ],
};

/// Descriptor for `NexusModInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusModInfoDescriptor = $convert.base64Decode(
    'CgxOZXh1c01vZEluZm8SDgoCaWQYASABKANSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGAoHc3'
    'VtbWFyeRgDIAEoCVIHc3VtbWFyeRI0CgVmaWxlcxgEIAMoCzIeLm1vZGNvbmR1Y3Rvci52MS5O'
    'ZXh1c0ZpbGVJbmZvUgVmaWxlcxIWCgZhdXRob3IYBSABKAlSBmF1dGhvchIaCghjYXRlZ29yeR'
    'gGIAEoCVIIY2F0ZWdvcnkSJAoLcGljdHVyZV91cmwYByABKAlIAFIKcGljdHVyZVVybIgBAUIO'
    'CgxfcGljdHVyZV91cmw=');

@$core.Deprecated('Use nexusModReplyDescriptor instead')
const NexusModReply$json = {
  '1': 'NexusModReply',
  '2': [
    {
      '1': 'mod',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusModInfo',
      '9': 0,
      '10': 'mod'
    },
    {
      '1': 'failure',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusFailure',
      '9': 0,
      '10': 'failure'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `NexusModReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusModReplyDescriptor = $convert.base64Decode(
    'Cg1OZXh1c01vZFJlcGx5EjEKA21vZBgBIAEoCzIdLm1vZGNvbmR1Y3Rvci52MS5OZXh1c01vZE'
    'luZm9IAFIDbW9kEjkKB2ZhaWx1cmUYAiABKAsyHS5tb2Rjb25kdWN0b3IudjEuTmV4dXNGYWls'
    'dXJlSABSB2ZhaWx1cmVCCAoGcmVzdWx0');

@$core.Deprecated('Use nexusDownloadRequestDescriptor instead')
const NexusDownloadRequest$json = {
  '1': 'NexusDownloadRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'artifact_id', '3': 2, '4': 1, '5': 9, '10': 'artifactId'},
    {'1': 'mod_id', '3': 3, '4': 1, '5': 3, '10': 'modId'},
    {'1': 'file_id', '3': 4, '4': 1, '5': 3, '10': 'fileId'},
    {'1': 'profile_id', '3': 5, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `NexusDownloadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusDownloadRequestDescriptor = $convert.base64Decode(
    'ChROZXh1c0Rvd25sb2FkUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lkEh8KC2FydGlmYWN0X2lkGAIgASgJUgphcnRpZmFjdElkEhUKBm1vZF9pZBgDIAEoA1IFbW9k'
    'SWQSFwoHZmlsZV9pZBgEIAEoA1IGZmlsZUlkEh0KCnByb2ZpbGVfaWQYBSABKAlSCXByb2ZpbG'
    'VJZA==');

@$core.Deprecated('Use nexusDownloadReplyDescriptor instead')
const NexusDownloadReply$json = {
  '1': 'NexusDownloadReply',
  '2': [
    {
      '1': 'artifact',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArchiveArtifact',
      '9': 0,
      '10': 'artifact'
    },
    {
      '1': 'failure',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusFailure',
      '9': 0,
      '10': 'failure'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `NexusDownloadReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusDownloadReplyDescriptor = $convert.base64Decode(
    'ChJOZXh1c0Rvd25sb2FkUmVwbHkSPgoIYXJ0aWZhY3QYASABKAsyIC5tb2Rjb25kdWN0b3Iudj'
    'EuQXJjaGl2ZUFydGlmYWN0SABSCGFydGlmYWN0EjkKB2ZhaWx1cmUYAiABKAsyHS5tb2Rjb25k'
    'dWN0b3IudjEuTmV4dXNGYWlsdXJlSABSB2ZhaWx1cmVCCAoGcmVzdWx0');

@$core.Deprecated('Use nexusDiscoveryRequestDescriptor instead')
const NexusDiscoveryRequest$json = {
  '1': 'NexusDiscoveryRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'feed', '3': 3, '4': 1, '5': 9, '10': 'feed'},
  ],
};

/// Descriptor for `NexusDiscoveryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusDiscoveryRequestDescriptor = $convert.base64Decode(
    'ChVOZXh1c0Rpc2NvdmVyeVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBIdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQSEgoEZmVlZBgDIAEoCVIEZmVlZA==');

@$core.Deprecated('Use nexusDiscoveryCardDescriptor instead')
const NexusDiscoveryCard$json = {
  '1': 'NexusDiscoveryCard',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'summary', '3': 3, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'category', '3': 5, '4': 1, '5': 9, '10': 'category'},
    {
      '1': 'picture_url',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'pictureUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_picture_url'},
  ],
};

/// Descriptor for `NexusDiscoveryCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusDiscoveryCardDescriptor = $convert.base64Decode(
    'ChJOZXh1c0Rpc2NvdmVyeUNhcmQSDgoCaWQYASABKANSAmlkEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USGAoHc3VtbWFyeRgDIAEoCVIHc3VtbWFyeRIWCgZhdXRob3IYBCABKAlSBmF1dGhvchIaCghj'
    'YXRlZ29yeRgFIAEoCVIIY2F0ZWdvcnkSJAoLcGljdHVyZV91cmwYBiABKAlIAFIKcGljdHVyZV'
    'VybIgBAUIOCgxfcGljdHVyZV91cmw=');

@$core.Deprecated('Use nexusDiscoveryReplyDescriptor instead')
const NexusDiscoveryReply$json = {
  '1': 'NexusDiscoveryReply',
  '2': [
    {
      '1': 'cards',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusDiscoveryCards',
      '9': 0,
      '10': 'cards'
    },
    {
      '1': 'failure',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusFailure',
      '9': 0,
      '10': 'failure'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `NexusDiscoveryReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusDiscoveryReplyDescriptor = $convert.base64Decode(
    'ChNOZXh1c0Rpc2NvdmVyeVJlcGx5EjwKBWNhcmRzGAEgASgLMiQubW9kY29uZHVjdG9yLnYxLk'
    '5leHVzRGlzY292ZXJ5Q2FyZHNIAFIFY2FyZHMSOQoHZmFpbHVyZRgCIAEoCzIdLm1vZGNvbmR1'
    'Y3Rvci52MS5OZXh1c0ZhaWx1cmVIAFIHZmFpbHVyZUIICgZyZXN1bHQ=');

@$core.Deprecated('Use nexusDiscoveryCardsDescriptor instead')
const NexusDiscoveryCards$json = {
  '1': 'NexusDiscoveryCards',
  '2': [
    {
      '1': 'mods',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.NexusDiscoveryCard',
      '10': 'mods'
    },
  ],
};

/// Descriptor for `NexusDiscoveryCards`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusDiscoveryCardsDescriptor = $convert.base64Decode(
    'ChNOZXh1c0Rpc2NvdmVyeUNhcmRzEjcKBG1vZHMYASADKAsyIy5tb2Rjb25kdWN0b3IudjEuTm'
    'V4dXNEaXNjb3ZlcnlDYXJkUgRtb2Rz');
