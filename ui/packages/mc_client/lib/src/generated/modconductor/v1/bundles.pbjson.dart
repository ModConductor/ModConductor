// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bundles.proto.

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

@$core.Deprecated('Use bundleModStateDescriptor instead')
const BundleModState$json = {
  '1': 'BundleModState',
  '2': [
    {'1': 'BUNDLE_MOD_STATE_UNSPECIFIED', '2': 0},
    {'1': 'BUNDLE_MOD_STATE_NEEDS_REVIEW', '2': 1},
    {'1': 'BUNDLE_MOD_STATE_INSTALLED', '2': 2},
    {'1': 'BUNDLE_MOD_STATE_FAILED', '2': 3},
    {'1': 'BUNDLE_MOD_STATE_INSTALLING', '2': 4},
  ],
};

/// Descriptor for `BundleModState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List bundleModStateDescriptor = $convert.base64Decode(
    'Cg5CdW5kbGVNb2RTdGF0ZRIgChxCVU5ETEVfTU9EX1NUQVRFX1VOU1BFQ0lGSUVEEAASIQodQl'
    'VORExFX01PRF9TVEFURV9ORUVEU19SRVZJRVcQARIeChpCVU5ETEVfTU9EX1NUQVRFX0lOU1RB'
    'TExFRBACEhsKF0JVTkRMRV9NT0RfU1RBVEVfRkFJTEVEEAMSHwobQlVORExFX01PRF9TVEFURV'
    '9JTlNUQUxMSU5HEAQ=');

@$core.Deprecated('Use bundleReferenceDescriptor instead')
const BundleReference$json = {
  '1': 'BundleReference',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `BundleReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleReferenceDescriptor = $convert.base64Decode(
    'Cg9CdW5kbGVSZWZlcmVuY2USIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBIOCg'
    'JpZBgCIAEoCVICaWQSGgoIcmV2aXNpb24YAyABKARSCHJldmlzaW9u');

@$core.Deprecated('Use bundleFoundDescriptor instead')
const BundleFound$json = {
  '1': 'BundleFound',
  '2': [
    {
      '1': 'bundle',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModBundle',
      '9': 0,
      '10': 'bundle',
      '17': true
    },
  ],
  '8': [
    {'1': '_bundle'},
  ],
};

/// Descriptor for `BundleFound`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleFoundDescriptor = $convert.base64Decode(
    'CgtCdW5kbGVGb3VuZBI3CgZidW5kbGUYASABKAsyGi5tb2Rjb25kdWN0b3IudjEuTW9kQnVuZG'
    'xlSABSBmJ1bmRsZYgBAUIJCgdfYnVuZGxl');

@$core.Deprecated('Use bundleArchiveDescriptor instead')
const BundleArchive$json = {
  '1': 'BundleArchive',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'path', '3': 2, '4': 3, '5': 9, '10': 'path'},
    {'1': 'bytes', '3': 3, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `BundleArchive`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleArchiveDescriptor = $convert.base64Decode(
    'Cg1CdW5kbGVBcmNoaXZlEhQKBWluZGV4GAEgASgNUgVpbmRleBISCgRwYXRoGAIgAygJUgRwYX'
    'RoEhQKBWJ5dGVzGAMgASgEUgVieXRlcw==');

@$core.Deprecated('Use bundleDiscoveryDescriptor instead')
const BundleDiscovery$json = {
  '1': 'BundleDiscovery',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArchiveInstallationDraft',
      '10': 'draft'
    },
    {
      '1': 'archives',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BundleArchive',
      '10': 'archives'
    },
  ],
};

/// Descriptor for `BundleDiscovery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleDiscoveryDescriptor = $convert.base64Decode(
    'Cg9CdW5kbGVEaXNjb3ZlcnkSPwoFZHJhZnQYASABKAsyKS5tb2Rjb25kdWN0b3IudjEuQXJjaG'
    'l2ZUluc3RhbGxhdGlvbkRyYWZ0UgVkcmFmdBI6CghhcmNoaXZlcxgCIAMoCzIeLm1vZGNvbmR1'
    'Y3Rvci52MS5CdW5kbGVBcmNoaXZlUghhcmNoaXZlcw==');

@$core.Deprecated('Use bundleSelectionDescriptor instead')
const BundleSelection$json = {
  '1': 'BundleSelection',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'entries', '3': 2, '4': 3, '5': 13, '10': 'entries'},
  ],
};

/// Descriptor for `BundleSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleSelectionDescriptor = $convert.base64Decode(
    'Cg9CdW5kbGVTZWxlY3Rpb24SQQoFZHJhZnQYASABKAsyKy5tb2Rjb25kdWN0b3IudjEuSW5zdG'
    'FsbGF0aW9uRHJhZnRSZWZlcmVuY2VSBWRyYWZ0EhgKB2VudHJpZXMYAiADKA1SB2VudHJpZXM=');

@$core.Deprecated('Use bundleModRequestDescriptor instead')
const BundleModRequest$json = {
  '1': 'BundleModRequest',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BundleReference',
      '10': 'reference'
    },
    {'1': 'mod', '3': 2, '4': 1, '5': 9, '10': 'mod'},
  ],
};

/// Descriptor for `BundleModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleModRequestDescriptor = $convert.base64Decode(
    'ChBCdW5kbGVNb2RSZXF1ZXN0Ej4KCXJlZmVyZW5jZRgBIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS'
    '5CdW5kbGVSZWZlcmVuY2VSCXJlZmVyZW5jZRIQCgNtb2QYAiABKAlSA21vZA==');

@$core.Deprecated('Use nestedBundleSelectionDescriptor instead')
const NestedBundleSelection$json = {
  '1': 'NestedBundleSelection',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BundleModRequest',
      '10': 'target'
    },
    {
      '1': 'draft',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'entries', '3': 3, '4': 3, '5': 13, '10': 'entries'},
  ],
};

/// Descriptor for `NestedBundleSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nestedBundleSelectionDescriptor = $convert.base64Decode(
    'ChVOZXN0ZWRCdW5kbGVTZWxlY3Rpb24SOQoGdGFyZ2V0GAEgASgLMiEubW9kY29uZHVjdG9yLn'
    'YxLkJ1bmRsZU1vZFJlcXVlc3RSBnRhcmdldBJBCgVkcmFmdBgCIAEoCzIrLm1vZGNvbmR1Y3Rv'
    'ci52MS5JbnN0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIFZHJhZnQSGAoHZW50cmllcxgDIAMoDV'
    'IHZW50cmllcw==');

@$core.Deprecated('Use bundleModRenameDescriptor instead')
const BundleModRename$json = {
  '1': 'BundleModRename',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BundleModRequest',
      '10': 'target'
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `BundleModRename`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleModRenameDescriptor = $convert.base64Decode(
    'Cg9CdW5kbGVNb2RSZW5hbWUSOQoGdGFyZ2V0GAEgASgLMiEubW9kY29uZHVjdG9yLnYxLkJ1bm'
    'RsZU1vZFJlcXVlc3RSBnRhcmdldBISCgRuYW1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use bundleModMoveDescriptor instead')
const BundleModMove$json = {
  '1': 'BundleModMove',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BundleModRequest',
      '10': 'target'
    },
    {'1': 'earlier', '3': 2, '4': 1, '5': 8, '10': 'earlier'},
  ],
};

/// Descriptor for `BundleModMove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleModMoveDescriptor = $convert.base64Decode(
    'Cg1CdW5kbGVNb2RNb3ZlEjkKBnRhcmdldBgBIAEoCzIhLm1vZGNvbmR1Y3Rvci52MS5CdW5kbG'
    'VNb2RSZXF1ZXN0UgZ0YXJnZXQSGAoHZWFybGllchgCIAEoCFIHZWFybGllcg==');

@$core.Deprecated('Use bundleConfigurationDescriptor instead')
const BundleConfiguration$json = {
  '1': 'BundleConfiguration',
  '2': [
    {
      '1': 'bundle',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModBundle',
      '10': 'bundle'
    },
    {
      '1': 'prepared',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BundleDiscovery',
      '10': 'prepared'
    },
  ],
};

/// Descriptor for `BundleConfiguration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleConfigurationDescriptor = $convert.base64Decode(
    'ChNCdW5kbGVDb25maWd1cmF0aW9uEjIKBmJ1bmRsZRgBIAEoCzIaLm1vZGNvbmR1Y3Rvci52MS'
    '5Nb2RCdW5kbGVSBmJ1bmRsZRI8CghwcmVwYXJlZBgCIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS5C'
    'dW5kbGVEaXNjb3ZlcnlSCHByZXBhcmVk');

@$core.Deprecated('Use bundleArchivePathDescriptor instead')
const BundleArchivePath$json = {
  '1': 'BundleArchivePath',
  '2': [
    {'1': 'components', '3': 1, '4': 3, '5': 9, '10': 'components'},
  ],
};

/// Descriptor for `BundleArchivePath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleArchivePathDescriptor = $convert.base64Decode(
    'ChFCdW5kbGVBcmNoaXZlUGF0aBIeCgpjb21wb25lbnRzGAEgAygJUgpjb21wb25lbnRz');

@$core.Deprecated('Use bundleModDescriptor instead')
const BundleMod$json = {
  '1': 'BundleMod',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'source_id', '3': 2, '4': 1, '5': 9, '10': 'sourceId'},
    {'1': 'mod_id', '3': 3, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'order', '3': 5, '4': 1, '5': 13, '10': 'order'},
    {
      '1': 'archives',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BundleArchivePath',
      '10': 'archives'
    },
    {'1': 'bytes', '3': 7, '4': 1, '5': 4, '10': 'bytes'},
    {
      '1': 'state',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.BundleModState',
      '10': 'state'
    },
    {
      '1': 'attempt_id',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'attemptId',
      '17': true
    },
    {
      '1': 'problem',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'incomplete_archive',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'incompleteArchive'
    },
  ],
  '8': [
    {'1': '_attempt_id'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `BundleMod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleModDescriptor = $convert.base64Decode(
    'CglCdW5kbGVNb2QSDgoCaWQYASABKAlSAmlkEhsKCXNvdXJjZV9pZBgCIAEoCVIIc291cmNlSW'
    'QSFQoGbW9kX2lkGAMgASgJUgVtb2RJZBISCgRuYW1lGAQgASgJUgRuYW1lEhQKBW9yZGVyGAUg'
    'ASgNUgVvcmRlchI+CghhcmNoaXZlcxgGIAMoCzIiLm1vZGNvbmR1Y3Rvci52MS5CdW5kbGVBcm'
    'NoaXZlUGF0aFIIYXJjaGl2ZXMSFAoFYnl0ZXMYByABKARSBWJ5dGVzEjUKBXN0YXRlGAggASgO'
    'Mh8ubW9kY29uZHVjdG9yLnYxLkJ1bmRsZU1vZFN0YXRlUgVzdGF0ZRIiCgphdHRlbXB0X2lkGA'
    'kgASgJSABSCWF0dGVtcHRJZIgBARIdCgdwcm9ibGVtGAogASgJSAFSB3Byb2JsZW2IAQESLQoS'
    'aW5jb21wbGV0ZV9hcmNoaXZlGAsgASgIUhFpbmNvbXBsZXRlQXJjaGl2ZUINCgtfYXR0ZW1wdF'
    '9pZEIKCghfcHJvYmxlbQ==');

@$core.Deprecated('Use modBundleDescriptor instead')
const ModBundle$json = {
  '1': 'ModBundle',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BundleReference',
      '10': 'reference'
    },
    {
      '1': 'artifact',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArtifactReference',
      '10': 'artifact'
    },
    {'1': 'archive_name', '3': 3, '4': 1, '5': 9, '10': 'archiveName'},
    {
      '1': 'mods',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BundleMod',
      '10': 'mods'
    },
    {'1': 'temporary_bytes', '3': 5, '4': 1, '5': 4, '10': 'temporaryBytes'},
    {
      '1': 'problem',
      '3': 6,
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

/// Descriptor for `ModBundle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modBundleDescriptor = $convert.base64Decode(
    'CglNb2RCdW5kbGUSPgoJcmVmZXJlbmNlGAEgASgLMiAubW9kY29uZHVjdG9yLnYxLkJ1bmRsZV'
    'JlZmVyZW5jZVIJcmVmZXJlbmNlEj4KCGFydGlmYWN0GAIgASgLMiIubW9kY29uZHVjdG9yLnYx'
    'LkFydGlmYWN0UmVmZXJlbmNlUghhcnRpZmFjdBIhCgxhcmNoaXZlX25hbWUYAyABKAlSC2FyY2'
    'hpdmVOYW1lEi4KBG1vZHMYBCADKAsyGi5tb2Rjb25kdWN0b3IudjEuQnVuZGxlTW9kUgRtb2Rz'
    'EicKD3RlbXBvcmFyeV9ieXRlcxgFIAEoBFIOdGVtcG9yYXJ5Qnl0ZXMSHQoHcHJvYmxlbRgGIA'
    'EoCUgAUgdwcm9ibGVtiAEBQgoKCF9wcm9ibGVt');

@$core.Deprecated('Use bundleClosedDescriptor instead')
const BundleClosed$json = {
  '1': 'BundleClosed',
};

/// Descriptor for `BundleClosed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bundleClosedDescriptor =
    $convert.base64Decode('CgxCdW5kbGVDbG9zZWQ=');
