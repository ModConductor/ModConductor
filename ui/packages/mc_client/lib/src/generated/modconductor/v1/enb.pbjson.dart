// This is a generated file - do not edit.
//
// Generated from modconductor/v1/enb.proto.

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

@$core.Deprecated('Use enbPhaseDescriptor instead')
const EnbPhase$json = {
  '1': 'EnbPhase',
  '2': [
    {'1': 'ENB_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'ENB_PHASE_UNAVAILABLE', '2': 1},
    {'1': 'ENB_PHASE_BLOCKED', '2': 2},
    {'1': 'ENB_PHASE_AVAILABLE', '2': 3},
    {'1': 'ENB_PHASE_WAITING_FOR_ARCHIVE', '2': 4},
    {'1': 'ENB_PHASE_VALIDATING', '2': 5},
    {'1': 'ENB_PHASE_ACQUIRING', '2': 6},
    {'1': 'ENB_PHASE_INSTALLING', '2': 7},
    {'1': 'ENB_PHASE_READY', '2': 8},
    {'1': 'ENB_PHASE_FAILED', '2': 9},
    {'1': 'ENB_PHASE_CONFLICT', '2': 10},
  ],
};

/// Descriptor for `EnbPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List enbPhaseDescriptor = $convert.base64Decode(
    'CghFbmJQaGFzZRIZChVFTkJfUEhBU0VfVU5TUEVDSUZJRUQQABIZChVFTkJfUEhBU0VfVU5BVk'
    'FJTEFCTEUQARIVChFFTkJfUEhBU0VfQkxPQ0tFRBACEhcKE0VOQl9QSEFTRV9BVkFJTEFCTEUQ'
    'AxIhCh1FTkJfUEhBU0VfV0FJVElOR19GT1JfQVJDSElWRRAEEhgKFEVOQl9QSEFTRV9WQUxJRE'
    'FUSU5HEAUSFwoTRU5CX1BIQVNFX0FDUVVJUklORxAGEhgKFEVOQl9QSEFTRV9JTlNUQUxMSU5H'
    'EAcSEwoPRU5CX1BIQVNFX1JFQURZEAgSFAoQRU5CX1BIQVNFX0ZBSUxFRBAJEhYKEkVOQl9QSE'
    'FTRV9DT05GTElDVBAK');

@$core.Deprecated('Use enbRequestDescriptor instead')
const EnbRequest$json = {
  '1': 'EnbRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `EnbRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enbRequestDescriptor = $convert.base64Decode(
    'CgpFbmJSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSHQoKcHJvZm'
    'lsZV9pZBgCIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use enbArchiveRequestDescriptor instead')
const EnbArchiveRequest$json = {
  '1': 'EnbArchiveRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'operation_id', '3': 3, '4': 1, '5': 9, '10': 'operationId'},
    {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `EnbArchiveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enbArchiveRequestDescriptor = $convert.base64Decode(
    'ChFFbmJBcmNoaXZlUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh'
    '0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBIhCgxvcGVyYXRpb25faWQYAyABKAlSC29w'
    'ZXJhdGlvbklkEhIKBHBhdGgYBCABKAlSBHBhdGg=');

@$core.Deprecated('Use enbStateDescriptor instead')
const EnbState$json = {
  '1': 'EnbState',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.EnbPhase',
      '10': 'phase'
    },
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'detail', '3': 3, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'runtime_version', '3': 4, '4': 1, '5': 9, '10': 'runtimeVersion'},
    {'1': 'preset_version', '3': 5, '4': 1, '5': 9, '10': 'presetVersion'},
    {
      '1': 'can_open_author_page',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'canOpenAuthorPage'
    },
    {
      '1': 'can_select_archive',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'canSelectArchive'
    },
    {'1': 'can_cancel', '3': 8, '4': 1, '5': 8, '10': 'canCancel'},
  ],
};

/// Descriptor for `EnbState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enbStateDescriptor = $convert.base64Decode(
    'CghFbmJTdGF0ZRIvCgVwaGFzZRgBIAEoDjIZLm1vZGNvbmR1Y3Rvci52MS5FbmJQaGFzZVIFcG'
    'hhc2USFgoGc3RhdHVzGAIgASgJUgZzdGF0dXMSFgoGZGV0YWlsGAMgASgJUgZkZXRhaWwSJwoP'
    'cnVudGltZV92ZXJzaW9uGAQgASgJUg5ydW50aW1lVmVyc2lvbhIlCg5wcmVzZXRfdmVyc2lvbh'
    'gFIAEoCVINcHJlc2V0VmVyc2lvbhIvChRjYW5fb3Blbl9hdXRob3JfcGFnZRgGIAEoCFIRY2Fu'
    'T3BlbkF1dGhvclBhZ2USLAoSY2FuX3NlbGVjdF9hcmNoaXZlGAcgASgIUhBjYW5TZWxlY3RBcm'
    'NoaXZlEh0KCmNhbl9jYW5jZWwYCCABKAhSCWNhbkNhbmNlbA==');
