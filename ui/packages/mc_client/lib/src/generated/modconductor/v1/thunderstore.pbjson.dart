// This is a generated file - do not edit.
//
// Generated from modconductor/v1/thunderstore.proto.

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

@$core.Deprecated('Use thunderstorePackageReferenceDescriptor instead')
const ThunderstorePackageReference$json = {
  '1': 'ThunderstorePackageReference',
  '2': [
    {'1': 'community', '3': 1, '4': 1, '5': 9, '10': 'community'},
    {'1': 'namespace', '3': 2, '4': 1, '5': 9, '10': 'namespace'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ThunderstorePackageReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstorePackageReferenceDescriptor =
    $convert.base64Decode(
        'ChxUaHVuZGVyc3RvcmVQYWNrYWdlUmVmZXJlbmNlEhwKCWNvbW11bml0eRgBIAEoCVIJY29tbX'
        'VuaXR5EhwKCW5hbWVzcGFjZRgCIAEoCVIJbmFtZXNwYWNlEhIKBG5hbWUYAyABKAlSBG5hbWU=');

@$core.Deprecated('Use thunderstoreVersionReferenceDescriptor instead')
const ThunderstoreVersionReference$json = {
  '1': 'ThunderstoreVersionReference',
  '2': [
    {
      '1': 'package',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstorePackageReference',
      '10': 'package'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `ThunderstoreVersionReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreVersionReferenceDescriptor =
    $convert.base64Decode(
        'ChxUaHVuZGVyc3RvcmVWZXJzaW9uUmVmZXJlbmNlEkcKB3BhY2thZ2UYASABKAsyLS5tb2Rjb2'
        '5kdWN0b3IudjEuVGh1bmRlcnN0b3JlUGFja2FnZVJlZmVyZW5jZVIHcGFja2FnZRIYCgd2ZXJz'
        'aW9uGAIgASgJUgd2ZXJzaW9u');

@$core.Deprecated('Use thunderstoreFailureDescriptor instead')
const ThunderstoreFailure$json = {
  '1': 'ThunderstoreFailure',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'retry_at_unix_ms',
      '3': 2,
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

/// Descriptor for `ThunderstoreFailure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreFailureDescriptor = $convert.base64Decode(
    'ChNUaHVuZGVyc3RvcmVGYWlsdXJlEhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2USLAoQcmV0cn'
    'lfYXRfdW5peF9tcxgCIAEoA0gAUg1yZXRyeUF0VW5peE1ziAEBQhMKEV9yZXRyeV9hdF91bml4'
    'X21z');

@$core.Deprecated('Use thunderstoreInstalledDescriptor instead')
const ThunderstoreInstalled$json = {
  '1': 'ThunderstoreInstalled',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreVersionReference',
      '10': 'reference'
    },
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
  ],
};

/// Descriptor for `ThunderstoreInstalled`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreInstalledDescriptor = $convert.base64Decode(
    'ChVUaHVuZGVyc3RvcmVJbnN0YWxsZWQSSwoJcmVmZXJlbmNlGAEgASgLMi0ubW9kY29uZHVjdG'
    '9yLnYxLlRodW5kZXJzdG9yZVZlcnNpb25SZWZlcmVuY2VSCXJlZmVyZW5jZRIVCgZtb2RfaWQY'
    'AiABKAlSBW1vZElk');

@$core.Deprecated('Use thunderstorePackagePreviewDescriptor instead')
const ThunderstorePackagePreview$json = {
  '1': 'ThunderstorePackagePreview',
  '2': [
    {
      '1': 'package',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstorePackageReference',
      '10': 'package'
    },
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'icon_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'iconUrl',
      '17': true
    },
    {'1': 'deprecated', '3': 4, '4': 1, '5': 8, '10': 'deprecated'},
    {
      '1': 'installed',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreInstalled',
      '10': 'installed'
    },
  ],
  '8': [
    {'1': '_icon_url'},
  ],
};

/// Descriptor for `ThunderstorePackagePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstorePackagePreviewDescriptor = $convert.base64Decode(
    'ChpUaHVuZGVyc3RvcmVQYWNrYWdlUHJldmlldxJHCgdwYWNrYWdlGAEgASgLMi0ubW9kY29uZH'
    'VjdG9yLnYxLlRodW5kZXJzdG9yZVBhY2thZ2VSZWZlcmVuY2VSB3BhY2thZ2USIAoLZGVzY3Jp'
    'cHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEh4KCGljb25fdXJsGAMgASgJSABSB2ljb25VcmyIAQ'
    'ESHgoKZGVwcmVjYXRlZBgEIAEoCFIKZGVwcmVjYXRlZBJECglpbnN0YWxsZWQYBSADKAsyJi5t'
    'b2Rjb25kdWN0b3IudjEuVGh1bmRlcnN0b3JlSW5zdGFsbGVkUglpbnN0YWxsZWRCCwoJX2ljb2'
    '5fdXJs');

@$core.Deprecated('Use thunderstoreSearchRequestDescriptor instead')
const ThunderstoreSearchRequest$json = {
  '1': 'ThunderstoreSearchRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'community', '3': 2, '4': 1, '5': 9, '10': 'community'},
    {'1': 'query', '3': 3, '4': 1, '5': 9, '10': 'query'},
    {'1': 'ordering', '3': 4, '4': 1, '5': 9, '10': 'ordering'},
    {'1': 'page', '3': 5, '4': 1, '5': 5, '10': 'page'},
  ],
};

/// Descriptor for `ThunderstoreSearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreSearchRequestDescriptor = $convert.base64Decode(
    'ChlUaHVuZGVyc3RvcmVTZWFyY2hSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3'
    'NwYWNlSWQSHAoJY29tbXVuaXR5GAIgASgJUgljb21tdW5pdHkSFAoFcXVlcnkYAyABKAlSBXF1'
    'ZXJ5EhoKCG9yZGVyaW5nGAQgASgJUghvcmRlcmluZxISCgRwYWdlGAUgASgFUgRwYWdl');

@$core.Deprecated('Use thunderstorePackagesDescriptor instead')
const ThunderstorePackages$json = {
  '1': 'ThunderstorePackages',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ThunderstorePackagePreview',
      '10': 'entries'
    },
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
    {
      '1': 'next_page',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'nextPage',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_page'},
  ],
};

/// Descriptor for `ThunderstorePackages`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstorePackagesDescriptor = $convert.base64Decode(
    'ChRUaHVuZGVyc3RvcmVQYWNrYWdlcxJFCgdlbnRyaWVzGAEgAygLMisubW9kY29uZHVjdG9yLn'
    'YxLlRodW5kZXJzdG9yZVBhY2thZ2VQcmV2aWV3UgdlbnRyaWVzEhQKBWNvdW50GAIgASgFUgVj'
    'b3VudBIgCgluZXh0X3BhZ2UYAyABKAVIAFIIbmV4dFBhZ2WIAQFCDAoKX25leHRfcGFnZQ==');

@$core.Deprecated('Use thunderstoreSearchReplyDescriptor instead')
const ThunderstoreSearchReply$json = {
  '1': 'ThunderstoreSearchReply',
  '2': [
    {
      '1': 'packages',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstorePackages',
      '9': 0,
      '10': 'packages'
    },
    {
      '1': 'failure',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreFailure',
      '9': 0,
      '10': 'failure'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ThunderstoreSearchReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreSearchReplyDescriptor = $convert.base64Decode(
    'ChdUaHVuZGVyc3RvcmVTZWFyY2hSZXBseRJDCghwYWNrYWdlcxgBIAEoCzIlLm1vZGNvbmR1Y3'
    'Rvci52MS5UaHVuZGVyc3RvcmVQYWNrYWdlc0gAUghwYWNrYWdlcxJACgdmYWlsdXJlGAIgASgL'
    'MiQubW9kY29uZHVjdG9yLnYxLlRodW5kZXJzdG9yZUZhaWx1cmVIAFIHZmFpbHVyZUIJCgdvdX'
    'Rjb21l');

@$core.Deprecated('Use thunderstoreDependencyDescriptor instead')
const ThunderstoreDependency$json = {
  '1': 'ThunderstoreDependency',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreVersionReference',
      '10': 'reference'
    },
    {'1': 'available', '3': 2, '4': 1, '5': 8, '10': 'available'},
    {
      '1': 'installed',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreInstalled',
      '10': 'installed'
    },
    {
      '1': 'icon_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'iconUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_icon_url'},
  ],
};

/// Descriptor for `ThunderstoreDependency`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreDependencyDescriptor = $convert.base64Decode(
    'ChZUaHVuZGVyc3RvcmVEZXBlbmRlbmN5EksKCXJlZmVyZW5jZRgBIAEoCzItLm1vZGNvbmR1Y3'
    'Rvci52MS5UaHVuZGVyc3RvcmVWZXJzaW9uUmVmZXJlbmNlUglyZWZlcmVuY2USHAoJYXZhaWxh'
    'YmxlGAIgASgIUglhdmFpbGFibGUSRAoJaW5zdGFsbGVkGAMgAygLMiYubW9kY29uZHVjdG9yLn'
    'YxLlRodW5kZXJzdG9yZUluc3RhbGxlZFIJaW5zdGFsbGVkEh4KCGljb25fdXJsGAQgASgJSABS'
    'B2ljb25VcmyIAQFCCwoJX2ljb25fdXJs');

@$core.Deprecated('Use thunderstorePackageRequestDescriptor instead')
const ThunderstorePackageRequest$json = {
  '1': 'ThunderstorePackageRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'package',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstorePackageReference',
      '10': 'package'
    },
    {
      '1': 'version',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'version',
      '17': true
    },
  ],
  '8': [
    {'1': '_version'},
  ],
};

/// Descriptor for `ThunderstorePackageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstorePackageRequestDescriptor = $convert.base64Decode(
    'ChpUaHVuZGVyc3RvcmVQYWNrYWdlUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcm'
    'tzcGFjZUlkEkcKB3BhY2thZ2UYAiABKAsyLS5tb2Rjb25kdWN0b3IudjEuVGh1bmRlcnN0b3Jl'
    'UGFja2FnZVJlZmVyZW5jZVIHcGFja2FnZRIdCgd2ZXJzaW9uGAMgASgJSABSB3ZlcnNpb26IAQ'
    'FCCgoIX3ZlcnNpb24=');

@$core.Deprecated('Use thunderstorePackageDetailsDescriptor instead')
const ThunderstorePackageDetails$json = {
  '1': 'ThunderstorePackageDetails',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreVersionReference',
      '10': 'reference'
    },
    {'1': 'latest_version', '3': 2, '4': 1, '5': 9, '10': 'latestVersion'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'icon_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'iconUrl',
      '17': true
    },
    {'1': 'deprecated', '3': 5, '4': 1, '5': 8, '10': 'deprecated'},
    {'1': 'categories', '3': 6, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'bytes', '3': 7, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'versions', '3': 8, '4': 3, '5': 9, '10': 'versions'},
    {
      '1': 'dependencies',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreDependency',
      '10': 'dependencies'
    },
    {
      '1': 'installed',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreInstalled',
      '10': 'installed'
    },
  ],
  '8': [
    {'1': '_icon_url'},
  ],
};

/// Descriptor for `ThunderstorePackageDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstorePackageDetailsDescriptor = $convert.base64Decode(
    'ChpUaHVuZGVyc3RvcmVQYWNrYWdlRGV0YWlscxJLCglyZWZlcmVuY2UYASABKAsyLS5tb2Rjb2'
    '5kdWN0b3IudjEuVGh1bmRlcnN0b3JlVmVyc2lvblJlZmVyZW5jZVIJcmVmZXJlbmNlEiUKDmxh'
    'dGVzdF92ZXJzaW9uGAIgASgJUg1sYXRlc3RWZXJzaW9uEiAKC2Rlc2NyaXB0aW9uGAMgASgJUg'
    'tkZXNjcmlwdGlvbhIeCghpY29uX3VybBgEIAEoCUgAUgdpY29uVXJsiAEBEh4KCmRlcHJlY2F0'
    'ZWQYBSABKAhSCmRlcHJlY2F0ZWQSHgoKY2F0ZWdvcmllcxgGIAMoCVIKY2F0ZWdvcmllcxIUCg'
    'VieXRlcxgHIAEoBFIFYnl0ZXMSGgoIdmVyc2lvbnMYCCADKAlSCHZlcnNpb25zEksKDGRlcGVu'
    'ZGVuY2llcxgJIAMoCzInLm1vZGNvbmR1Y3Rvci52MS5UaHVuZGVyc3RvcmVEZXBlbmRlbmN5Ug'
    'xkZXBlbmRlbmNpZXMSRAoJaW5zdGFsbGVkGAogAygLMiYubW9kY29uZHVjdG9yLnYxLlRodW5k'
    'ZXJzdG9yZUluc3RhbGxlZFIJaW5zdGFsbGVkQgsKCV9pY29uX3VybA==');

@$core.Deprecated('Use thunderstorePackageReplyDescriptor instead')
const ThunderstorePackageReply$json = {
  '1': 'ThunderstorePackageReply',
  '2': [
    {
      '1': 'package',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstorePackageDetails',
      '9': 0,
      '10': 'package'
    },
    {
      '1': 'failure',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreFailure',
      '9': 0,
      '10': 'failure'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ThunderstorePackageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstorePackageReplyDescriptor = $convert.base64Decode(
    'ChhUaHVuZGVyc3RvcmVQYWNrYWdlUmVwbHkSRwoHcGFja2FnZRgBIAEoCzIrLm1vZGNvbmR1Y3'
    'Rvci52MS5UaHVuZGVyc3RvcmVQYWNrYWdlRGV0YWlsc0gAUgdwYWNrYWdlEkAKB2ZhaWx1cmUY'
    'AiABKAsyJC5tb2Rjb25kdWN0b3IudjEuVGh1bmRlcnN0b3JlRmFpbHVyZUgAUgdmYWlsdXJlQg'
    'kKB291dGNvbWU=');

@$core.Deprecated('Use thunderstoreAcquireRequestDescriptor instead')
const ThunderstoreAcquireRequest$json = {
  '1': 'ThunderstoreAcquireRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'reference',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreVersionReference',
      '10': 'reference'
    },
  ],
};

/// Descriptor for `ThunderstoreAcquireRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreAcquireRequestDescriptor =
    $convert.base64Decode(
        'ChpUaHVuZGVyc3RvcmVBY3F1aXJlUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcm'
        'tzcGFjZUlkEksKCXJlZmVyZW5jZRgCIAEoCzItLm1vZGNvbmR1Y3Rvci52MS5UaHVuZGVyc3Rv'
        'cmVWZXJzaW9uUmVmZXJlbmNlUglyZWZlcmVuY2U=');

@$core.Deprecated('Use thunderstoreAcquisitionDescriptor instead')
const ThunderstoreAcquisition$json = {
  '1': 'ThunderstoreAcquisition',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreVersionReference',
      '10': 'reference'
    },
    {'1': 'stage', '3': 2, '4': 1, '5': 9, '10': 'stage'},
    {'1': 'bytes', '3': 3, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'total', '3': 4, '4': 1, '5': 4, '9': 0, '10': 'total', '17': true},
    {'1': 'completed', '3': 5, '4': 1, '5': 5, '10': 'completed'},
    {'1': 'packages', '3': 6, '4': 1, '5': 5, '10': 'packages'},
    {'1': 'mod_id', '3': 7, '4': 1, '5': 9, '9': 1, '10': 'modId', '17': true},
    {
      '1': 'failure',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreFailure',
      '9': 2,
      '10': 'failure',
      '17': true
    },
  ],
  '8': [
    {'1': '_total'},
    {'1': '_mod_id'},
    {'1': '_failure'},
  ],
};

/// Descriptor for `ThunderstoreAcquisition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreAcquisitionDescriptor = $convert.base64Decode(
    'ChdUaHVuZGVyc3RvcmVBY3F1aXNpdGlvbhJLCglyZWZlcmVuY2UYASABKAsyLS5tb2Rjb25kdW'
    'N0b3IudjEuVGh1bmRlcnN0b3JlVmVyc2lvblJlZmVyZW5jZVIJcmVmZXJlbmNlEhQKBXN0YWdl'
    'GAIgASgJUgVzdGFnZRIUCgVieXRlcxgDIAEoBFIFYnl0ZXMSGQoFdG90YWwYBCABKARIAFIFdG'
    '90YWyIAQESHAoJY29tcGxldGVkGAUgASgFUgljb21wbGV0ZWQSGgoIcGFja2FnZXMYBiABKAVS'
    'CHBhY2thZ2VzEhoKBm1vZF9pZBgHIAEoCUgBUgVtb2RJZIgBARJDCgdmYWlsdXJlGAggASgLMi'
    'QubW9kY29uZHVjdG9yLnYxLlRodW5kZXJzdG9yZUZhaWx1cmVIAlIHZmFpbHVyZYgBAUIICgZf'
    'dG90YWxCCQoHX21vZF9pZEIKCghfZmFpbHVyZQ==');

@$core.Deprecated('Use thunderstoreOpenedDescriptor instead')
const ThunderstoreOpened$json = {
  '1': 'ThunderstoreOpened',
};

/// Descriptor for `ThunderstoreOpened`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreOpenedDescriptor =
    $convert.base64Decode('ChJUaHVuZGVyc3RvcmVPcGVuZWQ=');
