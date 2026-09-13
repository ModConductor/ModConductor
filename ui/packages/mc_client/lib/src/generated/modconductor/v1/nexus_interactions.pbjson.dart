// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus_interactions.proto.

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

@$core.Deprecated('Use modNexusInteractionStateDescriptor instead')
const ModNexusInteractionState$json = {
  '1': 'ModNexusInteractionState',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 3, '10': 'revision'},
    {
      '1': 'tracking',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'tracking',
      '17': true
    },
    {
      '1': 'endorsement',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'endorsement',
      '17': true
    },
    {'1': 'busy', '3': 4, '4': 1, '5': 8, '10': 'busy'},
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
      '1': 'account_name',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'accountName',
      '17': true
    },
  ],
  '8': [
    {'1': '_tracking'},
    {'1': '_endorsement'},
    {'1': '_failure'},
    {'1': '_account_name'},
  ],
};

/// Descriptor for `ModNexusInteractionState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modNexusInteractionStateDescriptor = $convert.base64Decode(
    'ChhNb2ROZXh1c0ludGVyYWN0aW9uU3RhdGUSGgoIcmV2aXNpb24YASABKANSCHJldmlzaW9uEh'
    '8KCHRyYWNraW5nGAIgASgISABSCHRyYWNraW5niAEBEiUKC2VuZG9yc2VtZW50GAMgASgJSAFS'
    'C2VuZG9yc2VtZW50iAEBEhIKBGJ1c3kYBCABKAhSBGJ1c3kSPAoHZmFpbHVyZRgFIAEoCzIdLm'
    '1vZGNvbmR1Y3Rvci52MS5OZXh1c0ZhaWx1cmVIAlIHZmFpbHVyZYgBARImCgxhY2NvdW50X25h'
    'bWUYBiABKAlIA1ILYWNjb3VudE5hbWWIAQFCCwoJX3RyYWNraW5nQg4KDF9lbmRvcnNlbWVudE'
    'IKCghfZmFpbHVyZUIPCg1fYWNjb3VudF9uYW1l');

@$core.Deprecated('Use modNexusInteractionsReplyDescriptor instead')
const ModNexusInteractionsReply$json = {
  '1': 'ModNexusInteractionsReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusInteractionState',
      '9': 0,
      '10': 'state'
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

/// Descriptor for `ModNexusInteractionsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modNexusInteractionsReplyDescriptor = $convert.base64Decode(
    'ChlNb2ROZXh1c0ludGVyYWN0aW9uc1JlcGx5EkEKBXN0YXRlGAEgASgLMikubW9kY29uZHVjdG'
    '9yLnYxLk1vZE5leHVzSW50ZXJhY3Rpb25TdGF0ZUgAUgVzdGF0ZRI5CgdmYWlsdXJlGAIgASgL'
    'Mh0ubW9kY29uZHVjdG9yLnYxLk5leHVzRmFpbHVyZUgAUgdmYWlsdXJlQggKBnJlc3VsdA==');

@$core.Deprecated('Use changeModNexusInteractionRequestDescriptor instead')
const ChangeModNexusInteractionRequest$json = {
  '1': 'ChangeModNexusInteractionRequest',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModNexusReference',
      '10': 'reference'
    },
    {'1': 'revision', '3': 2, '4': 1, '5': 3, '10': 'revision'},
    {'1': 'action', '3': 3, '4': 1, '5': 9, '10': 'action'},
  ],
};

/// Descriptor for `ChangeModNexusInteractionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeModNexusInteractionRequestDescriptor =
    $convert.base64Decode(
        'CiBDaGFuZ2VNb2ROZXh1c0ludGVyYWN0aW9uUmVxdWVzdBJACglyZWZlcmVuY2UYASABKAsyIi'
        '5tb2Rjb25kdWN0b3IudjEuTW9kTmV4dXNSZWZlcmVuY2VSCXJlZmVyZW5jZRIaCghyZXZpc2lv'
        'bhgCIAEoA1IIcmV2aXNpb24SFgoGYWN0aW9uGAMgASgJUgZhY3Rpb24=');
