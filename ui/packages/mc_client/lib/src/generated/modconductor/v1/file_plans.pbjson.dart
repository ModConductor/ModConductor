// This is a generated file - do not edit.
//
// Generated from modconductor/v1/file_plans.proto.

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

@$core.Deprecated('Use fileSourceStandingDescriptor instead')
const FileSourceStanding$json = {
  '1': 'FileSourceStanding',
  '2': [
    {'1': 'FILE_SOURCE_STANDING_UNSPECIFIED', '2': 0},
    {'1': 'FILE_SOURCE_STANDING_WINNER', '2': 1},
    {'1': 'FILE_SOURCE_STANDING_ALTERNATIVE', '2': 2},
    {'1': 'FILE_SOURCE_STANDING_SELECTED', '2': 3},
    {'1': 'FILE_SOURCE_STANDING_PREVIOUS', '2': 4},
    {'1': 'FILE_SOURCE_STANDING_UNAVAILABLE', '2': 5},
  ],
};

/// Descriptor for `FileSourceStanding`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fileSourceStandingDescriptor = $convert.base64Decode(
    'ChJGaWxlU291cmNlU3RhbmRpbmcSJAogRklMRV9TT1VSQ0VfU1RBTkRJTkdfVU5TUEVDSUZJRU'
    'QQABIfChtGSUxFX1NPVVJDRV9TVEFORElOR19XSU5ORVIQARIkCiBGSUxFX1NPVVJDRV9TVEFO'
    'RElOR19BTFRFUk5BVElWRRACEiEKHUZJTEVfU09VUkNFX1NUQU5ESU5HX1NFTEVDVEVEEAMSIQ'
    'odRklMRV9TT1VSQ0VfU1RBTkRJTkdfUFJFVklPVVMQBBIkCiBGSUxFX1NPVVJDRV9TVEFORElO'
    'R19VTkFWQUlMQUJMRRAF');

@$core.Deprecated('Use filePreviewRepresentationDescriptor instead')
const FilePreviewRepresentation$json = {
  '1': 'FilePreviewRepresentation',
  '2': [
    {'1': 'FILE_PREVIEW_REPRESENTATION_UNSPECIFIED', '2': 0},
    {'1': 'FILE_PREVIEW_REPRESENTATION_TEXT', '2': 1},
    {'1': 'FILE_PREVIEW_REPRESENTATION_IMAGE', '2': 2},
    {'1': 'FILE_PREVIEW_REPRESENTATION_HEX', '2': 3},
  ],
};

/// Descriptor for `FilePreviewRepresentation`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List filePreviewRepresentationDescriptor = $convert.base64Decode(
    'ChlGaWxlUHJldmlld1JlcHJlc2VudGF0aW9uEisKJ0ZJTEVfUFJFVklFV19SRVBSRVNFTlRBVE'
    'lPTl9VTlNQRUNJRklFRBAAEiQKIEZJTEVfUFJFVklFV19SRVBSRVNFTlRBVElPTl9URVhUEAES'
    'JQohRklMRV9QUkVWSUVXX1JFUFJFU0VOVEFUSU9OX0lNQUdFEAISIwofRklMRV9QUkVWSUVXX1'
    'JFUFJFU0VOVEFUSU9OX0hFWBAD');

@$core.Deprecated('Use filePreviewStatusDescriptor instead')
const FilePreviewStatus$json = {
  '1': 'FilePreviewStatus',
  '2': [
    {'1': 'FILE_PREVIEW_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'FILE_PREVIEW_STATUS_READY', '2': 1},
    {'1': 'FILE_PREVIEW_STATUS_UNSUPPORTED', '2': 2},
    {'1': 'FILE_PREVIEW_STATUS_TOO_LARGE', '2': 3},
    {'1': 'FILE_PREVIEW_STATUS_CHANGED', '2': 4},
  ],
};

/// Descriptor for `FilePreviewStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List filePreviewStatusDescriptor = $convert.base64Decode(
    'ChFGaWxlUHJldmlld1N0YXR1cxIjCh9GSUxFX1BSRVZJRVdfU1RBVFVTX1VOU1BFQ0lGSUVEEA'
    'ASHQoZRklMRV9QUkVWSUVXX1NUQVRVU19SRUFEWRABEiMKH0ZJTEVfUFJFVklFV19TVEFUVVNf'
    'VU5TVVBQT1JURUQQAhIhCh1GSUxFX1BSRVZJRVdfU1RBVFVTX1RPT19MQVJHRRADEh8KG0ZJTE'
    'VfUFJFVklFV19TVEFUVVNfQ0hBTkdFRBAE');

@$core.Deprecated('Use textDocumentEncodingDescriptor instead')
const TextDocumentEncoding$json = {
  '1': 'TextDocumentEncoding',
  '2': [
    {'1': 'TEXT_DOCUMENT_ENCODING_UNSPECIFIED', '2': 0},
    {'1': 'TEXT_DOCUMENT_ENCODING_UTF8', '2': 1},
    {'1': 'TEXT_DOCUMENT_ENCODING_UTF8_BOM', '2': 2},
    {'1': 'TEXT_DOCUMENT_ENCODING_UTF16_LITTLE', '2': 3},
    {'1': 'TEXT_DOCUMENT_ENCODING_UTF16_BIG', '2': 4},
  ],
};

/// Descriptor for `TextDocumentEncoding`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List textDocumentEncodingDescriptor = $convert.base64Decode(
    'ChRUZXh0RG9jdW1lbnRFbmNvZGluZxImCiJURVhUX0RPQ1VNRU5UX0VOQ09ESU5HX1VOU1BFQ0'
    'lGSUVEEAASHwobVEVYVF9ET0NVTUVOVF9FTkNPRElOR19VVEY4EAESIwofVEVYVF9ET0NVTUVO'
    'VF9FTkNPRElOR19VVEY4X0JPTRACEicKI1RFWFRfRE9DVU1FTlRfRU5DT0RJTkdfVVRGMTZfTE'
    'lUVExFEAMSJAogVEVYVF9ET0NVTUVOVF9FTkNPRElOR19VVEYxNl9CSUcQBA==');

@$core.Deprecated('Use textDocumentNewlineDescriptor instead')
const TextDocumentNewline$json = {
  '1': 'TextDocumentNewline',
  '2': [
    {'1': 'TEXT_DOCUMENT_NEWLINE_UNSPECIFIED', '2': 0},
    {'1': 'TEXT_DOCUMENT_NEWLINE_NO_LINE_BREAKS', '2': 1},
    {'1': 'TEXT_DOCUMENT_NEWLINE_LF', '2': 2},
    {'1': 'TEXT_DOCUMENT_NEWLINE_CRLF', '2': 3},
  ],
};

/// Descriptor for `TextDocumentNewline`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List textDocumentNewlineDescriptor = $convert.base64Decode(
    'ChNUZXh0RG9jdW1lbnROZXdsaW5lEiUKIVRFWFRfRE9DVU1FTlRfTkVXTElORV9VTlNQRUNJRk'
    'lFRBAAEigKJFRFWFRfRE9DVU1FTlRfTkVXTElORV9OT19MSU5FX0JSRUFLUxABEhwKGFRFWFRf'
    'RE9DVU1FTlRfTkVXTElORV9MRhACEh4KGlRFWFRfRE9DVU1FTlRfTkVXTElORV9DUkxGEAM=');

@$core.Deprecated('Use plannedFileDispositionDescriptor instead')
const PlannedFileDisposition$json = {
  '1': 'PlannedFileDisposition',
  '2': [
    {'1': 'PLANNED_FILE_DISPOSITION_UNSPECIFIED', '2': 0},
    {'1': 'PLANNED_FILE_DISPOSITION_PLANNED', '2': 1},
    {'1': 'PLANNED_FILE_DISPOSITION_ABSENT', '2': 2},
    {'1': 'PLANNED_FILE_DISPOSITION_UNRESOLVED', '2': 3},
    {'1': 'PLANNED_FILE_DISPOSITION_WRITABLE', '2': 4},
  ],
};

/// Descriptor for `PlannedFileDisposition`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List plannedFileDispositionDescriptor = $convert.base64Decode(
    'ChZQbGFubmVkRmlsZURpc3Bvc2l0aW9uEigKJFBMQU5ORURfRklMRV9ESVNQT1NJVElPTl9VTl'
    'NQRUNJRklFRBAAEiQKIFBMQU5ORURfRklMRV9ESVNQT1NJVElPTl9QTEFOTkVEEAESIwofUExB'
    'Tk5FRF9GSUxFX0RJU1BPU0lUSU9OX0FCU0VOVBACEicKI1BMQU5ORURfRklMRV9ESVNQT1NJVE'
    'lPTl9VTlJFU09MVkVEEAMSJQohUExBTk5FRF9GSUxFX0RJU1BPU0lUSU9OX1dSSVRBQkxFEAQ=');

@$core.Deprecated('Use filePlanFaultCodeDescriptor instead')
const FilePlanFaultCode$json = {
  '1': 'FilePlanFaultCode',
  '2': [
    {'1': 'FILE_PLAN_FAULT_UNSPECIFIED', '2': 0},
    {'1': 'FILE_PLAN_FAULT_NOT_FOUND', '2': 1},
    {'1': 'FILE_PLAN_FAULT_BUSY', '2': 2},
    {'1': 'FILE_PLAN_FAULT_EXPIRED', '2': 3},
    {'1': 'FILE_PLAN_FAULT_STALE', '2': 4},
    {'1': 'FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE', '2': 5},
    {'1': 'FILE_PLAN_FAULT_FILE_UNAVAILABLE', '2': 6},
    {'1': 'FILE_PLAN_FAULT_LIMIT_EXCEEDED', '2': 7},
    {'1': 'FILE_PLAN_FAULT_CANCELLED', '2': 8},
    {'1': 'FILE_PLAN_FAULT_INVALID_COPY', '2': 9},
    {'1': 'FILE_PLAN_FAULT_BLOCKED', '2': 10},
    {'1': 'FILE_PLAN_FAULT_UNSUPPORTED', '2': 11},
    {'1': 'FILE_PLAN_FAULT_INVALID_EDIT', '2': 12},
  ],
};

/// Descriptor for `FilePlanFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List filePlanFaultCodeDescriptor = $convert.base64Decode(
    'ChFGaWxlUGxhbkZhdWx0Q29kZRIfChtGSUxFX1BMQU5fRkFVTFRfVU5TUEVDSUZJRUQQABIdCh'
    'lGSUxFX1BMQU5fRkFVTFRfTk9UX0ZPVU5EEAESGAoURklMRV9QTEFOX0ZBVUxUX0JVU1kQAhIb'
    'ChdGSUxFX1BMQU5fRkFVTFRfRVhQSVJFRBADEhkKFUZJTEVfUExBTl9GQVVMVF9TVEFMRRAEEi'
    'cKI0ZJTEVfUExBTl9GQVVMVF9DT05URVhUX1VOQVZBSUxBQkxFEAUSJAogRklMRV9QTEFOX0ZB'
    'VUxUX0ZJTEVfVU5BVkFJTEFCTEUQBhIiCh5GSUxFX1BMQU5fRkFVTFRfTElNSVRfRVhDRUVERU'
    'QQBxIdChlGSUxFX1BMQU5fRkFVTFRfQ0FOQ0VMTEVEEAgSIAocRklMRV9QTEFOX0ZBVUxUX0lO'
    'VkFMSURfQ09QWRAJEhsKF0ZJTEVfUExBTl9GQVVMVF9CTE9DS0VEEAoSHwobRklMRV9QTEFOX0'
    'ZBVUxUX1VOU1VQUE9SVEVEEAsSIAocRklMRV9QTEFOX0ZBVUxUX0lOVkFMSURfRURJVBAM');

@$core.Deprecated('Use managedFileCopyDescriptor instead')
const ManagedFileCopy$json = {
  '1': 'ManagedFileCopy',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'version_id', '3': 2, '4': 1, '5': 9, '10': 'versionId'},
    {
      '1': 'path',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
  ],
};

/// Descriptor for `ManagedFileCopy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedFileCopyDescriptor = $convert.base64Decode(
    'Cg9NYW5hZ2VkRmlsZUNvcHkSFQoGbW9kX2lkGAEgASgJUgVtb2RJZBIdCgp2ZXJzaW9uX2lkGA'
    'IgASgJUgl2ZXJzaW9uSWQSMwoEcGF0aBgDIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dp'
    'Y2FsUGF0aFIEcGF0aA==');

@$core.Deprecated('Use managedPreviewSourceDescriptor instead')
const ManagedPreviewSource$json = {
  '1': 'ManagedPreviewSource',
  '2': [
    {
      '1': 'copy',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedFileCopy',
      '10': 'copy'
    },
    {
      '1': 'source_path',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'sourcePath'
    },
    {
      '1': 'target',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
    {'1': 'length', '3': 4, '4': 1, '5': 4, '10': 'length'},
    {'1': 'sha256', '3': 5, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'payload_id', '3': 6, '4': 1, '5': 9, '10': 'payloadId'},
    {'1': 'mod_revision', '3': 7, '4': 1, '5': 4, '10': 'modRevision'},
  ],
};

/// Descriptor for `ManagedPreviewSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedPreviewSourceDescriptor = $convert.base64Decode(
    'ChRNYW5hZ2VkUHJldmlld1NvdXJjZRI0CgRjb3B5GAEgASgLMiAubW9kY29uZHVjdG9yLnYxLk'
    '1hbmFnZWRGaWxlQ29weVIEY29weRJACgtzb3VyY2VfcGF0aBgCIAEoCzIfLm1vZGNvbmR1Y3Rv'
    'ci52MS5Nb2RMb2dpY2FsUGF0aFIKc291cmNlUGF0aBI3CgZ0YXJnZXQYAyABKAsyHy5tb2Rjb2'
    '5kdWN0b3IudjEuTW9kTG9naWNhbFBhdGhSBnRhcmdldBIWCgZsZW5ndGgYBCABKARSBmxlbmd0'
    'aBIWCgZzaGEyNTYYBSABKAlSBnNoYTI1NhIdCgpwYXlsb2FkX2lkGAYgASgJUglwYXlsb2FkSW'
    'QSIQoMbW9kX3JldmlzaW9uGAcgASgEUgttb2RSZXZpc2lvbg==');

@$core.Deprecated('Use checkedGamePreviewSourceDescriptor instead')
const CheckedGamePreviewSource$json = {
  '1': 'CheckedGamePreviewSource',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'generation', '3': 2, '4': 1, '5': 9, '10': 'generation'},
    {'1': 'kind', '3': 3, '4': 1, '5': 13, '10': 'kind'},
    {
      '1': 'source_path',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'sourcePath'
    },
    {
      '1': 'target',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
    {'1': 'length', '3': 6, '4': 1, '5': 4, '10': 'length'},
    {'1': 'sha256', '3': 7, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `CheckedGamePreviewSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkedGamePreviewSourceDescriptor = $convert.base64Decode(
    'ChhDaGVja2VkR2FtZVByZXZpZXdTb3VyY2USHwoLc25hcHNob3RfaWQYASABKAlSCnNuYXBzaG'
    '90SWQSHgoKZ2VuZXJhdGlvbhgCIAEoCVIKZ2VuZXJhdGlvbhISCgRraW5kGAMgASgNUgRraW5k'
    'EkAKC3NvdXJjZV9wYXRoGAQgASgLMh8ubW9kY29uZHVjdG9yLnYxLk1vZExvZ2ljYWxQYXRoUg'
    'pzb3VyY2VQYXRoEjcKBnRhcmdldBgFIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dpY2Fs'
    'UGF0aFIGdGFyZ2V0EhYKBmxlbmd0aBgGIAEoBFIGbGVuZ3RoEhYKBnNoYTI1NhgHIAEoCVIGc2'
    'hhMjU2');

@$core.Deprecated('Use qualifiedArchiveEntryPreviewSourceDescriptor instead')
const QualifiedArchiveEntryPreviewSource$json = {
  '1': 'QualifiedArchiveEntryPreviewSource',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'artifact_id', '3': 2, '4': 1, '5': 9, '10': 'artifactId'},
    {
      '1': 'artifact_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'artifactRevision'
    },
    {'1': 'archive_sha256', '3': 4, '4': 1, '5': 9, '10': 'archiveSha256'},
    {'1': 'format', '3': 5, '4': 1, '5': 9, '10': 'format'},
    {'1': 'index', '3': 6, '4': 1, '5': 13, '10': 'index'},
    {
      '1': 'path',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
    {'1': 'length', '3': 8, '4': 1, '5': 4, '10': 'length'},
  ],
};

/// Descriptor for `QualifiedArchiveEntryPreviewSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List qualifiedArchiveEntryPreviewSourceDescriptor = $convert.base64Decode(
    'CiJRdWFsaWZpZWRBcmNoaXZlRW50cnlQcmV2aWV3U291cmNlEiEKDHdvcmtzcGFjZV9pZBgBIA'
    'EoCVILd29ya3NwYWNlSWQSHwoLYXJ0aWZhY3RfaWQYAiABKAlSCmFydGlmYWN0SWQSKwoRYXJ0'
    'aWZhY3RfcmV2aXNpb24YAyABKARSEGFydGlmYWN0UmV2aXNpb24SJQoOYXJjaGl2ZV9zaGEyNT'
    'YYBCABKAlSDWFyY2hpdmVTaGEyNTYSFgoGZm9ybWF0GAUgASgJUgZmb3JtYXQSFAoFaW5kZXgY'
    'BiABKA1SBWluZGV4EjMKBHBhdGgYByABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG9naWNhbF'
    'BhdGhSBHBhdGgSFgoGbGVuZ3RoGAggASgEUgZsZW5ndGg=');

@$core.Deprecated('Use filePreviewSourceDescriptor instead')
const FilePreviewSource$json = {
  '1': 'FilePreviewSource',
  '2': [
    {
      '1': 'managed',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedPreviewSource',
      '9': 0,
      '10': 'managed'
    },
    {
      '1': 'game',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CheckedGamePreviewSource',
      '9': 0,
      '10': 'game'
    },
    {
      '1': 'archive_entry',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.QualifiedArchiveEntryPreviewSource',
      '9': 0,
      '10': 'archiveEntry'
    },
  ],
  '8': [
    {'1': 'source'},
  ],
};

/// Descriptor for `FilePreviewSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewSourceDescriptor = $convert.base64Decode(
    'ChFGaWxlUHJldmlld1NvdXJjZRJBCgdtYW5hZ2VkGAEgASgLMiUubW9kY29uZHVjdG9yLnYxLk'
    '1hbmFnZWRQcmV2aWV3U291cmNlSABSB21hbmFnZWQSPwoEZ2FtZRgCIAEoCzIpLm1vZGNvbmR1'
    'Y3Rvci52MS5DaGVja2VkR2FtZVByZXZpZXdTb3VyY2VIAFIEZ2FtZRJaCg1hcmNoaXZlX2VudH'
    'J5GAMgASgLMjMubW9kY29uZHVjdG9yLnYxLlF1YWxpZmllZEFyY2hpdmVFbnRyeVByZXZpZXdT'
    'b3VyY2VIAFIMYXJjaGl2ZUVudHJ5QggKBnNvdXJjZQ==');

@$core.Deprecated('Use filePreviewTextDescriptor instead')
const FilePreviewText$json = {
  '1': 'FilePreviewText',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 9, '10': 'content'},
    {'1': 'encoding', '3': 2, '4': 1, '5': 9, '10': 'encoding'},
    {'1': 'lines', '3': 3, '4': 1, '5': 13, '10': 'lines'},
  ],
};

/// Descriptor for `FilePreviewText`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewTextDescriptor = $convert.base64Decode(
    'Cg9GaWxlUHJldmlld1RleHQSGAoHY29udGVudBgBIAEoCVIHY29udGVudBIaCghlbmNvZGluZx'
    'gCIAEoCVIIZW5jb2RpbmcSFAoFbGluZXMYAyABKA1SBWxpbmVz');

@$core.Deprecated('Use filePreviewImageDescriptor instead')
const FilePreviewImage$json = {
  '1': 'FilePreviewImage',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 12, '10': 'content'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
    {'1': 'width', '3': 3, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 13, '10': 'height'},
  ],
};

/// Descriptor for `FilePreviewImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewImageDescriptor = $convert.base64Decode(
    'ChBGaWxlUHJldmlld0ltYWdlEhgKB2NvbnRlbnQYASABKAxSB2NvbnRlbnQSFgoGZm9ybWF0GA'
    'IgASgJUgZmb3JtYXQSFAoFd2lkdGgYAyABKA1SBXdpZHRoEhYKBmhlaWdodBgEIAEoDVIGaGVp'
    'Z2h0');

@$core.Deprecated('Use filePreviewHexDescriptor instead')
const FilePreviewHex$json = {
  '1': 'FilePreviewHex',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 12, '10': 'content'},
    {'1': 'total_length', '3': 2, '4': 1, '5': 4, '10': 'totalLength'},
    {'1': 'truncated', '3': 3, '4': 1, '5': 8, '10': 'truncated'},
  ],
};

/// Descriptor for `FilePreviewHex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewHexDescriptor = $convert.base64Decode(
    'Cg5GaWxlUHJldmlld0hleBIYCgdjb250ZW50GAEgASgMUgdjb250ZW50EiEKDHRvdGFsX2xlbm'
    'd0aBgCIAEoBFILdG90YWxMZW5ndGgSHAoJdHJ1bmNhdGVkGAMgASgIUgl0cnVuY2F0ZWQ=');

@$core.Deprecated('Use filePreviewResultDescriptor instead')
const FilePreviewResult$json = {
  '1': 'FilePreviewResult',
  '2': [
    {
      '1': 'source',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewSource',
      '10': 'source'
    },
    {
      '1': 'standing',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FileSourceStanding',
      '10': 'standing'
    },
    {
      '1': 'target',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
    {
      '1': 'status',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FilePreviewStatus',
      '10': 'status'
    },
    {'1': 'detail', '3': 5, '4': 1, '5': 9, '10': 'detail'},
    {
      '1': 'text',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewText',
      '9': 0,
      '10': 'text'
    },
    {
      '1': 'image',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewImage',
      '9': 0,
      '10': 'image'
    },
    {
      '1': 'hex',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewHex',
      '9': 0,
      '10': 'hex'
    },
  ],
  '8': [
    {'1': 'content'},
  ],
};

/// Descriptor for `FilePreviewResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewResultDescriptor = $convert.base64Decode(
    'ChFGaWxlUHJldmlld1Jlc3VsdBI6CgZzb3VyY2UYASABKAsyIi5tb2Rjb25kdWN0b3IudjEuRm'
    'lsZVByZXZpZXdTb3VyY2VSBnNvdXJjZRI/CghzdGFuZGluZxgCIAEoDjIjLm1vZGNvbmR1Y3Rv'
    'ci52MS5GaWxlU291cmNlU3RhbmRpbmdSCHN0YW5kaW5nEjcKBnRhcmdldBgDIAEoCzIfLm1vZG'
    'NvbmR1Y3Rvci52MS5Nb2RMb2dpY2FsUGF0aFIGdGFyZ2V0EjoKBnN0YXR1cxgEIAEoDjIiLm1v'
    'ZGNvbmR1Y3Rvci52MS5GaWxlUHJldmlld1N0YXR1c1IGc3RhdHVzEhYKBmRldGFpbBgFIAEoCV'
    'IGZGV0YWlsEjYKBHRleHQYBiABKAsyIC5tb2Rjb25kdWN0b3IudjEuRmlsZVByZXZpZXdUZXh0'
    'SABSBHRleHQSOQoFaW1hZ2UYByABKAsyIS5tb2Rjb25kdWN0b3IudjEuRmlsZVByZXZpZXdJbW'
    'FnZUgAUgVpbWFnZRIzCgNoZXgYCCABKAsyHy5tb2Rjb25kdWN0b3IudjEuRmlsZVByZXZpZXdI'
    'ZXhIAFIDaGV4QgkKB2NvbnRlbnQ=');

@$core.Deprecated('Use filePreviewRequestDescriptor instead')
const FilePreviewRequest$json = {
  '1': 'FilePreviewRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewSource',
      '10': 'source'
    },
    {
      '1': 'representation',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FilePreviewRepresentation',
      '10': 'representation'
    },
  ],
};

/// Descriptor for `FilePreviewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewRequestDescriptor = $convert.base64Decode(
    'ChJGaWxlUHJldmlld1JlcXVlc3QSHwoLc25hcHNob3RfaWQYASABKAlSCnNuYXBzaG90SWQSOg'
    'oGc291cmNlGAIgASgLMiIubW9kY29uZHVjdG9yLnYxLkZpbGVQcmV2aWV3U291cmNlUgZzb3Vy'
    'Y2USUgoOcmVwcmVzZW50YXRpb24YAyABKA4yKi5tb2Rjb25kdWN0b3IudjEuRmlsZVByZXZpZX'
    'dSZXByZXNlbnRhdGlvblIOcmVwcmVzZW50YXRpb24=');

@$core.Deprecated('Use filePreviewReplyDescriptor instead')
const FilePreviewReply$json = {
  '1': 'FilePreviewReply',
  '2': [
    {
      '1': 'preview',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewResult',
      '9': 0,
      '10': 'preview'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FilePreviewReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePreviewReplyDescriptor = $convert.base64Decode(
    'ChBGaWxlUHJldmlld1JlcGx5Ej4KB3ByZXZpZXcYASABKAsyIi5tb2Rjb25kdWN0b3IudjEuRm'
    'lsZVByZXZpZXdSZXN1bHRIAFIHcHJldmlldxI2CgVmYXVsdBgCIAEoCzIeLm1vZGNvbmR1Y3Rv'
    'ci52MS5GaWxlUGxhbkZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use textDocumentDescriptor instead')
const TextDocument$json = {
  '1': 'TextDocument',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'encoding',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.TextDocumentEncoding',
      '10': 'encoding'
    },
    {
      '1': 'newline',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.TextDocumentNewline',
      '10': 'newline'
    },
    {'1': 'final_terminator', '3': 4, '4': 1, '5': 8, '10': 'finalTerminator'},
    {'1': 'lines', '3': 5, '4': 1, '5': 13, '10': 'lines'},
  ],
};

/// Descriptor for `TextDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textDocumentDescriptor = $convert.base64Decode(
    'CgxUZXh0RG9jdW1lbnQSGAoHY29udGVudBgBIAEoCVIHY29udGVudBJBCghlbmNvZGluZxgCIA'
    'EoDjIlLm1vZGNvbmR1Y3Rvci52MS5UZXh0RG9jdW1lbnRFbmNvZGluZ1IIZW5jb2RpbmcSPgoH'
    'bmV3bGluZRgDIAEoDjIkLm1vZGNvbmR1Y3Rvci52MS5UZXh0RG9jdW1lbnROZXdsaW5lUgduZX'
    'dsaW5lEikKEGZpbmFsX3Rlcm1pbmF0b3IYBCABKAhSD2ZpbmFsVGVybWluYXRvchIUCgVsaW5l'
    'cxgFIAEoDVIFbGluZXM=');

@$core.Deprecated('Use managedTextDocumentDescriptor instead')
const ManagedTextDocument$json = {
  '1': 'ManagedTextDocument',
  '2': [
    {
      '1': 'source',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedPreviewSource',
      '10': 'source'
    },
    {
      '1': 'document',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.TextDocument',
      '10': 'document'
    },
  ],
};

/// Descriptor for `ManagedTextDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedTextDocumentDescriptor = $convert.base64Decode(
    'ChNNYW5hZ2VkVGV4dERvY3VtZW50Ej0KBnNvdXJjZRgBIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS'
    '5NYW5hZ2VkUHJldmlld1NvdXJjZVIGc291cmNlEjkKCGRvY3VtZW50GAIgASgLMh0ubW9kY29u'
    'ZHVjdG9yLnYxLlRleHREb2N1bWVudFIIZG9jdW1lbnQ=');

@$core.Deprecated('Use managedTextEditDescriptor instead')
const ManagedTextEdit$json = {
  '1': 'ManagedTextEdit',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'version_id', '3': 2, '4': 1, '5': 9, '10': 'versionId'},
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedPreviewSource',
      '10': 'source'
    },
  ],
};

/// Descriptor for `ManagedTextEdit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedTextEditDescriptor = $convert.base64Decode(
    'Cg9NYW5hZ2VkVGV4dEVkaXQSDgoCaWQYASABKAlSAmlkEh0KCnZlcnNpb25faWQYAiABKAlSCX'
    'ZlcnNpb25JZBI9CgZzb3VyY2UYAyABKAsyJS5tb2Rjb25kdWN0b3IudjEuTWFuYWdlZFByZXZp'
    'ZXdTb3VyY2VSBnNvdXJjZQ==');

@$core.Deprecated('Use openManagedTextRequestDescriptor instead')
const OpenManagedTextRequest$json = {
  '1': 'OpenManagedTextRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedPreviewSource',
      '10': 'source'
    },
  ],
};

/// Descriptor for `OpenManagedTextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openManagedTextRequestDescriptor = $convert.base64Decode(
    'ChZPcGVuTWFuYWdlZFRleHRSZXF1ZXN0Eh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdE'
    'lkEj0KBnNvdXJjZRgCIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS5NYW5hZ2VkUHJldmlld1NvdXJj'
    'ZVIGc291cmNl');

@$core.Deprecated('Use saveManagedTextRequestDescriptor instead')
const SaveManagedTextRequest$json = {
  '1': 'SaveManagedTextRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedPreviewSource',
      '10': 'source'
    },
    {'1': 'content', '3': 4, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `SaveManagedTextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveManagedTextRequestDescriptor = $convert.base64Decode(
    'ChZTYXZlTWFuYWdlZFRleHRSZXF1ZXN0Eh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdE'
    'lkEg4KAmlkGAIgASgJUgJpZBI9CgZzb3VyY2UYAyABKAsyJS5tb2Rjb25kdWN0b3IudjEuTWFu'
    'YWdlZFByZXZpZXdTb3VyY2VSBnNvdXJjZRIYCgdjb250ZW50GAQgASgJUgdjb250ZW50');

@$core.Deprecated('Use abandonManagedTextRequestDescriptor instead')
const AbandonManagedTextRequest$json = {
  '1': 'AbandonManagedTextRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `AbandonManagedTextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List abandonManagedTextRequestDescriptor =
    $convert.base64Decode(
        'ChlBYmFuZG9uTWFuYWdlZFRleHRSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use managedTextReplyDescriptor instead')
const ManagedTextReply$json = {
  '1': 'ManagedTextReply',
  '2': [
    {
      '1': 'document',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedTextDocument',
      '9': 0,
      '10': 'document'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ManagedTextReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedTextReplyDescriptor = $convert.base64Decode(
    'ChBNYW5hZ2VkVGV4dFJlcGx5EkIKCGRvY3VtZW50GAEgASgLMiQubW9kY29uZHVjdG9yLnYxLk'
    '1hbmFnZWRUZXh0RG9jdW1lbnRIAFIIZG9jdW1lbnQSNgoFZmF1bHQYAiABKAsyHi5tb2Rjb25k'
    'dWN0b3IudjEuRmlsZVBsYW5GYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use managedTextEditReplyDescriptor instead')
const ManagedTextEditReply$json = {
  '1': 'ManagedTextEditReply',
  '2': [
    {
      '1': 'edit',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedTextEdit',
      '9': 0,
      '10': 'edit'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ManagedTextEditReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedTextEditReplyDescriptor = $convert.base64Decode(
    'ChRNYW5hZ2VkVGV4dEVkaXRSZXBseRI2CgRlZGl0GAEgASgLMiAubW9kY29uZHVjdG9yLnYxLk'
    '1hbmFnZWRUZXh0RWRpdEgAUgRlZGl0EjYKBWZhdWx0GAIgASgLMh4ubW9kY29uZHVjdG9yLnYx'
    'LkZpbGVQbGFuRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use managedTextAbandonReplyDescriptor instead')
const ManagedTextAbandonReply$json = {
  '1': 'ManagedTextAbandonReply',
  '2': [
    {'1': 'abandoned_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'abandonedId'},
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ManagedTextAbandonReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List managedTextAbandonReplyDescriptor = $convert.base64Decode(
    'ChdNYW5hZ2VkVGV4dEFiYW5kb25SZXBseRIjCgxhYmFuZG9uZWRfaWQYASABKAlIAFILYWJhbm'
    'RvbmVkSWQSNgoFZmF1bHQYAiABKAsyHi5tb2Rjb25kdWN0b3IudjEuRmlsZVBsYW5GYXVsdEgA'
    'UgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use filePlanCursorDescriptor instead')
const FilePlanCursor$json = {
  '1': 'FilePlanCursor',
  '2': [
    {'1': 'identity', '3': 1, '4': 1, '5': 9, '10': 'identity'},
    {'1': 'offset', '3': 2, '4': 1, '5': 13, '10': 'offset'},
  ],
};

/// Descriptor for `FilePlanCursor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanCursorDescriptor = $convert.base64Decode(
    'Cg5GaWxlUGxhbkN1cnNvchIaCghpZGVudGl0eRgBIAEoCVIIaWRlbnRpdHkSFgoGb2Zmc2V0GA'
    'IgASgNUgZvZmZzZXQ=');

@$core.Deprecated('Use openFilePlanRequestDescriptor instead')
const OpenFilePlanRequest$json = {
  '1': 'OpenFilePlanRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `OpenFilePlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openFilePlanRequestDescriptor = $convert.base64Decode(
    'ChNPcGVuRmlsZVBsYW5SZXF1ZXN0Eh0KCnByb2ZpbGVfaWQYASABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use acquireFilePlanRequestDescriptor instead')
const AcquireFilePlanRequest$json = {
  '1': 'AcquireFilePlanRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'refresh', '3': 2, '4': 1, '5': 8, '10': 'refresh'},
  ],
};

/// Descriptor for `AcquireFilePlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acquireFilePlanRequestDescriptor =
    $convert.base64Decode(
        'ChZBY3F1aXJlRmlsZVBsYW5SZXF1ZXN0Eh0KCnByb2ZpbGVfaWQYASABKAlSCXByb2ZpbGVJZB'
        'IYCgdyZWZyZXNoGAIgASgIUgdyZWZyZXNo');

@$core.Deprecated('Use filePlanRequestDescriptor instead')
const FilePlanRequest$json = {
  '1': 'FilePlanRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `FilePlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanRequestDescriptor = $convert.base64Decode(
    'Cg9GaWxlUGxhblJlcXVlc3QSHwoLc25hcHNob3RfaWQYASABKAlSCnNuYXBzaG90SWQ=');

@$core.Deprecated('Use filePlanChildrenRequestDescriptor instead')
const FilePlanChildrenRequest$json = {
  '1': 'FilePlanChildrenRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'parent',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'parent'
    },
    {'1': 'filter', '3': 3, '4': 1, '5': 9, '10': 'filter'},
    {
      '1': 'cursor',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanCursor',
      '10': 'cursor'
    },
  ],
};

/// Descriptor for `FilePlanChildrenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanChildrenRequestDescriptor = $convert.base64Decode(
    'ChdGaWxlUGxhbkNoaWxkcmVuUmVxdWVzdBIfCgtzbmFwc2hvdF9pZBgBIAEoCVIKc25hcHNob3'
    'RJZBI3CgZwYXJlbnQYAiABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG9naWNhbFBhdGhSBnBh'
    'cmVudBIWCgZmaWx0ZXIYAyABKAlSBmZpbHRlchI3CgZjdXJzb3IYBCABKAsyHy5tb2Rjb25kdW'
    'N0b3IudjEuRmlsZVBsYW5DdXJzb3JSBmN1cnNvcg==');

@$core.Deprecated('Use filePlanProblemsRequestDescriptor instead')
const FilePlanProblemsRequest$json = {
  '1': 'FilePlanProblemsRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'cursor',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanCursor',
      '10': 'cursor'
    },
  ],
};

/// Descriptor for `FilePlanProblemsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanProblemsRequestDescriptor = $convert.base64Decode(
    'ChdGaWxlUGxhblByb2JsZW1zUmVxdWVzdBIfCgtzbmFwc2hvdF9pZBgBIAEoCVIKc25hcHNob3'
    'RJZBI3CgZjdXJzb3IYAiABKAsyHy5tb2Rjb25kdWN0b3IudjEuRmlsZVBsYW5DdXJzb3JSBmN1'
    'cnNvcg==');

@$core.Deprecated('Use inspectFilePlanRequestDescriptor instead')
const InspectFilePlanRequest$json = {
  '1': 'InspectFilePlanRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'target',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
    {
      '1': 'cursor',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanCursor',
      '10': 'cursor'
    },
  ],
};

/// Descriptor for `InspectFilePlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectFilePlanRequestDescriptor = $convert.base64Decode(
    'ChZJbnNwZWN0RmlsZVBsYW5SZXF1ZXN0Eh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdE'
    'lkEjcKBnRhcmdldBgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dpY2FsUGF0aFIGdGFy'
    'Z2V0EjcKBmN1cnNvchgDIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5GaWxlUGxhbkN1cnNvclIGY3'
    'Vyc29y');

@$core.Deprecated('Use inspectSavedFileRequestDescriptor instead')
const InspectSavedFileRequest$json = {
  '1': 'InspectSavedFileRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'copy',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedFileCopy',
      '10': 'copy'
    },
  ],
};

/// Descriptor for `InspectSavedFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectSavedFileRequestDescriptor = $convert.base64Decode(
    'ChdJbnNwZWN0U2F2ZWRGaWxlUmVxdWVzdBIfCgtzbmFwc2hvdF9pZBgBIAEoCVIKc25hcHNob3'
    'RJZBI0CgRjb3B5GAIgASgLMiAubW9kY29uZHVjdG9yLnYxLk1hbmFnZWRGaWxlQ29weVIEY29w'
    'eQ==');

@$core.Deprecated('Use changeFileVisibilityRequestDescriptor instead')
const ChangeFileVisibilityRequest$json = {
  '1': 'ChangeFileVisibilityRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'copy',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedFileCopy',
      '10': 'copy'
    },
    {'1': 'hidden', '3': 3, '4': 1, '5': 8, '10': 'hidden'},
  ],
};

/// Descriptor for `ChangeFileVisibilityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeFileVisibilityRequestDescriptor =
    $convert.base64Decode(
        'ChtDaGFuZ2VGaWxlVmlzaWJpbGl0eVJlcXVlc3QSHwoLc25hcHNob3RfaWQYASABKAlSCnNuYX'
        'BzaG90SWQSNAoEY29weRgCIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS5NYW5hZ2VkRmlsZUNvcHlS'
        'BGNvcHkSFgoGaGlkZGVuGAMgASgIUgZoaWRkZW4=');

@$core.Deprecated('Use fileVisibilityHistoryRequestDescriptor instead')
const FileVisibilityHistoryRequest$json = {
  '1': 'FileVisibilityHistoryRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'copy',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedFileCopy',
      '10': 'copy'
    },
    {
      '1': 'before_id',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'beforeId',
      '17': true
    },
  ],
  '8': [
    {'1': '_before_id'},
  ],
};

/// Descriptor for `FileVisibilityHistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVisibilityHistoryRequestDescriptor = $convert.base64Decode(
    'ChxGaWxlVmlzaWJpbGl0eUhpc3RvcnlSZXF1ZXN0Eh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbm'
    'Fwc2hvdElkEjQKBGNvcHkYAiABKAsyIC5tb2Rjb25kdWN0b3IudjEuTWFuYWdlZEZpbGVDb3B5'
    'UgRjb3B5EiAKCWJlZm9yZV9pZBgDIAEoBEgAUghiZWZvcmVJZIgBAUIMCgpfYmVmb3JlX2lk');

@$core.Deprecated('Use filePlanStateDescriptor instead')
const FilePlanState$json = {
  '1': 'FilePlanState',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'fingerprint', '3': 4, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'loaded', '3': 5, '4': 1, '5': 8, '10': 'loaded'},
    {'1': 'stale', '3': 6, '4': 1, '5': 8, '10': 'stale'},
    {'1': 'planned_files', '3': 7, '4': 1, '5': 13, '10': 'plannedFiles'},
    {'1': 'absent_targets', '3': 8, '4': 1, '5': 13, '10': 'absentTargets'},
    {'1': 'inspected_files', '3': 9, '4': 1, '5': 13, '10': 'inspectedFiles'},
    {'1': 'problems', '3': 10, '4': 3, '5': 9, '10': 'problems'},
    {'1': 'problem_count', '3': 11, '4': 1, '5': 13, '10': 'problemCount'},
    {
      '1': 'observed_at_unix_ms',
      '3': 12,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'observedAtUnixMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_observed_at_unix_ms'},
  ],
};

/// Descriptor for `FilePlanState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanStateDescriptor = $convert.base64Decode(
    'Cg1GaWxlUGxhblN0YXRlEh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdElkEiEKDHdvcm'
    'tzcGFjZV9pZBgCIAEoCVILd29ya3NwYWNlSWQSHQoKcHJvZmlsZV9pZBgDIAEoCVIJcHJvZmls'
    'ZUlkEiAKC2ZpbmdlcnByaW50GAQgASgJUgtmaW5nZXJwcmludBIWCgZsb2FkZWQYBSABKAhSBm'
    'xvYWRlZBIUCgVzdGFsZRgGIAEoCFIFc3RhbGUSIwoNcGxhbm5lZF9maWxlcxgHIAEoDVIMcGxh'
    'bm5lZEZpbGVzEiUKDmFic2VudF90YXJnZXRzGAggASgNUg1hYnNlbnRUYXJnZXRzEicKD2luc3'
    'BlY3RlZF9maWxlcxgJIAEoDVIOaW5zcGVjdGVkRmlsZXMSGgoIcHJvYmxlbXMYCiADKAlSCHBy'
    'b2JsZW1zEiMKDXByb2JsZW1fY291bnQYCyABKA1SDHByb2JsZW1Db3VudBIyChNvYnNlcnZlZF'
    '9hdF91bml4X21zGAwgASgDSABSEG9ic2VydmVkQXRVbml4TXOIAQFCFgoUX29ic2VydmVkX2F0'
    'X3VuaXhfbXM=');

@$core.Deprecated('Use plannedFileNodeDescriptor instead')
const PlannedFileNode$json = {
  '1': 'PlannedFileNode',
  '2': [
    {
      '1': 'path',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
    {'1': 'directory', '3': 2, '4': 1, '5': 8, '10': 'directory'},
    {
      '1': 'disposition',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.PlannedFileDisposition',
      '10': 'disposition'
    },
    {'1': 'source_name', '3': 4, '4': 1, '5': 9, '10': 'sourceName'},
    {'1': 'copies', '3': 5, '4': 1, '5': 13, '10': 'copies'},
  ],
};

/// Descriptor for `PlannedFileNode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List plannedFileNodeDescriptor = $convert.base64Decode(
    'Cg9QbGFubmVkRmlsZU5vZGUSMwoEcGF0aBgBIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2'
    'dpY2FsUGF0aFIEcGF0aBIcCglkaXJlY3RvcnkYAiABKAhSCWRpcmVjdG9yeRJJCgtkaXNwb3Np'
    'dGlvbhgDIAEoDjInLm1vZGNvbmR1Y3Rvci52MS5QbGFubmVkRmlsZURpc3Bvc2l0aW9uUgtkaX'
    'Nwb3NpdGlvbhIfCgtzb3VyY2VfbmFtZRgEIAEoCVIKc291cmNlTmFtZRIWCgZjb3BpZXMYBSAB'
    'KA1SBmNvcGllcw==');

@$core.Deprecated('Use plannedFilePageDescriptor instead')
const PlannedFilePage$json = {
  '1': 'PlannedFilePage',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanState',
      '10': 'state'
    },
    {
      '1': 'nodes',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.PlannedFileNode',
      '10': 'nodes'
    },
    {
      '1': 'next',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanCursor',
      '10': 'next'
    },
  ],
};

/// Descriptor for `PlannedFilePage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List plannedFilePageDescriptor = $convert.base64Decode(
    'Cg9QbGFubmVkRmlsZVBhZ2USNAoFc3RhdGUYASABKAsyHi5tb2Rjb25kdWN0b3IudjEuRmlsZV'
    'BsYW5TdGF0ZVIFc3RhdGUSNgoFbm9kZXMYAiADKAsyIC5tb2Rjb25kdWN0b3IudjEuUGxhbm5l'
    'ZEZpbGVOb2RlUgVub2RlcxIzCgRuZXh0GAMgASgLMh8ubW9kY29uZHVjdG9yLnYxLkZpbGVQbG'
    'FuQ3Vyc29yUgRuZXh0');

@$core.Deprecated('Use inspectedFileCopyDescriptor instead')
const InspectedFileCopy$json = {
  '1': 'InspectedFileCopy',
  '2': [
    {
      '1': 'copy',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedFileCopy',
      '10': 'copy'
    },
    {
      '1': 'source_path',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'sourcePath'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version_label', '3': 4, '4': 1, '5': 9, '10': 'versionLabel'},
    {
      '1': 'priority',
      '3': 5,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'priority',
      '17': true
    },
    {'1': 'enabled', '3': 6, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'hidden', '3': 7, '4': 1, '5': 8, '10': 'hidden'},
    {'1': 'winner', '3': 8, '4': 1, '5': 8, '10': 'winner'},
    {'1': 'historical', '3': 9, '4': 1, '5': 8, '10': 'historical'},
    {'1': 'length', '3': 10, '4': 1, '5': 4, '10': 'length'},
    {'1': 'sha256', '3': 11, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'can_hide', '3': 12, '4': 1, '5': 8, '10': 'canHide'},
    {'1': 'can_unhide', '3': 13, '4': 1, '5': 8, '10': 'canUnhide'},
    {
      '1': 'source',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePreviewSource',
      '10': 'source'
    },
    {
      '1': 'standing',
      '3': 15,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FileSourceStanding',
      '10': 'standing'
    },
  ],
  '8': [
    {'1': '_priority'},
  ],
};

/// Descriptor for `InspectedFileCopy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectedFileCopyDescriptor = $convert.base64Decode(
    'ChFJbnNwZWN0ZWRGaWxlQ29weRI0CgRjb3B5GAEgASgLMiAubW9kY29uZHVjdG9yLnYxLk1hbm'
    'FnZWRGaWxlQ29weVIEY29weRJACgtzb3VyY2VfcGF0aBgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52'
    'MS5Nb2RMb2dpY2FsUGF0aFIKc291cmNlUGF0aBISCgRuYW1lGAMgASgJUgRuYW1lEiMKDXZlcn'
    'Npb25fbGFiZWwYBCABKAlSDHZlcnNpb25MYWJlbBIfCghwcmlvcml0eRgFIAEoDUgAUghwcmlv'
    'cml0eYgBARIYCgdlbmFibGVkGAYgASgIUgdlbmFibGVkEhYKBmhpZGRlbhgHIAEoCFIGaGlkZG'
    'VuEhYKBndpbm5lchgIIAEoCFIGd2lubmVyEh4KCmhpc3RvcmljYWwYCSABKAhSCmhpc3Rvcmlj'
    'YWwSFgoGbGVuZ3RoGAogASgEUgZsZW5ndGgSFgoGc2hhMjU2GAsgASgJUgZzaGEyNTYSGQoIY2'
    'FuX2hpZGUYDCABKAhSB2NhbkhpZGUSHQoKY2FuX3VuaGlkZRgNIAEoCFIJY2FuVW5oaWRlEjoK'
    'BnNvdXJjZRgOIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5GaWxlUHJldmlld1NvdXJjZVIGc291cm'
    'NlEj8KCHN0YW5kaW5nGA8gASgOMiMubW9kY29uZHVjdG9yLnYxLkZpbGVTb3VyY2VTdGFuZGlu'
    'Z1IIc3RhbmRpbmdCCwoJX3ByaW9yaXR5');

@$core.Deprecated('Use plannedFileInspectionDescriptor instead')
const PlannedFileInspection$json = {
  '1': 'PlannedFileInspection',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanState',
      '10': 'state'
    },
    {
      '1': 'target',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
    {
      '1': 'copies',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InspectedFileCopy',
      '10': 'copies'
    },
    {
      '1': 'next',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanCursor',
      '10': 'next'
    },
    {
      '1': 'focused_copy',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InspectedFileCopy',
      '10': 'focusedCopy'
    },
    {'1': 'writable', '3': 6, '4': 1, '5': 8, '10': 'writable'},
  ],
};

/// Descriptor for `PlannedFileInspection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List plannedFileInspectionDescriptor = $convert.base64Decode(
    'ChVQbGFubmVkRmlsZUluc3BlY3Rpb24SNAoFc3RhdGUYASABKAsyHi5tb2Rjb25kdWN0b3Iudj'
    'EuRmlsZVBsYW5TdGF0ZVIFc3RhdGUSNwoGdGFyZ2V0GAIgASgLMh8ubW9kY29uZHVjdG9yLnYx'
    'Lk1vZExvZ2ljYWxQYXRoUgZ0YXJnZXQSOgoGY29waWVzGAMgAygLMiIubW9kY29uZHVjdG9yLn'
    'YxLkluc3BlY3RlZEZpbGVDb3B5UgZjb3BpZXMSMwoEbmV4dBgEIAEoCzIfLm1vZGNvbmR1Y3Rv'
    'ci52MS5GaWxlUGxhbkN1cnNvclIEbmV4dBJFCgxmb2N1c2VkX2NvcHkYBSABKAsyIi5tb2Rjb2'
    '5kdWN0b3IudjEuSW5zcGVjdGVkRmlsZUNvcHlSC2ZvY3VzZWRDb3B5EhoKCHdyaXRhYmxlGAYg'
    'ASgIUgh3cml0YWJsZQ==');

@$core.Deprecated('Use fileVisibilityChangeDescriptor instead')
const FileVisibilityChange$json = {
  '1': 'FileVisibilityChange',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanState',
      '10': 'state'
    },
    {
      '1': 'changed',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PlannedFileNode',
      '10': 'changed'
    },
  ],
};

/// Descriptor for `FileVisibilityChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVisibilityChangeDescriptor = $convert.base64Decode(
    'ChRGaWxlVmlzaWJpbGl0eUNoYW5nZRI0CgVzdGF0ZRgBIAEoCzIeLm1vZGNvbmR1Y3Rvci52MS'
    '5GaWxlUGxhblN0YXRlUgVzdGF0ZRI6CgdjaGFuZ2VkGAIgASgLMiAubW9kY29uZHVjdG9yLnYx'
    'LlBsYW5uZWRGaWxlTm9kZVIHY2hhbmdlZA==');

@$core.Deprecated('Use fileVisibilityAuditDescriptor instead')
const FileVisibilityAudit$json = {
  '1': 'FileVisibilityAudit',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {
      '1': 'copy',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ManagedFileCopy',
      '10': 'copy'
    },
    {'1': 'hidden', '3': 3, '4': 1, '5': 8, '10': 'hidden'},
    {'1': 'before_hidden', '3': 4, '4': 1, '5': 8, '10': 'beforeHidden'},
    {'1': 'profile_id', '3': 5, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'before_fingerprint',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'beforeFingerprint'
    },
    {
      '1': 'after_fingerprint',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'afterFingerprint'
    },
    {
      '1': 'recorded_at_unix_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '10': 'recordedAtUnixMs'
    },
  ],
};

/// Descriptor for `FileVisibilityAudit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVisibilityAuditDescriptor = $convert.base64Decode(
    'ChNGaWxlVmlzaWJpbGl0eUF1ZGl0Eg4KAmlkGAEgASgEUgJpZBI0CgRjb3B5GAIgASgLMiAubW'
    '9kY29uZHVjdG9yLnYxLk1hbmFnZWRGaWxlQ29weVIEY29weRIWCgZoaWRkZW4YAyABKAhSBmhp'
    'ZGRlbhIjCg1iZWZvcmVfaGlkZGVuGAQgASgIUgxiZWZvcmVIaWRkZW4SHQoKcHJvZmlsZV9pZB'
    'gFIAEoCVIJcHJvZmlsZUlkEi0KEmJlZm9yZV9maW5nZXJwcmludBgGIAEoCVIRYmVmb3JlRmlu'
    'Z2VycHJpbnQSKwoRYWZ0ZXJfZmluZ2VycHJpbnQYByABKAlSEGFmdGVyRmluZ2VycHJpbnQSLQ'
    'oTcmVjb3JkZWRfYXRfdW5peF9tcxgIIAEoA1IQcmVjb3JkZWRBdFVuaXhNcw==');

@$core.Deprecated('Use fileVisibilityHistoryDescriptor instead')
const FileVisibilityHistory$json = {
  '1': 'FileVisibilityHistory',
  '2': [
    {
      '1': 'changes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.FileVisibilityAudit',
      '10': 'changes'
    },
    {
      '1': 'next_before_id',
      '3': 2,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'nextBeforeId',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_before_id'},
  ],
};

/// Descriptor for `FileVisibilityHistory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVisibilityHistoryDescriptor = $convert.base64Decode(
    'ChVGaWxlVmlzaWJpbGl0eUhpc3RvcnkSPgoHY2hhbmdlcxgBIAMoCzIkLm1vZGNvbmR1Y3Rvci'
    '52MS5GaWxlVmlzaWJpbGl0eUF1ZGl0UgdjaGFuZ2VzEikKDm5leHRfYmVmb3JlX2lkGAIgASgE'
    'SABSDG5leHRCZWZvcmVJZIgBAUIRCg9fbmV4dF9iZWZvcmVfaWQ=');

@$core.Deprecated('Use filePlanProblemsDescriptor instead')
const FilePlanProblems$json = {
  '1': 'FilePlanProblems',
  '2': [
    {'1': 'problems', '3': 1, '4': 3, '5': 9, '10': 'problems'},
    {
      '1': 'next',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanCursor',
      '10': 'next'
    },
  ],
};

/// Descriptor for `FilePlanProblems`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanProblemsDescriptor = $convert.base64Decode(
    'ChBGaWxlUGxhblByb2JsZW1zEhoKCHByb2JsZW1zGAEgAygJUghwcm9ibGVtcxIzCgRuZXh0GA'
    'IgASgLMh8ubW9kY29uZHVjdG9yLnYxLkZpbGVQbGFuQ3Vyc29yUgRuZXh0');

@$core.Deprecated('Use filePlanFaultDescriptor instead')
const FilePlanFault$json = {
  '1': 'FilePlanFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FilePlanFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `FilePlanFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanFaultDescriptor = $convert.base64Decode(
    'Cg1GaWxlUGxhbkZhdWx0EjYKBGNvZGUYASABKA4yIi5tb2Rjb25kdWN0b3IudjEuRmlsZVBsYW'
    '5GYXVsdENvZGVSBGNvZGUSFgoGZGV0YWlsGAIgASgJUgZkZXRhaWw=');

@$core.Deprecated('Use filePlanReplyDescriptor instead')
const FilePlanReply$json = {
  '1': 'FilePlanReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanState',
      '9': 0,
      '10': 'state'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FilePlanReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanReplyDescriptor = $convert.base64Decode(
    'Cg1GaWxlUGxhblJlcGx5EjYKBXN0YXRlGAEgASgLMh4ubW9kY29uZHVjdG9yLnYxLkZpbGVQbG'
    'FuU3RhdGVIAFIFc3RhdGUSNgoFZmF1bHQYAiABKAsyHi5tb2Rjb25kdWN0b3IudjEuRmlsZVBs'
    'YW5GYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use filePlanPageReplyDescriptor instead')
const FilePlanPageReply$json = {
  '1': 'FilePlanPageReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PlannedFilePage',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FilePlanPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanPageReplyDescriptor = $convert.base64Decode(
    'ChFGaWxlUGxhblBhZ2VSZXBseRI2CgRwYWdlGAEgASgLMiAubW9kY29uZHVjdG9yLnYxLlBsYW'
    '5uZWRGaWxlUGFnZUgAUgRwYWdlEjYKBWZhdWx0GAIgASgLMh4ubW9kY29uZHVjdG9yLnYxLkZp'
    'bGVQbGFuRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use filePlanInspectionReplyDescriptor instead')
const FilePlanInspectionReply$json = {
  '1': 'FilePlanInspectionReply',
  '2': [
    {
      '1': 'inspection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PlannedFileInspection',
      '9': 0,
      '10': 'inspection'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FilePlanInspectionReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanInspectionReplyDescriptor = $convert.base64Decode(
    'ChdGaWxlUGxhbkluc3BlY3Rpb25SZXBseRJICgppbnNwZWN0aW9uGAEgASgLMiYubW9kY29uZH'
    'VjdG9yLnYxLlBsYW5uZWRGaWxlSW5zcGVjdGlvbkgAUgppbnNwZWN0aW9uEjYKBWZhdWx0GAIg'
    'ASgLMh4ubW9kY29uZHVjdG9yLnYxLkZpbGVQbGFuRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ'
    '==');

@$core.Deprecated('Use fileVisibilityReplyDescriptor instead')
const FileVisibilityReply$json = {
  '1': 'FileVisibilityReply',
  '2': [
    {
      '1': 'change',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FileVisibilityChange',
      '9': 0,
      '10': 'change'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FileVisibilityReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVisibilityReplyDescriptor = $convert.base64Decode(
    'ChNGaWxlVmlzaWJpbGl0eVJlcGx5Ej8KBmNoYW5nZRgBIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS'
    '5GaWxlVmlzaWJpbGl0eUNoYW5nZUgAUgZjaGFuZ2USNgoFZmF1bHQYAiABKAsyHi5tb2Rjb25k'
    'dWN0b3IudjEuRmlsZVBsYW5GYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use fileVisibilityHistoryReplyDescriptor instead')
const FileVisibilityHistoryReply$json = {
  '1': 'FileVisibilityHistoryReply',
  '2': [
    {
      '1': 'history',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FileVisibilityHistory',
      '9': 0,
      '10': 'history'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FileVisibilityHistoryReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVisibilityHistoryReplyDescriptor = $convert.base64Decode(
    'ChpGaWxlVmlzaWJpbGl0eUhpc3RvcnlSZXBseRJCCgdoaXN0b3J5GAEgASgLMiYubW9kY29uZH'
    'VjdG9yLnYxLkZpbGVWaXNpYmlsaXR5SGlzdG9yeUgAUgdoaXN0b3J5EjYKBWZhdWx0GAIgASgL'
    'Mh4ubW9kY29uZHVjdG9yLnYxLkZpbGVQbGFuRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use filePlanProblemsReplyDescriptor instead')
const FilePlanProblemsReply$json = {
  '1': 'FilePlanProblemsReply',
  '2': [
    {
      '1': 'problems',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanProblems',
      '9': 0,
      '10': 'problems'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `FilePlanProblemsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanProblemsReplyDescriptor = $convert.base64Decode(
    'ChVGaWxlUGxhblByb2JsZW1zUmVwbHkSPwoIcHJvYmxlbXMYASABKAsyIS5tb2Rjb25kdWN0b3'
    'IudjEuRmlsZVBsYW5Qcm9ibGVtc0gAUghwcm9ibGVtcxI2CgVmYXVsdBgCIAEoCzIeLm1vZGNv'
    'bmR1Y3Rvci52MS5GaWxlUGxhbkZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use filePlanLoadProgressDescriptor instead')
const FilePlanLoadProgress$json = {
  '1': 'FilePlanLoadProgress',
  '2': [
    {'1': 'files', '3': 1, '4': 1, '5': 13, '10': 'files'},
    {'1': 'total_files', '3': 2, '4': 1, '5': 13, '10': 'totalFiles'},
    {'1': 'bytes', '3': 3, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'total_bytes', '3': 4, '4': 1, '5': 4, '10': 'totalBytes'},
  ],
};

/// Descriptor for `FilePlanLoadProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanLoadProgressDescriptor = $convert.base64Decode(
    'ChRGaWxlUGxhbkxvYWRQcm9ncmVzcxIUCgVmaWxlcxgBIAEoDVIFZmlsZXMSHwoLdG90YWxfZm'
    'lsZXMYAiABKA1SCnRvdGFsRmlsZXMSFAoFYnl0ZXMYAyABKARSBWJ5dGVzEh8KC3RvdGFsX2J5'
    'dGVzGAQgASgEUgp0b3RhbEJ5dGVz');

@$core.Deprecated('Use filePlanLoadEventDescriptor instead')
const FilePlanLoadEvent$json = {
  '1': 'FilePlanLoadEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanLoadProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'finished',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.FilePlanReply',
      '9': 0,
      '10': 'finished'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `FilePlanLoadEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filePlanLoadEventDescriptor = $convert.base64Decode(
    'ChFGaWxlUGxhbkxvYWRFdmVudBJDCghwcm9ncmVzcxgBIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS'
    '5GaWxlUGxhbkxvYWRQcm9ncmVzc0gAUghwcm9ncmVzcxI8CghmaW5pc2hlZBgCIAEoCzIeLm1v'
    'ZGNvbmR1Y3Rvci52MS5GaWxlUGxhblJlcGx5SABSCGZpbmlzaGVkQgcKBWV2ZW50');
