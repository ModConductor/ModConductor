// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus_metadata.proto.

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

@$core.Deprecated('Use modNexusRequestDescriptor instead')
const ModNexusRequest$json = {
  '1': 'ModNexusRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `ModNexusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modNexusRequestDescriptor = $convert.base64Decode(
    'Cg9Nb2ROZXh1c1JlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBIVCg'
    'Ztb2RfaWQYAiABKAlSBW1vZElkEh0KCnByb2ZpbGVfaWQYAyABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use modNexusReferenceDescriptor instead')
const ModNexusReference$json = {
  '1': 'ModNexusReference',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'link_revision', '3': 3, '4': 1, '5': 3, '10': 'linkRevision'},
    {'1': 'version_id', '3': 4, '4': 1, '5': 9, '10': 'versionId'},
    {
      '1': 'provider_mod',
      '3': 5,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'providerMod',
      '17': true
    },
    {'1': 'mod_revision', '3': 6, '4': 1, '5': 3, '10': 'modRevision'},
  ],
  '8': [
    {'1': '_provider_mod'},
  ],
};

/// Descriptor for `ModNexusReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modNexusReferenceDescriptor = $convert.base64Decode(
    'ChFNb2ROZXh1c1JlZmVyZW5jZRIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh'
    'UKBm1vZF9pZBgCIAEoCVIFbW9kSWQSIwoNbGlua19yZXZpc2lvbhgDIAEoA1IMbGlua1Jldmlz'
    'aW9uEh0KCnZlcnNpb25faWQYBCABKAlSCXZlcnNpb25JZBImCgxwcm92aWRlcl9tb2QYBSABKA'
    'NIAFILcHJvdmlkZXJNb2SIAQESIQoMbW9kX3JldmlzaW9uGAYgASgDUgttb2RSZXZpc2lvbkIP'
    'Cg1fcHJvdmlkZXJfbW9k');

@$core.Deprecated('Use nexusMetadataFileDescriptor instead')
const NexusMetadataFile$json = {
  '1': 'NexusMetadataFile',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusFileInfo',
      '10': 'file'
    },
    {'1': 'category_id', '3': 2, '4': 1, '5': 5, '10': 'categoryId'},
    {
      '1': 'uploaded_unix_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'uploadedUnixMs',
      '17': true
    },
    {'1': 'update_candidate', '3': 4, '4': 1, '5': 8, '10': 'updateCandidate'},
  ],
  '8': [
    {'1': '_uploaded_unix_ms'},
  ],
};

/// Descriptor for `NexusMetadataFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusMetadataFileDescriptor = $convert.base64Decode(
    'ChFOZXh1c01ldGFkYXRhRmlsZRIyCgRmaWxlGAEgASgLMh4ubW9kY29uZHVjdG9yLnYxLk5leH'
    'VzRmlsZUluZm9SBGZpbGUSHwoLY2F0ZWdvcnlfaWQYAiABKAVSCmNhdGVnb3J5SWQSLQoQdXBs'
    'b2FkZWRfdW5peF9tcxgDIAEoA0gAUg51cGxvYWRlZFVuaXhNc4gBARIpChB1cGRhdGVfY2FuZG'
    'lkYXRlGAQgASgIUg91cGRhdGVDYW5kaWRhdGVCEwoRX3VwbG9hZGVkX3VuaXhfbXM=');

@$core.Deprecated('Use nexusPublicMetadataDescriptor instead')
const NexusPublicMetadata$json = {
  '1': 'NexusPublicMetadata',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'summary', '3': 2, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'uploader', '3': 5, '4': 1, '5': 9, '10': 'uploader'},
    {
      '1': 'category_id',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'categoryId',
      '17': true
    },
    {'1': 'category', '3': 7, '4': 1, '5': 9, '10': 'category'},
    {
      '1': 'modified_unix_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'modifiedUnixMs',
      '17': true
    },
    {'1': 'available', '3': 9, '4': 1, '5': 8, '10': 'available'},
    {'1': 'allows_rating', '3': 10, '4': 1, '5': 8, '10': 'allowsRating'},
    {
      '1': 'files',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.NexusMetadataFile',
      '10': 'files'
    },
  ],
  '8': [
    {'1': '_category_id'},
    {'1': '_modified_unix_ms'},
  ],
};

/// Descriptor for `NexusPublicMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusPublicMetadataDescriptor = $convert.base64Decode(
    'ChNOZXh1c1B1YmxpY01ldGFkYXRhEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHc3VtbWFyeRgCIA'
    'EoCVIHc3VtbWFyeRIYCgd2ZXJzaW9uGAMgASgJUgd2ZXJzaW9uEhYKBmF1dGhvchgEIAEoCVIG'
    'YXV0aG9yEhoKCHVwbG9hZGVyGAUgASgJUgh1cGxvYWRlchIkCgtjYXRlZ29yeV9pZBgGIAEoA0'
    'gAUgpjYXRlZ29yeUlkiAEBEhoKCGNhdGVnb3J5GAcgASgJUghjYXRlZ29yeRItChBtb2RpZmll'
    'ZF91bml4X21zGAggASgDSAFSDm1vZGlmaWVkVW5peE1ziAEBEhwKCWF2YWlsYWJsZRgJIAEoCF'
    'IJYXZhaWxhYmxlEiMKDWFsbG93c19yYXRpbmcYCiABKAhSDGFsbG93c1JhdGluZxI4CgVmaWxl'
    'cxgLIAMoCzIiLm1vZGNvbmR1Y3Rvci52MS5OZXh1c01ldGFkYXRhRmlsZVIFZmlsZXNCDgoMX2'
    'NhdGVnb3J5X2lkQhMKEV9tb2RpZmllZF91bml4X21z');

@$core.Deprecated('Use modNexusDetailsDescriptor instead')
const ModNexusDetails$json = {
  '1': 'ModNexusDetails',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusReference',
      '10': 'reference'
    },
    {'1': 'local_name', '3': 2, '4': 1, '5': 9, '10': 'localName'},
    {
      '1': 'installed_file',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'installedFile',
      '17': true
    },
    {
      '1': 'installed_version',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'installedVersion'
    },
    {'1': 'linked_manually', '3': 5, '4': 1, '5': 8, '10': 'linkedManually'},
    {
      '1': 'metadata',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusPublicMetadata',
      '9': 1,
      '10': 'metadata',
      '17': true
    },
    {'1': 'freshness', '3': 7, '4': 1, '5': 9, '10': 'freshness'},
    {
      '1': 'checked_unix_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'checkedUnixMs',
      '17': true
    },
    {'1': 'problem', '3': 9, '4': 1, '5': 9, '10': 'problem'},
    {
      '1': 'category_id',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'categoryId',
      '17': true
    },
    {'1': 'category', '3': 11, '4': 1, '5': 9, '10': 'category'},
  ],
  '8': [
    {'1': '_installed_file'},
    {'1': '_metadata'},
    {'1': '_checked_unix_ms'},
    {'1': '_category_id'},
  ],
};

/// Descriptor for `ModNexusDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modNexusDetailsDescriptor = $convert.base64Decode(
    'Cg9Nb2ROZXh1c0RldGFpbHMSQAoJcmVmZXJlbmNlGAEgASgLMiIubW9kY29uZHVjdG9yLnYxLk'
    '1vZE5leHVzUmVmZXJlbmNlUglyZWZlcmVuY2USHQoKbG9jYWxfbmFtZRgCIAEoCVIJbG9jYWxO'
    'YW1lEioKDmluc3RhbGxlZF9maWxlGAMgASgDSABSDWluc3RhbGxlZEZpbGWIAQESKwoRaW5zdG'
    'FsbGVkX3ZlcnNpb24YBCABKAlSEGluc3RhbGxlZFZlcnNpb24SJwoPbGlua2VkX21hbnVhbGx5'
    'GAUgASgIUg5saW5rZWRNYW51YWxseRJFCghtZXRhZGF0YRgGIAEoCzIkLm1vZGNvbmR1Y3Rvci'
    '52MS5OZXh1c1B1YmxpY01ldGFkYXRhSAFSCG1ldGFkYXRhiAEBEhwKCWZyZXNobmVzcxgHIAEo'
    'CVIJZnJlc2huZXNzEisKD2NoZWNrZWRfdW5peF9tcxgIIAEoA0gCUg1jaGVja2VkVW5peE1ziA'
    'EBEhgKB3Byb2JsZW0YCSABKAlSB3Byb2JsZW0SJAoLY2F0ZWdvcnlfaWQYCiABKAlIA1IKY2F0'
    'ZWdvcnlJZIgBARIaCghjYXRlZ29yeRgLIAEoCVIIY2F0ZWdvcnlCEQoPX2luc3RhbGxlZF9maW'
    'xlQgsKCV9tZXRhZGF0YUISChBfY2hlY2tlZF91bml4X21zQg4KDF9jYXRlZ29yeV9pZA==');

@$core.Deprecated('Use modNexusReplyDescriptor instead')
const ModNexusReply$json = {
  '1': 'ModNexusReply',
  '2': [
    {
      '1': 'details',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusDetails',
      '9': 0,
      '10': 'details'
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

/// Descriptor for `ModNexusReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modNexusReplyDescriptor = $convert.base64Decode(
    'Cg1Nb2ROZXh1c1JlcGx5EjwKB2RldGFpbHMYASABKAsyIC5tb2Rjb25kdWN0b3IudjEuTW9kTm'
    'V4dXNEZXRhaWxzSABSB2RldGFpbHMSOQoHZmFpbHVyZRgCIAEoCzIdLm1vZGNvbmR1Y3Rvci52'
    'MS5OZXh1c0ZhaWx1cmVIAFIHZmFpbHVyZUIICgZyZXN1bHQ=');

@$core.Deprecated('Use linkModNexusRequestDescriptor instead')
const LinkModNexusRequest$json = {
  '1': 'LinkModNexusRequest',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusReference',
      '10': 'reference'
    },
    {
      '1': 'provider_mod',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'providerMod',
      '17': true
    },
    {
      '1': 'file_id',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'fileId',
      '17': true
    },
    {'1': 'profile_id', '3': 4, '4': 1, '5': 9, '10': 'profileId'},
  ],
  '8': [
    {'1': '_provider_mod'},
    {'1': '_file_id'},
  ],
};

/// Descriptor for `LinkModNexusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkModNexusRequestDescriptor = $convert.base64Decode(
    'ChNMaW5rTW9kTmV4dXNSZXF1ZXN0EkAKCXJlZmVyZW5jZRgBIAEoCzIiLm1vZGNvbmR1Y3Rvci'
    '52MS5Nb2ROZXh1c1JlZmVyZW5jZVIJcmVmZXJlbmNlEiYKDHByb3ZpZGVyX21vZBgCIAEoA0gA'
    'Ugtwcm92aWRlck1vZIgBARIcCgdmaWxlX2lkGAMgASgDSAFSBmZpbGVJZIgBARIdCgpwcm9maW'
    'xlX2lkGAQgASgJUglwcm9maWxlSWRCDwoNX3Byb3ZpZGVyX21vZEIKCghfZmlsZV9pZA==');

@$core.Deprecated('Use mapModNexusCategoryRequestDescriptor instead')
const MapModNexusCategoryRequest$json = {
  '1': 'MapModNexusCategoryRequest',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusReference',
      '10': 'reference'
    },
    {'1': 'category_id', '3': 2, '4': 1, '5': 9, '10': 'categoryId'},
    {
      '1': 'provider_category_id',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'providerCategoryId'
    },
  ],
};

/// Descriptor for `MapModNexusCategoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mapModNexusCategoryRequestDescriptor = $convert.base64Decode(
    'ChpNYXBNb2ROZXh1c0NhdGVnb3J5UmVxdWVzdBJACglyZWZlcmVuY2UYASABKAsyIi5tb2Rjb2'
    '5kdWN0b3IudjEuTW9kTmV4dXNSZWZlcmVuY2VSCXJlZmVyZW5jZRIfCgtjYXRlZ29yeV9pZBgC'
    'IAEoCVIKY2F0ZWdvcnlJZBIwChRwcm92aWRlcl9jYXRlZ29yeV9pZBgDIAEoA1IScHJvdmlkZX'
    'JDYXRlZ29yeUlk');

@$core.Deprecated('Use downloadModNexusFileRequestDescriptor instead')
const DownloadModNexusFileRequest$json = {
  '1': 'DownloadModNexusFileRequest',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusReference',
      '10': 'reference'
    },
    {'1': 'file_id', '3': 2, '4': 1, '5': 3, '10': 'fileId'},
    {'1': 'update_only', '3': 3, '4': 1, '5': 8, '10': 'updateOnly'},
    {'1': 'artifact_id', '3': 4, '4': 1, '5': 9, '10': 'artifactId'},
  ],
};

/// Descriptor for `DownloadModNexusFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadModNexusFileRequestDescriptor = $convert.base64Decode(
    'ChtEb3dubG9hZE1vZE5leHVzRmlsZVJlcXVlc3QSQAoJcmVmZXJlbmNlGAEgASgLMiIubW9kY2'
    '9uZHVjdG9yLnYxLk1vZE5leHVzUmVmZXJlbmNlUglyZWZlcmVuY2USFwoHZmlsZV9pZBgCIAEo'
    'A1IGZmlsZUlkEh8KC3VwZGF0ZV9vbmx5GAMgASgIUgp1cGRhdGVPbmx5Eh8KC2FydGlmYWN0X2'
    'lkGAQgASgJUgphcnRpZmFjdElk');
