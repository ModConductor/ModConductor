// This is a generated file - do not edit.
//
// Generated from modconductor/v1/installation_review.proto.

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

@$core.Deprecated('Use installationSourcePathDescriptor instead')
const InstallationSourcePath$json = {
  '1': 'InstallationSourcePath',
  '2': [
    {'1': 'path', '3': 1, '4': 3, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `InstallationSourcePath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationSourcePathDescriptor =
    $convert.base64Decode(
        'ChZJbnN0YWxsYXRpb25Tb3VyY2VQYXRoEhIKBHBhdGgYASADKAlSBHBhdGg=');

@$core.Deprecated('Use installationReviewedFileDescriptor instead')
const InstallationReviewedFile$json = {
  '1': 'InstallationReviewedFile',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'destination', '3': 2, '4': 3, '5': 9, '10': 'destination'},
    {'1': 'source', '3': 3, '4': 3, '5': 9, '10': 'source'},
    {'1': 'choice', '3': 4, '4': 1, '5': 9, '10': 'choice'},
    {'1': 'bytes', '3': 5, '4': 1, '5': 4, '10': 'bytes'},
    {
      '1': 'replaces',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InstallationSourcePath',
      '10': 'replaces'
    },
  ],
};

/// Descriptor for `InstallationReviewedFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationReviewedFileDescriptor = $convert.base64Decode(
    'ChhJbnN0YWxsYXRpb25SZXZpZXdlZEZpbGUSFAoFaW5kZXgYASABKA1SBWluZGV4EiAKC2Rlc3'
    'RpbmF0aW9uGAIgAygJUgtkZXN0aW5hdGlvbhIWCgZzb3VyY2UYAyADKAlSBnNvdXJjZRIWCgZj'
    'aG9pY2UYBCABKAlSBmNob2ljZRIUCgVieXRlcxgFIAEoBFIFYnl0ZXMSQwoIcmVwbGFjZXMYBi'
    'ADKAsyJy5tb2Rjb25kdWN0b3IudjEuSW5zdGFsbGF0aW9uU291cmNlUGF0aFIIcmVwbGFjZXM=');
