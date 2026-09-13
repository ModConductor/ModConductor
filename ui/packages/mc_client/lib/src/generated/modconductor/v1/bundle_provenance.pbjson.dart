// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bundle_provenance.proto.

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

@$core.Deprecated('Use bundleArchiveSourceDescriptor instead')
const BundleArchiveSource$json = {
  '1': 'BundleArchiveSource',
  '2': [
    {'1': 'path', '3': 1, '4': 3, '5': 9, '10': 'path'},
    {'1': 'sha256', '3': 2, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `BundleArchiveSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleArchiveSourceDescriptor = $convert.base64Decode(
    'ChNCdW5kbGVBcmNoaXZlU291cmNlEhIKBHBhdGgYASADKAlSBHBhdGgSFgoGc2hhMjU2GAIgAS'
    'gJUgZzaGEyNTY=');

@$core.Deprecated('Use bundleProvenanceDescriptor instead')
const BundleProvenance$json = {
  '1': 'BundleProvenance',
  '2': [
    {'1': 'parent_sha256', '3': 1, '4': 1, '5': 9, '10': 'parentSha256'},
    {
      '1': 'archives',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BundleArchiveSource',
      '10': 'archives'
    },
  ],
};

/// Descriptor for `BundleProvenance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleProvenanceDescriptor = $convert.base64Decode(
    'ChBCdW5kbGVQcm92ZW5hbmNlEiMKDXBhcmVudF9zaGEyNTYYASABKAlSDHBhcmVudFNoYTI1Nh'
    'JACghhcmNoaXZlcxgCIAMoCzIkLm1vZGNvbmR1Y3Rvci52MS5CdW5kbGVBcmNoaXZlU291cmNl'
    'UghhcmNoaXZlcw==');
