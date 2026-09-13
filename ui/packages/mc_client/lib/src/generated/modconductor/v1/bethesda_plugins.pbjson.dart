// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bethesda_plugins.proto.

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

@$core.Deprecated('Use scanPluginsRequestDescriptor instead')
const ScanPluginsRequest$json = {
  '1': 'ScanPluginsRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `ScanPluginsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanPluginsRequestDescriptor =
    $convert.base64Decode(
        'ChJTY2FuUGx1Z2luc1JlcXVlc3QSHQoKcHJvZmlsZV9pZBgBIAEoCVIJcHJvZmlsZUlk');

@$core.Deprecated('Use readPluginsRequestDescriptor instead')
const ReadPluginsRequest$json = {
  '1': 'ReadPluginsRequest',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
  ],
};

/// Descriptor for `ReadPluginsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readPluginsRequestDescriptor = $convert.base64Decode(
    'ChJSZWFkUGx1Z2luc1JlcXVlc3QSHwoLc25hcHNob3RfaWQYASABKAlSCnNuYXBzaG90SWQ=');

@$core.Deprecated('Use bethesdaPluginSourceDescriptor instead')
const BethesdaPluginSource$json = {
  '1': 'BethesdaPluginSource',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {'1': 'mod_id', '3': 4, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'version_id', '3': 5, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'game_file', '3': 6, '4': 1, '5': 8, '10': 'gameFile'},
  ],
};

/// Descriptor for `BethesdaPluginSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bethesdaPluginSourceDescriptor = $convert.base64Decode(
    'ChRCZXRoZXNkYVBsdWdpblNvdXJjZRISCgRuYW1lGAEgASgJUgRuYW1lEhgKB3ZlcnNpb24YAi'
    'ABKAlSB3ZlcnNpb24SEgoEcGF0aBgDIAEoCVIEcGF0aBIVCgZtb2RfaWQYBCABKAlSBW1vZElk'
    'Eh0KCnZlcnNpb25faWQYBSABKAlSCXZlcnNpb25JZBIbCglnYW1lX2ZpbGUYBiABKAhSCGdhbW'
    'VGaWxl');

@$core.Deprecated('Use bethesdaMasterDescriptor instead')
const BethesdaMaster$json = {
  '1': 'BethesdaMaster',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginSource',
      '10': 'source'
    },
  ],
};

/// Descriptor for `BethesdaMaster`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bethesdaMasterDescriptor = $convert.base64Decode(
    'Cg5CZXRoZXNkYU1hc3RlchISCgRuYW1lGAEgASgJUgRuYW1lEhYKBnN0YXR1cxgCIAEoCVIGc3'
    'RhdHVzEj0KBnNvdXJjZRgDIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS5CZXRoZXNkYVBsdWdpblNv'
    'dXJjZVIGc291cmNl');

@$core.Deprecated('Use bethesdaPluginHeaderDescriptor instead')
const BethesdaPluginHeader$json = {
  '1': 'BethesdaPluginHeader',
  '2': [
    {'1': 'extension', '3': 1, '4': 1, '5': 9, '10': 'extension'},
    {'1': 'flags', '3': 2, '4': 1, '5': 13, '10': 'flags'},
    {'1': 'form_version', '3': 3, '4': 1, '5': 13, '10': 'formVersion'},
    {'1': 'header_version', '3': 4, '4': 1, '5': 2, '10': 'headerVersion'},
    {'1': 'declared_records', '3': 5, '4': 1, '5': 13, '10': 'declaredRecords'},
    {'1': 'localized', '3': 6, '4': 1, '5': 8, '10': 'localized'},
    {'1': 'author', '3': 7, '4': 1, '5': 9, '10': 'author'},
    {'1': 'description', '3': 8, '4': 1, '5': 9, '10': 'description'},
    {'1': 'flag_labels', '3': 9, '4': 1, '5': 9, '10': 'flagLabels'},
  ],
};

/// Descriptor for `BethesdaPluginHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bethesdaPluginHeaderDescriptor = $convert.base64Decode(
    'ChRCZXRoZXNkYVBsdWdpbkhlYWRlchIcCglleHRlbnNpb24YASABKAlSCWV4dGVuc2lvbhIUCg'
    'VmbGFncxgCIAEoDVIFZmxhZ3MSIQoMZm9ybV92ZXJzaW9uGAMgASgNUgtmb3JtVmVyc2lvbhIl'
    'Cg5oZWFkZXJfdmVyc2lvbhgEIAEoAlINaGVhZGVyVmVyc2lvbhIpChBkZWNsYXJlZF9yZWNvcm'
    'RzGAUgASgNUg9kZWNsYXJlZFJlY29yZHMSHAoJbG9jYWxpemVkGAYgASgIUglsb2NhbGl6ZWQS'
    'FgoGYXV0aG9yGAcgASgJUgZhdXRob3ISIAoLZGVzY3JpcHRpb24YCCABKAlSC2Rlc2NyaXB0aW'
    '9uEh8KC2ZsYWdfbGFiZWxzGAkgASgJUgpmbGFnTGFiZWxz');

@$core.Deprecated('Use bethesdaPluginDescriptor instead')
const BethesdaPlugin$json = {
  '1': 'BethesdaPlugin',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {'1': 'problem', '3': 4, '4': 1, '5': 9, '10': 'problem'},
    {'1': 'has_issues', '3': 5, '4': 1, '5': 8, '10': 'hasIssues'},
    {
      '1': 'winner',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginSource',
      '10': 'winner'
    },
    {
      '1': 'alternatives',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginSource',
      '10': 'alternatives'
    },
    {
      '1': 'header',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginHeader',
      '10': 'header'
    },
    {
      '1': 'masters',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BethesdaMaster',
      '10': 'masters'
    },
  ],
};

/// Descriptor for `BethesdaPlugin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bethesdaPluginDescriptor = $convert.base64Decode(
    'Cg5CZXRoZXNkYVBsdWdpbhISCgRuYW1lGAEgASgJUgRuYW1lEhIKBGtpbmQYAiABKAlSBGtpbm'
    'QSFgoGc3RhdHVzGAMgASgJUgZzdGF0dXMSGAoHcHJvYmxlbRgEIAEoCVIHcHJvYmxlbRIdCgpo'
    'YXNfaXNzdWVzGAUgASgIUgloYXNJc3N1ZXMSPQoGd2lubmVyGAYgASgLMiUubW9kY29uZHVjdG'
    '9yLnYxLkJldGhlc2RhUGx1Z2luU291cmNlUgZ3aW5uZXISSQoMYWx0ZXJuYXRpdmVzGAcgAygL'
    'MiUubW9kY29uZHVjdG9yLnYxLkJldGhlc2RhUGx1Z2luU291cmNlUgxhbHRlcm5hdGl2ZXMSPQ'
    'oGaGVhZGVyGAggASgLMiUubW9kY29uZHVjdG9yLnYxLkJldGhlc2RhUGx1Z2luSGVhZGVyUgZo'
    'ZWFkZXISOQoHbWFzdGVycxgJIAMoCzIfLm1vZGNvbmR1Y3Rvci52MS5CZXRoZXNkYU1hc3Rlcl'
    'IHbWFzdGVycw==');

@$core.Deprecated('Use bethesdaPluginSnapshotDescriptor instead')
const BethesdaPluginSnapshot$json = {
  '1': 'BethesdaPluginSnapshot',
  '2': [
    {'1': 'snapshot_id', '3': 1, '4': 1, '5': 9, '10': 'snapshotId'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'observed_at_unix_ms',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'observedAtUnixMs'
    },
    {'1': 'stale', '3': 5, '4': 1, '5': 8, '10': 'stale'},
    {
      '1': 'plugins',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPlugin',
      '10': 'plugins'
    },
    {'1': 'problems', '3': 7, '4': 3, '5': 9, '10': 'problems'},
  ],
};

/// Descriptor for `BethesdaPluginSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bethesdaPluginSnapshotDescriptor = $convert.base64Decode(
    'ChZCZXRoZXNkYVBsdWdpblNuYXBzaG90Eh8KC3NuYXBzaG90X2lkGAEgASgJUgpzbmFwc2hvdE'
    'lkEiEKDHdvcmtzcGFjZV9pZBgCIAEoCVILd29ya3NwYWNlSWQSHQoKcHJvZmlsZV9pZBgDIAEo'
    'CVIJcHJvZmlsZUlkEi0KE29ic2VydmVkX2F0X3VuaXhfbXMYBCABKANSEG9ic2VydmVkQXRVbm'
    'l4TXMSFAoFc3RhbGUYBSABKAhSBXN0YWxlEjkKB3BsdWdpbnMYBiADKAsyHy5tb2Rjb25kdWN0'
    'b3IudjEuQmV0aGVzZGFQbHVnaW5SB3BsdWdpbnMSGgoIcHJvYmxlbXMYByADKAlSCHByb2JsZW'
    '1z');

@$core.Deprecated('Use bethesdaPluginsReplyDescriptor instead')
const BethesdaPluginsReply$json = {
  '1': 'BethesdaPluginsReply',
  '2': [
    {
      '1': 'snapshot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.BethesdaPluginSnapshot',
      '9': 0,
      '10': 'snapshot'
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

/// Descriptor for `BethesdaPluginsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bethesdaPluginsReplyDescriptor = $convert.base64Decode(
    'ChRCZXRoZXNkYVBsdWdpbnNSZXBseRJFCghzbmFwc2hvdBgBIAEoCzInLm1vZGNvbmR1Y3Rvci'
    '52MS5CZXRoZXNkYVBsdWdpblNuYXBzaG90SABSCHNuYXBzaG90EjYKBWZhdWx0GAIgASgLMh4u'
    'bW9kY29uZHVjdG9yLnYxLkZpbGVQbGFuRmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');
