// This is a generated file - do not edit.
//
// Generated from modconductor/v1/desktop.proto.

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

@$core.Deprecated('Use desktopIntentKindDescriptor instead')
const DesktopIntentKind$json = {
  '1': 'DesktopIntentKind',
  '2': [
    {'1': 'DESKTOP_INTENT_KIND_UNSPECIFIED', '2': 0},
    {'1': 'DESKTOP_INTENT_KIND_SHOW', '2': 1},
    {'1': 'DESKTOP_INTENT_KIND_WORKSPACE', '2': 2},
    {'1': 'DESKTOP_INTENT_KIND_ARCHIVE', '2': 3},
    {'1': 'DESKTOP_INTENT_KIND_ARCHIVES', '2': 4},
    {'1': 'DESKTOP_INTENT_KIND_PROFILE', '2': 5},
  ],
};

/// Descriptor for `DesktopIntentKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List desktopIntentKindDescriptor = $convert.base64Decode(
    'ChFEZXNrdG9wSW50ZW50S2luZBIjCh9ERVNLVE9QX0lOVEVOVF9LSU5EX1VOU1BFQ0lGSUVEEA'
    'ASHAoYREVTS1RPUF9JTlRFTlRfS0lORF9TSE9XEAESIQodREVTS1RPUF9JTlRFTlRfS0lORF9X'
    'T1JLU1BBQ0UQAhIfChtERVNLVE9QX0lOVEVOVF9LSU5EX0FSQ0hJVkUQAxIgChxERVNLVE9QX0'
    'lOVEVOVF9LSU5EX0FSQ0hJVkVTEAQSHwobREVTS1RPUF9JTlRFTlRfS0lORF9QUk9GSUxFEAU=');

@$core.Deprecated('Use updateHandoffRequestDescriptor instead')
const UpdateHandoffRequest$json = {
  '1': 'UpdateHandoffRequest',
};

/// Descriptor for `UpdateHandoffRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateHandoffRequestDescriptor =
    $convert.base64Decode('ChRVcGRhdGVIYW5kb2ZmUmVxdWVzdA==');

@$core.Deprecated('Use updateHandoffReplyDescriptor instead')
const UpdateHandoffReply$json = {
  '1': 'UpdateHandoffReply',
  '2': [
    {'1': 'ready', '3': 1, '4': 1, '5': 8, '10': 'ready'},
    {'1': 'problem', '3': 2, '4': 1, '5': 9, '10': 'problem'},
  ],
};

/// Descriptor for `UpdateHandoffReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateHandoffReplyDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVIYW5kb2ZmUmVwbHkSFAoFcmVhZHkYASABKAhSBXJlYWR5EhgKB3Byb2JsZW0YAi'
    'ABKAlSB3Byb2JsZW0=');

@$core.Deprecated('Use resolveDesktopRequestMessageDescriptor instead')
const ResolveDesktopRequestMessage$json = {
  '1': 'ResolveDesktopRequestMessage',
  '2': [
    {'1': 'arguments', '3': 1, '4': 3, '5': 9, '10': 'arguments'},
  ],
};

/// Descriptor for `ResolveDesktopRequestMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolveDesktopRequestMessageDescriptor =
    $convert.base64Decode(
        'ChxSZXNvbHZlRGVza3RvcFJlcXVlc3RNZXNzYWdlEhwKCWFyZ3VtZW50cxgBIAMoCVIJYXJndW'
        '1lbnRz');

@$core.Deprecated('Use desktopIntentDescriptor instead')
const DesktopIntent$json = {
  '1': 'DesktopIntent',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.DesktopIntentKind',
      '10': 'kind'
    },
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'workspace_id', '3': 3, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'length', '3': 4, '4': 1, '5': 4, '10': 'length'},
  ],
};

/// Descriptor for `DesktopIntent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List desktopIntentDescriptor = $convert.base64Decode(
    'Cg1EZXNrdG9wSW50ZW50EjYKBGtpbmQYASABKA4yIi5tb2Rjb25kdWN0b3IudjEuRGVza3RvcE'
    'ludGVudEtpbmRSBGtpbmQSEgoEcGF0aBgCIAEoCVIEcGF0aBIhCgx3b3Jrc3BhY2VfaWQYAyAB'
    'KAlSC3dvcmtzcGFjZUlkEhYKBmxlbmd0aBgEIAEoBFIGbGVuZ3Ro');

@$core.Deprecated('Use desktopRequestReplyDescriptor instead')
const DesktopRequestReply$json = {
  '1': 'DesktopRequestReply',
  '2': [
    {
      '1': 'intent',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.DesktopIntent',
      '9': 0,
      '10': 'intent'
    },
    {'1': 'problem', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'problem'},
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `DesktopRequestReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List desktopRequestReplyDescriptor = $convert.base64Decode(
    'ChNEZXNrdG9wUmVxdWVzdFJlcGx5EjgKBmludGVudBgBIAEoCzIeLm1vZGNvbmR1Y3Rvci52MS'
    '5EZXNrdG9wSW50ZW50SABSBmludGVudBIaCgdwcm9ibGVtGAIgASgJSABSB3Byb2JsZW1CCQoH'
    'b3V0Y29tZQ==');
