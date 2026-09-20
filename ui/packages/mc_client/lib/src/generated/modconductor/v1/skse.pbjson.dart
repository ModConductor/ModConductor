// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skse.proto.

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

@$core.Deprecated('Use sksePhaseDescriptor instead')
const SksePhase$json = {
  '1': 'SksePhase',
  '2': [
    {'1': 'SKSE_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'SKSE_PHASE_UNAVAILABLE', '2': 1},
    {'1': 'SKSE_PHASE_AVAILABLE', '2': 2},
    {'1': 'SKSE_PHASE_WAITING_FOR_NEXUS', '2': 3},
    {'1': 'SKSE_PHASE_DOWNLOADING', '2': 4},
    {'1': 'SKSE_PHASE_INSTALLING', '2': 5},
    {'1': 'SKSE_PHASE_READY', '2': 6},
    {'1': 'SKSE_PHASE_FAILED', '2': 7},
    {'1': 'SKSE_PHASE_UPDATE_AVAILABLE', '2': 8},
    {'1': 'SKSE_PHASE_INCOMPATIBLE', '2': 9},
    {'1': 'SKSE_PHASE_SOURCE_UNAVAILABLE', '2': 10},
  ],
};

/// Descriptor for `SksePhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sksePhaseDescriptor = $convert.base64Decode(
    'CglTa3NlUGhhc2USGgoWU0tTRV9QSEFTRV9VTlNQRUNJRklFRBAAEhoKFlNLU0VfUEhBU0VfVU'
    '5BVkFJTEFCTEUQARIYChRTS1NFX1BIQVNFX0FWQUlMQUJMRRACEiAKHFNLU0VfUEhBU0VfV0FJ'
    'VElOR19GT1JfTkVYVVMQAxIaChZTS1NFX1BIQVNFX0RPV05MT0FESU5HEAQSGQoVU0tTRV9QSE'
    'FTRV9JTlNUQUxMSU5HEAUSFAoQU0tTRV9QSEFTRV9SRUFEWRAGEhUKEVNLU0VfUEhBU0VfRkFJ'
    'TEVEEAcSHwobU0tTRV9QSEFTRV9VUERBVEVfQVZBSUxBQkxFEAgSGwoXU0tTRV9QSEFTRV9JTk'
    'NPTVBBVElCTEUQCRIhCh1TS1NFX1BIQVNFX1NPVVJDRV9VTkFWQUlMQUJMRRAK');

@$core.Deprecated('Use skseRequestDescriptor instead')
const SkseRequest$json = {
  '1': 'SkseRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `SkseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skseRequestDescriptor = $convert.base64Decode(
    'CgtTa3NlUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh0KCnByb2'
    'ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use skseStateDescriptor instead')
const SkseState$json = {
  '1': 'SkseState',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SksePhase',
      '10': 'phase'
    },
    {'1': 'game_version', '3': 2, '4': 1, '5': 9, '10': 'gameVersion'},
    {
      '1': 'component_version',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'componentVersion'
    },
    {'1': 'status', '3': 4, '4': 1, '5': 9, '10': 'status'},
    {'1': 'detail', '3': 5, '4': 1, '5': 9, '10': 'detail'},
    {
      '1': 'nexus_file_id',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'nexusFileId',
      '17': true
    },
  ],
  '8': [
    {'1': '_nexus_file_id'},
  ],
};

/// Descriptor for `SkseState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skseStateDescriptor = $convert.base64Decode(
    'CglTa3NlU3RhdGUSMAoFcGhhc2UYASABKA4yGi5tb2Rjb25kdWN0b3IudjEuU2tzZVBoYXNlUg'
    'VwaGFzZRIhCgxnYW1lX3ZlcnNpb24YAiABKAlSC2dhbWVWZXJzaW9uEisKEWNvbXBvbmVudF92'
    'ZXJzaW9uGAMgASgJUhBjb21wb25lbnRWZXJzaW9uEhYKBnN0YXR1cxgEIAEoCVIGc3RhdHVzEh'
    'YKBmRldGFpbBgFIAEoCVIGZGV0YWlsEicKDW5leHVzX2ZpbGVfaWQYBiABKANIAFILbmV4dXNG'
    'aWxlSWSIAQFCEAoOX25leHVzX2ZpbGVfaWQ=');
