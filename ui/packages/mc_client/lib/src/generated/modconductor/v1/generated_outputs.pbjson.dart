// This is a generated file - do not edit.
//
// Generated from modconductor/v1/generated_outputs.proto.

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

@$core.Deprecated('Use outputLocationKindDescriptor instead')
const OutputLocationKind$json = {
  '1': 'OutputLocationKind',
  '2': [
    {'1': 'OUTPUT_LOCATION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'OUTPUT_LOCATION_KIND_TOOL_FOLDER', '2': 1},
    {'1': 'OUTPUT_LOCATION_KIND_WRITABLE_FILE', '2': 2},
  ],
};

/// Descriptor for `OutputLocationKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputLocationKindDescriptor = $convert.base64Decode(
    'ChJPdXRwdXRMb2NhdGlvbktpbmQSJAogT1VUUFVUX0xPQ0FUSU9OX0tJTkRfVU5TUEVDSUZJRU'
    'QQABIkCiBPVVRQVVRfTE9DQVRJT05fS0lORF9UT09MX0ZPTERFUhABEiYKIk9VVFBVVF9MT0NB'
    'VElPTl9LSU5EX1dSSVRBQkxFX0ZJTEUQAg==');

@$core.Deprecated('Use outputLocationStatusDescriptor instead')
const OutputLocationStatus$json = {
  '1': 'OutputLocationStatus',
  '2': [
    {'1': 'OUTPUT_LOCATION_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'OUTPUT_LOCATION_STATUS_UNINITIALIZED', '2': 1},
    {'1': 'OUTPUT_LOCATION_STATUS_READY', '2': 2},
    {'1': 'OUTPUT_LOCATION_STATUS_STOPPED', '2': 3},
  ],
};

/// Descriptor for `OutputLocationStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputLocationStatusDescriptor = $convert.base64Decode(
    'ChRPdXRwdXRMb2NhdGlvblN0YXR1cxImCiJPVVRQVVRfTE9DQVRJT05fU1RBVFVTX1VOU1BFQ0'
    'lGSUVEEAASKAokT1VUUFVUX0xPQ0FUSU9OX1NUQVRVU19VTklOSVRJQUxJWkVEEAESIAocT1VU'
    'UFVUX0xPQ0FUSU9OX1NUQVRVU19SRUFEWRACEiIKHk9VVFBVVF9MT0NBVElPTl9TVEFUVVNfU1'
    'RPUFBFRBAD');

@$core.Deprecated('Use outputFileStatusDescriptor instead')
const OutputFileStatus$json = {
  '1': 'OutputFileStatus',
  '2': [
    {'1': 'OUTPUT_FILE_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'OUTPUT_FILE_STATUS_NEW', '2': 1},
    {'1': 'OUTPUT_FILE_STATUS_CHANGED', '2': 2},
    {'1': 'OUTPUT_FILE_STATUS_KEPT', '2': 3},
    {'1': 'OUTPUT_FILE_STATUS_ABSENT', '2': 4},
  ],
};

/// Descriptor for `OutputFileStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputFileStatusDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRGaWxlU3RhdHVzEiIKHk9VVFBVVF9GSUxFX1NUQVRVU19VTlNQRUNJRklFRBAAEh'
    'oKFk9VVFBVVF9GSUxFX1NUQVRVU19ORVcQARIeChpPVVRQVVRfRklMRV9TVEFUVVNfQ0hBTkdF'
    'RBACEhsKF09VVFBVVF9GSUxFX1NUQVRVU19LRVBUEAMSHQoZT1VUUFVUX0ZJTEVfU1RBVFVTX0'
    'FCU0VOVBAE');

@$core.Deprecated('Use outputActionKindDescriptor instead')
const OutputActionKind$json = {
  '1': 'OutputActionKind',
  '2': [
    {'1': 'OUTPUT_ACTION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'OUTPUT_ACTION_KIND_KEEP', '2': 1},
    {'1': 'OUTPUT_ACTION_KIND_DISCARD', '2': 2},
    {'1': 'OUTPUT_ACTION_KIND_MOVE_TO_MOD', '2': 3},
    {'1': 'OUTPUT_ACTION_KIND_SAVE_COPY_TO_MOD', '2': 4},
  ],
};

/// Descriptor for `OutputActionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputActionKindDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRBY3Rpb25LaW5kEiIKHk9VVFBVVF9BQ1RJT05fS0lORF9VTlNQRUNJRklFRBAAEh'
    'sKF09VVFBVVF9BQ1RJT05fS0lORF9LRUVQEAESHgoaT1VUUFVUX0FDVElPTl9LSU5EX0RJU0NB'
    'UkQQAhIiCh5PVVRQVVRfQUNUSU9OX0tJTkRfTU9WRV9UT19NT0QQAxInCiNPVVRQVVRfQUNUSU'
    '9OX0tJTkRfU0FWRV9DT1BZX1RPX01PRBAE');

@$core.Deprecated('Use outputDispositionDescriptor instead')
const OutputDisposition$json = {
  '1': 'OutputDisposition',
  '2': [
    {'1': 'OUTPUT_DISPOSITION_UNSPECIFIED', '2': 0},
    {'1': 'OUTPUT_DISPOSITION_KEPT', '2': 1},
    {'1': 'OUTPUT_DISPOSITION_DISCARDED', '2': 2},
    {'1': 'OUTPUT_DISPOSITION_MOVED', '2': 3},
    {'1': 'OUTPUT_DISPOSITION_COPIED', '2': 4},
    {'1': 'OUTPUT_DISPOSITION_CHANGED', '2': 5},
    {'1': 'OUTPUT_DISPOSITION_PENDING', '2': 6},
  ],
};

/// Descriptor for `OutputDisposition`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputDispositionDescriptor = $convert.base64Decode(
    'ChFPdXRwdXREaXNwb3NpdGlvbhIiCh5PVVRQVVRfRElTUE9TSVRJT05fVU5TUEVDSUZJRUQQAB'
    'IbChdPVVRQVVRfRElTUE9TSVRJT05fS0VQVBABEiAKHE9VVFBVVF9ESVNQT1NJVElPTl9ESVND'
    'QVJERUQQAhIcChhPVVRQVVRfRElTUE9TSVRJT05fTU9WRUQQAxIdChlPVVRQVVRfRElTUE9TSV'
    'RJT05fQ09QSUVEEAQSHgoaT1VUUFVUX0RJU1BPU0lUSU9OX0NIQU5HRUQQBRIeChpPVVRQVVRf'
    'RElTUE9TSVRJT05fUEVORElORxAG');

@$core.Deprecated('Use outputFaultCodeDescriptor instead')
const OutputFaultCode$json = {
  '1': 'OutputFaultCode',
  '2': [
    {'1': 'OUTPUT_FAULT_UNSPECIFIED', '2': 0},
    {'1': 'OUTPUT_FAULT_NOT_FOUND', '2': 1},
    {'1': 'OUTPUT_FAULT_BUSY', '2': 2},
    {'1': 'OUTPUT_FAULT_STALE', '2': 3},
    {'1': 'OUTPUT_FAULT_CANCELLED', '2': 4},
    {'1': 'OUTPUT_FAULT_INVALID', '2': 5},
    {'1': 'OUTPUT_FAULT_UNAVAILABLE', '2': 6},
    {'1': 'OUTPUT_FAULT_LIMIT_EXCEEDED', '2': 7},
  ],
};

/// Descriptor for `OutputFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputFaultCodeDescriptor = $convert.base64Decode(
    'Cg9PdXRwdXRGYXVsdENvZGUSHAoYT1VUUFVUX0ZBVUxUX1VOU1BFQ0lGSUVEEAASGgoWT1VUUF'
    'VUX0ZBVUxUX05PVF9GT1VORBABEhUKEU9VVFBVVF9GQVVMVF9CVVNZEAISFgoST1VUUFVUX0ZB'
    'VUxUX1NUQUxFEAMSGgoWT1VUUFVUX0ZBVUxUX0NBTkNFTExFRBAEEhgKFE9VVFBVVF9GQVVMVF'
    '9JTlZBTElEEAUSHAoYT1VUUFVUX0ZBVUxUX1VOQVZBSUxBQkxFEAYSHwobT1VUUFVUX0ZBVUxU'
    'X0xJTUlUX0VYQ0VFREVEEAc=');

@$core.Deprecated('Use outputScopeRefDescriptor instead')
const OutputScopeRef$json = {
  '1': 'OutputScopeRef',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'context_id', '3': 2, '4': 1, '5': 9, '10': 'contextId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'context_revision', '3': 4, '4': 1, '5': 4, '10': 'contextRevision'},
  ],
};

/// Descriptor for `OutputScopeRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputScopeRefDescriptor = $convert.base64Decode(
    'Cg5PdXRwdXRTY29wZVJlZhIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh0KCm'
    'NvbnRleHRfaWQYAiABKAlSCWNvbnRleHRJZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24S'
    'KQoQY29udGV4dF9yZXZpc2lvbhgEIAEoBFIPY29udGV4dFJldmlzaW9u');

@$core.Deprecated('Use readOutputsRequestDescriptor instead')
const ReadOutputsRequest$json = {
  '1': 'ReadOutputsRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'context_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'contextId',
      '17': true
    },
  ],
  '8': [
    {'1': '_context_id'},
  ],
};

/// Descriptor for `ReadOutputsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readOutputsRequestDescriptor = $convert.base64Decode(
    'ChJSZWFkT3V0cHV0c1JlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IiCgpjb250ZXh0X2lkGAIgASgJSABSCWNvbnRleHRJZIgBAUINCgtfY29udGV4dF9pZA==');

@$core.Deprecated('Use outputLocationDescriptor instead')
const OutputLocation$json = {
  '1': 'OutputLocation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'context_id', '3': 3, '4': 1, '5': 9, '10': 'contextId'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputLocationKind',
      '10': 'kind'
    },
    {
      '1': 'target',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
    {'1': 'revision', '3': 7, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputLocationStatus',
      '10': 'status'
    },
    {'1': 'physical_path', '3': 9, '4': 1, '5': 9, '10': 'physicalPath'},
  ],
};

/// Descriptor for `OutputLocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputLocationDescriptor = $convert.base64Decode(
    'Cg5PdXRwdXRMb2NhdGlvbhIOCgJpZBgBIAEoCVICaWQSIQoMd29ya3NwYWNlX2lkGAIgASgJUg'
    't3b3Jrc3BhY2VJZBIdCgpjb250ZXh0X2lkGAMgASgJUgljb250ZXh0SWQSEgoEbmFtZRgEIAEo'
    'CVIEbmFtZRI3CgRraW5kGAUgASgOMiMubW9kY29uZHVjdG9yLnYxLk91dHB1dExvY2F0aW9uS2'
    'luZFIEa2luZBI3CgZ0YXJnZXQYBiABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG9naWNhbFBh'
    'dGhSBnRhcmdldBIaCghyZXZpc2lvbhgHIAEoBFIIcmV2aXNpb24SPQoGc3RhdHVzGAggASgOMi'
    'UubW9kY29uZHVjdG9yLnYxLk91dHB1dExvY2F0aW9uU3RhdHVzUgZzdGF0dXMSIwoNcGh5c2lj'
    'YWxfcGF0aBgJIAEoCVIMcGh5c2ljYWxQYXRo');

@$core.Deprecated('Use outputContextDescriptor instead')
const OutputContext$json = {
  '1': 'OutputContext',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'installation', '3': 2, '4': 1, '5': 9, '10': 'installation'},
    {'1': 'current', '3': 3, '4': 1, '5': 8, '10': 'current'},
  ],
};

/// Descriptor for `OutputContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputContextDescriptor = $convert.base64Decode(
    'Cg1PdXRwdXRDb250ZXh0Eg4KAmlkGAEgASgJUgJpZBIiCgxpbnN0YWxsYXRpb24YAiABKAlSDG'
    'luc3RhbGxhdGlvbhIYCgdjdXJyZW50GAMgASgIUgdjdXJyZW50');

@$core.Deprecated('Use outputScopeDescriptor instead')
const OutputScope$json = {
  '1': 'OutputScope',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputScopeRef',
      '10': 'reference'
    },
    {'1': 'installation', '3': 2, '4': 1, '5': 9, '10': 'installation'},
    {
      '1': 'locations',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OutputLocation',
      '10': 'locations'
    },
    {
      '1': 'contexts',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OutputContext',
      '10': 'contexts'
    },
    {'1': 'pending_actions', '3': 5, '4': 3, '5': 9, '10': 'pendingActions'},
  ],
};

/// Descriptor for `OutputScope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputScopeDescriptor = $convert.base64Decode(
    'CgtPdXRwdXRTY29wZRI9CglyZWZlcmVuY2UYASABKAsyHy5tb2Rjb25kdWN0b3IudjEuT3V0cH'
    'V0U2NvcGVSZWZSCXJlZmVyZW5jZRIiCgxpbnN0YWxsYXRpb24YAiABKAlSDGluc3RhbGxhdGlv'
    'bhI9Cglsb2NhdGlvbnMYAyADKAsyHy5tb2Rjb25kdWN0b3IudjEuT3V0cHV0TG9jYXRpb25SCW'
    'xvY2F0aW9ucxI6Cghjb250ZXh0cxgEIAMoCzIeLm1vZGNvbmR1Y3Rvci52MS5PdXRwdXRDb250'
    'ZXh0Ughjb250ZXh0cxInCg9wZW5kaW5nX2FjdGlvbnMYBSADKAlSDnBlbmRpbmdBY3Rpb25z');

@$core.Deprecated('Use addOutputLocationRequestDescriptor instead')
const AddOutputLocationRequest$json = {
  '1': 'AddOutputLocationRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'expected',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputScopeRef',
      '10': 'expected'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputLocationKind',
      '10': 'kind'
    },
    {
      '1': 'target',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'target'
    },
  ],
};

/// Descriptor for `AddOutputLocationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addOutputLocationRequestDescriptor = $convert.base64Decode(
    'ChhBZGRPdXRwdXRMb2NhdGlvblJlcXVlc3QSDgoCaWQYASABKAlSAmlkEjsKCGV4cGVjdGVkGA'
    'IgASgLMh8ubW9kY29uZHVjdG9yLnYxLk91dHB1dFNjb3BlUmVmUghleHBlY3RlZBISCgRuYW1l'
    'GAMgASgJUgRuYW1lEjcKBGtpbmQYBCABKA4yIy5tb2Rjb25kdWN0b3IudjEuT3V0cHV0TG9jYX'
    'Rpb25LaW5kUgRraW5kEjcKBnRhcmdldBgFIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dp'
    'Y2FsUGF0aFIGdGFyZ2V0');

@$core.Deprecated('Use stopOutputLocationRequestDescriptor instead')
const StopOutputLocationRequest$json = {
  '1': 'StopOutputLocationRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `StopOutputLocationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopOutputLocationRequestDescriptor =
    $convert.base64Decode(
        'ChlTdG9wT3V0cHV0TG9jYXRpb25SZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIaCghyZXZpc2lvbh'
        'gCIAEoBFIIcmV2aXNpb24=');

@$core.Deprecated('Use observeOutputsRequestDescriptor instead')
const ObserveOutputsRequest$json = {
  '1': 'ObserveOutputsRequest',
  '2': [
    {
      '1': 'expected',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputScopeRef',
      '10': 'expected'
    },
  ],
};

/// Descriptor for `ObserveOutputsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List observeOutputsRequestDescriptor = $convert.base64Decode(
    'ChVPYnNlcnZlT3V0cHV0c1JlcXVlc3QSOwoIZXhwZWN0ZWQYASABKAsyHy5tb2Rjb25kdWN0b3'
    'IudjEuT3V0cHV0U2NvcGVSZWZSCGV4cGVjdGVk');

@$core.Deprecated('Use outputFileDescriptor instead')
const OutputFile$json = {
  '1': 'OutputFile',
  '2': [
    {'1': 'location_id', '3': 1, '4': 1, '5': 9, '10': 'locationId'},
    {
      '1': 'path',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
    {
      '1': 'status',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputFileStatus',
      '10': 'status'
    },
    {'1': 'length', '3': 4, '4': 1, '5': 4, '10': 'length'},
    {'1': 'sha256', '3': 5, '4': 1, '5': 9, '10': 'sha256'},
    {
      '1': 'observed_at_unix_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'observedAtUnixMs'
    },
    {
      '1': 'deployment_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'deploymentId',
      '17': true
    },
  ],
  '8': [
    {'1': '_deployment_id'},
  ],
};

/// Descriptor for `OutputFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputFileDescriptor = $convert.base64Decode(
    'CgpPdXRwdXRGaWxlEh8KC2xvY2F0aW9uX2lkGAEgASgJUgpsb2NhdGlvbklkEjMKBHBhdGgYAi'
    'ABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG9naWNhbFBhdGhSBHBhdGgSOQoGc3RhdHVzGAMg'
    'ASgOMiEubW9kY29uZHVjdG9yLnYxLk91dHB1dEZpbGVTdGF0dXNSBnN0YXR1cxIWCgZsZW5ndG'
    'gYBCABKARSBmxlbmd0aBIWCgZzaGEyNTYYBSABKAlSBnNoYTI1NhItChNvYnNlcnZlZF9hdF91'
    'bml4X21zGAYgASgDUhBvYnNlcnZlZEF0VW5peE1zEigKDWRlcGxveW1lbnRfaWQYByABKAlIAF'
    'IMZGVwbG95bWVudElkiAEBQhAKDl9kZXBsb3ltZW50X2lk');

@$core.Deprecated('Use outputSnapshotDescriptor instead')
const OutputSnapshot$json = {
  '1': 'OutputSnapshot',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'scope',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputScope',
      '10': 'scope'
    },
    {
      '1': 'observed_at_unix_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'observedAtUnixMs'
    },
    {'1': 'files', '3': 4, '4': 1, '5': 13, '10': 'files'},
    {'1': 'entries', '3': 5, '4': 1, '5': 13, '10': 'entries'},
    {'1': 'unreviewed', '3': 6, '4': 1, '5': 13, '10': 'unreviewed'},
  ],
};

/// Descriptor for `OutputSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputSnapshotDescriptor = $convert.base64Decode(
    'Cg5PdXRwdXRTbmFwc2hvdBIOCgJpZBgBIAEoCVICaWQSMgoFc2NvcGUYAiABKAsyHC5tb2Rjb2'
    '5kdWN0b3IudjEuT3V0cHV0U2NvcGVSBXNjb3BlEi0KE29ic2VydmVkX2F0X3VuaXhfbXMYAyAB'
    'KANSEG9ic2VydmVkQXRVbml4TXMSFAoFZmlsZXMYBCABKA1SBWZpbGVzEhgKB2VudHJpZXMYBS'
    'ABKA1SB2VudHJpZXMSHgoKdW5yZXZpZXdlZBgGIAEoDVIKdW5yZXZpZXdlZA==');

@$core.Deprecated('Use outputPageRequestDescriptor instead')
const OutputPageRequest$json = {
  '1': 'OutputPageRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'cursor', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'cursor', '17': true},
    {'1': 'filter', '3': 3, '4': 1, '5': 9, '10': 'filter'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputLocationKind',
      '10': 'kind'
    },
  ],
  '8': [
    {'1': '_cursor'},
  ],
};

/// Descriptor for `OutputPageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPageRequestDescriptor = $convert.base64Decode(
    'ChFPdXRwdXRQYWdlUmVxdWVzdBIfCgtzbmFwc2hvdF9pZBgBIAEoCVIKc25hcHNob3RJZBIbCg'
    'ZjdXJzb3IYAiABKAlIAFIGY3Vyc29yiAEBEhYKBmZpbHRlchgDIAEoCVIGZmlsdGVyEjcKBGtp'
    'bmQYBCABKA4yIy5tb2Rjb25kdWN0b3IudjEuT3V0cHV0TG9jYXRpb25LaW5kUgRraW5kQgkKB1'
    '9jdXJzb3I=');

@$core.Deprecated('Use outputPageDescriptor instead')
const OutputPage$json = {
  '1': 'OutputPage',
  '2': [
    {
      '1': 'snapshot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputSnapshot',
      '10': 'snapshot'
    },
    {
      '1': 'entries',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OutputFile',
      '10': 'entries'
    },
    {'1': 'matching', '3': 3, '4': 1, '5': 13, '10': 'matching'},
    {
      '1': 'next_cursor',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextCursor',
      '17': true
    },
    {'1': 'files', '3': 5, '4': 1, '5': 13, '10': 'files'},
    {'1': 'unreviewed', '3': 6, '4': 1, '5': 13, '10': 'unreviewed'},
  ],
  '8': [
    {'1': '_next_cursor'},
  ],
};

/// Descriptor for `OutputPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPageDescriptor = $convert.base64Decode(
    'CgpPdXRwdXRQYWdlEjsKCHNuYXBzaG90GAEgASgLMh8ubW9kY29uZHVjdG9yLnYxLk91dHB1dF'
    'NuYXBzaG90UghzbmFwc2hvdBI1CgdlbnRyaWVzGAIgAygLMhsubW9kY29uZHVjdG9yLnYxLk91'
    'dHB1dEZpbGVSB2VudHJpZXMSGgoIbWF0Y2hpbmcYAyABKA1SCG1hdGNoaW5nEiQKC25leHRfY3'
    'Vyc29yGAQgASgJSABSCm5leHRDdXJzb3KIAQESFAoFZmlsZXMYBSABKA1SBWZpbGVzEh4KCnVu'
    'cmV2aWV3ZWQYBiABKA1SCnVucmV2aWV3ZWRCDgoMX25leHRfY3Vyc29y');

@$core.Deprecated('Use outputSelectionDescriptor instead')
const OutputSelection$json = {
  '1': 'OutputSelection',
  '2': [
    {'1': 'location_id', '3': 1, '4': 1, '5': 9, '10': 'locationId'},
    {
      '1': 'path',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
  ],
};

/// Descriptor for `OutputSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputSelectionDescriptor = $convert.base64Decode(
    'Cg9PdXRwdXRTZWxlY3Rpb24SHwoLbG9jYXRpb25faWQYASABKAlSCmxvY2F0aW9uSWQSMwoEcG'
    'F0aBgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dpY2FsUGF0aFIEcGF0aA==');

@$core.Deprecated('Use existingOutputModDescriptor instead')
const ExistingOutputMod$json = {
  '1': 'ExistingOutputMod',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 2, '4': 1, '5': 4, '10': 'revision'},
    {'1': 'version_label', '3': 3, '4': 1, '5': 9, '10': 'versionLabel'},
  ],
};

/// Descriptor for `ExistingOutputMod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List existingOutputModDescriptor = $convert.base64Decode(
    'ChFFeGlzdGluZ091dHB1dE1vZBIVCgZtb2RfaWQYASABKAlSBW1vZElkEhoKCHJldmlzaW9uGA'
    'IgASgEUghyZXZpc2lvbhIjCg12ZXJzaW9uX2xhYmVsGAMgASgJUgx2ZXJzaW9uTGFiZWw=');

@$core.Deprecated('Use newOutputModDescriptor instead')
const NewOutputMod$json = {
  '1': 'NewOutputMod',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version_label', '3': 3, '4': 1, '5': 9, '10': 'versionLabel'},
  ],
};

/// Descriptor for `NewOutputMod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newOutputModDescriptor = $convert.base64Decode(
    'CgxOZXdPdXRwdXRNb2QSFQoGbW9kX2lkGAEgASgJUgVtb2RJZBISCgRuYW1lGAIgASgJUgRuYW'
    '1lEiMKDXZlcnNpb25fbGFiZWwYAyABKAlSDHZlcnNpb25MYWJlbA==');

@$core.Deprecated('Use outputDestinationDescriptor instead')
const OutputDestination$json = {
  '1': 'OutputDestination',
  '2': [
    {
      '1': 'existing_mod',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ExistingOutputMod',
      '9': 0,
      '10': 'existingMod'
    },
    {
      '1': 'new_mod',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.NewOutputMod',
      '9': 0,
      '10': 'newMod'
    },
  ],
  '8': [
    {'1': 'destination'},
  ],
};

/// Descriptor for `OutputDestination`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputDestinationDescriptor = $convert.base64Decode(
    'ChFPdXRwdXREZXN0aW5hdGlvbhJHCgxleGlzdGluZ19tb2QYASABKAsyIi5tb2Rjb25kdWN0b3'
    'IudjEuRXhpc3RpbmdPdXRwdXRNb2RIAFILZXhpc3RpbmdNb2QSOAoHbmV3X21vZBgCIAEoCzId'
    'Lm1vZGNvbmR1Y3Rvci52MS5OZXdPdXRwdXRNb2RIAFIGbmV3TW9kQg0KC2Rlc3RpbmF0aW9u');

@$core.Deprecated('Use outputActionSpecDescriptor instead')
const OutputActionSpec$json = {
  '1': 'OutputActionSpec',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputActionKind',
      '10': 'kind'
    },
    {
      '1': 'destination',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputDestination',
      '10': 'destination'
    },
  ],
};

/// Descriptor for `OutputActionSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputActionSpecDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRBY3Rpb25TcGVjEjUKBGtpbmQYASABKA4yIS5tb2Rjb25kdWN0b3IudjEuT3V0cH'
    'V0QWN0aW9uS2luZFIEa2luZBJECgtkZXN0aW5hdGlvbhgCIAEoCzIiLm1vZGNvbmR1Y3Rvci52'
    'MS5PdXRwdXREZXN0aW5hdGlvblILZGVzdGluYXRpb24=');

@$core.Deprecated('Use outputPromotionRequestDescriptor instead')
const OutputPromotionRequest$json = {
  '1': 'OutputPromotionRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'files',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OutputSelection',
      '10': 'files'
    },
    {
      '1': 'action',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputActionSpec',
      '10': 'action'
    },
  ],
};

/// Descriptor for `OutputPromotionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPromotionRequestDescriptor = $convert.base64Decode(
    'ChZPdXRwdXRQcm9tb3Rpb25SZXF1ZXN0Eh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdE'
    'lkEjYKBWZpbGVzGAIgAygLMiAubW9kY29uZHVjdG9yLnYxLk91dHB1dFNlbGVjdGlvblIFZmls'
    'ZXMSOQoGYWN0aW9uGAMgASgLMiEubW9kY29uZHVjdG9yLnYxLk91dHB1dEFjdGlvblNwZWNSBm'
    'FjdGlvbg==');

@$core.Deprecated('Use outputPromotionPreviewDescriptor instead')
const OutputPromotionPreview$json = {
  '1': 'OutputPromotionPreview',
  '2': [
    {'1': 'selected', '3': 1, '4': 1, '5': 13, '10': 'selected'},
    {
      '1': 'replaced',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'replaced'
    },
    {
      '1': 'previous_version',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'previousVersion',
      '17': true
    },
    {
      '1': 'registered_source',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'registeredSource'
    },
  ],
  '8': [
    {'1': '_previous_version'},
  ],
};

/// Descriptor for `OutputPromotionPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPromotionPreviewDescriptor = $convert.base64Decode(
    'ChZPdXRwdXRQcm9tb3Rpb25QcmV2aWV3EhoKCHNlbGVjdGVkGAEgASgNUghzZWxlY3RlZBI7Cg'
    'hyZXBsYWNlZBgCIAMoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RMb2dpY2FsUGF0aFIIcmVwbGFj'
    'ZWQSLgoQcHJldmlvdXNfdmVyc2lvbhgDIAEoCUgAUg9wcmV2aW91c1ZlcnNpb26IAQESKwoRcm'
    'VnaXN0ZXJlZF9zb3VyY2UYBCABKAhSEHJlZ2lzdGVyZWRTb3VyY2VCEwoRX3ByZXZpb3VzX3Zl'
    'cnNpb24=');

@$core.Deprecated('Use applyOutputActionRequestDescriptor instead')
const ApplyOutputActionRequest$json = {
  '1': 'ApplyOutputActionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'snapshot_id', '3': 2, '4': 1, '5': 9, '10': 'snapshotId'},
    {
      '1': 'files',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OutputSelection',
      '10': 'files'
    },
    {
      '1': 'action',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputActionSpec',
      '10': 'action'
    },
  ],
};

/// Descriptor for `ApplyOutputActionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyOutputActionRequestDescriptor = $convert.base64Decode(
    'ChhBcHBseU91dHB1dEFjdGlvblJlcXVlc3QSDgoCaWQYASABKAlSAmlkEh8KC3NuYXBzaG90X2'
    'lkGAIgASgJUgpzbmFwc2hvdElkEjYKBWZpbGVzGAMgAygLMiAubW9kY29uZHVjdG9yLnYxLk91'
    'dHB1dFNlbGVjdGlvblIFZmlsZXMSOQoGYWN0aW9uGAQgASgLMiEubW9kY29uZHVjdG9yLnYxLk'
    '91dHB1dEFjdGlvblNwZWNSBmFjdGlvbg==');

@$core.Deprecated('Use outputActionRequestDescriptor instead')
const OutputActionRequest$json = {
  '1': 'OutputActionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `OutputActionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputActionRequestDescriptor = $convert
    .base64Decode('ChNPdXRwdXRBY3Rpb25SZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use outputActionEntryDescriptor instead')
const OutputActionEntry$json = {
  '1': 'OutputActionEntry',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputSelection',
      '10': 'file'
    },
    {
      '1': 'disposition',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputDisposition',
      '10': 'disposition'
    },
  ],
};

/// Descriptor for `OutputActionEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputActionEntryDescriptor = $convert.base64Decode(
    'ChFPdXRwdXRBY3Rpb25FbnRyeRI0CgRmaWxlGAEgASgLMiAubW9kY29uZHVjdG9yLnYxLk91dH'
    'B1dFNlbGVjdGlvblIEZmlsZRJECgtkaXNwb3NpdGlvbhgCIAEoDjIiLm1vZGNvbmR1Y3Rvci52'
    'MS5PdXRwdXREaXNwb3NpdGlvblILZGlzcG9zaXRpb24=');

@$core.Deprecated('Use outputActionResultDescriptor instead')
const OutputActionResult$json = {
  '1': 'OutputActionResult',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'version_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'versionId',
      '17': true
    },
    {'1': 'published', '3': 3, '4': 1, '5': 8, '10': 'published'},
    {
      '1': 'entries',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OutputActionEntry',
      '10': 'entries'
    },
    {'1': 'complete', '3': 5, '4': 1, '5': 8, '10': 'complete'},
  ],
  '8': [
    {'1': '_version_id'},
  ],
};

/// Descriptor for `OutputActionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputActionResultDescriptor = $convert.base64Decode(
    'ChJPdXRwdXRBY3Rpb25SZXN1bHQSDgoCaWQYASABKAlSAmlkEiIKCnZlcnNpb25faWQYAiABKA'
    'lIAFIJdmVyc2lvbklkiAEBEhwKCXB1Ymxpc2hlZBgDIAEoCFIJcHVibGlzaGVkEjwKB2VudHJp'
    'ZXMYBCADKAsyIi5tb2Rjb25kdWN0b3IudjEuT3V0cHV0QWN0aW9uRW50cnlSB2VudHJpZXMSGg'
    'oIY29tcGxldGUYBSABKAhSCGNvbXBsZXRlQg0KC192ZXJzaW9uX2lk');

@$core.Deprecated('Use outputFaultDescriptor instead')
const OutputFault$json = {
  '1': 'OutputFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.OutputFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `OutputFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputFaultDescriptor = $convert.base64Decode(
    'CgtPdXRwdXRGYXVsdBI0CgRjb2RlGAEgASgOMiAubW9kY29uZHVjdG9yLnYxLk91dHB1dEZhdW'
    'x0Q29kZVIEY29kZRIWCgZkZXRhaWwYAiABKAlSBmRldGFpbA==');

@$core.Deprecated('Use outputScopeReplyDescriptor instead')
const OutputScopeReply$json = {
  '1': 'OutputScopeReply',
  '2': [
    {
      '1': 'scope',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputScope',
      '9': 0,
      '10': 'scope'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `OutputScopeReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputScopeReplyDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRTY29wZVJlcGx5EjQKBXNjb3BlGAEgASgLMhwubW9kY29uZHVjdG9yLnYxLk91dH'
    'B1dFNjb3BlSABSBXNjb3BlEjQKBWZhdWx0GAIgASgLMhwubW9kY29uZHVjdG9yLnYxLk91dHB1'
    'dEZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use outputLocationReplyDescriptor instead')
const OutputLocationReply$json = {
  '1': 'OutputLocationReply',
  '2': [
    {
      '1': 'location',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputLocation',
      '9': 0,
      '10': 'location'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `OutputLocationReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputLocationReplyDescriptor = $convert.base64Decode(
    'ChNPdXRwdXRMb2NhdGlvblJlcGx5Ej0KCGxvY2F0aW9uGAEgASgLMh8ubW9kY29uZHVjdG9yLn'
    'YxLk91dHB1dExvY2F0aW9uSABSCGxvY2F0aW9uEjQKBWZhdWx0GAIgASgLMhwubW9kY29uZHVj'
    'dG9yLnYxLk91dHB1dEZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use outputSnapshotReplyDescriptor instead')
const OutputSnapshotReply$json = {
  '1': 'OutputSnapshotReply',
  '2': [
    {
      '1': 'snapshot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputSnapshot',
      '9': 0,
      '10': 'snapshot'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `OutputSnapshotReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputSnapshotReplyDescriptor = $convert.base64Decode(
    'ChNPdXRwdXRTbmFwc2hvdFJlcGx5Ej0KCHNuYXBzaG90GAEgASgLMh8ubW9kY29uZHVjdG9yLn'
    'YxLk91dHB1dFNuYXBzaG90SABSCHNuYXBzaG90EjQKBWZhdWx0GAIgASgLMhwubW9kY29uZHVj'
    'dG9yLnYxLk91dHB1dEZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use outputPageReplyDescriptor instead')
const OutputPageReply$json = {
  '1': 'OutputPageReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputPage',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `OutputPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPageReplyDescriptor = $convert.base64Decode(
    'Cg9PdXRwdXRQYWdlUmVwbHkSMQoEcGFnZRgBIAEoCzIbLm1vZGNvbmR1Y3Rvci52MS5PdXRwdX'
    'RQYWdlSABSBHBhZ2USNAoFZmF1bHQYAiABKAsyHC5tb2Rjb25kdWN0b3IudjEuT3V0cHV0RmF1'
    'bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use outputPromotionReplyDescriptor instead')
const OutputPromotionReply$json = {
  '1': 'OutputPromotionReply',
  '2': [
    {
      '1': 'preview',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputPromotionPreview',
      '9': 0,
      '10': 'preview'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `OutputPromotionReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPromotionReplyDescriptor = $convert.base64Decode(
    'ChRPdXRwdXRQcm9tb3Rpb25SZXBseRJDCgdwcmV2aWV3GAEgASgLMicubW9kY29uZHVjdG9yLn'
    'YxLk91dHB1dFByb21vdGlvblByZXZpZXdIAFIHcHJldmlldxI0CgVmYXVsdBgCIAEoCzIcLm1v'
    'ZGNvbmR1Y3Rvci52MS5PdXRwdXRGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use outputActionReplyDescriptor instead')
const OutputActionReply$json = {
  '1': 'OutputActionReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputActionResult',
      '9': 0,
      '10': 'result'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `OutputActionReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputActionReplyDescriptor = $convert.base64Decode(
    'ChFPdXRwdXRBY3Rpb25SZXBseRI9CgZyZXN1bHQYASABKAsyIy5tb2Rjb25kdWN0b3IudjEuT3'
    'V0cHV0QWN0aW9uUmVzdWx0SABSBnJlc3VsdBI0CgVmYXVsdBgCIAEoCzIcLm1vZGNvbmR1Y3Rv'
    'ci52MS5PdXRwdXRGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use outputProgressDescriptor instead')
const OutputProgress$json = {
  '1': 'OutputProgress',
  '2': [
    {'1': 'files', '3': 1, '4': 1, '5': 13, '10': 'files'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `OutputProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputProgressDescriptor = $convert.base64Decode(
    'Cg5PdXRwdXRQcm9ncmVzcxIUCgVmaWxlcxgBIAEoDVIFZmlsZXMSFAoFYnl0ZXMYAiABKARSBW'
    'J5dGVz');

@$core.Deprecated('Use outputLoadEventDescriptor instead')
const OutputLoadEvent$json = {
  '1': 'OutputLoadEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'finished',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OutputSnapshotReply',
      '9': 0,
      '10': 'finished'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `OutputLoadEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputLoadEventDescriptor = $convert.base64Decode(
    'Cg9PdXRwdXRMb2FkRXZlbnQSPQoIcHJvZ3Jlc3MYASABKAsyHy5tb2Rjb25kdWN0b3IudjEuT3'
    'V0cHV0UHJvZ3Jlc3NIAFIIcHJvZ3Jlc3MSQgoIZmluaXNoZWQYAiABKAsyJC5tb2Rjb25kdWN0'
    'b3IudjEuT3V0cHV0U25hcHNob3RSZXBseUgAUghmaW5pc2hlZEIHCgVldmVudA==');
