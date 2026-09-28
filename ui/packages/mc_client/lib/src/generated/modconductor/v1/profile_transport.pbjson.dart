// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_transport.proto.

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

@$core.Deprecated('Use inspectProfileTransportRequestDescriptor instead')
const InspectProfileTransportRequest$json = {
  '1': 'InspectProfileTransportRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `InspectProfileTransportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectProfileTransportRequestDescriptor =
    $convert.base64Decode(
        'Ch5JbnNwZWN0UHJvZmlsZVRyYW5zcG9ydFJlcXVlc3QSEgoEcGF0aBgBIAEoCVIEcGF0aA==');

@$core.Deprecated('Use previewExportProfileTransportRequestDescriptor instead')
const PreviewExportProfileTransportRequest$json = {
  '1': 'PreviewExportProfileTransportRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `PreviewExportProfileTransportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewExportProfileTransportRequestDescriptor =
    $convert.base64Decode(
        'CiRQcmV2aWV3RXhwb3J0UHJvZmlsZVRyYW5zcG9ydFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGA'
        'EgASgJUgt3b3Jrc3BhY2VJZBIdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQ=');

@$core.Deprecated('Use profileSourceRequirementDescriptor instead')
const ProfileSourceRequirement$json = {
  '1': 'ProfileSourceRequirement',
  '2': [
    {'1': 'mod_index', '3': 1, '4': 1, '5': 13, '10': 'modIndex'},
    {'1': 'mod_name', '3': 2, '4': 1, '5': 9, '10': 'modName'},
    {'1': 'archive_name', '3': 3, '4': 1, '5': 9, '10': 'archiveName'},
    {'1': 'sha256', '3': 4, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'length', '3': 5, '4': 1, '5': 4, '10': 'length'},
    {
      '1': 'provider_game',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'providerGame',
      '17': true
    },
    {
      '1': 'provider_mod',
      '3': 7,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'providerMod',
      '17': true
    },
    {
      '1': 'provider_file',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'providerFile',
      '17': true
    },
    {
      '1': 'provider_version',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'providerVersion',
      '17': true
    },
  ],
  '8': [
    {'1': '_provider_game'},
    {'1': '_provider_mod'},
    {'1': '_provider_file'},
    {'1': '_provider_version'},
  ],
};

/// Descriptor for `ProfileSourceRequirement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileSourceRequirementDescriptor = $convert.base64Decode(
    'ChhQcm9maWxlU291cmNlUmVxdWlyZW1lbnQSGwoJbW9kX2luZGV4GAEgASgNUghtb2RJbmRleB'
    'IZCghtb2RfbmFtZRgCIAEoCVIHbW9kTmFtZRIhCgxhcmNoaXZlX25hbWUYAyABKAlSC2FyY2hp'
    'dmVOYW1lEhYKBnNoYTI1NhgEIAEoCVIGc2hhMjU2EhYKBmxlbmd0aBgFIAEoBFIGbGVuZ3RoEi'
    'gKDXByb3ZpZGVyX2dhbWUYBiABKAlIAFIMcHJvdmlkZXJHYW1liAEBEiYKDHByb3ZpZGVyX21v'
    'ZBgHIAEoA0gBUgtwcm92aWRlck1vZIgBARIoCg1wcm92aWRlcl9maWxlGAggASgDSAJSDHByb3'
    'ZpZGVyRmlsZYgBARIuChBwcm92aWRlcl92ZXJzaW9uGAkgASgJSANSD3Byb3ZpZGVyVmVyc2lv'
    'bogBAUIQCg5fcHJvdmlkZXJfZ2FtZUIPCg1fcHJvdmlkZXJfbW9kQhAKDl9wcm92aWRlcl9maW'
    'xlQhMKEV9wcm92aWRlcl92ZXJzaW9u');

@$core.Deprecated('Use profileTransportPreviewDescriptor instead')
const ProfileTransportPreview$json = {
  '1': 'ProfileTransportPreview',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'game', '3': 2, '4': 1, '5': 9, '10': 'game'},
    {'1': 'mod_count', '3': 3, '4': 1, '5': 13, '10': 'modCount'},
    {'1': 'save_file_count', '3': 4, '4': 1, '5': 13, '10': 'saveFileCount'},
    {'1': 'save_bytes', '3': 5, '4': 1, '5': 4, '10': 'saveBytes'},
    {
      '1': 'sources',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileSourceRequirement',
      '10': 'sources'
    },
    {'1': 'mod_file_count', '3': 7, '4': 1, '5': 13, '10': 'modFileCount'},
  ],
};

/// Descriptor for `ProfileTransportPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileTransportPreviewDescriptor = $convert.base64Decode(
    'ChdQcm9maWxlVHJhbnNwb3J0UHJldmlldxISCgRuYW1lGAEgASgJUgRuYW1lEhIKBGdhbWUYAi'
    'ABKAlSBGdhbWUSGwoJbW9kX2NvdW50GAMgASgNUghtb2RDb3VudBImCg9zYXZlX2ZpbGVfY291'
    'bnQYBCABKA1SDXNhdmVGaWxlQ291bnQSHQoKc2F2ZV9ieXRlcxgFIAEoBFIJc2F2ZUJ5dGVzEk'
    'MKB3NvdXJjZXMYBiADKAsyKS5tb2Rjb25kdWN0b3IudjEuUHJvZmlsZVNvdXJjZVJlcXVpcmVt'
    'ZW50Ugdzb3VyY2VzEiQKDm1vZF9maWxlX2NvdW50GAcgASgNUgxtb2RGaWxlQ291bnQ=');

@$core.Deprecated('Use exportProfileTransportRequestDescriptor instead')
const ExportProfileTransportRequest$json = {
  '1': 'ExportProfileTransportRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'destination', '3': 3, '4': 1, '5': 9, '10': 'destination'},
    {'1': 'include_saves', '3': 4, '4': 1, '5': 8, '10': 'includeSaves'},
  ],
};

/// Descriptor for `ExportProfileTransportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportProfileTransportRequestDescriptor = $convert.base64Decode(
    'Ch1FeHBvcnRQcm9maWxlVHJhbnNwb3J0UmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3'
    'dvcmtzcGFjZUlkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBIgCgtkZXN0aW5hdGlv'
    'bhgDIAEoCVILZGVzdGluYXRpb24SIwoNaW5jbHVkZV9zYXZlcxgEIAEoCFIMaW5jbHVkZVNhdm'
    'Vz');

@$core.Deprecated('Use manualProfileSourceDescriptor instead')
const ManualProfileSource$json = {
  '1': 'ManualProfileSource',
  '2': [
    {'1': 'mod_index', '3': 1, '4': 1, '5': 13, '10': 'modIndex'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `ManualProfileSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List manualProfileSourceDescriptor = $convert.base64Decode(
    'ChNNYW51YWxQcm9maWxlU291cmNlEhsKCW1vZF9pbmRleBgBIAEoDVIIbW9kSW5kZXgSEgoEcG'
    'F0aBgCIAEoCVIEcGF0aA==');

@$core.Deprecated('Use importProfileTransportRequestDescriptor instead')
const ImportProfileTransportRequest$json = {
  '1': 'ImportProfileTransportRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'game_profile_id', '3': 3, '4': 1, '5': 9, '10': 'gameProfileId'},
    {'1': 'profile_name', '3': 4, '4': 1, '5': 9, '10': 'profileName'},
    {
      '1': 'manual_sources',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ManualProfileSource',
      '10': 'manualSources'
    },
  ],
};

/// Descriptor for `ImportProfileTransportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importProfileTransportRequestDescriptor = $convert.base64Decode(
    'Ch1JbXBvcnRQcm9maWxlVHJhbnNwb3J0UmVxdWVzdBISCgRwYXRoGAEgASgJUgRwYXRoEiEKDH'
    'dvcmtzcGFjZV9pZBgCIAEoCVILd29ya3NwYWNlSWQSJgoPZ2FtZV9wcm9maWxlX2lkGAMgASgJ'
    'Ug1nYW1lUHJvZmlsZUlkEiEKDHByb2ZpbGVfbmFtZRgEIAEoCVILcHJvZmlsZU5hbWUSSwoObW'
    'FudWFsX3NvdXJjZXMYBSADKAsyJC5tb2Rjb25kdWN0b3IudjEuTWFudWFsUHJvZmlsZVNvdXJj'
    'ZVINbWFudWFsU291cmNlcw==');

@$core.Deprecated('Use profileTransportResultDescriptor instead')
const ProfileTransportResult$json = {
  '1': 'ProfileTransportResult',
  '2': [
    {
      '1': 'profile_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'profileId',
      '17': true
    },
    {
      '1': 'problem',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'problem',
      '17': true
    },
  ],
  '8': [
    {'1': '_profile_id'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `ProfileTransportResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileTransportResultDescriptor = $convert.base64Decode(
    'ChZQcm9maWxlVHJhbnNwb3J0UmVzdWx0EiIKCnByb2ZpbGVfaWQYASABKAlIAFIJcHJvZmlsZU'
    'lkiAEBEh0KB3Byb2JsZW0YAiABKAlIAVIHcHJvYmxlbYgBAUINCgtfcHJvZmlsZV9pZEIKCghf'
    'cHJvYmxlbQ==');
