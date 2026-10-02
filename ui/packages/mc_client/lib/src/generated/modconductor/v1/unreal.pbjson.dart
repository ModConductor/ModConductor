// This is a generated file - do not edit.
//
// Generated from modconductor/v1/unreal.proto.

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

@$core.Deprecated('Use unrealLoaderInfoDescriptor instead')
const UnrealLoaderInfo$json = {
  '1': 'UnrealLoaderInfo',
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
    {'1': 'loader_id', '3': 5, '4': 1, '5': 9, '10': 'loaderId'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'subtitle',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'subtitle',
      '17': true
    },
    {'1': 'version', '3': 8, '4': 1, '5': 9, '10': 'version'},
    {'1': 'icon_url', '3': 9, '4': 1, '5': 9, '10': 'iconUrl'},
    {
      '1': 'icon_headers',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.UnrealLoaderInfo.IconHeadersEntry',
      '10': 'iconHeaders'
    },
    {'1': 'mod_id', '3': 11, '4': 1, '5': 9, '9': 1, '10': 'modId', '17': true},
    {'1': 'enabled', '3': 12, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'archive_required', '3': 13, '4': 1, '5': 8, '10': 'archiveRequired'},
    {'1': 'settings_files', '3': 14, '4': 3, '5': 9, '10': 'settingsFiles'},
    {'1': 'log_available', '3': 15, '4': 1, '5': 8, '10': 'logAvailable'},
    {'1': 'declared_version', '3': 16, '4': 1, '5': 9, '10': 'declaredVersion'},
    {
      '1': 'declared_version_label',
      '3': 17,
      '4': 1,
      '5': 9,
      '10': 'declaredVersionLabel'
    },
    {'1': 'declared_source', '3': 18, '4': 1, '5': 9, '10': 'declaredSource'},
    {'1': 'upstream_license', '3': 19, '4': 1, '5': 9, '10': 'upstreamLicense'},
    {
      '1': 'upstream_commit',
      '3': 20,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'upstreamCommit',
      '17': true
    },
  ],
  '3': [UnrealLoaderInfo_IconHeadersEntry$json],
  '8': [
    {'1': '_subtitle'},
    {'1': '_mod_id'},
    {'1': '_upstream_commit'},
  ],
};

@$core.Deprecated('Use unrealLoaderInfoDescriptor instead')
const UnrealLoaderInfo_IconHeadersEntry$json = {
  '1': 'IconHeadersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `UnrealLoaderInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unrealLoaderInfoDescriptor = $convert.base64Decode(
    'ChBVbnJlYWxMb2FkZXJJbmZvEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSHQ'
    'oKcHJvZmlsZV9pZBgCIAEoCVIJcHJvZmlsZUlkEikKEGNvbnRleHRfcmV2aXNpb24YAyABKARS'
    'D2NvbnRleHRSZXZpc2lvbhItChJzZWxlY3Rpb25fcmV2aXNpb24YBCABKARSEXNlbGVjdGlvbl'
    'JldmlzaW9uEhsKCWxvYWRlcl9pZBgFIAEoCVIIbG9hZGVySWQSEgoEbmFtZRgGIAEoCVIEbmFt'
    'ZRIfCghzdWJ0aXRsZRgHIAEoCUgAUghzdWJ0aXRsZYgBARIYCgd2ZXJzaW9uGAggASgJUgd2ZX'
    'JzaW9uEhkKCGljb25fdXJsGAkgASgJUgdpY29uVXJsElUKDGljb25faGVhZGVycxgKIAMoCzIy'
    'Lm1vZGNvbmR1Y3Rvci52MS5VbnJlYWxMb2FkZXJJbmZvLkljb25IZWFkZXJzRW50cnlSC2ljb2'
    '5IZWFkZXJzEhoKBm1vZF9pZBgLIAEoCUgBUgVtb2RJZIgBARIYCgdlbmFibGVkGAwgASgIUgdl'
    'bmFibGVkEikKEGFyY2hpdmVfcmVxdWlyZWQYDSABKAhSD2FyY2hpdmVSZXF1aXJlZBIlCg5zZX'
    'R0aW5nc19maWxlcxgOIAMoCVINc2V0dGluZ3NGaWxlcxIjCg1sb2dfYXZhaWxhYmxlGA8gASgI'
    'Ugxsb2dBdmFpbGFibGUSKQoQZGVjbGFyZWRfdmVyc2lvbhgQIAEoCVIPZGVjbGFyZWRWZXJzaW'
    '9uEjQKFmRlY2xhcmVkX3ZlcnNpb25fbGFiZWwYESABKAlSFGRlY2xhcmVkVmVyc2lvbkxhYmVs'
    'EicKD2RlY2xhcmVkX3NvdXJjZRgSIAEoCVIOZGVjbGFyZWRTb3VyY2USKQoQdXBzdHJlYW1fbG'
    'ljZW5zZRgTIAEoCVIPdXBzdHJlYW1MaWNlbnNlEiwKD3Vwc3RyZWFtX2NvbW1pdBgUIAEoCUgC'
    'Ug51cHN0cmVhbUNvbW1pdIgBARo+ChBJY29uSGVhZGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2'
    'V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCCwoJX3N1YnRpdGxlQgkKB19tb2RfaWRCEgoQ'
    'X3Vwc3RyZWFtX2NvbW1pdA==');

@$core.Deprecated('Use unrealLoaderReplyDescriptor instead')
const UnrealLoaderReply$json = {
  '1': 'UnrealLoaderReply',
  '2': [
    {
      '1': 'loader',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.UnrealLoaderInfo',
      '9': 0,
      '10': 'loader'
    },
    {'1': 'problem', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'problem'},
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `UnrealLoaderReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unrealLoaderReplyDescriptor = $convert.base64Decode(
    'ChFVbnJlYWxMb2FkZXJSZXBseRI7CgZsb2FkZXIYASABKAsyIS5tb2Rjb25kdWN0b3IudjEuVW'
    '5yZWFsTG9hZGVySW5mb0gAUgZsb2FkZXISGgoHcHJvYmxlbRgCIAEoCUgAUgdwcm9ibGVtQggK'
    'BnJlc3VsdA==');

@$core.Deprecated('Use acquireUnrealLoaderRequestDescriptor instead')
const AcquireUnrealLoaderRequest$json = {
  '1': 'AcquireUnrealLoaderRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'context_revision', '3': 3, '4': 1, '5': 4, '10': 'contextRevision'},
    {'1': 'archive_path', '3': 4, '4': 1, '5': 9, '10': 'archivePath'},
  ],
};

/// Descriptor for `AcquireUnrealLoaderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acquireUnrealLoaderRequestDescriptor = $convert.base64Decode(
    'ChpBY3F1aXJlVW5yZWFsTG9hZGVyUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcm'
    'tzcGFjZUlkEh0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBIpChBjb250ZXh0X3Jldmlz'
    'aW9uGAMgASgEUg9jb250ZXh0UmV2aXNpb24SIQoMYXJjaGl2ZV9wYXRoGAQgASgJUgthcmNoaX'
    'ZlUGF0aA==');

@$core.Deprecated('Use unrealAcquisitionProgressDescriptor instead')
const UnrealAcquisitionProgress$json = {
  '1': 'UnrealAcquisitionProgress',
  '2': [
    {'1': 'stage', '3': 1, '4': 1, '5': 9, '10': 'stage'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'total', '3': 3, '4': 1, '5': 4, '9': 0, '10': 'total', '17': true},
    {'1': 'mod_id', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'modId', '17': true},
    {
      '1': 'problem',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'loader',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.UnrealLoaderInfo',
      '10': 'loader'
    },
  ],
  '8': [
    {'1': '_total'},
    {'1': '_mod_id'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `UnrealAcquisitionProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unrealAcquisitionProgressDescriptor = $convert.base64Decode(
    'ChlVbnJlYWxBY3F1aXNpdGlvblByb2dyZXNzEhQKBXN0YWdlGAEgASgJUgVzdGFnZRIUCgVieX'
    'RlcxgCIAEoBFIFYnl0ZXMSGQoFdG90YWwYAyABKARIAFIFdG90YWyIAQESGgoGbW9kX2lkGAQg'
    'ASgJSAFSBW1vZElkiAEBEh0KB3Byb2JsZW0YBSABKAlIAlIHcHJvYmxlbYgBARI5CgZsb2FkZX'
    'IYBiABKAsyIS5tb2Rjb25kdWN0b3IudjEuVW5yZWFsTG9hZGVySW5mb1IGbG9hZGVyQggKBl90'
    'b3RhbEIJCgdfbW9kX2lkQgoKCF9wcm9ibGVt');

@$core.Deprecated('Use unrealTextRequestDescriptor instead')
const UnrealTextRequest$json = {
  '1': 'UnrealTextRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'log', '3': 4, '4': 1, '5': 8, '10': 'log'},
  ],
};

/// Descriptor for `UnrealTextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unrealTextRequestDescriptor = $convert.base64Decode(
    'ChFVbnJlYWxUZXh0UmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEh'
    '0KCnByb2ZpbGVfaWQYAiABKAlSCXByb2ZpbGVJZBISCgRuYW1lGAMgASgJUgRuYW1lEhAKA2xv'
    'ZxgEIAEoCFIDbG9n');

@$core.Deprecated('Use saveUnrealTextRequestDescriptor instead')
const SaveUnrealTextRequest$json = {
  '1': 'SaveUnrealTextRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'original', '3': 4, '4': 1, '5': 12, '10': 'original'},
    {'1': 'content', '3': 5, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `SaveUnrealTextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveUnrealTextRequestDescriptor = $convert.base64Decode(
    'ChVTYXZlVW5yZWFsVGV4dFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBIdCgpwcm9maWxlX2lkGAIgASgJUglwcm9maWxlSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRIa'
    'CghvcmlnaW5hbBgEIAEoDFIIb3JpZ2luYWwSGAoHY29udGVudBgFIAEoCVIHY29udGVudA==');

@$core.Deprecated('Use unrealPageReplyDescriptor instead')
const UnrealPageReply$json = {
  '1': 'UnrealPageReply',
  '2': [
    {'1': 'problem', '3': 1, '4': 1, '5': 9, '10': 'problem'},
  ],
};

/// Descriptor for `UnrealPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unrealPageReplyDescriptor = $convert.base64Decode(
    'Cg9VbnJlYWxQYWdlUmVwbHkSGAoHcHJvYmxlbRgBIAEoCVIHcHJvYmxlbQ==');
