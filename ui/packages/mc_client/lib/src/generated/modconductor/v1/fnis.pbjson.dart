// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fnis.proto.

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

@$core.Deprecated('Use fnisPhaseDescriptor instead')
const FnisPhase$json = {
  '1': 'FnisPhase',
  '2': [
    {'1': 'FNIS_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'FNIS_PHASE_UNAVAILABLE', '2': 1},
    {'1': 'FNIS_PHASE_AVAILABLE', '2': 2},
    {'1': 'FNIS_PHASE_WAITING_FOR_NEXUS', '2': 3},
    {'1': 'FNIS_PHASE_DOWNLOADING', '2': 4},
    {'1': 'FNIS_PHASE_INSTALLING', '2': 5},
    {'1': 'FNIS_PHASE_READY', '2': 6},
    {'1': 'FNIS_PHASE_FAILED', '2': 7},
    {'1': 'FNIS_PHASE_UPDATE_AVAILABLE', '2': 8},
    {'1': 'FNIS_PHASE_RECOVERY_REQUIRED', '2': 9},
    {'1': 'FNIS_PHASE_SOURCE_UNAVAILABLE', '2': 10},
  ],
};

/// Descriptor for `FnisPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fnisPhaseDescriptor = $convert.base64Decode(
    'CglGbmlzUGhhc2USGgoWRk5JU19QSEFTRV9VTlNQRUNJRklFRBAAEhoKFkZOSVNfUEhBU0VfVU'
    '5BVkFJTEFCTEUQARIYChRGTklTX1BIQVNFX0FWQUlMQUJMRRACEiAKHEZOSVNfUEhBU0VfV0FJ'
    'VElOR19GT1JfTkVYVVMQAxIaChZGTklTX1BIQVNFX0RPV05MT0FESU5HEAQSGQoVRk5JU19QSE'
    'FTRV9JTlNUQUxMSU5HEAUSFAoQRk5JU19QSEFTRV9SRUFEWRAGEhUKEUZOSVNfUEhBU0VfRkFJ'
    'TEVEEAcSHwobRk5JU19QSEFTRV9VUERBVEVfQVZBSUxBQkxFEAgSIAocRk5JU19QSEFTRV9SRU'
    'NPVkVSWV9SRVFVSVJFRBAJEiEKHUZOSVNfUEhBU0VfU09VUkNFX1VOQVZBSUxBQkxFEAo=');

@$core.Deprecated('Use fnisRequestDescriptor instead')
const FnisRequest$json = {
  '1': 'FnisRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `FnisRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fnisRequestDescriptor = $convert.base64Decode(
    'CgtGbmlzUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh0KCnByb2'
    'ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use fnisStateDescriptor instead')
const FnisState$json = {
  '1': 'FnisState',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FnisPhase',
      '10': 'phase'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {'1': 'detail', '3': 4, '4': 1, '5': 9, '10': 'detail'},
    {
      '1': 'nexus_file_id',
      '3': 5,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'nexusFileId',
      '17': true
    },
    {'1': 'can_install', '3': 6, '4': 1, '5': 8, '10': 'canInstall'},
    {'1': 'can_cancel', '3': 7, '4': 1, '5': 8, '10': 'canCancel'},
    {'1': 'can_update', '3': 8, '4': 1, '5': 8, '10': 'canUpdate'},
    {'1': 'can_remove', '3': 9, '4': 1, '5': 8, '10': 'canRemove'},
    {'1': 'can_recover', '3': 10, '4': 1, '5': 8, '10': 'canRecover'},
  ],
  '8': [
    {'1': '_nexus_file_id'},
  ],
};

/// Descriptor for `FnisState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fnisStateDescriptor = $convert.base64Decode(
    'CglGbmlzU3RhdGUSMAoFcGhhc2UYASABKA4yGi5tb2Rjb25kdWN0b3IudjEuRm5pc1BoYXNlUg'
    'VwaGFzZRIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhYKBnN0YXR1cxgDIAEoCVIGc3RhdHVz'
    'EhYKBmRldGFpbBgEIAEoCVIGZGV0YWlsEicKDW5leHVzX2ZpbGVfaWQYBSABKANIAFILbmV4dX'
    'NGaWxlSWSIAQESHwoLY2FuX2luc3RhbGwYBiABKAhSCmNhbkluc3RhbGwSHQoKY2FuX2NhbmNl'
    'bBgHIAEoCFIJY2FuQ2FuY2VsEh0KCmNhbl91cGRhdGUYCCABKAhSCWNhblVwZGF0ZRIdCgpjYW'
    '5fcmVtb3ZlGAkgASgIUgljYW5SZW1vdmUSHwoLY2FuX3JlY292ZXIYCiABKAhSCmNhblJlY292'
    'ZXJCEAoOX25leHVzX2ZpbGVfaWQ=');
