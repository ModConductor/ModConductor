// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_launch.proto.

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

@$core.Deprecated('Use gameLaunchStateRequestDescriptor instead')
const GameLaunchStateRequest$json = {
  '1': 'GameLaunchStateRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `GameLaunchStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameLaunchStateRequestDescriptor =
    $convert.base64Decode(
        'ChZHYW1lTGF1bmNoU3RhdGVSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
        'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use gameLaunchStateDescriptor instead')
const GameLaunchState$json = {
  '1': 'GameLaunchState',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'context_revision', '3': 3, '4': 1, '5': 4, '10': 'contextRevision'},
    {'1': 'source_token', '3': 4, '4': 1, '5': 9, '10': 'sourceToken'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'runtime', '3': 6, '4': 1, '5': 9, '10': 'runtime'},
    {
      '1': 'problem',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'latest',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableRun',
      '10': 'latest'
    },
  ],
  '8': [
    {'1': '_problem'},
  ],
};

/// Descriptor for `GameLaunchState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameLaunchStateDescriptor = $convert.base64Decode(
    'Cg9HYW1lTGF1bmNoU3RhdGUSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBIdCg'
    'pwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQSKQoQY29udGV4dF9yZXZpc2lvbhgDIAEoBFIP'
    'Y29udGV4dFJldmlzaW9uEiEKDHNvdXJjZV90b2tlbhgEIAEoCVILc291cmNlVG9rZW4SEgoEbm'
    'FtZRgFIAEoCVIEbmFtZRIYCgdydW50aW1lGAYgASgJUgdydW50aW1lEh0KB3Byb2JsZW0YByAB'
    'KAlIAFIHcHJvYmxlbYgBARI2CgZsYXRlc3QYCCABKAsyHi5tb2Rjb25kdWN0b3IudjEuRXhlY3'
    'V0YWJsZVJ1blIGbGF0ZXN0QgoKCF9wcm9ibGVt');

@$core.Deprecated('Use gameLaunchStateReplyDescriptor instead')
const GameLaunchStateReply$json = {
  '1': 'GameLaunchStateReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameLaunchState',
      '9': 0,
      '10': 'state'
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExecutableProblem',
      '9': 0,
      '10': 'problem'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `GameLaunchStateReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameLaunchStateReplyDescriptor = $convert.base64Decode(
    'ChRHYW1lTGF1bmNoU3RhdGVSZXBseRI4CgVzdGF0ZRgBIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS'
    '5HYW1lTGF1bmNoU3RhdGVIAFIFc3RhdGUSPgoHcHJvYmxlbRgCIAEoCzIiLm1vZGNvbmR1Y3Rv'
    'ci52MS5FeGVjdXRhYmxlUHJvYmxlbUgAUgdwcm9ibGVtQggKBnJlc3VsdA==');
