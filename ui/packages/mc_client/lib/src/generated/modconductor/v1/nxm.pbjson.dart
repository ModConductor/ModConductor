// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nxm.proto.

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

@$core.Deprecated('Use nexusIngressRequestDescriptor instead')
const NexusIngressRequest$json = {
  '1': 'NexusIngressRequest',
  '2': [
    {'1': 'process_id', '3': 1, '4': 1, '5': 5, '10': 'processId'},
  ],
};

/// Descriptor for `NexusIngressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusIngressRequestDescriptor = $convert.base64Decode(
    'ChNOZXh1c0luZ3Jlc3NSZXF1ZXN0Eh0KCnByb2Nlc3NfaWQYASABKAVSCXByb2Nlc3NJZA==');

@$core.Deprecated('Use nexusIngressReplyDescriptor instead')
const NexusIngressReply$json = {
  '1': 'NexusIngressReply',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
    {'1': 'capability', '3': 2, '4': 1, '5': 12, '10': 'capability'},
    {'1': 'process_id', '3': 3, '4': 1, '5': 5, '10': 'processId'},
  ],
};

/// Descriptor for `NexusIngressReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusIngressReplyDescriptor = $convert.base64Decode(
    'ChFOZXh1c0luZ3Jlc3NSZXBseRIaCghlbmRwb2ludBgBIAEoCVIIZW5kcG9pbnQSHgoKY2FwYW'
    'JpbGl0eRgCIAEoDFIKY2FwYWJpbGl0eRIdCgpwcm9jZXNzX2lkGAMgASgFUglwcm9jZXNzSWQ=');

@$core.Deprecated('Use nexusLinkRequestDescriptor instead')
const NexusLinkRequest$json = {
  '1': 'NexusLinkRequest',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 9, '10': 'reference'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
  ],
};

/// Descriptor for `NexusLinkRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusLinkRequestDescriptor = $convert.base64Decode(
    'ChBOZXh1c0xpbmtSZXF1ZXN0EhwKCXJlZmVyZW5jZRgBIAEoCVIJcmVmZXJlbmNlEiEKDHdvcm'
    'tzcGFjZV9pZBgCIAEoCVILd29ya3NwYWNlSWQ=');

@$core.Deprecated('Use nexusLinkReplyDescriptor instead')
const NexusLinkReply$json = {
  '1': 'NexusLinkReply',
  '2': [
    {'1': 'game', '3': 1, '4': 1, '5': 9, '10': 'game'},
    {
      '1': 'file',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NexusFileInfo',
      '10': 'file'
    },
    {'1': 'problem', '3': 3, '4': 1, '5': 9, '10': 'problem'},
    {'1': 'sign_in_required', '3': 4, '4': 1, '5': 8, '10': 'signInRequired'},
    {
      '1': 'artifact',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArchiveArtifact',
      '10': 'artifact'
    },
    {'1': 'problem_detail', '3': 6, '4': 1, '5': 9, '10': 'problemDetail'},
  ],
};

/// Descriptor for `NexusLinkReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nexusLinkReplyDescriptor = $convert.base64Decode(
    'Cg5OZXh1c0xpbmtSZXBseRISCgRnYW1lGAEgASgJUgRnYW1lEjIKBGZpbGUYAiABKAsyHi5tb2'
    'Rjb25kdWN0b3IudjEuTmV4dXNGaWxlSW5mb1IEZmlsZRIYCgdwcm9ibGVtGAMgASgJUgdwcm9i'
    'bGVtEigKEHNpZ25faW5fcmVxdWlyZWQYBCABKAhSDnNpZ25JblJlcXVpcmVkEjwKCGFydGlmYW'
    'N0GAUgASgLMiAubW9kY29uZHVjdG9yLnYxLkFyY2hpdmVBcnRpZmFjdFIIYXJ0aWZhY3QSJQoO'
    'cHJvYmxlbV9kZXRhaWwYBiABKAlSDXByb2JsZW1EZXRhaWw=');
