// This is a generated file - do not edit.
//
// Generated from modconductor/v1/diagnostics.proto.

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

@$core.Deprecated('Use diagnosticSeverityDescriptor instead')
const DiagnosticSeverity$json = {
  '1': 'DiagnosticSeverity',
  '2': [
    {'1': 'DIAGNOSTIC_SEVERITY_INFORMATION', '2': 0},
    {'1': 'DIAGNOSTIC_SEVERITY_WARNING', '2': 1},
    {'1': 'DIAGNOSTIC_SEVERITY_ERROR', '2': 2},
  ],
};

/// Descriptor for `DiagnosticSeverity`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List diagnosticSeverityDescriptor = $convert.base64Decode(
    'ChJEaWFnbm9zdGljU2V2ZXJpdHkSIwofRElBR05PU1RJQ19TRVZFUklUWV9JTkZPUk1BVElPTh'
    'AAEh8KG0RJQUdOT1NUSUNfU0VWRVJJVFlfV0FSTklORxABEh0KGURJQUdOT1NUSUNfU0VWRVJJ'
    'VFlfRVJST1IQAg==');

@$core.Deprecated('Use diagnosticFixabilityDescriptor instead')
const DiagnosticFixability$json = {
  '1': 'DiagnosticFixability',
  '2': [
    {'1': 'DIAGNOSTIC_FIXABILITY_NOT_FIXABLE', '2': 0},
    {'1': 'DIAGNOSTIC_FIXABILITY_PREVIEW_AVAILABLE', '2': 1},
    {'1': 'DIAGNOSTIC_FIXABILITY_READY', '2': 2},
    {'1': 'DIAGNOSTIC_FIXABILITY_REFUSED', '2': 3},
  ],
};

/// Descriptor for `DiagnosticFixability`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List diagnosticFixabilityDescriptor = $convert.base64Decode(
    'ChREaWFnbm9zdGljRml4YWJpbGl0eRIlCiFESUFHTk9TVElDX0ZJWEFCSUxJVFlfTk9UX0ZJWE'
    'FCTEUQABIrCidESUFHTk9TVElDX0ZJWEFCSUxJVFlfUFJFVklFV19BVkFJTEFCTEUQARIfChtE'
    'SUFHTk9TVElDX0ZJWEFCSUxJVFlfUkVBRFkQAhIhCh1ESUFHTk9TVElDX0ZJWEFCSUxJVFlfUk'
    'VGVVNFRBAD');

@$core.Deprecated('Use diagnosticFaultDescriptor instead')
const DiagnosticFault$json = {
  '1': 'DiagnosticFault',
  '2': [
    {'1': 'DIAGNOSTIC_FAULT_NONE', '2': 0},
    {'1': 'DIAGNOSTIC_FAULT_NOT_FOUND', '2': 1},
    {'1': 'DIAGNOSTIC_FAULT_EXPIRED', '2': 2},
    {'1': 'DIAGNOSTIC_FAULT_STALE', '2': 3},
    {'1': 'DIAGNOSTIC_FAULT_FOREIGN', '2': 4},
    {'1': 'DIAGNOSTIC_FAULT_NOT_OWNED', '2': 5},
    {'1': 'DIAGNOSTIC_FAULT_BUSY', '2': 6},
    {'1': 'DIAGNOSTIC_FAULT_OVERSIZED', '2': 7},
    {'1': 'DIAGNOSTIC_FAULT_UNSUPPORTED', '2': 8},
    {'1': 'DIAGNOSTIC_FAULT_CANCELLED', '2': 9},
  ],
};

/// Descriptor for `DiagnosticFault`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List diagnosticFaultDescriptor = $convert.base64Decode(
    'Cg9EaWFnbm9zdGljRmF1bHQSGQoVRElBR05PU1RJQ19GQVVMVF9OT05FEAASHgoaRElBR05PU1'
    'RJQ19GQVVMVF9OT1RfRk9VTkQQARIcChhESUFHTk9TVElDX0ZBVUxUX0VYUElSRUQQAhIaChZE'
    'SUFHTk9TVElDX0ZBVUxUX1NUQUxFEAMSHAoYRElBR05PU1RJQ19GQVVMVF9GT1JFSUdOEAQSHg'
    'oaRElBR05PU1RJQ19GQVVMVF9OT1RfT1dORUQQBRIZChVESUFHTk9TVElDX0ZBVUxUX0JVU1kQ'
    'BhIeChpESUFHTk9TVElDX0ZBVUxUX09WRVJTSVpFRBAHEiAKHERJQUdOT1NUSUNfRkFVTFRfVU'
    '5TVVBQT1JURUQQCBIeChpESUFHTk9TVElDX0ZBVUxUX0NBTkNFTExFRBAJ');

@$core.Deprecated('Use diagnosticRequestDescriptor instead')
const DiagnosticRequest$json = {
  '1': 'DiagnosticRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'file_snapshot_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'fileSnapshotId',
      '17': true
    },
    {
      '1': 'deployment_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'deploymentId',
      '17': true
    },
    {
      '1': 'deployment_revision',
      '3': 5,
      '4': 1,
      '5': 4,
      '9': 2,
      '10': 'deploymentRevision',
      '17': true
    },
    {
      '1': 'operation_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'operationId',
      '17': true
    },
  ],
  '8': [
    {'1': '_file_snapshot_id'},
    {'1': '_deployment_id'},
    {'1': '_deployment_revision'},
    {'1': '_operation_id'},
  ],
};

/// Descriptor for `DiagnosticRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticRequestDescriptor = $convert.base64Decode(
    'ChFEaWFnbm9zdGljUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh'
    '0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBItChBmaWxlX3NuYXBzaG90X2lkGAMgASgJ'
    'SABSDmZpbGVTbmFwc2hvdElkiAEBEigKDWRlcGxveW1lbnRfaWQYBCABKAlIAVIMZGVwbG95bW'
    'VudElkiAEBEjQKE2RlcGxveW1lbnRfcmV2aXNpb24YBSABKARIAlISZGVwbG95bWVudFJldmlz'
    'aW9uiAEBEiYKDG9wZXJhdGlvbl9pZBgGIAEoCUgDUgtvcGVyYXRpb25JZIgBAUITChFfZmlsZV'
    '9zbmFwc2hvdF9pZEIQCg5fZGVwbG95bWVudF9pZEIWChRfZGVwbG95bWVudF9yZXZpc2lvbkIP'
    'Cg1fb3BlcmF0aW9uX2lk');

@$core.Deprecated('Use diagnosticSnapshotReferenceDescriptor instead')
const DiagnosticSnapshotReference$json = {
  '1': 'DiagnosticSnapshotReference',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `DiagnosticSnapshotReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticSnapshotReferenceDescriptor =
    $convert.base64Decode(
        'ChtEaWFnbm9zdGljU25hcHNob3RSZWZlcmVuY2USHwoLc25hcHNob3RfaWQYASABKAlSCnNuYX'
        'BzaG90SWQ=');

@$core.Deprecated('Use diagnosticPreviewRequestDescriptor instead')
const DiagnosticPreviewRequest$json = {
  '1': 'DiagnosticPreviewRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'problem_id', '3': 2, '4': 1, '5': 9, '10': 'problemId'},
  ],
};

/// Descriptor for `DiagnosticPreviewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticPreviewRequestDescriptor =
    $convert.base64Decode(
        'ChhEaWFnbm9zdGljUHJldmlld1JlcXVlc3QSHwoLc25hcHNob3RfaWQYASABKAlSCnNuYXBzaG'
        '90SWQSHQoKcHJvYmxlbV9pZBgCIAEoCVIJcHJvYmxlbUlk');

@$core.Deprecated('Use diagnosticApplyRequestDescriptor instead')
const DiagnosticApplyRequest$json = {
  '1': 'DiagnosticApplyRequest',
  '2': [
    {'1': 'preview_id', '3': 1, '4': 1, '5': 9, '10': 'previewId'},
    {'1': 'action_id', '3': 2, '4': 1, '5': 9, '10': 'actionId'},
  ],
};

/// Descriptor for `DiagnosticApplyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticApplyRequestDescriptor =
    $convert.base64Decode(
        'ChZEaWFnbm9zdGljQXBwbHlSZXF1ZXN0Eh0KCnByZXZpZXdfaWQYASABKAlSCXByZXZpZXdJZB'
        'IbCglhY3Rpb25faWQYAiABKAlSCGFjdGlvbklk');

@$core.Deprecated('Use diagnosticEvidenceDescriptor instead')
const DiagnosticEvidence$json = {
  '1': 'DiagnosticEvidence',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `DiagnosticEvidence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticEvidenceDescriptor = $convert.base64Decode(
    'ChJEaWFnbm9zdGljRXZpZGVuY2USFAoFbGFiZWwYASABKAlSBWxhYmVsEhQKBXZhbHVlGAIgAS'
    'gJUgV2YWx1ZQ==');

@$core.Deprecated('Use diagnosticCorrelationDescriptor instead')
const DiagnosticCorrelation$json = {
  '1': 'DiagnosticCorrelation',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'revision',
      '17': true
    },
  ],
  '8': [
    {'1': '_revision'},
  ],
};

/// Descriptor for `DiagnosticCorrelation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticCorrelationDescriptor = $convert.base64Decode(
    'ChVEaWFnbm9zdGljQ29ycmVsYXRpb24SEgoEa2luZBgBIAEoCVIEa2luZBIOCgJpZBgCIAEoCV'
    'ICaWQSHwoIcmV2aXNpb24YAyABKARIAFIIcmV2aXNpb26IAQFCCwoJX3JldmlzaW9u');

@$core.Deprecated('Use diagnosticFindingDescriptor instead')
const DiagnosticFinding$json = {
  '1': 'DiagnosticFinding',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {
      '1': 'severity',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DiagnosticSeverity',
      '10': 'severity'
    },
    {'1': 'workspace_name', '3': 4, '4': 1, '5': 9, '10': 'workspaceName'},
    {'1': 'profile_name', '3': 5, '4': 1, '5': 9, '10': 'profileName'},
    {'1': 'game_name', '3': 6, '4': 1, '5': 9, '10': 'gameName'},
    {'1': 'title', '3': 7, '4': 1, '5': 9, '10': 'title'},
    {'1': 'summary', '3': 8, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'area', '3': 9, '4': 1, '5': 9, '10': 'area'},
    {
      '1': 'evidence',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticEvidence',
      '10': 'evidence'
    },
    {'1': 'next_action', '3': 11, '4': 1, '5': 9, '10': 'nextAction'},
    {
      '1': 'fixability',
      '3': 12,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DiagnosticFixability',
      '10': 'fixability'
    },
    {'1': 'fix_detail', '3': 13, '4': 1, '5': 9, '10': 'fixDetail'},
    {
      '1': 'correlations',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticCorrelation',
      '10': 'correlations'
    },
    {
      '1': 'detail',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'detail',
      '17': true
    },
  ],
  '8': [
    {'1': '_detail'},
  ],
};

/// Descriptor for `DiagnosticFinding`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticFindingDescriptor = $convert.base64Decode(
    'ChFEaWFnbm9zdGljRmluZGluZxIOCgJpZBgBIAEoCVICaWQSEgoEY29kZRgCIAEoCVIEY29kZR'
    'I/CghzZXZlcml0eRgDIAEoDjIjLm1vZGNvbmR1Y3Rvci52MS5EaWFnbm9zdGljU2V2ZXJpdHlS'
    'CHNldmVyaXR5EiUKDndvcmtzcGFjZV9uYW1lGAQgASgJUg13b3Jrc3BhY2VOYW1lEiEKDHByb2'
    'ZpbGVfbmFtZRgFIAEoCVILcHJvZmlsZU5hbWUSGwoJZ2FtZV9uYW1lGAYgASgJUghnYW1lTmFt'
    'ZRIUCgV0aXRsZRgHIAEoCVIFdGl0bGUSGAoHc3VtbWFyeRgIIAEoCVIHc3VtbWFyeRISCgRhcm'
    'VhGAkgASgJUgRhcmVhEj8KCGV2aWRlbmNlGAogAygLMiMubW9kY29uZHVjdG9yLnYxLkRpYWdu'
    'b3N0aWNFdmlkZW5jZVIIZXZpZGVuY2USHwoLbmV4dF9hY3Rpb24YCyABKAlSCm5leHRBY3Rpb2'
    '4SRQoKZml4YWJpbGl0eRgMIAEoDjIlLm1vZGNvbmR1Y3Rvci52MS5EaWFnbm9zdGljRml4YWJp'
    'bGl0eVIKZml4YWJpbGl0eRIdCgpmaXhfZGV0YWlsGA0gASgJUglmaXhEZXRhaWwSSgoMY29ycm'
    'VsYXRpb25zGA4gAygLMiYubW9kY29uZHVjdG9yLnYxLkRpYWdub3N0aWNDb3JyZWxhdGlvblIM'
    'Y29ycmVsYXRpb25zEhsKBmRldGFpbBgPIAEoCUgAUgZkZXRhaWyIAQFCCQoHX2RldGFpbA==');

@$core.Deprecated('Use diagnosticSnapshotDescriptor instead')
const DiagnosticSnapshot$json = {
  '1': 'DiagnosticSnapshot',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'captured_at', '3': 4, '4': 1, '5': 9, '10': 'capturedAt'},
    {
      '1': 'findings',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticFinding',
      '10': 'findings'
    },
  ],
};

/// Descriptor for `DiagnosticSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticSnapshotDescriptor = $convert.base64Decode(
    'ChJEaWFnbm9zdGljU25hcHNob3QSDgoCaWQYASABKAlSAmlkEiEKDHdvcmtzcGFjZV9pZBgCIA'
    'EoCVILd29ya3NwYWNlSWQSHQoKcHJvZmlsZV9pZBgDIAEoCVIJcHJvZmlsZUlkEh8KC2NhcHR1'
    'cmVkX2F0GAQgASgJUgpjYXB0dXJlZEF0Ej4KCGZpbmRpbmdzGAUgAygLMiIubW9kY29uZHVjdG'
    '9yLnYxLkRpYWdub3N0aWNGaW5kaW5nUghmaW5kaW5ncw==');

@$core.Deprecated('Use diagnosticSnapshotReplyDescriptor instead')
const DiagnosticSnapshotReply$json = {
  '1': 'DiagnosticSnapshotReply',
  '2': [
    {
      '1': 'snapshot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticSnapshot',
      '9': 0,
      '10': 'snapshot'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DiagnosticFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DiagnosticSnapshotReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticSnapshotReplyDescriptor = $convert.base64Decode(
    'ChdEaWFnbm9zdGljU25hcHNob3RSZXBseRJBCghzbmFwc2hvdBgBIAEoCzIjLm1vZGNvbmR1Y3'
    'Rvci52MS5EaWFnbm9zdGljU25hcHNob3RIAFIIc25hcHNob3QSOAoFZmF1bHQYAiABKA4yIC5t'
    'b2Rjb25kdWN0b3IudjEuRGlhZ25vc3RpY0ZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use diagnosticPreviewDescriptor instead')
const DiagnosticPreview$json = {
  '1': 'DiagnosticPreview',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'snapshot_id', '3': 2, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'problem_id', '3': 3, '4': 1, '5': 9, '10': 'problemId'},
    {'1': 'expires_at', '3': 4, '4': 1, '5': 9, '10': 'expiresAt'},
    {'1': 'paths', '3': 5, '4': 3, '5': 9, '10': 'paths'},
    {'1': 'result', '3': 6, '4': 1, '5': 9, '10': 'result'},
  ],
};

/// Descriptor for `DiagnosticPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticPreviewDescriptor = $convert.base64Decode(
    'ChFEaWFnbm9zdGljUHJldmlldxIOCgJpZBgBIAEoCVICaWQSHwoLc25hcHNob3RfaWQYAiABKA'
    'lSCnNuYXBzaG90SWQSHQoKcHJvYmxlbV9pZBgDIAEoCVIJcHJvYmxlbUlkEh0KCmV4cGlyZXNf'
    'YXQYBCABKAlSCWV4cGlyZXNBdBIUCgVwYXRocxgFIAMoCVIFcGF0aHMSFgoGcmVzdWx0GAYgAS'
    'gJUgZyZXN1bHQ=');

@$core.Deprecated('Use diagnosticPreviewReplyDescriptor instead')
const DiagnosticPreviewReply$json = {
  '1': 'DiagnosticPreviewReply',
  '2': [
    {
      '1': 'preview',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticPreview',
      '9': 0,
      '10': 'preview'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DiagnosticFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DiagnosticPreviewReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticPreviewReplyDescriptor = $convert.base64Decode(
    'ChZEaWFnbm9zdGljUHJldmlld1JlcGx5Ej4KB3ByZXZpZXcYASABKAsyIi5tb2Rjb25kdWN0b3'
    'IudjEuRGlhZ25vc3RpY1ByZXZpZXdIAFIHcHJldmlldxI4CgVmYXVsdBgCIAEoDjIgLm1vZGNv'
    'bmR1Y3Rvci52MS5EaWFnbm9zdGljRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use diagnosticApplyResultDescriptor instead')
const DiagnosticApplyResult$json = {
  '1': 'DiagnosticApplyResult',
  '2': [
    {'1': 'preview_id', '3': 1, '4': 1, '5': 9, '10': 'previewId'},
    {'1': 'complete', '3': 2, '4': 1, '5': 8, '10': 'complete'},
    {'1': 'result', '3': 3, '4': 1, '5': 9, '10': 'result'},
    {'1': 'detail', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'detail', '17': true},
  ],
  '8': [
    {'1': '_detail'},
  ],
};

/// Descriptor for `DiagnosticApplyResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticApplyResultDescriptor = $convert.base64Decode(
    'ChVEaWFnbm9zdGljQXBwbHlSZXN1bHQSHQoKcHJldmlld19pZBgBIAEoCVIJcHJldmlld0lkEh'
    'oKCGNvbXBsZXRlGAIgASgIUghjb21wbGV0ZRIWCgZyZXN1bHQYAyABKAlSBnJlc3VsdBIbCgZk'
    'ZXRhaWwYBCABKAlIAFIGZGV0YWlsiAEBQgkKB19kZXRhaWw=');

@$core.Deprecated('Use diagnosticApplyReplyDescriptor instead')
const DiagnosticApplyReply$json = {
  '1': 'DiagnosticApplyReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticApplyResult',
      '9': 0,
      '10': 'result'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DiagnosticFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DiagnosticApplyReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticApplyReplyDescriptor = $convert.base64Decode(
    'ChREaWFnbm9zdGljQXBwbHlSZXBseRJACgZyZXN1bHQYASABKAsyJi5tb2Rjb25kdWN0b3Iudj'
    'EuRGlhZ25vc3RpY0FwcGx5UmVzdWx0SABSBnJlc3VsdBI4CgVmYXVsdBgCIAEoDjIgLm1vZGNv'
    'bmR1Y3Rvci52MS5EaWFnbm9zdGljRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use diagnosticSupportReportDescriptor instead')
const DiagnosticSupportReport$json = {
  '1': 'DiagnosticSupportReport',
  '2': [
    {'1': 'file_name', '3': 1, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'content', '3': 2, '4': 1, '5': 12, '10': 'content'},
  ],
};

/// Descriptor for `DiagnosticSupportReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticSupportReportDescriptor =
    $convert.base64Decode(
        'ChdEaWFnbm9zdGljU3VwcG9ydFJlcG9ydBIbCglmaWxlX25hbWUYASABKAlSCGZpbGVOYW1lEh'
        'gKB2NvbnRlbnQYAiABKAxSB2NvbnRlbnQ=');

@$core.Deprecated('Use diagnosticSupportReplyDescriptor instead')
const DiagnosticSupportReply$json = {
  '1': 'DiagnosticSupportReply',
  '2': [
    {
      '1': 'report',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DiagnosticSupportReport',
      '9': 0,
      '10': 'report'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DiagnosticFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DiagnosticSupportReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticSupportReplyDescriptor = $convert.base64Decode(
    'ChZEaWFnbm9zdGljU3VwcG9ydFJlcGx5EkIKBnJlcG9ydBgBIAEoCzIoLm1vZGNvbmR1Y3Rvci'
    '52MS5EaWFnbm9zdGljU3VwcG9ydFJlcG9ydEgAUgZyZXBvcnQSOAoFZmF1bHQYAiABKA4yIC5t'
    'b2Rjb25kdWN0b3IudjEuRGlhZ25vc3RpY0ZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');
