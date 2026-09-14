// This is a generated file - do not edit.
//
// Generated from modconductor/v1/loot_sort.proto.

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

@$core.Deprecated('Use lootProblemKindDescriptor instead')
const LootProblemKind$json = {
  '1': 'LootProblemKind',
  '2': [
    {'1': 'LOOT_PROBLEM_KIND_UNSPECIFIED', '2': 0},
    {'1': 'LOOT_PROBLEM_KIND_BUSY', '2': 1},
    {'1': 'LOOT_PROBLEM_KIND_STALE', '2': 2},
    {'1': 'LOOT_PROBLEM_KIND_CANCELLED', '2': 3},
    {'1': 'LOOT_PROBLEM_KIND_UNSUPPORTED', '2': 4},
    {'1': 'LOOT_PROBLEM_KIND_METADATA', '2': 5},
    {'1': 'LOOT_PROBLEM_KIND_HELPER', '2': 6},
    {'1': 'LOOT_PROBLEM_KIND_RESPONSE', '2': 7},
  ],
};

/// Descriptor for `LootProblemKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List lootProblemKindDescriptor = $convert.base64Decode(
    'Cg9Mb290UHJvYmxlbUtpbmQSIQodTE9PVF9QUk9CTEVNX0tJTkRfVU5TUEVDSUZJRUQQABIaCh'
    'ZMT09UX1BST0JMRU1fS0lORF9CVVNZEAESGwoXTE9PVF9QUk9CTEVNX0tJTkRfU1RBTEUQAhIf'
    'ChtMT09UX1BST0JMRU1fS0lORF9DQU5DRUxMRUQQAxIhCh1MT09UX1BST0JMRU1fS0lORF9VTl'
    'NVUFBPUlRFRBAEEh4KGkxPT1RfUFJPQkxFTV9LSU5EX01FVEFEQVRBEAUSHAoYTE9PVF9QUk9C'
    'TEVNX0tJTkRfSEVMUEVSEAYSHgoaTE9PVF9QUk9CTEVNX0tJTkRfUkVTUE9OU0UQBw==');

@$core.Deprecated('Use readLootStateRequestDescriptor instead')
const ReadLootStateRequest$json = {
  '1': 'ReadLootStateRequest',
};

/// Descriptor for `ReadLootStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readLootStateRequestDescriptor =
    $convert.base64Decode('ChRSZWFkTG9vdFN0YXRlUmVxdWVzdA==');

@$core.Deprecated('Use previewLootSortRequestDescriptor instead')
const PreviewLootSortRequest$json = {
  '1': 'PreviewLootSortRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'headers_id', '3': 3, '4': 1, '5': 9, '10': 'headersId'},
  ],
};

/// Descriptor for `PreviewLootSortRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewLootSortRequestDescriptor = $convert.base64Decode(
    'ChZQcmV2aWV3TG9vdFNvcnRSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEh0KCmhlYWRlcnNfaWQYAyABKAlS'
    'CWhlYWRlcnNJZA==');

@$core.Deprecated('Use applyLootSortRequestDescriptor instead')
const ApplyLootSortRequest$json = {
  '1': 'ApplyLootSortRequest',
  '2': [
    {'1': 'proposal_id', '3': 1, '4': 1, '5': 9, '10': 'proposalId'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'headers_id', '3': 3, '4': 1, '5': 9, '10': 'headersId'},
  ],
};

/// Descriptor for `ApplyLootSortRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyLootSortRequestDescriptor = $convert.base64Decode(
    'ChRBcHBseUxvb3RTb3J0UmVxdWVzdBIfCgtwcm9wb3NhbF9pZBgBIAEoCVIKcHJvcG9zYWxJZB'
    'I7CghleHBlY3RlZBgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVJlZlIIZXhw'
    'ZWN0ZWQSHQoKaGVhZGVyc19pZBgDIAEoCVIJaGVhZGVyc0lk');

@$core.Deprecated('Use dismissLootSortRequestDescriptor instead')
const DismissLootSortRequest$json = {
  '1': 'DismissLootSortRequest',
  '2': [
    {'1': 'proposal_id', '3': 1, '4': 1, '5': 9, '10': 'proposalId'},
  ],
};

/// Descriptor for `DismissLootSortRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dismissLootSortRequestDescriptor =
    $convert.base64Decode(
        'ChZEaXNtaXNzTG9vdFNvcnRSZXF1ZXN0Eh8KC3Byb3Bvc2FsX2lkGAEgASgJUgpwcm9wb3NhbE'
        'lk');

@$core.Deprecated('Use refreshLootMetadataRequestDescriptor instead')
const RefreshLootMetadataRequest$json = {
  '1': 'RefreshLootMetadataRequest',
};

/// Descriptor for `RefreshLootMetadataRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshLootMetadataRequestDescriptor =
    $convert.base64Decode('ChpSZWZyZXNoTG9vdE1ldGFkYXRhUmVxdWVzdA==');

@$core.Deprecated('Use lootMetadataStateDescriptor instead')
const LootMetadataState$json = {
  '1': 'LootMetadataState',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 9, '10': 'revision'},
    {
      '1': 'masterlist_commit',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'masterlistCommit'
    },
    {'1': 'prelude_commit', '3': 3, '4': 1, '5': 9, '10': 'preludeCommit'},
    {
      '1': 'masterlist_sha256',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'masterlistSha256'
    },
    {'1': 'prelude_sha256', '3': 5, '4': 1, '5': 9, '10': 'preludeSha256'},
    {'1': 'fetched_unix_ms', '3': 6, '4': 1, '5': 3, '10': 'fetchedUnixMs'},
  ],
};

/// Descriptor for `LootMetadataState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootMetadataStateDescriptor = $convert.base64Decode(
    'ChFMb290TWV0YWRhdGFTdGF0ZRIaCghyZXZpc2lvbhgBIAEoCVIIcmV2aXNpb24SKwoRbWFzdG'
    'VybGlzdF9jb21taXQYAiABKAlSEG1hc3Rlcmxpc3RDb21taXQSJQoOcHJlbHVkZV9jb21taXQY'
    'AyABKAlSDXByZWx1ZGVDb21taXQSKwoRbWFzdGVybGlzdF9zaGEyNTYYBCABKAlSEG1hc3Rlcm'
    'xpc3RTaGEyNTYSJQoOcHJlbHVkZV9zaGEyNTYYBSABKAlSDXByZWx1ZGVTaGEyNTYSJgoPZmV0'
    'Y2hlZF91bml4X21zGAYgASgDUg1mZXRjaGVkVW5peE1z');

@$core.Deprecated('Use lootSortMoveDescriptor instead')
const LootSortMove$json = {
  '1': 'LootSortMove',
  '2': [
    {'1': 'plugin', '3': 1, '4': 1, '5': 9, '10': 'plugin'},
    {'1': 'current', '3': 2, '4': 1, '5': 5, '10': 'current'},
    {'1': 'proposed', '3': 3, '4': 1, '5': 5, '10': 'proposed'},
    {'1': 'reason', '3': 4, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `LootSortMove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootSortMoveDescriptor = $convert.base64Decode(
    'CgxMb290U29ydE1vdmUSFgoGcGx1Z2luGAEgASgJUgZwbHVnaW4SGAoHY3VycmVudBgCIAEoBV'
    'IHY3VycmVudBIaCghwcm9wb3NlZBgDIAEoBVIIcHJvcG9zZWQSFgoGcmVhc29uGAQgASgJUgZy'
    'ZWFzb24=');

@$core.Deprecated('Use lootSortMessageDescriptor instead')
const LootSortMessage$json = {
  '1': 'LootSortMessage',
  '2': [
    {'1': 'plugin', '3': 1, '4': 1, '5': 9, '10': 'plugin'},
    {'1': 'level', '3': 2, '4': 1, '5': 9, '10': 'level'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `LootSortMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootSortMessageDescriptor = $convert.base64Decode(
    'Cg9Mb290U29ydE1lc3NhZ2USFgoGcGx1Z2luGAEgASgJUgZwbHVnaW4SFAoFbGV2ZWwYAiABKA'
    'lSBWxldmVsEhIKBHRleHQYAyABKAlSBHRleHQ=');

@$core.Deprecated('Use lootSortProposalDescriptor instead')
const LootSortProposal$json = {
  '1': 'LootSortProposal',
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
    {'1': 'headers_id', '3': 3, '4': 1, '5': 9, '10': 'headersId'},
    {'1': 'created_unix_ms', '3': 4, '4': 1, '5': 3, '10': 'createdUnixMs'},
    {'1': 'current', '3': 5, '4': 3, '5': 9, '10': 'current'},
    {'1': 'sorted', '3': 6, '4': 3, '5': 9, '10': 'sorted'},
    {
      '1': 'moves',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.LootSortMove',
      '10': 'moves'
    },
    {
      '1': 'messages',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.LootSortMessage',
      '10': 'messages'
    },
    {
      '1': 'metadata',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LootMetadataState',
      '10': 'metadata'
    },
    {'1': 'helper_version', '3': 10, '4': 1, '5': 9, '10': 'helperVersion'},
    {'1': 'libloot_version', '3': 11, '4': 1, '5': 9, '10': 'liblootVersion'},
    {'1': 'libloot_revision', '3': 12, '4': 1, '5': 9, '10': 'liblootRevision'},
  ],
};

/// Descriptor for `LootSortProposal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootSortProposalDescriptor = $convert.base64Decode(
    'ChBMb290U29ydFByb3Bvc2FsEg4KAmlkGAEgASgJUgJpZBI7CghleHBlY3RlZBgCIAEoCzIfLm'
    '1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlRGF0YVJlZlIIZXhwZWN0ZWQSHQoKaGVhZGVyc19pZBgD'
    'IAEoCVIJaGVhZGVyc0lkEiYKD2NyZWF0ZWRfdW5peF9tcxgEIAEoA1INY3JlYXRlZFVuaXhNcx'
    'IYCgdjdXJyZW50GAUgAygJUgdjdXJyZW50EhYKBnNvcnRlZBgGIAMoCVIGc29ydGVkEjMKBW1v'
    'dmVzGAcgAygLMh0ubW9kY29uZHVjdG9yLnYxLkxvb3RTb3J0TW92ZVIFbW92ZXMSPAoIbWVzc2'
    'FnZXMYCCADKAsyIC5tb2Rjb25kdWN0b3IudjEuTG9vdFNvcnRNZXNzYWdlUghtZXNzYWdlcxI+'
    'CghtZXRhZGF0YRgJIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5Mb290TWV0YWRhdGFTdGF0ZVIIbW'
    'V0YWRhdGESJQoOaGVscGVyX3ZlcnNpb24YCiABKAlSDWhlbHBlclZlcnNpb24SJwoPbGlibG9v'
    'dF92ZXJzaW9uGAsgASgJUg5saWJsb290VmVyc2lvbhIpChBsaWJsb290X3JldmlzaW9uGAwgAS'
    'gJUg9saWJsb290UmV2aXNpb24=');

@$core.Deprecated('Use lootStateDescriptor instead')
const LootState$json = {
  '1': 'LootState',
  '2': [
    {'1': 'capability_id', '3': 1, '4': 1, '5': 9, '10': 'capabilityId'},
    {'1': 'available', '3': 2, '4': 1, '5': 8, '10': 'available'},
    {'1': 'reason', '3': 3, '4': 1, '5': 9, '10': 'reason'},
    {
      '1': 'metadata',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LootMetadataState',
      '10': 'metadata'
    },
    {
      '1': 'proposal',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LootSortProposal',
      '10': 'proposal'
    },
  ],
};

/// Descriptor for `LootState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootStateDescriptor = $convert.base64Decode(
    'CglMb290U3RhdGUSIwoNY2FwYWJpbGl0eV9pZBgBIAEoCVIMY2FwYWJpbGl0eUlkEhwKCWF2YW'
    'lsYWJsZRgCIAEoCFIJYXZhaWxhYmxlEhYKBnJlYXNvbhgDIAEoCVIGcmVhc29uEj4KCG1ldGFk'
    'YXRhGAQgASgLMiIubW9kY29uZHVjdG9yLnYxLkxvb3RNZXRhZGF0YVN0YXRlUghtZXRhZGF0YR'
    'I9Cghwcm9wb3NhbBgFIAEoCzIhLm1vZGNvbmR1Y3Rvci52MS5Mb290U29ydFByb3Bvc2FsUghw'
    'cm9wb3NhbA==');

@$core.Deprecated('Use lootProblemDescriptor instead')
const LootProblem$json = {
  '1': 'LootProblem',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.LootProblemKind',
      '10': 'kind'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `LootProblem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootProblemDescriptor = $convert.base64Decode(
    'CgtMb290UHJvYmxlbRI0CgRraW5kGAEgASgOMiAubW9kY29uZHVjdG9yLnYxLkxvb3RQcm9ibG'
    'VtS2luZFIEa2luZBIWCgZkZXRhaWwYAiABKAlSBmRldGFpbA==');

@$core.Deprecated('Use lootStateReplyDescriptor instead')
const LootStateReply$json = {
  '1': 'LootStateReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LootState',
      '9': 0,
      '10': 'state'
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LootProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `LootStateReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lootStateReplyDescriptor = $convert.base64Decode(
    'Cg5Mb290U3RhdGVSZXBseRIyCgVzdGF0ZRgBIAEoCzIaLm1vZGNvbmR1Y3Rvci52MS5Mb290U3'
    'RhdGVIAFIFc3RhdGUSOAoHcHJvYmxlbRgCIAEoCzIcLm1vZGNvbmR1Y3Rvci52MS5Mb290UHJv'
    'YmxlbUgAUgdwcm9ibGVtQgkKB291dGNvbWU=');
