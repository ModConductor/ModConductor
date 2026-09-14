// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_inspection.proto.

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

@$core.Deprecated('Use inspectedArchiveDescriptor instead')
const InspectedArchive$json = {
  '1': 'InspectedArchive',
  '2': [
    {'1': 'sha256', '3': 1, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
    {
      '1': 'entries',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InspectedArchiveEntry',
      '10': 'entries'
    },
    {'1': 'total_size', '3': 4, '4': 1, '5': 4, '10': 'totalSize'},
  ],
};

/// Descriptor for `InspectedArchive`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectedArchiveDescriptor = $convert.base64Decode(
    'ChBJbnNwZWN0ZWRBcmNoaXZlEhYKBnNoYTI1NhgBIAEoCVIGc2hhMjU2EhYKBmZvcm1hdBgCIA'
    'EoCVIGZm9ybWF0EkAKB2VudHJpZXMYAyADKAsyJi5tb2Rjb25kdWN0b3IudjEuSW5zcGVjdGVk'
    'QXJjaGl2ZUVudHJ5UgdlbnRyaWVzEh0KCnRvdGFsX3NpemUYBCABKARSCXRvdGFsU2l6ZQ==');

@$core.Deprecated('Use inspectedArchiveEntryDescriptor instead')
const InspectedArchiveEntry$json = {
  '1': 'InspectedArchiveEntry',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'components', '3': 2, '4': 3, '5': 9, '10': 'components'},
    {'1': 'directory', '3': 3, '4': 1, '5': 8, '10': 'directory'},
    {'1': 'size', '3': 4, '4': 1, '5': 4, '10': 'size'},
    {
      '1': 'compressed_size',
      '3': 5,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'compressedSize',
      '17': true
    },
  ],
  '8': [
    {'1': '_compressed_size'},
  ],
};

/// Descriptor for `InspectedArchiveEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectedArchiveEntryDescriptor = $convert.base64Decode(
    'ChVJbnNwZWN0ZWRBcmNoaXZlRW50cnkSFAoFaW5kZXgYASABKA1SBWluZGV4Eh4KCmNvbXBvbm'
    'VudHMYAiADKAlSCmNvbXBvbmVudHMSHAoJZGlyZWN0b3J5GAMgASgIUglkaXJlY3RvcnkSEgoE'
    'c2l6ZRgEIAEoBFIEc2l6ZRIsCg9jb21wcmVzc2VkX3NpemUYBSABKARIAFIOY29tcHJlc3NlZF'
    'NpemWIAQFCEgoQX2NvbXByZXNzZWRfc2l6ZQ==');

@$core.Deprecated('Use previewArchiveEntryRequestDescriptor instead')
const PreviewArchiveEntryRequest$json = {
  '1': 'PreviewArchiveEntryRequest',
  '2': [
    {
      '1': 'artifact',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArtifactReference',
      '10': 'artifact'
    },
    {'1': 'sha256', '3': 2, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'format', '3': 3, '4': 1, '5': 9, '10': 'format'},
    {
      '1': 'entry',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InspectedArchiveEntry',
      '10': 'entry'
    },
    {
      '1': 'representation',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FilePreviewRepresentation',
      '10': 'representation'
    },
  ],
};

/// Descriptor for `PreviewArchiveEntryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewArchiveEntryRequestDescriptor = $convert.base64Decode(
    'ChpQcmV2aWV3QXJjaGl2ZUVudHJ5UmVxdWVzdBI+CghhcnRpZmFjdBgBIAEoCzIiLm1vZGNvbm'
    'R1Y3Rvci52MS5BcnRpZmFjdFJlZmVyZW5jZVIIYXJ0aWZhY3QSFgoGc2hhMjU2GAIgASgJUgZz'
    'aGEyNTYSFgoGZm9ybWF0GAMgASgJUgZmb3JtYXQSPAoFZW50cnkYBCABKAsyJi5tb2Rjb25kdW'
    'N0b3IudjEuSW5zcGVjdGVkQXJjaGl2ZUVudHJ5UgVlbnRyeRJSCg5yZXByZXNlbnRhdGlvbhgF'
    'IAEoDjIqLm1vZGNvbmR1Y3Rvci52MS5GaWxlUHJldmlld1JlcHJlc2VudGF0aW9uUg5yZXByZX'
    'NlbnRhdGlvbg==');
