// This is a generated file - do not edit.
//
// Generated from modconductor/v1/download_models.proto.

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

@$core.Deprecated('Use downloadPhaseDescriptor instead')
const DownloadPhase$json = {
  '1': 'DownloadPhase',
  '2': [
    {'1': 'DOWNLOAD_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'DOWNLOAD_PHASE_QUEUED', '2': 1},
    {'1': 'DOWNLOAD_PHASE_RUNNING', '2': 2},
    {'1': 'DOWNLOAD_PHASE_WAITING', '2': 3},
    {'1': 'DOWNLOAD_PHASE_PAUSED', '2': 4},
    {'1': 'DOWNLOAD_PHASE_FAILED', '2': 5},
    {'1': 'DOWNLOAD_PHASE_COMPLETE', '2': 6},
  ],
};

/// Descriptor for `DownloadPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List downloadPhaseDescriptor = $convert.base64Decode(
    'Cg1Eb3dubG9hZFBoYXNlEh4KGkRPV05MT0FEX1BIQVNFX1VOU1BFQ0lGSUVEEAASGQoVRE9XTk'
    'xPQURfUEhBU0VfUVVFVUVEEAESGgoWRE9XTkxPQURfUEhBU0VfUlVOTklORxACEhoKFkRPV05M'
    'T0FEX1BIQVNFX1dBSVRJTkcQAxIZChVET1dOTE9BRF9QSEFTRV9QQVVTRUQQBBIZChVET1dOTE'
    '9BRF9QSEFTRV9GQUlMRUQQBRIbChdET1dOTE9BRF9QSEFTRV9DT01QTEVURRAG');

@$core.Deprecated('Use archiveDownloadDescriptor instead')
const ArchiveDownload$json = {
  '1': 'ArchiveDownload',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DownloadPhase',
      '10': 'phase'
    },
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'total', '3': 3, '4': 1, '5': 4, '9': 0, '10': 'total', '17': true},
    {'1': 'source', '3': 4, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'expected_sha256',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'expectedSha256',
      '17': true
    },
    {'1': 'checksum_matched', '3': 6, '4': 1, '5': 8, '10': 'checksumMatched'},
    {'1': 'restart_required', '3': 7, '4': 1, '5': 8, '10': 'restartRequired'},
    {
      '1': 'retry_at_unix_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'retryAtUnixMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_total'},
    {'1': '_expected_sha256'},
    {'1': '_retry_at_unix_ms'},
  ],
};

/// Descriptor for `ArchiveDownload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archiveDownloadDescriptor = $convert.base64Decode(
    'Cg9BcmNoaXZlRG93bmxvYWQSNAoFcGhhc2UYASABKA4yHi5tb2Rjb25kdWN0b3IudjEuRG93bm'
    'xvYWRQaGFzZVIFcGhhc2USFAoFYnl0ZXMYAiABKARSBWJ5dGVzEhkKBXRvdGFsGAMgASgESABS'
    'BXRvdGFsiAEBEhYKBnNvdXJjZRgEIAEoCVIGc291cmNlEiwKD2V4cGVjdGVkX3NoYTI1NhgFIA'
    'EoCUgBUg5leHBlY3RlZFNoYTI1NogBARIpChBjaGVja3N1bV9tYXRjaGVkGAYgASgIUg9jaGVj'
    'a3N1bU1hdGNoZWQSKQoQcmVzdGFydF9yZXF1aXJlZBgHIAEoCFIPcmVzdGFydFJlcXVpcmVkEi'
    'wKEHJldHJ5X2F0X3VuaXhfbXMYCCABKANIAlINcmV0cnlBdFVuaXhNc4gBAUIICgZfdG90YWxC'
    'EgoQX2V4cGVjdGVkX3NoYTI1NkITChFfcmV0cnlfYXRfdW5peF9tcw==');
