// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bepinex.proto.

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

@$core.Deprecated('Use loaderRequestDescriptor instead')
const LoaderRequest$json = {
  '1': 'LoaderRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `LoaderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loaderRequestDescriptor = $convert.base64Decode(
    'Cg1Mb2FkZXJSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSHQoKcH'
    'JvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use changeLoaderRequestDescriptor instead')
const ChangeLoaderRequest$json = {
  '1': 'ChangeLoaderRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'context_revision', '3': 3, '4': 1, '5': 4, '10': 'contextRevision'},
    {
      '1': 'selection_revision',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'selectionRevision'
    },
    {'1': 'enabled', '3': 5, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `ChangeLoaderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeLoaderRequestDescriptor = $convert.base64Decode(
    'ChNDaGFuZ2VMb2FkZXJSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSW'
    'QSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEikKEGNvbnRleHRfcmV2aXNpb24YAyAB'
    'KARSD2NvbnRleHRSZXZpc2lvbhItChJzZWxlY3Rpb25fcmV2aXNpb24YBCABKARSEXNlbGVjdG'
    'lvblJldmlzaW9uEhgKB2VuYWJsZWQYBSABKAhSB2VuYWJsZWQ=');

@$core.Deprecated('Use loaderInfoDescriptor instead')
const LoaderInfo$json = {
  '1': 'LoaderInfo',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'context_revision', '3': 3, '4': 1, '5': 4, '10': 'contextRevision'},
    {
      '1': 'selection_revision',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'selectionRevision'
    },
    {
      '1': 'package',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreVersionReference',
      '10': 'package'
    },
    {'1': 'mod_id', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'modId', '17': true},
    {'1': 'enabled', '3': 7, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'settings_available',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'settingsAvailable'
    },
    {'1': 'log_available', '3': 9, '4': 1, '5': 8, '10': 'logAvailable'},
  ],
  '8': [
    {'1': '_mod_id'},
  ],
};

/// Descriptor for `LoaderInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loaderInfoDescriptor = $convert.base64Decode(
    'CgpMb2FkZXJJbmZvEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSHQoKcHJvZm'
    'lsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEikKEGNvbnRleHRfcmV2aXNpb24YAyABKARSD2NvbnRl'
    'eHRSZXZpc2lvbhItChJzZWxlY3Rpb25fcmV2aXNpb24YBCABKARSEXNlbGVjdGlvblJldmlzaW'
    '9uEkcKB3BhY2thZ2UYBSABKAsyLS5tb2Rjb25kdWN0b3IudjEuVGh1bmRlcnN0b3JlVmVyc2lv'
    'blJlZmVyZW5jZVIHcGFja2FnZRIaCgZtb2RfaWQYBiABKAlIAFIFbW9kSWSIAQESGAoHZW5hYm'
    'xlZBgHIAEoCFIHZW5hYmxlZBItChJzZXR0aW5nc19hdmFpbGFibGUYCCABKAhSEXNldHRpbmdz'
    'QXZhaWxhYmxlEiMKDWxvZ19hdmFpbGFibGUYCSABKAhSDGxvZ0F2YWlsYWJsZUIJCgdfbW9kX2'
    'lk');

@$core.Deprecated('Use loaderReplyDescriptor instead')
const LoaderReply$json = {
  '1': 'LoaderReply',
  '2': [
    {
      '1': 'loader',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LoaderInfo',
      '9': 0,
      '10': 'loader'
    },
    {'1': 'problem', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'problem'},
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `LoaderReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loaderReplyDescriptor = $convert.base64Decode(
    'CgtMb2FkZXJSZXBseRI1CgZsb2FkZXIYASABKAsyGy5tb2Rjb25kdWN0b3IudjEuTG9hZGVySW'
    '5mb0gAUgZsb2FkZXISGgoHcHJvYmxlbRgCIAEoCUgAUgdwcm9ibGVtQggKBnJlc3VsdA==');

@$core.Deprecated('Use loaderTextDescriptor instead')
const LoaderText$json = {
  '1': 'LoaderText',
  '2': [
    {
      '1': 'document',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.TextDocument',
      '10': 'document'
    },
    {'1': 'original', '3': 2, '4': 1, '5': 12, '10': 'original'},
  ],
};

/// Descriptor for `LoaderText`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loaderTextDescriptor = $convert.base64Decode(
    'CgpMb2FkZXJUZXh0EjkKCGRvY3VtZW50GAEgASgLMh0ubW9kY29uZHVjdG9yLnYxLlRleHREb2'
    'N1bWVudFIIZG9jdW1lbnQSGgoIb3JpZ2luYWwYAiABKAxSCG9yaWdpbmFs');

@$core.Deprecated('Use loaderTextReplyDescriptor instead')
const LoaderTextReply$json = {
  '1': 'LoaderTextReply',
  '2': [
    {
      '1': 'text',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.LoaderText',
      '9': 0,
      '10': 'text'
    },
    {'1': 'problem', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'problem'},
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `LoaderTextReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loaderTextReplyDescriptor = $convert.base64Decode(
    'Cg9Mb2FkZXJUZXh0UmVwbHkSMQoEdGV4dBgBIAEoCzIbLm1vZGNvbmR1Y3Rvci52MS5Mb2FkZX'
    'JUZXh0SABSBHRleHQSGgoHcHJvYmxlbRgCIAEoCUgAUgdwcm9ibGVtQggKBnJlc3VsdA==');

@$core.Deprecated('Use saveLoaderSettingsRequestDescriptor instead')
const SaveLoaderSettingsRequest$json = {
  '1': 'SaveLoaderSettingsRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'original', '3': 3, '4': 1, '5': 12, '10': 'original'},
    {'1': 'content', '3': 4, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `SaveLoaderSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveLoaderSettingsRequestDescriptor = $convert.base64Decode(
    'ChlTYXZlTG9hZGVyU2V0dGluZ3NSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3'
    'NwYWNlSWQSHQoKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEhoKCG9yaWdpbmFsGAMgASgM'
    'UghvcmlnaW5hbBIYCgdjb250ZW50GAQgASgJUgdjb250ZW50');
