// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_mods.proto.

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

@$core.Deprecated('Use profileModRestrictionDescriptor instead')
const ProfileModRestriction$json = {
  '1': 'ProfileModRestriction',
  '2': [
    {'1': 'PROFILE_MOD_RESTRICTION_UNSPECIFIED', '2': 0},
    {'1': 'PROFILE_MOD_RESTRICTION_BACKUP', '2': 1},
    {'1': 'PROFILE_MOD_RESTRICTION_UNMANAGED', '2': 2},
    {'1': 'PROFILE_MOD_RESTRICTION_AUTOMATIC', '2': 3},
  ],
};

/// Descriptor for `ProfileModRestriction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List profileModRestrictionDescriptor = $convert.base64Decode(
    'ChVQcm9maWxlTW9kUmVzdHJpY3Rpb24SJwojUFJPRklMRV9NT0RfUkVTVFJJQ1RJT05fVU5TUE'
    'VDSUZJRUQQABIiCh5QUk9GSUxFX01PRF9SRVNUUklDVElPTl9CQUNLVVAQARIlCiFQUk9GSUxF'
    'X01PRF9SRVNUUklDVElPTl9VTk1BTkFHRUQQAhIlCiFQUk9GSUxFX01PRF9SRVNUUklDVElPTl'
    '9BVVRPTUFUSUMQAw==');

@$core.Deprecated('Use profileModMoveDescriptor instead')
const ProfileModMove$json = {
  '1': 'ProfileModMove',
  '2': [
    {'1': 'PROFILE_MOD_MOVE_UNSPECIFIED', '2': 0},
    {'1': 'PROFILE_MOD_MOVE_UP', '2': 1},
    {'1': 'PROFILE_MOD_MOVE_DOWN', '2': 2},
  ],
};

/// Descriptor for `ProfileModMove`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List profileModMoveDescriptor = $convert.base64Decode(
    'Cg5Qcm9maWxlTW9kTW92ZRIgChxQUk9GSUxFX01PRF9NT1ZFX1VOU1BFQ0lGSUVEEAASFwoTUF'
    'JPRklMRV9NT0RfTU9WRV9VUBABEhkKFVBST0ZJTEVfTU9EX01PVkVfRE9XThAC');

@$core.Deprecated('Use managedProfileModDescriptor instead')
const ManagedProfileMod$json = {
  '1': 'ManagedProfileMod',
  '2': [
    {'1': 'priority', '3': 1, '4': 1, '5': 13, '10': 'priority'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `ManagedProfileMod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedProfileModDescriptor = $convert.base64Decode(
    'ChFNYW5hZ2VkUHJvZmlsZU1vZBIaCghwcmlvcml0eRgBIAEoDVIIcHJpb3JpdHkSGAoHZW5hYm'
    'xlZBgCIAEoCFIHZW5hYmxlZA==');

@$core.Deprecated('Use orderedProfileModDescriptor instead')
const OrderedProfileMod$json = {
  '1': 'OrderedProfileMod',
  '2': [
    {'1': 'priority', '3': 1, '4': 1, '5': 13, '10': 'priority'},
  ],
};

/// Descriptor for `OrderedProfileMod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List orderedProfileModDescriptor = $convert.base64Decode(
    'ChFPcmRlcmVkUHJvZmlsZU1vZBIaCghwcmlvcml0eRgBIAEoDVIIcHJpb3JpdHk=');

@$core.Deprecated('Use profileModSelectionDescriptor instead')
const ProfileModSelection$json = {
  '1': 'ProfileModSelection',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'managed',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedProfileMod',
      '9': 0,
      '10': 'managed'
    },
    {
      '1': 'separator',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OrderedProfileMod',
      '9': 0,
      '10': 'separator'
    },
    {
      '1': 'locked',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileModRestriction',
      '9': 0,
      '10': 'locked'
    },
  ],
  '8': [
    {'1': 'state'},
  ],
};

/// Descriptor for `ProfileModSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModSelectionDescriptor = $convert.base64Decode(
    'ChNQcm9maWxlTW9kU2VsZWN0aW9uEhUKBm1vZF9pZBgBIAEoCVIFbW9kSWQSPgoHbWFuYWdlZB'
    'gCIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5NYW5hZ2VkUHJvZmlsZU1vZEgAUgdtYW5hZ2VkEkIK'
    'CXNlcGFyYXRvchgDIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5PcmRlcmVkUHJvZmlsZU1vZEgAUg'
    'lzZXBhcmF0b3ISQAoGbG9ja2VkGAQgASgOMiYubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVNb2RS'
    'ZXN0cmljdGlvbkgAUgZsb2NrZWRCBwoFc3RhdGU=');

@$core.Deprecated('Use profileModViewDescriptor instead')
const ProfileModView$json = {
  '1': 'ProfileModView',
  '2': [
    {
      '1': 'mod',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryMod',
      '10': 'mod'
    },
    {
      '1': 'selection',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileModSelection',
      '10': 'selection'
    },
  ],
};

/// Descriptor for `ProfileModView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModViewDescriptor = $convert.base64Decode(
    'Cg5Qcm9maWxlTW9kVmlldxIvCgNtb2QYASABKAsyHS5tb2Rjb25kdWN0b3IudjEuSW52ZW50b3'
    'J5TW9kUgNtb2QSQgoJc2VsZWN0aW9uGAIgASgLMiQubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVN'
    'b2RTZWxlY3Rpb25SCXNlbGVjdGlvbg==');

@$core.Deprecated('Use readProfileModsRequestDescriptor instead')
const ReadProfileModsRequest$json = {
  '1': 'ReadProfileModsRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'after_mod_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'afterModId',
      '17': true
    },
    {
      '1': 'expected_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 1,
      '10': 'expectedRevision',
      '17': true
    },
  ],
  '8': [
    {'1': '_after_mod_id'},
    {'1': '_expected_revision'},
  ],
};

/// Descriptor for `ReadProfileModsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readProfileModsRequestDescriptor = $convert.base64Decode(
    'ChZSZWFkUHJvZmlsZU1vZHNSZXF1ZXN0Eh0KCnByb2ZpbGVfaWQYASABKAlSCXByb2ZpbGVJZB'
    'IlCgxhZnRlcl9tb2RfaWQYAiABKAlIAFIKYWZ0ZXJNb2RJZIgBARIwChFleHBlY3RlZF9yZXZp'
    'c2lvbhgDIAEoBEgBUhBleHBlY3RlZFJldmlzaW9uiAEBQg8KDV9hZnRlcl9tb2RfaWRCFAoSX2'
    'V4cGVjdGVkX3JldmlzaW9u');

@$core.Deprecated('Use profileModsPageDescriptor instead')
const ProfileModsPage$json = {
  '1': 'ProfileModsPage',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'entries',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileModView',
      '10': 'entries'
    },
    {
      '1': 'next_mod_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextModId',
      '17': true
    },
    {'1': 'total', '3': 4, '4': 1, '5': 13, '10': 'total'},
    {'1': 'enabled_count', '3': 5, '4': 1, '5': 13, '10': 'enabledCount'},
  ],
  '8': [
    {'1': '_next_mod_id'},
  ],
};

/// Descriptor for `ProfileModsPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModsPageDescriptor = $convert.base64Decode(
    'Cg9Qcm9maWxlTW9kc1BhZ2USGgoIcmV2aXNpb24YASABKARSCHJldmlzaW9uEjkKB2VudHJpZX'
    'MYAiADKAsyHy5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZU1vZFZpZXdSB2VudHJpZXMSIwoLbmV4'
    'dF9tb2RfaWQYAyABKAlIAFIJbmV4dE1vZElkiAEBEhQKBXRvdGFsGAQgASgNUgV0b3RhbBIjCg'
    '1lbmFibGVkX2NvdW50GAUgASgNUgxlbmFibGVkQ291bnRCDgoMX25leHRfbW9kX2lk');

@$core.Deprecated('Use profileModsReplyDescriptor instead')
const ProfileModsReply$json = {
  '1': 'ProfileModsReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileModsPage',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ProfileModsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModsReplyDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlTW9kc1JlcGx5EjYKBHBhZ2UYASABKAsyIC5tb2Rjb25kdWN0b3IudjEuUHJvZm'
    'lsZU1vZHNQYWdlSABSBHBhZ2USOAoFZmF1bHQYAiABKAsyIC5tb2Rjb25kdWN0b3IudjEuTW9k'
    'TGlicmFyeUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use changeProfileModsRequestDescriptor instead')
const ChangeProfileModsRequest$json = {
  '1': 'ChangeProfileModsRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {'1': 'mod_ids', '3': 3, '4': 3, '5': 9, '10': 'modIds'},
    {'1': 'enabled', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'enabled'},
    {
      '1': 'move',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ProfileModMove',
      '9': 0,
      '10': 'move'
    },
  ],
  '8': [
    {'1': 'edit'},
  ],
};

/// Descriptor for `ChangeProfileModsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeProfileModsRequestDescriptor = $convert.base64Decode(
    'ChhDaGFuZ2VQcm9maWxlTW9kc1JlcXVlc3QSHQoKcHJvZmlsZV9pZBgBIAEoCVIJcHJvZmlsZU'
    'lkEisKEWV4cGVjdGVkX3JldmlzaW9uGAIgASgEUhBleHBlY3RlZFJldmlzaW9uEhcKB21vZF9p'
    'ZHMYAyADKAlSBm1vZElkcxIaCgdlbmFibGVkGAQgASgISABSB2VuYWJsZWQSNQoEbW92ZRgFIA'
    'EoDjIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlTW9kTW92ZUgAUgRtb3ZlQgYKBGVkaXQ=');

@$core.Deprecated('Use profileModsDeltaDescriptor instead')
const ProfileModsDelta$json = {
  '1': 'ProfileModsDelta',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'changed',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileModSelection',
      '10': 'changed'
    },
    {'1': 'enabled_count', '3': 3, '4': 1, '5': 13, '10': 'enabledCount'},
  ],
};

/// Descriptor for `ProfileModsDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModsDeltaDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlTW9kc0RlbHRhEhoKCHJldmlzaW9uGAEgASgEUghyZXZpc2lvbhI+CgdjaGFuZ2'
    'VkGAIgAygLMiQubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVNb2RTZWxlY3Rpb25SB2NoYW5nZWQS'
    'IwoNZW5hYmxlZF9jb3VudBgDIAEoDVIMZW5hYmxlZENvdW50');

@$core.Deprecated('Use profileModsChangeReplyDescriptor instead')
const ProfileModsChangeReply$json = {
  '1': 'ProfileModsChangeReply',
  '2': [
    {
      '1': 'delta',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileModsDelta',
      '9': 0,
      '10': 'delta'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ProfileModsChangeReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModsChangeReplyDescriptor = $convert.base64Decode(
    'ChZQcm9maWxlTW9kc0NoYW5nZVJlcGx5EjkKBWRlbHRhGAEgASgLMiEubW9kY29uZHVjdG9yLn'
    'YxLlByb2ZpbGVNb2RzRGVsdGFIAFIFZGVsdGESOAoFZmF1bHQYAiABKAsyIC5tb2Rjb25kdWN0'
    'b3IudjEuTW9kTGlicmFyeUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use readProfileModRequestDescriptor instead')
const ReadProfileModRequest$json = {
  '1': 'ReadProfileModRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'expected_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'expectedRevision',
      '17': true
    },
  ],
  '8': [
    {'1': '_expected_revision'},
  ],
};

/// Descriptor for `ReadProfileModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readProfileModRequestDescriptor = $convert.base64Decode(
    'ChVSZWFkUHJvZmlsZU1vZFJlcXVlc3QSHQoKcHJvZmlsZV9pZBgBIAEoCVIJcHJvZmlsZUlkEh'
    'UKBm1vZF9pZBgCIAEoCVIFbW9kSWQSMAoRZXhwZWN0ZWRfcmV2aXNpb24YAyABKARIAFIQZXhw'
    'ZWN0ZWRSZXZpc2lvbogBAUIUChJfZXhwZWN0ZWRfcmV2aXNpb24=');

@$core.Deprecated('Use profileModDetailDescriptor instead')
const ProfileModDetail$json = {
  '1': 'ProfileModDetail',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'entry',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileModView',
      '10': 'entry'
    },
  ],
};

/// Descriptor for `ProfileModDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModDetailDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlTW9kRGV0YWlsEhoKCHJldmlzaW9uGAEgASgEUghyZXZpc2lvbhI1CgVlbnRyeR'
    'gCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlTW9kVmlld1IFZW50cnk=');

@$core.Deprecated('Use profileModReplyDescriptor instead')
const ProfileModReply$json = {
  '1': 'ProfileModReply',
  '2': [
    {
      '1': 'detail',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileModDetail',
      '9': 0,
      '10': 'detail'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ProfileModReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileModReplyDescriptor = $convert.base64Decode(
    'Cg9Qcm9maWxlTW9kUmVwbHkSOwoGZGV0YWlsGAEgASgLMiEubW9kY29uZHVjdG9yLnYxLlByb2'
    'ZpbGVNb2REZXRhaWxIAFIGZGV0YWlsEjgKBWZhdWx0GAIgASgLMiAubW9kY29uZHVjdG9yLnYx'
    'Lk1vZExpYnJhcnlGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');
