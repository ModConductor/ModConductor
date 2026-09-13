// This is a generated file - do not edit.
//
// Generated from modconductor/v1/plugin_order.proto.

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

@$core.Deprecated('Use readPluginOrderRequestDescriptor instead')
const ReadPluginOrderRequest$json = {
  '1': 'ReadPluginOrderRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'headers_id', '3': 3, '4': 1, '5': 9, '10': 'headersId'},
  ],
};

/// Descriptor for `ReadPluginOrderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readPluginOrderRequestDescriptor = $convert.base64Decode(
    'ChZSZWFkUGx1Z2luT3JkZXJSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEh0KCmhlYWRlcnNfaWQYAyABKAlS'
    'CWhlYWRlcnNJZA==');

@$core.Deprecated('Use pluginOrderSettingDescriptor instead')
const PluginOrderSetting$json = {
  '1': 'PluginOrderSetting',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enabled',
      '17': true
    },
    {
      '1': 'locked_index',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 1,
      '10': 'lockedIndex',
      '17': true
    },
    {'1': 'required', '3': 4, '4': 1, '5': 8, '10': 'required'},
  ],
  '8': [
    {'1': '_enabled'},
    {'1': '_locked_index'},
  ],
};

/// Descriptor for `PluginOrderSetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pluginOrderSettingDescriptor = $convert.base64Decode(
    'ChJQbHVnaW5PcmRlclNldHRpbmcSEgoEbmFtZRgBIAEoCVIEbmFtZRIdCgdlbmFibGVkGAIgAS'
    'gISABSB2VuYWJsZWSIAQESJgoMbG9ja2VkX2luZGV4GAMgASgFSAFSC2xvY2tlZEluZGV4iAEB'
    'EhoKCHJlcXVpcmVkGAQgASgIUghyZXF1aXJlZEIKCghfZW5hYmxlZEIPCg1fbG9ja2VkX2luZG'
    'V4');

@$core.Deprecated('Use pluginOrderIssueDescriptor instead')
const PluginOrderIssue$json = {
  '1': 'PluginOrderIssue',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `PluginOrderIssue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pluginOrderIssueDescriptor = $convert.base64Decode(
    'ChBQbHVnaW5PcmRlcklzc3VlEhIKBG5hbWUYASABKAlSBG5hbWUSFgoGZGV0YWlsGAIgASgJUg'
    'ZkZXRhaWw=');

@$core.Deprecated('Use profilePluginOrderDescriptor instead')
const ProfilePluginOrder$json = {
  '1': 'ProfilePluginOrder',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'reference'
    },
    {
      '1': 'headers',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginSnapshot',
      '10': 'headers'
    },
    {
      '1': 'entries',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.PluginOrderSetting',
      '10': 'entries'
    },
    {
      '1': 'issues',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.PluginOrderIssue',
      '10': 'issues'
    },
    {'1': 'full', '3': 5, '4': 1, '5': 5, '10': 'full'},
    {'1': 'light', '3': 6, '4': 1, '5': 5, '10': 'light'},
    {'1': 'full_limit', '3': 7, '4': 1, '5': 5, '10': 'fullLimit'},
    {'1': 'saved', '3': 8, '4': 1, '5': 8, '10': 'saved'},
    {'1': 'applied', '3': 9, '4': 1, '5': 8, '10': 'applied'},
    {'1': 'external_changed', '3': 10, '4': 1, '5': 8, '10': 'externalChanged'},
    {'1': 'pending', '3': 11, '4': 1, '5': 8, '10': 'pending'},
    {
      '1': 'unknown',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.PluginOrderSetting',
      '10': 'unknown'
    },
    {'1': 'pending_problem', '3': 13, '4': 1, '5': 9, '10': 'pendingProblem'},
  ],
};

/// Descriptor for `ProfilePluginOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profilePluginOrderDescriptor = $convert.base64Decode(
    'ChJQcm9maWxlUGx1Z2luT3JkZXISPQoJcmVmZXJlbmNlGAEgASgLMh8ubW9kY29uZHVjdG9yLn'
    'YxLlByb2ZpbGVEYXRhUmVmUglyZWZlcmVuY2USQQoHaGVhZGVycxgCIAEoCzInLm1vZGNvbmR1'
    'Y3Rvci52MS5CZXRoZXNkYVBsdWdpblNuYXBzaG90UgdoZWFkZXJzEj0KB2VudHJpZXMYAyADKA'
    'syIy5tb2Rjb25kdWN0b3IudjEuUGx1Z2luT3JkZXJTZXR0aW5nUgdlbnRyaWVzEjkKBmlzc3Vl'
    'cxgEIAMoCzIhLm1vZGNvbmR1Y3Rvci52MS5QbHVnaW5PcmRlcklzc3VlUgZpc3N1ZXMSEgoEZn'
    'VsbBgFIAEoBVIEZnVsbBIUCgVsaWdodBgGIAEoBVIFbGlnaHQSHQoKZnVsbF9saW1pdBgHIAEo'
    'BVIJZnVsbExpbWl0EhQKBXNhdmVkGAggASgIUgVzYXZlZBIYCgdhcHBsaWVkGAkgASgIUgdhcH'
    'BsaWVkEikKEGV4dGVybmFsX2NoYW5nZWQYCiABKAhSD2V4dGVybmFsQ2hhbmdlZBIYCgdwZW5k'
    'aW5nGAsgASgIUgdwZW5kaW5nEj0KB3Vua25vd24YDCADKAsyIy5tb2Rjb25kdWN0b3IudjEuUG'
    'x1Z2luT3JkZXJTZXR0aW5nUgd1bmtub3duEicKD3BlbmRpbmdfcHJvYmxlbRgNIAEoCVIOcGVu'
    'ZGluZ1Byb2JsZW0=');

@$core.Deprecated('Use changePluginOrderRequestDescriptor instead')
const ChangePluginOrderRequest$json = {
  '1': 'ChangePluginOrderRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'headers_id', '3': 2, '4': 1, '5': 9, '10': 'headersId'},
    {'1': 'names', '3': 3, '4': 3, '5': 9, '10': 'names'},
    {'1': 'enabled', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'enabled'},
    {'1': 'move_up', '3': 5, '4': 1, '5': 8, '9': 0, '10': 'moveUp'},
    {'1': 'locked', '3': 6, '4': 1, '5': 8, '9': 0, '10': 'locked'},
  ],
  '8': [
    {'1': 'change'},
  ],
};

/// Descriptor for `ChangePluginOrderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePluginOrderRequestDescriptor = $convert.base64Decode(
    'ChhDaGFuZ2VQbHVnaW5PcmRlclJlcXVlc3QSOwoIZXhwZWN0ZWQYASABKAsyHy5tb2Rjb25kdW'
    'N0b3IudjEuUHJvZmlsZURhdGFSZWZSCGV4cGVjdGVkEh0KCmhlYWRlcnNfaWQYAiABKAlSCWhl'
    'YWRlcnNJZBIUCgVuYW1lcxgDIAMoCVIFbmFtZXMSGgoHZW5hYmxlZBgEIAEoCEgAUgdlbmFibG'
    'VkEhkKB21vdmVfdXAYBSABKAhIAFIGbW92ZVVwEhgKBmxvY2tlZBgGIAEoCEgAUgZsb2NrZWRC'
    'CAoGY2hhbmdl');

@$core.Deprecated('Use useGamePluginOrderRequestDescriptor instead')
const UseGamePluginOrderRequest$json = {
  '1': 'UseGamePluginOrderRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileDataRef',
      '10': 'expected'
    },
    {'1': 'headers_id', '3': 2, '4': 1, '5': 9, '10': 'headersId'},
  ],
};

/// Descriptor for `UseGamePluginOrderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List useGamePluginOrderRequestDescriptor = $convert.base64Decode(
    'ChlVc2VHYW1lUGx1Z2luT3JkZXJSZXF1ZXN0EjsKCGV4cGVjdGVkGAEgASgLMh8ubW9kY29uZH'
    'VjdG9yLnYxLlByb2ZpbGVEYXRhUmVmUghleHBlY3RlZBIdCgpoZWFkZXJzX2lkGAIgASgJUglo'
    'ZWFkZXJzSWQ=');

@$core.Deprecated('Use pluginOrderReplyDescriptor instead')
const PluginOrderReply$json = {
  '1': 'PluginOrderReply',
  '2': [
    {
      '1': 'order',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfilePluginOrder',
      '9': 0,
      '10': 'order'
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

/// Descriptor for `PluginOrderReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pluginOrderReplyDescriptor = $convert.base64Decode(
    'ChBQbHVnaW5PcmRlclJlcGx5EjsKBW9yZGVyGAEgASgLMiMubW9kY29uZHVjdG9yLnYxLlByb2'
    'ZpbGVQbHVnaW5PcmRlckgAUgVvcmRlchI/Cgdwcm9ibGVtGAIgASgLMiMubW9kY29uZHVjdG9y'
    'LnYxLlByb2ZpbGVEYXRhUHJvYmxlbUgAUgdwcm9ibGVtQgkKB291dGNvbWU=');
