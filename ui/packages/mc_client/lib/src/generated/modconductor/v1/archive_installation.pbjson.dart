// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_installation.proto.

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

@$core.Deprecated('Use installationPhaseDescriptor instead')
const InstallationPhase$json = {
  '1': 'InstallationPhase',
  '2': [
    {'1': 'INSTALLATION_PHASE_RUNNING', '2': 0},
    {'1': 'INSTALLATION_PHASE_STOPPED', '2': 1},
    {'1': 'INSTALLATION_PHASE_COMPLETE', '2': 2},
    {'1': 'INSTALLATION_PHASE_DISCARDED', '2': 3},
  ],
};

/// Descriptor for `InstallationPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List installationPhaseDescriptor = $convert.base64Decode(
    'ChFJbnN0YWxsYXRpb25QaGFzZRIeChpJTlNUQUxMQVRJT05fUEhBU0VfUlVOTklORxAAEh4KGk'
    'lOU1RBTExBVElPTl9QSEFTRV9TVE9QUEVEEAESHwobSU5TVEFMTEFUSU9OX1BIQVNFX0NPTVBM'
    'RVRFEAISIAocSU5TVEFMTEFUSU9OX1BIQVNFX0RJU0NBUkRFRBAD');

@$core.Deprecated('Use installationDraftReferenceDescriptor instead')
const InstallationDraftReference$json = {
  '1': 'InstallationDraftReference',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `InstallationDraftReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationDraftReferenceDescriptor =
    $convert.base64Decode(
        'ChpJbnN0YWxsYXRpb25EcmFmdFJlZmVyZW5jZRIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcm'
        'tzcGFjZUlkEg4KAmlkGAIgASgJUgJpZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24=');

@$core.Deprecated('Use installationDraftClosedDescriptor instead')
const InstallationDraftClosed$json = {
  '1': 'InstallationDraftClosed',
};

/// Descriptor for `InstallationDraftClosed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationDraftClosedDescriptor =
    $convert.base64Decode('ChdJbnN0YWxsYXRpb25EcmFmdENsb3NlZA==');

@$core.Deprecated('Use installationWorkspaceDescriptor instead')
const InstallationWorkspace$json = {
  '1': 'InstallationWorkspace',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
  ],
};

/// Descriptor for `InstallationWorkspace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationWorkspaceDescriptor = $convert.base64Decode(
    'ChVJbnN0YWxsYXRpb25Xb3Jrc3BhY2USIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZA==');

@$core.Deprecated('Use installationReferenceDescriptor instead')
const InstallationReference$json = {
  '1': 'InstallationReference',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `InstallationReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationReferenceDescriptor = $convert.base64Decode(
    'ChVJbnN0YWxsYXRpb25SZWZlcmVuY2USIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBIOCgJpZBgCIAEoCVICaWQ=');

@$core.Deprecated('Use installationFileDescriptor instead')
const InstallationFile$json = {
  '1': 'InstallationFile',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'destination', '3': 2, '4': 3, '5': 9, '10': 'destination'},
  ],
};

/// Descriptor for `InstallationFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationFileDescriptor = $convert.base64Decode(
    'ChBJbnN0YWxsYXRpb25GaWxlEhQKBWluZGV4GAEgASgNUgVpbmRleBIgCgtkZXN0aW5hdGlvbh'
    'gCIAMoCVILZGVzdGluYXRpb24=');

@$core.Deprecated('Use archiveInstallationDraftDescriptor instead')
const ArchiveInstallationDraft$json = {
  '1': 'ArchiveInstallationDraft',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {
      '1': 'artifact',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArtifactReference',
      '10': 'artifact'
    },
    {'1': 'archive_name', '3': 3, '4': 1, '5': 9, '10': 'archiveName'},
    {
      '1': 'manifest',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InspectedArchive',
      '10': 'manifest'
    },
    {'1': 'root', '3': 5, '4': 3, '5': 9, '10': 'root'},
    {
      '1': 'files',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InstallationFile',
      '10': 'files'
    },
    {'1': 'name', '3': 7, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 8, '4': 1, '5': 9, '10': 'version'},
    {'1': 'bytes', '3': 9, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'can_install', '3': 10, '4': 1, '5': 8, '10': 'canInstall'},
  ],
};

/// Descriptor for `ArchiveInstallationDraft`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archiveInstallationDraftDescriptor = $convert.base64Decode(
    'ChhBcmNoaXZlSW5zdGFsbGF0aW9uRHJhZnQSSQoJcmVmZXJlbmNlGAEgASgLMisubW9kY29uZH'
    'VjdG9yLnYxLkluc3RhbGxhdGlvbkRyYWZ0UmVmZXJlbmNlUglyZWZlcmVuY2USPgoIYXJ0aWZh'
    'Y3QYAiABKAsyIi5tb2Rjb25kdWN0b3IudjEuQXJ0aWZhY3RSZWZlcmVuY2VSCGFydGlmYWN0Ei'
    'EKDGFyY2hpdmVfbmFtZRgDIAEoCVILYXJjaGl2ZU5hbWUSPQoIbWFuaWZlc3QYBCABKAsyIS5t'
    'b2Rjb25kdWN0b3IudjEuSW5zcGVjdGVkQXJjaGl2ZVIIbWFuaWZlc3QSEgoEcm9vdBgFIAMoCV'
    'IEcm9vdBI3CgVmaWxlcxgGIAMoCzIhLm1vZGNvbmR1Y3Rvci52MS5JbnN0YWxsYXRpb25GaWxl'
    'UgVmaWxlcxISCgRuYW1lGAcgASgJUgRuYW1lEhgKB3ZlcnNpb24YCCABKAlSB3ZlcnNpb24SFA'
    'oFYnl0ZXMYCSABKARSBWJ5dGVzEh8KC2Nhbl9pbnN0YWxsGAogASgIUgpjYW5JbnN0YWxs');

@$core.Deprecated('Use installationRootDescriptor instead')
const InstallationRoot$json = {
  '1': 'InstallationRoot',
  '2': [
    {'1': 'components', '3': 1, '4': 3, '5': 9, '10': 'components'},
  ],
};

/// Descriptor for `InstallationRoot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationRootDescriptor = $convert.base64Decode(
    'ChBJbnN0YWxsYXRpb25Sb290Eh4KCmNvbXBvbmVudHMYASADKAlSCmNvbXBvbmVudHM=');

@$core.Deprecated('Use installationInclusionDescriptor instead')
const InstallationInclusion$json = {
  '1': 'InstallationInclusion',
  '2': [
    {'1': 'source', '3': 1, '4': 3, '5': 9, '10': 'source'},
    {'1': 'included', '3': 2, '4': 1, '5': 8, '10': 'included'},
  ],
};

/// Descriptor for `InstallationInclusion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationInclusionDescriptor = $convert.base64Decode(
    'ChVJbnN0YWxsYXRpb25JbmNsdXNpb24SFgoGc291cmNlGAEgAygJUgZzb3VyY2USGgoIaW5jbH'
    'VkZWQYAiABKAhSCGluY2x1ZGVk');

@$core.Deprecated('Use installationDestinationDescriptor instead')
const InstallationDestination$json = {
  '1': 'InstallationDestination',
  '2': [
    {'1': 'source', '3': 1, '4': 3, '5': 9, '10': 'source'},
    {'1': 'destination', '3': 2, '4': 3, '5': 9, '10': 'destination'},
  ],
};

/// Descriptor for `InstallationDestination`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationDestinationDescriptor =
    $convert.base64Decode(
        'ChdJbnN0YWxsYXRpb25EZXN0aW5hdGlvbhIWCgZzb3VyY2UYASADKAlSBnNvdXJjZRIgCgtkZX'
        'N0aW5hdGlvbhgCIAMoCVILZGVzdGluYXRpb24=');

@$core.Deprecated('Use installationMetadataDescriptor instead')
const InstallationMetadata$json = {
  '1': 'InstallationMetadata',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `InstallationMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationMetadataDescriptor = $convert.base64Decode(
    'ChRJbnN0YWxsYXRpb25NZXRhZGF0YRISCgRuYW1lGAEgASgJUgRuYW1lEhgKB3ZlcnNpb24YAi'
    'ABKAlSB3ZlcnNpb24=');

@$core.Deprecated('Use installationLayoutChangeDescriptor instead')
const InstallationLayoutChange$json = {
  '1': 'InstallationLayoutChange',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {
      '1': 'root',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationRoot',
      '9': 0,
      '10': 'root'
    },
    {
      '1': 'inclusion',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationInclusion',
      '9': 0,
      '10': 'inclusion'
    },
    {
      '1': 'destination',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDestination',
      '9': 0,
      '10': 'destination'
    },
    {
      '1': 'metadata',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationMetadata',
      '9': 0,
      '10': 'metadata'
    },
  ],
  '8': [
    {'1': 'change'},
  ],
};

/// Descriptor for `InstallationLayoutChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installationLayoutChangeDescriptor = $convert.base64Decode(
    'ChhJbnN0YWxsYXRpb25MYXlvdXRDaGFuZ2USSQoJcmVmZXJlbmNlGAEgASgLMisubW9kY29uZH'
    'VjdG9yLnYxLkluc3RhbGxhdGlvbkRyYWZ0UmVmZXJlbmNlUglyZWZlcmVuY2USNwoEcm9vdBgC'
    'IAEoCzIhLm1vZGNvbmR1Y3Rvci52MS5JbnN0YWxsYXRpb25Sb290SABSBHJvb3QSRgoJaW5jbH'
    'VzaW9uGAMgASgLMiYubW9kY29uZHVjdG9yLnYxLkluc3RhbGxhdGlvbkluY2x1c2lvbkgAUglp'
    'bmNsdXNpb24STAoLZGVzdGluYXRpb24YBCABKAsyKC5tb2Rjb25kdWN0b3IudjEuSW5zdGFsbG'
    'F0aW9uRGVzdGluYXRpb25IAFILZGVzdGluYXRpb24SQwoIbWV0YWRhdGEYBSABKAsyJS5tb2Rj'
    'b25kdWN0b3IudjEuSW5zdGFsbGF0aW9uTWV0YWRhdGFIAFIIbWV0YWRhdGFCCAoGY2hhbmdl');

@$core.Deprecated('Use startArchiveInstallationDescriptor instead')
const StartArchiveInstallation$json = {
  '1': 'StartArchiveInstallation',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `StartArchiveInstallation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startArchiveInstallationDescriptor = $convert.base64Decode(
    'ChhTdGFydEFyY2hpdmVJbnN0YWxsYXRpb24SQQoFZHJhZnQYASABKAsyKy5tb2Rjb25kdWN0b3'
    'IudjEuSW5zdGFsbGF0aW9uRHJhZnRSZWZlcmVuY2VSBWRyYWZ0Eg4KAmlkGAIgASgJUgJpZA==');

@$core.Deprecated('Use archiveInstallationStatusDescriptor instead')
const ArchiveInstallationStatus$json = {
  '1': 'ArchiveInstallationStatus',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'artifact_id', '3': 3, '4': 1, '5': 9, '10': 'artifactId'},
    {'1': 'archive_name', '3': 4, '4': 1, '5': 9, '10': 'archiveName'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 6, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'phase',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InstallationPhase',
      '10': 'phase'
    },
    {'1': 'files', '3': 8, '4': 1, '5': 13, '10': 'files'},
    {'1': 'total_files', '3': 9, '4': 1, '5': 13, '10': 'totalFiles'},
    {'1': 'bytes', '3': 10, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'total_bytes', '3': 11, '4': 1, '5': 4, '10': 'totalBytes'},
    {
      '1': 'problem',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'problem',
      '17': true
    },
    {'1': 'mod_id', '3': 13, '4': 1, '5': 9, '9': 1, '10': 'modId', '17': true},
    {
      '1': 'version_id',
      '3': 14,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'versionId',
      '17': true
    },
    {
      '1': 'temporary_bytes',
      '3': 15,
      '4': 1,
      '5': 4,
      '9': 3,
      '10': 'temporaryBytes',
      '17': true
    },
    {'1': 'is_update', '3': 16, '4': 1, '5': 8, '10': 'isUpdate'},
  ],
  '8': [
    {'1': '_problem'},
    {'1': '_mod_id'},
    {'1': '_version_id'},
    {'1': '_temporary_bytes'},
  ],
};

/// Descriptor for `ArchiveInstallationStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archiveInstallationStatusDescriptor = $convert.base64Decode(
    'ChlBcmNoaXZlSW5zdGFsbGF0aW9uU3RhdHVzEg4KAmlkGAEgASgJUgJpZBIhCgx3b3Jrc3BhY2'
    'VfaWQYAiABKAlSC3dvcmtzcGFjZUlkEh8KC2FydGlmYWN0X2lkGAMgASgJUgphcnRpZmFjdElk'
    'EiEKDGFyY2hpdmVfbmFtZRgEIAEoCVILYXJjaGl2ZU5hbWUSEgoEbmFtZRgFIAEoCVIEbmFtZR'
    'IYCgd2ZXJzaW9uGAYgASgJUgd2ZXJzaW9uEjgKBXBoYXNlGAcgASgOMiIubW9kY29uZHVjdG9y'
    'LnYxLkluc3RhbGxhdGlvblBoYXNlUgVwaGFzZRIUCgVmaWxlcxgIIAEoDVIFZmlsZXMSHwoLdG'
    '90YWxfZmlsZXMYCSABKA1SCnRvdGFsRmlsZXMSFAoFYnl0ZXMYCiABKARSBWJ5dGVzEh8KC3Rv'
    'dGFsX2J5dGVzGAsgASgEUgp0b3RhbEJ5dGVzEh0KB3Byb2JsZW0YDCABKAlIAFIHcHJvYmxlbY'
    'gBARIaCgZtb2RfaWQYDSABKAlIAVIFbW9kSWSIAQESIgoKdmVyc2lvbl9pZBgOIAEoCUgCUgl2'
    'ZXJzaW9uSWSIAQESLAoPdGVtcG9yYXJ5X2J5dGVzGA8gASgESANSDnRlbXBvcmFyeUJ5dGVziA'
    'EBEhsKCWlzX3VwZGF0ZRgQIAEoCFIIaXNVcGRhdGVCCgoIX3Byb2JsZW1CCQoHX21vZF9pZEIN'
    'CgtfdmVyc2lvbl9pZEISChBfdGVtcG9yYXJ5X2J5dGVz');

@$core.Deprecated('Use archiveInstallationListDescriptor instead')
const ArchiveInstallationList$json = {
  '1': 'ArchiveInstallationList',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ArchiveInstallationStatus',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ArchiveInstallationList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archiveInstallationListDescriptor =
    $convert.base64Decode(
        'ChdBcmNoaXZlSW5zdGFsbGF0aW9uTGlzdBJECgdlbnRyaWVzGAEgAygLMioubW9kY29uZHVjdG'
        '9yLnYxLkFyY2hpdmVJbnN0YWxsYXRpb25TdGF0dXNSB2VudHJpZXM=');
