// This is a generated file - do not edit.
//
// Generated from modconductor/v1/deployments.proto.

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

@$core.Deprecated('Use deploymentPhaseDescriptor instead')
const DeploymentPhase$json = {
  '1': 'DeploymentPhase',
  '2': [
    {'1': 'DEPLOYMENT_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'DEPLOYMENT_PHASE_PREPARING', '2': 1},
    {'1': 'DEPLOYMENT_PHASE_APPLYING', '2': 2},
    {'1': 'DEPLOYMENT_PHASE_RESTORING', '2': 3},
    {'1': 'DEPLOYMENT_PHASE_COMPLETE', '2': 4},
    {'1': 'DEPLOYMENT_PHASE_RESTORED', '2': 5},
    {'1': 'DEPLOYMENT_PHASE_BLOCKED', '2': 6},
  ],
};

/// Descriptor for `DeploymentPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List deploymentPhaseDescriptor = $convert.base64Decode(
    'Cg9EZXBsb3ltZW50UGhhc2USIAocREVQTE9ZTUVOVF9QSEFTRV9VTlNQRUNJRklFRBAAEh4KGk'
    'RFUExPWU1FTlRfUEhBU0VfUFJFUEFSSU5HEAESHQoZREVQTE9ZTUVOVF9QSEFTRV9BUFBMWUlO'
    'RxACEh4KGkRFUExPWU1FTlRfUEhBU0VfUkVTVE9SSU5HEAMSHQoZREVQTE9ZTUVOVF9QSEFTRV'
    '9DT01QTEVURRAEEh0KGURFUExPWU1FTlRfUEhBU0VfUkVTVE9SRUQQBRIcChhERVBMT1lNRU5U'
    'X1BIQVNFX0JMT0NLRUQQBg==');

@$core.Deprecated('Use deploymentFaultCodeDescriptor instead')
const DeploymentFaultCode$json = {
  '1': 'DeploymentFaultCode',
  '2': [
    {'1': 'DEPLOYMENT_FAULT_UNSPECIFIED', '2': 0},
    {'1': 'DEPLOYMENT_FAULT_NOT_FOUND', '2': 1},
    {'1': 'DEPLOYMENT_FAULT_BUSY', '2': 2},
    {'1': 'DEPLOYMENT_FAULT_STALE', '2': 3},
    {'1': 'DEPLOYMENT_FAULT_CANCELLED', '2': 4},
    {'1': 'DEPLOYMENT_FAULT_BLOCKED', '2': 5},
    {'1': 'DEPLOYMENT_FAULT_UNAVAILABLE', '2': 6},
  ],
};

/// Descriptor for `DeploymentFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List deploymentFaultCodeDescriptor = $convert.base64Decode(
    'ChNEZXBsb3ltZW50RmF1bHRDb2RlEiAKHERFUExPWU1FTlRfRkFVTFRfVU5TUEVDSUZJRUQQAB'
    'IeChpERVBMT1lNRU5UX0ZBVUxUX05PVF9GT1VORBABEhkKFURFUExPWU1FTlRfRkFVTFRfQlVT'
    'WRACEhoKFkRFUExPWU1FTlRfRkFVTFRfU1RBTEUQAxIeChpERVBMT1lNRU5UX0ZBVUxUX0NBTk'
    'NFTExFRBAEEhwKGERFUExPWU1FTlRfRkFVTFRfQkxPQ0tFRBAFEiAKHERFUExPWU1FTlRfRkFV'
    'TFRfVU5BVkFJTEFCTEUQBg==');

@$core.Deprecated('Use readDeploymentRequestDescriptor instead')
const ReadDeploymentRequest$json = {
  '1': 'ReadDeploymentRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `ReadDeploymentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readDeploymentRequestDescriptor = $convert.base64Decode(
    'ChVSZWFkRGVwbG95bWVudFJlcXVlc3QSHQoKcHJvZmlsZV9pZBgBIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use deploymentProfileDescriptor instead')
const DeploymentProfile$json = {
  '1': 'DeploymentProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'enabled_mods', '3': 4, '4': 1, '5': 13, '10': 'enabledMods'},
  ],
};

/// Descriptor for `DeploymentProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentProfileDescriptor = $convert.base64Decode(
    'ChFEZXBsb3ltZW50UHJvZmlsZRIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24SIQoMZW5hYmxlZF9tb2RzGAQgASgNUgtlbmFi'
    'bGVkTW9kcw==');

@$core.Deprecated('Use savedDeploymentDescriptor instead')
const SavedDeployment$json = {
  '1': 'SavedDeployment',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'prepared_at_unix_ms',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'preparedAtUnixMs',
      '17': true
    },
    {
      '1': 'profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentProfile',
      '10': 'profile'
    },
    {'1': 'known', '3': 4, '4': 1, '5': 8, '10': 'known'},
    {'1': 'active', '3': 5, '4': 1, '5': 8, '10': 'active'},
    {'1': 'fingerprint', '3': 6, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'can_restore', '3': 7, '4': 1, '5': 8, '10': 'canRestore'},
  ],
  '8': [
    {'1': '_prepared_at_unix_ms'},
  ],
};

/// Descriptor for `SavedDeployment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savedDeploymentDescriptor = $convert.base64Decode(
    'Cg9TYXZlZERlcGxveW1lbnQSDgoCaWQYASABKAlSAmlkEjIKE3ByZXBhcmVkX2F0X3VuaXhfbX'
    'MYAiABKANIAFIQcHJlcGFyZWRBdFVuaXhNc4gBARI8Cgdwcm9maWxlGAMgASgLMiIubW9kY29u'
    'ZHVjdG9yLnYxLkRlcGxveW1lbnRQcm9maWxlUgdwcm9maWxlEhQKBWtub3duGAQgASgIUgVrbm'
    '93bhIWCgZhY3RpdmUYBSABKAhSBmFjdGl2ZRIgCgtmaW5nZXJwcmludBgGIAEoCVILZmluZ2Vy'
    'cHJpbnQSHwoLY2FuX3Jlc3RvcmUYByABKAhSCmNhblJlc3RvcmVCFgoUX3ByZXBhcmVkX2F0X3'
    'VuaXhfbXM=');

@$core.Deprecated('Use deploymentStateDescriptor instead')
const DeploymentState$json = {
  '1': 'DeploymentState',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'active',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SavedDeployment',
      '10': 'active'
    },
    {
      '1': 'pending_receipt',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'pendingReceipt',
      '17': true
    },
    {'1': 'source_token', '3': 5, '4': 1, '5': 9, '10': 'sourceToken'},
  ],
  '8': [
    {'1': '_pending_receipt'},
  ],
};

/// Descriptor for `DeploymentState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentStateDescriptor = $convert.base64Decode(
    'Cg9EZXBsb3ltZW50U3RhdGUSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBIaCg'
    'hyZXZpc2lvbhgCIAEoBFIIcmV2aXNpb24SOAoGYWN0aXZlGAMgASgLMiAubW9kY29uZHVjdG9y'
    'LnYxLlNhdmVkRGVwbG95bWVudFIGYWN0aXZlEiwKD3BlbmRpbmdfcmVjZWlwdBgEIAEoCUgAUg'
    '5wZW5kaW5nUmVjZWlwdIgBARIhCgxzb3VyY2VfdG9rZW4YBSABKAlSC3NvdXJjZVRva2VuQhIK'
    'EF9wZW5kaW5nX3JlY2VpcHQ=');

@$core.Deprecated('Use savedDeploymentsRequestDescriptor instead')
const SavedDeploymentsRequest$json = {
  '1': 'SavedDeploymentsRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'before', '3': 2, '4': 1, '5': 4, '9': 0, '10': 'before', '17': true},
  ],
  '8': [
    {'1': '_before'},
  ],
};

/// Descriptor for `SavedDeploymentsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savedDeploymentsRequestDescriptor =
    $convert.base64Decode(
        'ChdTYXZlZERlcGxveW1lbnRzUmVxdWVzdBIdCgpwcm9maWxlX2lkGAEgASgJUglwcm9maWxlSW'
        'QSGwoGYmVmb3JlGAIgASgESABSBmJlZm9yZYgBAUIJCgdfYmVmb3Jl');

@$core.Deprecated('Use savedDeploymentsPageDescriptor instead')
const SavedDeploymentsPage$json = {
  '1': 'SavedDeploymentsPage',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SavedDeployment',
      '10': 'entries'
    },
    {
      '1': 'next_before',
      '3': 2,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'nextBefore',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_before'},
  ],
};

/// Descriptor for `SavedDeploymentsPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savedDeploymentsPageDescriptor = $convert.base64Decode(
    'ChRTYXZlZERlcGxveW1lbnRzUGFnZRI6CgdlbnRyaWVzGAEgAygLMiAubW9kY29uZHVjdG9yLn'
    'YxLlNhdmVkRGVwbG95bWVudFIHZW50cmllcxIkCgtuZXh0X2JlZm9yZRgCIAEoBEgAUgpuZXh0'
    'QmVmb3JliAEBQg4KDF9uZXh0X2JlZm9yZQ==');

@$core.Deprecated('Use prepareDeploymentRequestDescriptor instead')
const PrepareDeploymentRequest$json = {
  '1': 'PrepareDeploymentRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'source_token', '3': 3, '4': 1, '5': 9, '10': 'sourceToken'},
    {'1': 'retained', '3': 4, '4': 1, '5': 8, '10': 'retained'},
    {
      '1': 'generation_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'generationId',
      '17': true
    },
  ],
  '8': [
    {'1': '_generation_id'},
  ],
};

/// Descriptor for `PrepareDeploymentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareDeploymentRequestDescriptor = $convert.base64Decode(
    'ChhQcmVwYXJlRGVwbG95bWVudFJlcXVlc3QSDgoCaWQYASABKAlSAmlkEh0KCnByb2ZpbGVfaW'
    'QYAiABKAlSCXByb2ZpbGVJZBIhCgxzb3VyY2VfdG9rZW4YAyABKAlSC3NvdXJjZVRva2VuEhoK'
    'CHJldGFpbmVkGAQgASgIUghyZXRhaW5lZBIoCg1nZW5lcmF0aW9uX2lkGAUgASgJSABSDGdlbm'
    'VyYXRpb25JZIgBAUIQCg5fZ2VuZXJhdGlvbl9pZA==');

@$core.Deprecated('Use preparedDeploymentDescriptor instead')
const PreparedDeployment$json = {
  '1': 'PreparedDeployment',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'fingerprint', '3': 3, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'source_token', '3': 4, '4': 1, '5': 9, '10': 'sourceToken'},
    {
      '1': 'profile',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentProfile',
      '10': 'profile'
    },
    {'1': 'writable_files', '3': 6, '4': 1, '5': 13, '10': 'writableFiles'},
    {'1': 'changed_paths', '3': 7, '4': 1, '5': 13, '10': 'changedPaths'},
    {
      '1': 'preserved_originals',
      '3': 8,
      '4': 1,
      '5': 13,
      '10': 'preservedOriginals'
    },
    {'1': 'managed_links', '3': 9, '4': 1, '5': 13, '10': 'managedLinks'},
    {'1': 'copied_bytes', '3': 10, '4': 1, '5': 4, '10': 'copiedBytes'},
    {'1': 'required_bytes', '3': 11, '4': 1, '5': 4, '10': 'requiredBytes'},
  ],
};

/// Descriptor for `PreparedDeployment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparedDeploymentDescriptor = $convert.base64Decode(
    'ChJQcmVwYXJlZERlcGxveW1lbnQSDgoCaWQYASABKAlSAmlkEiEKDHdvcmtzcGFjZV9pZBgCIA'
    'EoCVILd29ya3NwYWNlSWQSIAoLZmluZ2VycHJpbnQYAyABKAlSC2ZpbmdlcnByaW50EiEKDHNv'
    'dXJjZV90b2tlbhgEIAEoCVILc291cmNlVG9rZW4SPAoHcHJvZmlsZRgFIAEoCzIiLm1vZGNvbm'
    'R1Y3Rvci52MS5EZXBsb3ltZW50UHJvZmlsZVIHcHJvZmlsZRIlCg53cml0YWJsZV9maWxlcxgG'
    'IAEoDVINd3JpdGFibGVGaWxlcxIjCg1jaGFuZ2VkX3BhdGhzGAcgASgNUgxjaGFuZ2VkUGF0aH'
    'MSLwoTcHJlc2VydmVkX29yaWdpbmFscxgIIAEoDVIScHJlc2VydmVkT3JpZ2luYWxzEiMKDW1h'
    'bmFnZWRfbGlua3MYCSABKA1SDG1hbmFnZWRMaW5rcxIhCgxjb3BpZWRfYnl0ZXMYCiABKARSC2'
    'NvcGllZEJ5dGVzEiUKDnJlcXVpcmVkX2J5dGVzGAsgASgEUg1yZXF1aXJlZEJ5dGVz');

@$core.Deprecated('Use activateDeploymentRequestDescriptor instead')
const ActivateDeploymentRequest$json = {
  '1': 'ActivateDeploymentRequest',
  '2': [
    {'1': 'prepared_id', '3': 1, '4': 1, '5': 9, '10': 'preparedId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'source_token', '3': 3, '4': 1, '5': 9, '10': 'sourceToken'},
  ],
};

/// Descriptor for `ActivateDeploymentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activateDeploymentRequestDescriptor = $convert.base64Decode(
    'ChlBY3RpdmF0ZURlcGxveW1lbnRSZXF1ZXN0Eh8KC3ByZXBhcmVkX2lkGAEgASgJUgpwcmVwYX'
    'JlZElkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBIhCgxzb3VyY2VfdG9rZW4YAyAB'
    'KAlSC3NvdXJjZVRva2Vu');

@$core.Deprecated('Use recoverDeploymentRequestDescriptor instead')
const RecoverDeploymentRequest$json = {
  '1': 'RecoverDeploymentRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 9, '10': 'receiptId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'restore', '3': 3, '4': 1, '5': 8, '10': 'restore'},
  ],
};

/// Descriptor for `RecoverDeploymentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recoverDeploymentRequestDescriptor = $convert.base64Decode(
    'ChhSZWNvdmVyRGVwbG95bWVudFJlcXVlc3QSHQoKcmVjZWlwdF9pZBgBIAEoCVIJcmVjZWlwdE'
    'lkEhoKCHJldmlzaW9uGAIgASgEUghyZXZpc2lvbhIYCgdyZXN0b3JlGAMgASgIUgdyZXN0b3Jl');

@$core.Deprecated('Use deploymentReceiptRequestDescriptor instead')
const DeploymentReceiptRequest$json = {
  '1': 'DeploymentReceiptRequest',
  '2': [
    {'1': 'receipt_id', '3': 1, '4': 1, '5': 9, '10': 'receiptId'},
  ],
};

/// Descriptor for `DeploymentReceiptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentReceiptRequestDescriptor =
    $convert.base64Decode(
        'ChhEZXBsb3ltZW50UmVjZWlwdFJlcXVlc3QSHQoKcmVjZWlwdF9pZBgBIAEoCVIJcmVjZWlwdE'
        'lk');

@$core.Deprecated('Use deploymentReceiptDescriptor instead')
const DeploymentReceipt$json = {
  '1': 'DeploymentReceipt',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'phase',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DeploymentPhase',
      '10': 'phase'
    },
    {
      '1': 'previous',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'previous',
      '17': true
    },
    {'1': 'proposed', '3': 6, '4': 1, '5': 9, '10': 'proposed'},
    {'1': 'completed', '3': 7, '4': 1, '5': 13, '10': 'completed'},
    {'1': 'total', '3': 8, '4': 1, '5': 13, '10': 'total'},
    {'1': 'detail', '3': 9, '4': 1, '5': 9, '10': 'detail'},
  ],
  '8': [
    {'1': '_previous'},
  ],
};

/// Descriptor for `DeploymentReceipt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentReceiptDescriptor = $convert.base64Decode(
    'ChFEZXBsb3ltZW50UmVjZWlwdBIOCgJpZBgBIAEoCVICaWQSIQoMd29ya3NwYWNlX2lkGAIgAS'
    'gJUgt3b3Jrc3BhY2VJZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24SNgoFcGhhc2UYBCAB'
    'KA4yIC5tb2Rjb25kdWN0b3IudjEuRGVwbG95bWVudFBoYXNlUgVwaGFzZRIfCghwcmV2aW91cx'
    'gFIAEoCUgAUghwcmV2aW91c4gBARIaCghwcm9wb3NlZBgGIAEoCVIIcHJvcG9zZWQSHAoJY29t'
    'cGxldGVkGAcgASgNUgljb21wbGV0ZWQSFAoFdG90YWwYCCABKA1SBXRvdGFsEhYKBmRldGFpbB'
    'gJIAEoCVIGZGV0YWlsQgsKCV9wcmV2aW91cw==');

@$core.Deprecated('Use deploymentProgressDescriptor instead')
const DeploymentProgress$json = {
  '1': 'DeploymentProgress',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DeploymentPhase',
      '10': 'phase'
    },
    {'1': 'completed', '3': 2, '4': 1, '5': 13, '10': 'completed'},
    {'1': 'total', '3': 3, '4': 1, '5': 13, '10': 'total'},
    {'1': 'bytes', '3': 4, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `DeploymentProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentProgressDescriptor = $convert.base64Decode(
    'ChJEZXBsb3ltZW50UHJvZ3Jlc3MSNgoFcGhhc2UYASABKA4yIC5tb2Rjb25kdWN0b3IudjEuRG'
    'VwbG95bWVudFBoYXNlUgVwaGFzZRIcCgljb21wbGV0ZWQYAiABKA1SCWNvbXBsZXRlZBIUCgV0'
    'b3RhbBgDIAEoDVIFdG90YWwSFAoFYnl0ZXMYBCABKARSBWJ5dGVz');

@$core.Deprecated('Use deploymentFaultDescriptor instead')
const DeploymentFault$json = {
  '1': 'DeploymentFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DeploymentFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `DeploymentFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentFaultDescriptor = $convert.base64Decode(
    'Cg9EZXBsb3ltZW50RmF1bHQSOAoEY29kZRgBIAEoDjIkLm1vZGNvbmR1Y3Rvci52MS5EZXBsb3'
    'ltZW50RmF1bHRDb2RlUgRjb2RlEhYKBmRldGFpbBgCIAEoCVIGZGV0YWls');

@$core.Deprecated('Use deploymentStateReplyDescriptor instead')
const DeploymentStateReply$json = {
  '1': 'DeploymentStateReply',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentState',
      '9': 0,
      '10': 'state'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DeploymentStateReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentStateReplyDescriptor = $convert.base64Decode(
    'ChREZXBsb3ltZW50U3RhdGVSZXBseRI4CgVzdGF0ZRgBIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS'
    '5EZXBsb3ltZW50U3RhdGVIAFIFc3RhdGUSOAoFZmF1bHQYAiABKAsyIC5tb2Rjb25kdWN0b3Iu'
    'djEuRGVwbG95bWVudEZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use savedDeploymentsReplyDescriptor instead')
const SavedDeploymentsReply$json = {
  '1': 'SavedDeploymentsReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SavedDeploymentsPage',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `SavedDeploymentsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savedDeploymentsReplyDescriptor = $convert.base64Decode(
    'ChVTYXZlZERlcGxveW1lbnRzUmVwbHkSOwoEcGFnZRgBIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS'
    '5TYXZlZERlcGxveW1lbnRzUGFnZUgAUgRwYWdlEjgKBWZhdWx0GAIgASgLMiAubW9kY29uZHVj'
    'dG9yLnYxLkRlcGxveW1lbnRGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use preparedDeploymentReplyDescriptor instead')
const PreparedDeploymentReply$json = {
  '1': 'PreparedDeploymentReply',
  '2': [
    {
      '1': 'prepared',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PreparedDeployment',
      '9': 0,
      '10': 'prepared'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `PreparedDeploymentReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparedDeploymentReplyDescriptor = $convert.base64Decode(
    'ChdQcmVwYXJlZERlcGxveW1lbnRSZXBseRJBCghwcmVwYXJlZBgBIAEoCzIjLm1vZGNvbmR1Y3'
    'Rvci52MS5QcmVwYXJlZERlcGxveW1lbnRIAFIIcHJlcGFyZWQSOAoFZmF1bHQYAiABKAsyIC5t'
    'b2Rjb25kdWN0b3IudjEuRGVwbG95bWVudEZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use deploymentReceiptReplyDescriptor instead')
const DeploymentReceiptReply$json = {
  '1': 'DeploymentReceiptReply',
  '2': [
    {
      '1': 'receipt',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentReceipt',
      '9': 0,
      '10': 'receipt'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DeploymentReceiptReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentReceiptReplyDescriptor = $convert.base64Decode(
    'ChZEZXBsb3ltZW50UmVjZWlwdFJlcGx5Ej4KB3JlY2VpcHQYASABKAsyIi5tb2Rjb25kdWN0b3'
    'IudjEuRGVwbG95bWVudFJlY2VpcHRIAFIHcmVjZWlwdBI4CgVmYXVsdBgCIAEoCzIgLm1vZGNv'
    'bmR1Y3Rvci52MS5EZXBsb3ltZW50RmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use deploymentPrepareEventDescriptor instead')
const DeploymentPrepareEvent$json = {
  '1': 'DeploymentPrepareEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'finished',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PreparedDeploymentReply',
      '9': 0,
      '10': 'finished'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `DeploymentPrepareEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentPrepareEventDescriptor = $convert.base64Decode(
    'ChZEZXBsb3ltZW50UHJlcGFyZUV2ZW50EkEKCHByb2dyZXNzGAEgASgLMiMubW9kY29uZHVjdG'
    '9yLnYxLkRlcGxveW1lbnRQcm9ncmVzc0gAUghwcm9ncmVzcxJGCghmaW5pc2hlZBgCIAEoCzIo'
    'Lm1vZGNvbmR1Y3Rvci52MS5QcmVwYXJlZERlcGxveW1lbnRSZXBseUgAUghmaW5pc2hlZEIHCg'
    'VldmVudA==');

@$core.Deprecated('Use deploymentRunEventDescriptor instead')
const DeploymentRunEvent$json = {
  '1': 'DeploymentRunEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'finished',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DeploymentReceiptReply',
      '9': 0,
      '10': 'finished'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `DeploymentRunEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deploymentRunEventDescriptor = $convert.base64Decode(
    'ChJEZXBsb3ltZW50UnVuRXZlbnQSQQoIcHJvZ3Jlc3MYASABKAsyIy5tb2Rjb25kdWN0b3Iudj'
    'EuRGVwbG95bWVudFByb2dyZXNzSABSCHByb2dyZXNzEkUKCGZpbmlzaGVkGAIgASgLMicubW9k'
    'Y29uZHVjdG9yLnYxLkRlcGxveW1lbnRSZWNlaXB0UmVwbHlIAFIIZmluaXNoZWRCBwoFZXZlbn'
    'Q=');
