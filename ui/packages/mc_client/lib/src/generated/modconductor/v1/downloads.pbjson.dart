// This is a generated file - do not edit.
//
// Generated from modconductor/v1/downloads.proto.

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

@$core.Deprecated('Use downloadCommandDescriptor instead')
const DownloadCommand$json = {
  '1': 'DownloadCommand',
  '2': [
    {'1': 'DOWNLOAD_COMMAND_UNSPECIFIED', '2': 0},
    {'1': 'DOWNLOAD_COMMAND_PAUSE', '2': 1},
    {'1': 'DOWNLOAD_COMMAND_RESUME', '2': 2},
    {'1': 'DOWNLOAD_COMMAND_RESTART', '2': 3},
  ],
};

/// Descriptor for `DownloadCommand`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List downloadCommandDescriptor = $convert.base64Decode(
    'Cg9Eb3dubG9hZENvbW1hbmQSIAocRE9XTkxPQURfQ09NTUFORF9VTlNQRUNJRklFRBAAEhoKFk'
    'RPV05MT0FEX0NPTU1BTkRfUEFVU0UQARIbChdET1dOTE9BRF9DT01NQU5EX1JFU1VNRRACEhwK'
    'GERPV05MT0FEX0NPTU1BTkRfUkVTVEFSVBAD');

@$core.Deprecated('Use downloadStartRequestDescriptor instead')
const DownloadStartRequest$json = {
  '1': 'DownloadStartRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'sources', '3': 4, '4': 3, '5': 9, '10': 'sources'},
    {
      '1': 'expected_length',
      '3': 5,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'expectedLength',
      '17': true
    },
    {
      '1': 'expected_sha256',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'expectedSha256',
      '17': true
    },
  ],
  '8': [
    {'1': '_expected_length'},
    {'1': '_expected_sha256'},
  ],
};

/// Descriptor for `DownloadStartRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadStartRequestDescriptor = $convert.base64Decode(
    'ChREb3dubG9hZFN0YXJ0UmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lkEg4KAmlkGAIgASgJUgJpZBISCgRuYW1lGAMgASgJUgRuYW1lEhgKB3NvdXJjZXMYBCADKAlS'
    'B3NvdXJjZXMSLAoPZXhwZWN0ZWRfbGVuZ3RoGAUgASgESABSDmV4cGVjdGVkTGVuZ3RoiAEBEi'
    'wKD2V4cGVjdGVkX3NoYTI1NhgGIAEoCUgBUg5leHBlY3RlZFNoYTI1NogBAUISChBfZXhwZWN0'
    'ZWRfbGVuZ3RoQhIKEF9leHBlY3RlZF9zaGEyNTY=');

@$core.Deprecated('Use downloadControlRequestDescriptor instead')
const DownloadControlRequest$json = {
  '1': 'DownloadControlRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'command',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DownloadCommand',
      '10': 'command'
    },
  ],
};

/// Descriptor for `DownloadControlRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadControlRequestDescriptor = $convert.base64Decode(
    'ChZEb3dubG9hZENvbnRyb2xSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYW'
    'NlSWQSDgoCaWQYAiABKAlSAmlkEjoKB2NvbW1hbmQYAyABKA4yIC5tb2Rjb25kdWN0b3IudjEu'
    'RG93bmxvYWRDb21tYW5kUgdjb21tYW5k');

@$core.Deprecated('Use downloadWatchRequestDescriptor instead')
const DownloadWatchRequest$json = {
  '1': 'DownloadWatchRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'ids', '3': 2, '4': 3, '5': 9, '10': 'ids'},
  ],
};

/// Descriptor for `DownloadWatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadWatchRequestDescriptor = $convert.base64Decode(
    'ChREb3dubG9hZFdhdGNoUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lkEhAKA2lkcxgCIAMoCVIDaWRz');
