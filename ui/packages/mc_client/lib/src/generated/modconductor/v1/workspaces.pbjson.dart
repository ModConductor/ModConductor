// This is a generated file - do not edit.
//
// Generated from modconductor/v1/workspaces.proto.

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

@$core.Deprecated('Use workspaceRootIssueReasonDescriptor instead')
const WorkspaceRootIssueReason$json = {
  '1': 'WorkspaceRootIssueReason',
  '2': [
    {'1': 'WORKSPACE_ROOT_ISSUE_REASON_UNSPECIFIED', '2': 0},
    {'1': 'WORKSPACE_ROOT_ISSUE_REASON_INCOMPLETE_CREATION', '2': 1},
    {'1': 'WORKSPACE_ROOT_ISSUE_REASON_OWNERSHIP_UNPROVED', '2': 2},
    {'1': 'WORKSPACE_ROOT_ISSUE_REASON_IDENTITY_UNVERIFIED', '2': 3},
  ],
};

/// Descriptor for `WorkspaceRootIssueReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceRootIssueReasonDescriptor = $convert.base64Decode(
    'ChhXb3Jrc3BhY2VSb290SXNzdWVSZWFzb24SKwonV09SS1NQQUNFX1JPT1RfSVNTVUVfUkVBU0'
    '9OX1VOU1BFQ0lGSUVEEAASMwovV09SS1NQQUNFX1JPT1RfSVNTVUVfUkVBU09OX0lOQ09NUExF'
    'VEVfQ1JFQVRJT04QARIyCi5XT1JLU1BBQ0VfUk9PVF9JU1NVRV9SRUFTT05fT1dORVJTSElQX1'
    'VOUFJPVkVEEAISMwovV09SS1NQQUNFX1JPT1RfSVNTVUVfUkVBU09OX0lERU5USVRZX1VOVkVS'
    'SUZJRUQQAw==');

@$core.Deprecated('Use workspaceFaultCodeDescriptor instead')
const WorkspaceFaultCode$json = {
  '1': 'WorkspaceFaultCode',
  '2': [
    {'1': 'WORKSPACE_FAULT_CODE_UNSPECIFIED', '2': 0},
    {'1': 'WORKSPACE_FAULT_CODE_NOT_FOUND', '2': 1},
    {'1': 'WORKSPACE_FAULT_CODE_STALE_REVISION', '2': 2},
    {'1': 'WORKSPACE_FAULT_CODE_IDENTITY_CONFLICT', '2': 3},
    {'1': 'WORKSPACE_FAULT_CODE_SELECTED_PROFILE', '2': 4},
    {'1': 'WORKSPACE_FAULT_CODE_INVALID_NAME', '2': 5},
    {'1': 'WORKSPACE_FAULT_CODE_INVALID_ROOT', '2': 6},
    {'1': 'WORKSPACE_FAULT_CODE_ROOT_UNRESOLVED', '2': 7},
    {'1': 'WORKSPACE_FAULT_CODE_BUSY', '2': 8},
    {'1': 'WORKSPACE_FAULT_CODE_PROFILE_DATA', '2': 9},
  ],
};

/// Descriptor for `WorkspaceFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceFaultCodeDescriptor = $convert.base64Decode(
    'ChJXb3Jrc3BhY2VGYXVsdENvZGUSJAogV09SS1NQQUNFX0ZBVUxUX0NPREVfVU5TUEVDSUZJRU'
    'QQABIiCh5XT1JLU1BBQ0VfRkFVTFRfQ09ERV9OT1RfRk9VTkQQARInCiNXT1JLU1BBQ0VfRkFV'
    'TFRfQ09ERV9TVEFMRV9SRVZJU0lPThACEioKJldPUktTUEFDRV9GQVVMVF9DT0RFX0lERU5USV'
    'RZX0NPTkZMSUNUEAMSKQolV09SS1NQQUNFX0ZBVUxUX0NPREVfU0VMRUNURURfUFJPRklMRRAE'
    'EiUKIVdPUktTUEFDRV9GQVVMVF9DT0RFX0lOVkFMSURfTkFNRRAFEiUKIVdPUktTUEFDRV9GQV'
    'VMVF9DT0RFX0lOVkFMSURfUk9PVBAGEigKJFdPUktTUEFDRV9GQVVMVF9DT0RFX1JPT1RfVU5S'
    'RVNPTFZFRBAHEh0KGVdPUktTUEFDRV9GQVVMVF9DT0RFX0JVU1kQCBIlCiFXT1JLU1BBQ0VfRk'
    'FVTFRfQ09ERV9QUk9GSUxFX0RBVEEQCQ==');

@$core.Deprecated('Use profileInfoDescriptor instead')
const ProfileInfo$json = {
  '1': 'ProfileInfo',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ProfileInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileInfoDescriptor = $convert.base64Decode(
    'CgtQcm9maWxlSW5mbxIdCgpwcm9maWxlX2lkGAEgASgJUglwcm9maWxlSWQSEgoEbmFtZRgCIA'
    'EoCVIEbmFtZQ==');

@$core.Deprecated('Use pendingWorkspaceRootDescriptor instead')
const PendingWorkspaceRoot$json = {
  '1': 'PendingWorkspaceRoot',
  '2': [
    {'1': 'receipt_revision', '3': 1, '4': 1, '5': 4, '10': 'receiptRevision'},
    {
      '1': 'reason',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.WorkspaceRootIssueReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `PendingWorkspaceRoot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pendingWorkspaceRootDescriptor = $convert.base64Decode(
    'ChRQZW5kaW5nV29ya3NwYWNlUm9vdBIpChByZWNlaXB0X3JldmlzaW9uGAEgASgEUg9yZWNlaX'
    'B0UmV2aXNpb24SQQoGcmVhc29uGAIgASgOMikubW9kY29uZHVjdG9yLnYxLldvcmtzcGFjZVJv'
    'b3RJc3N1ZVJlYXNvblIGcmVhc29u');

@$core.Deprecated('Use workspaceInfoDescriptor instead')
const WorkspaceInfo$json = {
  '1': 'WorkspaceInfo',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {'1': 'revision', '3': 4, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'selected_profile',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileInfo',
      '10': 'selectedProfile'
    },
    {
      '1': 'pending_root',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PendingWorkspaceRoot',
      '10': 'pendingRoot'
    },
  ],
};

/// Descriptor for `WorkspaceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceInfoDescriptor = $convert.base64Decode(
    'Cg1Xb3Jrc3BhY2VJbmZvEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSEgoEbm'
    'FtZRgCIAEoCVIEbmFtZRISCgRwYXRoGAMgASgJUgRwYXRoEhoKCHJldmlzaW9uGAQgASgEUghy'
    'ZXZpc2lvbhJHChBzZWxlY3RlZF9wcm9maWxlGAUgASgLMhwubW9kY29uZHVjdG9yLnYxLlByb2'
    'ZpbGVJbmZvUg9zZWxlY3RlZFByb2ZpbGUSSAoMcGVuZGluZ19yb290GAYgASgLMiUubW9kY29u'
    'ZHVjdG9yLnYxLlBlbmRpbmdXb3Jrc3BhY2VSb290UgtwZW5kaW5nUm9vdA==');

@$core.Deprecated('Use workspacePageDescriptor instead')
const WorkspacePage$json = {
  '1': 'WorkspacePage',
  '2': [
    {
      '1': 'workspace',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.WorkspaceInfo',
      '10': 'workspace'
    },
    {
      '1': 'profiles',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProfileInfo',
      '10': 'profiles'
    },
    {
      '1': 'next_profile_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextProfileId',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_profile_id'},
  ],
};

/// Descriptor for `WorkspacePage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspacePageDescriptor = $convert.base64Decode(
    'Cg1Xb3Jrc3BhY2VQYWdlEjwKCXdvcmtzcGFjZRgBIAEoCzIeLm1vZGNvbmR1Y3Rvci52MS5Xb3'
    'Jrc3BhY2VJbmZvUgl3b3Jrc3BhY2USOAoIcHJvZmlsZXMYAiADKAsyHC5tb2Rjb25kdWN0b3Iu'
    'djEuUHJvZmlsZUluZm9SCHByb2ZpbGVzEisKD25leHRfcHJvZmlsZV9pZBgDIAEoCUgAUg1uZX'
    'h0UHJvZmlsZUlkiAEBQhIKEF9uZXh0X3Byb2ZpbGVfaWQ=');

@$core.Deprecated('Use workspaceFaultDescriptor instead')
const WorkspaceFault$json = {
  '1': 'WorkspaceFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.WorkspaceFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `WorkspaceFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceFaultDescriptor = $convert.base64Decode(
    'Cg5Xb3Jrc3BhY2VGYXVsdBI3CgRjb2RlGAEgASgOMiMubW9kY29uZHVjdG9yLnYxLldvcmtzcG'
    'FjZUZhdWx0Q29kZVIEY29kZRIWCgZkZXRhaWwYAiABKAlSBmRldGFpbA==');

@$core.Deprecated('Use workspaceReplyDescriptor instead')
const WorkspaceReply$json = {
  '1': 'WorkspaceReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.WorkspacePage',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.WorkspaceFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `WorkspaceReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceReplyDescriptor = $convert.base64Decode(
    'Cg5Xb3Jrc3BhY2VSZXBseRI0CgRwYWdlGAEgASgLMh4ubW9kY29uZHVjdG9yLnYxLldvcmtzcG'
    'FjZVBhZ2VIAFIEcGFnZRI3CgVmYXVsdBgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Xb3Jrc3Bh'
    'Y2VGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use createWorkspaceRequestDescriptor instead')
const CreateWorkspaceRequest$json = {
  '1': 'CreateWorkspaceRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'expected_revision',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
  ],
};

/// Descriptor for `CreateWorkspaceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createWorkspaceRequestDescriptor = $convert.base64Decode(
    'ChZDcmVhdGVXb3Jrc3BhY2VSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRwYXRoGAMgASgJUgRwYXRoEisKEWV4cGVjdGVk'
    'X3JldmlzaW9uGAQgASgEUhBleHBlY3RlZFJldmlzaW9u');

@$core.Deprecated('Use openWorkspaceRequestDescriptor instead')
const OpenWorkspaceRequest$json = {
  '1': 'OpenWorkspaceRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `OpenWorkspaceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openWorkspaceRequestDescriptor = $convert
    .base64Decode('ChRPcGVuV29ya3NwYWNlUmVxdWVzdBISCgRwYXRoGAEgASgJUgRwYXRo');

@$core.Deprecated('Use readWorkspaceRequestDescriptor instead')
const ReadWorkspaceRequest$json = {
  '1': 'ReadWorkspaceRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'after_profile_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'afterProfileId',
      '17': true
    },
  ],
  '8': [
    {'1': '_after_profile_id'},
  ],
};

/// Descriptor for `ReadWorkspaceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readWorkspaceRequestDescriptor = $convert.base64Decode(
    'ChRSZWFkV29ya3NwYWNlUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lkEi0KEGFmdGVyX3Byb2ZpbGVfaWQYAiABKAlIAFIOYWZ0ZXJQcm9maWxlSWSIAQFCEwoRX2Fm'
    'dGVyX3Byb2ZpbGVfaWQ=');

@$core.Deprecated('Use cloneProfileDescriptor instead')
const CloneProfile$json = {
  '1': 'CloneProfile',
  '2': [
    {'1': 'source_profile_id', '3': 1, '4': 1, '5': 9, '10': 'sourceProfileId'},
    {
      '1': 'copy',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileInfo',
      '10': 'copy'
    },
  ],
};

/// Descriptor for `CloneProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cloneProfileDescriptor = $convert.base64Decode(
    'CgxDbG9uZVByb2ZpbGUSKgoRc291cmNlX3Byb2ZpbGVfaWQYASABKAlSD3NvdXJjZVByb2ZpbG'
    'VJZBIwCgRjb3B5GAIgASgLMhwubW9kY29uZHVjdG9yLnYxLlByb2ZpbGVJbmZvUgRjb3B5');

@$core.Deprecated('Use editProfileRequestDescriptor instead')
const EditProfileRequest$json = {
  '1': 'EditProfileRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {
      '1': 'create_profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileInfo',
      '9': 0,
      '10': 'createProfile'
    },
    {
      '1': 'clone_profile',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CloneProfile',
      '9': 0,
      '10': 'cloneProfile'
    },
    {
      '1': 'rename_profile',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileInfo',
      '9': 0,
      '10': 'renameProfile'
    },
    {
      '1': 'select_profile_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'selectProfileId'
    },
    {
      '1': 'delete_profile_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deleteProfileId'
    },
  ],
  '8': [
    {'1': 'edit'},
  ],
};

/// Descriptor for `EditProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editProfileRequestDescriptor = $convert.base64Decode(
    'ChJFZGl0UHJvZmlsZVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IrChFleHBlY3RlZF9yZXZpc2lvbhgCIAEoBFIQZXhwZWN0ZWRSZXZpc2lvbhJFCg5jcmVhdGVf'
    'cHJvZmlsZRgDIAEoCzIcLm1vZGNvbmR1Y3Rvci52MS5Qcm9maWxlSW5mb0gAUg1jcmVhdGVQcm'
    '9maWxlEkQKDWNsb25lX3Byb2ZpbGUYBCABKAsyHS5tb2Rjb25kdWN0b3IudjEuQ2xvbmVQcm9m'
    'aWxlSABSDGNsb25lUHJvZmlsZRJFCg5yZW5hbWVfcHJvZmlsZRgFIAEoCzIcLm1vZGNvbmR1Y3'
    'Rvci52MS5Qcm9maWxlSW5mb0gAUg1yZW5hbWVQcm9maWxlEiwKEXNlbGVjdF9wcm9maWxlX2lk'
    'GAYgASgJSABSD3NlbGVjdFByb2ZpbGVJZBIsChFkZWxldGVfcHJvZmlsZV9pZBgHIAEoCUgAUg'
    '9kZWxldGVQcm9maWxlSWRCBgoEZWRpdA==');

@$core.Deprecated('Use profileChangeDescriptor instead')
const ProfileChange$json = {
  '1': 'ProfileChange',
  '2': [
    {
      '1': 'workspace',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.WorkspaceInfo',
      '10': 'workspace'
    },
    {
      '1': 'changed',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileInfo',
      '10': 'changed'
    },
    {
      '1': 'deleted_profile_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deletedProfileId',
      '17': true
    },
  ],
  '8': [
    {'1': '_deleted_profile_id'},
  ],
};

/// Descriptor for `ProfileChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileChangeDescriptor = $convert.base64Decode(
    'Cg1Qcm9maWxlQ2hhbmdlEjwKCXdvcmtzcGFjZRgBIAEoCzIeLm1vZGNvbmR1Y3Rvci52MS5Xb3'
    'Jrc3BhY2VJbmZvUgl3b3Jrc3BhY2USNgoHY2hhbmdlZBgCIAEoCzIcLm1vZGNvbmR1Y3Rvci52'
    'MS5Qcm9maWxlSW5mb1IHY2hhbmdlZBIxChJkZWxldGVkX3Byb2ZpbGVfaWQYAyABKAlIAFIQZG'
    'VsZXRlZFByb2ZpbGVJZIgBAUIVChNfZGVsZXRlZF9wcm9maWxlX2lk');

@$core.Deprecated('Use profileReplyDescriptor instead')
const ProfileReply$json = {
  '1': 'ProfileReply',
  '2': [
    {
      '1': 'change',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileChange',
      '9': 0,
      '10': 'change'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.WorkspaceFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ProfileReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileReplyDescriptor = $convert.base64Decode(
    'CgxQcm9maWxlUmVwbHkSOAoGY2hhbmdlGAEgASgLMh4ubW9kY29uZHVjdG9yLnYxLlByb2ZpbG'
    'VDaGFuZ2VIAFIGY2hhbmdlEjcKBWZhdWx0GAIgASgLMh8ubW9kY29uZHVjdG9yLnYxLldvcmtz'
    'cGFjZUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use checkWorkspaceRequestDescriptor instead')
const CheckWorkspaceRequest$json = {
  '1': 'CheckWorkspaceRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'expected_receipt_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedReceiptRevision'
    },
  ],
};

/// Descriptor for `CheckWorkspaceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkWorkspaceRequestDescriptor = $convert.base64Decode(
    'ChVDaGVja1dvcmtzcGFjZVJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBI6ChlleHBlY3RlZF9yZWNlaXB0X3JldmlzaW9uGAIgASgEUhdleHBlY3RlZFJlY2VpcHRS'
    'ZXZpc2lvbg==');

@$core.Deprecated('Use recentWorkspacesRequestDescriptor instead')
const RecentWorkspacesRequest$json = {
  '1': 'RecentWorkspacesRequest',
  '2': [
    {
      '1': 'after_workspace_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'afterWorkspaceId',
      '17': true
    },
  ],
  '8': [
    {'1': '_after_workspace_id'},
  ],
};

/// Descriptor for `RecentWorkspacesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentWorkspacesRequestDescriptor =
    $convert.base64Decode(
        'ChdSZWNlbnRXb3Jrc3BhY2VzUmVxdWVzdBIxChJhZnRlcl93b3Jrc3BhY2VfaWQYASABKAlIAF'
        'IQYWZ0ZXJXb3Jrc3BhY2VJZIgBAUIVChNfYWZ0ZXJfd29ya3NwYWNlX2lk');

@$core.Deprecated('Use recentWorkspacesReplyDescriptor instead')
const RecentWorkspacesReply$json = {
  '1': 'RecentWorkspacesReply',
  '2': [
    {
      '1': 'workspaces',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.WorkspaceInfo',
      '10': 'workspaces'
    },
    {
      '1': 'next_workspace_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextWorkspaceId',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_workspace_id'},
  ],
};

/// Descriptor for `RecentWorkspacesReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentWorkspacesReplyDescriptor = $convert.base64Decode(
    'ChVSZWNlbnRXb3Jrc3BhY2VzUmVwbHkSPgoKd29ya3NwYWNlcxgBIAMoCzIeLm1vZGNvbmR1Y3'
    'Rvci52MS5Xb3Jrc3BhY2VJbmZvUgp3b3Jrc3BhY2VzEi8KEW5leHRfd29ya3NwYWNlX2lkGAIg'
    'ASgJSABSD25leHRXb3Jrc3BhY2VJZIgBAUIUChJfbmV4dF93b3Jrc3BhY2VfaWQ=');

@$core.Deprecated('Use profileCopyProgressDescriptor instead')
const ProfileCopyProgress$json = {
  '1': 'ProfileCopyProgress',
  '2': [
    {'1': 'files', '3': 1, '4': 1, '5': 13, '10': 'files'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ProfileCopyProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileCopyProgressDescriptor = $convert.base64Decode(
    'ChNQcm9maWxlQ29weVByb2dyZXNzEhQKBWZpbGVzGAEgASgNUgVmaWxlcxIUCgVieXRlcxgCIA'
    'EoBFIFYnl0ZXM=');

@$core.Deprecated('Use resumeProfileEditRequestDescriptor instead')
const ResumeProfileEditRequest$json = {
  '1': 'ResumeProfileEditRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'action_id', '3': 2, '4': 1, '5': 9, '10': 'actionId'},
  ],
};

/// Descriptor for `ResumeProfileEditRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resumeProfileEditRequestDescriptor =
    $convert.base64Decode(
        'ChhSZXN1bWVQcm9maWxlRWRpdFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3'
        'BhY2VJZBIbCglhY3Rpb25faWQYAiABKAlSCGFjdGlvbklk');

@$core.Deprecated('Use profileEditEventDescriptor instead')
const ProfileEditEvent$json = {
  '1': 'ProfileEditEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileCopyProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'finished',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileReply',
      '9': 0,
      '10': 'finished'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ProfileEditEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileEditEventDescriptor = $convert.base64Decode(
    'ChBQcm9maWxlRWRpdEV2ZW50EkIKCHByb2dyZXNzGAEgASgLMiQubW9kY29uZHVjdG9yLnYxLl'
    'Byb2ZpbGVDb3B5UHJvZ3Jlc3NIAFIIcHJvZ3Jlc3MSOwoIZmluaXNoZWQYAiABKAsyHS5tb2Rj'
    'b25kdWN0b3IudjEuUHJvZmlsZVJlcGx5SABSCGZpbmlzaGVkQgcKBWV2ZW50');
