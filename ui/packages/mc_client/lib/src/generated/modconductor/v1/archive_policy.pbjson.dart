// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_policy.proto.

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

@$core.Deprecated('Use archivePolicyStateDescriptor instead')
const ArchivePolicyState$json = {
  '1': 'ArchivePolicyState',
  '2': [
    {'1': 'ARCHIVE_POLICY_STATE_UNSPECIFIED', '2': 0},
    {'1': 'ARCHIVE_POLICY_STATE_ACTIVE', '2': 1},
    {'1': 'ARCHIVE_POLICY_STATE_INACTIVE', '2': 2},
    {'1': 'ARCHIVE_POLICY_STATE_UNAVAILABLE', '2': 3},
    {'1': 'ARCHIVE_POLICY_STATE_UNSUPPORTED', '2': 4},
  ],
};

/// Descriptor for `ArchivePolicyState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List archivePolicyStateDescriptor = $convert.base64Decode(
    'ChJBcmNoaXZlUG9saWN5U3RhdGUSJAogQVJDSElWRV9QT0xJQ1lfU1RBVEVfVU5TUEVDSUZJRU'
    'QQABIfChtBUkNISVZFX1BPTElDWV9TVEFURV9BQ1RJVkUQARIhCh1BUkNISVZFX1BPTElDWV9T'
    'VEFURV9JTkFDVElWRRACEiQKIEFSQ0hJVkVfUE9MSUNZX1NUQVRFX1VOQVZBSUxBQkxFEAMSJA'
    'ogQVJDSElWRV9QT0xJQ1lfU1RBVEVfVU5TVVBQT1JURUQQBA==');

@$core.Deprecated('Use scanArchivePolicyRequestDescriptor instead')
const ScanArchivePolicyRequest$json = {
  '1': 'ScanArchivePolicyRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'headers_id', '3': 3, '4': 1, '5': 9, '10': 'headersId'},
  ],
};

/// Descriptor for `ScanArchivePolicyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanArchivePolicyRequestDescriptor = $convert.base64Decode(
    'ChhTY2FuQXJjaGl2ZVBvbGljeVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3'
    'BhY2VJZBIdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQSHQoKaGVhZGVyc19pZBgDIAEo'
    'CVIJaGVhZGVyc0lk');

@$core.Deprecated('Use readArchivePolicyRequestDescriptor instead')
const ReadArchivePolicyRequest$json = {
  '1': 'ReadArchivePolicyRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'snapshot_id', '3': 3, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `ReadArchivePolicyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readArchivePolicyRequestDescriptor = $convert.base64Decode(
    'ChhSZWFkQXJjaGl2ZVBvbGljeVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3'
    'BhY2VJZBIdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQSHwoLc25hcHNob3RfaWQYAyAB'
    'KAlSCnNuYXBzaG90SWQ=');

@$core.Deprecated('Use applyArchivePolicyRequestDescriptor instead')
const ApplyArchivePolicyRequest$json = {
  '1': 'ApplyArchivePolicyRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'snapshot_id', '3': 3, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `ApplyArchivePolicyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyArchivePolicyRequestDescriptor = $convert.base64Decode(
    'ChlBcHBseUFyY2hpdmVQb2xpY3lSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBI7CghleHBlY3RlZB'
    'gCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVJlZlIIZXhwZWN0ZWQSHwoLc25h'
    'cHNob3RfaWQYAyABKAlSCnNuYXBzaG90SWQ=');

@$core.Deprecated('Use restoreArchivePolicyRequestDescriptor instead')
const RestoreArchivePolicyRequest$json = {
  '1': 'RestoreArchivePolicyRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
  ],
};

/// Descriptor for `RestoreArchivePolicyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restoreArchivePolicyRequestDescriptor =
    $convert.base64Decode(
        'ChtSZXN0b3JlQXJjaGl2ZVBvbGljeVJlcXVlc3QSDgoCaWQYASABKAlSAmlkEjsKCGV4cGVjdG'
        'VkGAIgASgLMh8ubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZA==');

@$core.Deprecated('Use archivePolicyEntryDescriptor instead')
const ArchivePolicyEntry$json = {
  '1': 'ArchivePolicyEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'position',
      '3': 2,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'position',
      '17': true
    },
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ArchivePolicyState',
      '10': 'state'
    },
    {'1': 'required', '3': 4, '4': 1, '5': 8, '10': 'required'},
    {'1': 'explicit', '3': 5, '4': 1, '5': 8, '10': 'explicit'},
    {'1': 'ini_key', '3': 6, '4': 1, '5': 9, '10': 'iniKey'},
    {
      '1': 'ini_position',
      '3': 7,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'iniPosition',
      '17': true
    },
    {
      '1': 'associated_plugin',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'associatedPlugin'
    },
    {'1': 'reasons', '3': 9, '4': 3, '5': 9, '10': 'reasons'},
    {
      '1': 'source',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginSource',
      '10': 'source'
    },
    {'1': 'format', '3': 11, '4': 1, '5': 9, '10': 'format'},
    {'1': 'problem', '3': 12, '4': 1, '5': 9, '10': 'problem'},
  ],
  '8': [
    {'1': '_position'},
    {'1': '_ini_position'},
  ],
};

/// Descriptor for `ArchivePolicyEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archivePolicyEntryDescriptor = $convert.base64Decode(
    'ChJBcmNoaXZlUG9saWN5RW50cnkSEgoEbmFtZRgBIAEoCVIEbmFtZRIfCghwb3NpdGlvbhgCIA'
    'EoDUgAUghwb3NpdGlvbogBARI5CgVzdGF0ZRgDIAEoDjIjLm1vZGNvbmR1Y3Rvci52MS5BcmNo'
    'aXZlUG9saWN5U3RhdGVSBXN0YXRlEhoKCHJlcXVpcmVkGAQgASgIUghyZXF1aXJlZBIaCghleH'
    'BsaWNpdBgFIAEoCFIIZXhwbGljaXQSFwoHaW5pX2tleRgGIAEoCVIGaW5pS2V5EiYKDGluaV9w'
    'b3NpdGlvbhgHIAEoDUgBUgtpbmlQb3NpdGlvbogBARIrChFhc3NvY2lhdGVkX3BsdWdpbhgIIA'
    'EoCVIQYXNzb2NpYXRlZFBsdWdpbhIYCgdyZWFzb25zGAkgAygJUgdyZWFzb25zEj0KBnNvdXJj'
    'ZRgKIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS5CZXRoZXNkYVBsdWdpblNvdXJjZVIGc291cmNlEh'
    'YKBmZvcm1hdBgLIAEoCVIGZm9ybWF0EhgKB3Byb2JsZW0YDCABKAlSB3Byb2JsZW1CCwoJX3Bv'
    'c2l0aW9uQg8KDV9pbmlfcG9zaXRpb24=');

@$core.Deprecated('Use archivePolicyViewDescriptor instead')
const ArchivePolicyView$json = {
  '1': 'ArchivePolicyView',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'reference'
    },
    {'1': 'snapshot_id', '3': 2, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'observed_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'observedAtUnixMs'
    },
    {'1': 'stale', '3': 4, '4': 1, '5': 8, '10': 'stale'},
    {
      '1': 'entries',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ArchivePolicyEntry',
      '10': 'entries'
    },
    {'1': 'problems', '3': 6, '4': 3, '5': 9, '10': 'problems'},
    {
      '1': 'blocking_problems',
      '3': 7,
      '4': 3,
      '5': 9,
      '10': 'blockingProblems'
    },
    {'1': 'saved', '3': 8, '4': 1, '5': 8, '10': 'saved'},
    {'1': 'applied', '3': 9, '4': 1, '5': 8, '10': 'applied'},
    {'1': 'pending', '3': 10, '4': 1, '5': 8, '10': 'pending'},
    {'1': 'pending_problem', '3': 11, '4': 1, '5': 9, '10': 'pendingProblem'},
    {'1': 'invalidation', '3': 12, '4': 1, '5': 9, '10': 'invalidation'},
  ],
};

/// Descriptor for `ArchivePolicyView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archivePolicyViewDescriptor = $convert.base64Decode(
    'ChFBcmNoaXZlUG9saWN5VmlldxI9CglyZWZlcmVuY2UYASABKAsyHy5tb2Rjb25kdWN0b3Iudj'
    'EuUHJvZmlsZURhdGFSZWZSCXJlZmVyZW5jZRIfCgtzbmFwc2hvdF9pZBgCIAEoCVIKc25hcHNo'
    'b3RJZBItChNvYnNlcnZlZF9hdF91bml4X21zGAMgASgDUhBvYnNlcnZlZEF0VW5peE1zEhQKBX'
    'N0YWxlGAQgASgIUgVzdGFsZRI9CgdlbnRyaWVzGAUgAygLMiMubW9kY29uZHVjdG9yLnYxLkFy'
    'Y2hpdmVQb2xpY3lFbnRyeVIHZW50cmllcxIaCghwcm9ibGVtcxgGIAMoCVIIcHJvYmxlbXMSKw'
    'oRYmxvY2tpbmdfcHJvYmxlbXMYByADKAlSEGJsb2NraW5nUHJvYmxlbXMSFAoFc2F2ZWQYCCAB'
    'KAhSBXNhdmVkEhgKB2FwcGxpZWQYCSABKAhSB2FwcGxpZWQSGAoHcGVuZGluZxgKIAEoCFIHcG'
    'VuZGluZxInCg9wZW5kaW5nX3Byb2JsZW0YCyABKAlSDnBlbmRpbmdQcm9ibGVtEiIKDGludmFs'
    'aWRhdGlvbhgMIAEoCVIMaW52YWxpZGF0aW9u');

@$core.Deprecated('Use archivePolicyReplyDescriptor instead')
const ArchivePolicyReply$json = {
  '1': 'ArchivePolicyReply',
  '2': [
    {
      '1': 'policy',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArchivePolicyView',
      '9': 0,
      '10': 'policy'
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ArchivePolicyReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archivePolicyReplyDescriptor = $convert.base64Decode(
    'ChJBcmNoaXZlUG9saWN5UmVwbHkSPAoGcG9saWN5GAEgASgLMiIubW9kY29uZHVjdG9yLnYxLk'
    'FyY2hpdmVQb2xpY3lWaWV3SABSBnBvbGljeRI/Cgdwcm9ibGVtGAIgASgLMiMubW9kY29uZHVj'
    'dG9yLnYxLlByb2ZpbGVEYXRhUHJvYmxlbUgAUgdwcm9ibGVtQgkKB291dGNvbWU=');
