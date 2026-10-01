// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_catalogue.proto.

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

@$core.Deprecated('Use readGameCatalogueRequestDescriptor instead')
const ReadGameCatalogueRequest$json = {
  '1': 'ReadGameCatalogueRequest',
};

/// Descriptor for `ReadGameCatalogueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readGameCatalogueRequestDescriptor =
    $convert.base64Decode('ChhSZWFkR2FtZUNhdGFsb2d1ZVJlcXVlc3Q=');

@$core.Deprecated('Use gameCatalogueReplyDescriptor instead')
const GameCatalogueReply$json = {
  '1': 'GameCatalogueReply',
  '2': [
    {
      '1': 'games',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.GameDefinitionInfo',
      '10': 'games'
    },
  ],
};

/// Descriptor for `GameCatalogueReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gameCatalogueReplyDescriptor = $convert.base64Decode(
    'ChJHYW1lQ2F0YWxvZ3VlUmVwbHkSOQoFZ2FtZXMYASADKAsyIy5tb2Rjb25kdWN0b3IudjEuR2'
    'FtZURlZmluaXRpb25JbmZvUgVnYW1lcw==');

@$core.Deprecated('Use openScriptExtenderPageRequestDescriptor instead')
const OpenScriptExtenderPageRequest$json = {
  '1': 'OpenScriptExtenderPageRequest',
  '2': [
    {'1': 'game_id', '3': 1, '4': 1, '5': 9, '10': 'gameId'},
  ],
};

/// Descriptor for `OpenScriptExtenderPageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openScriptExtenderPageRequestDescriptor =
    $convert.base64Decode(
        'Ch1PcGVuU2NyaXB0RXh0ZW5kZXJQYWdlUmVxdWVzdBIXCgdnYW1lX2lkGAEgASgJUgZnYW1lSW'
        'Q=');

@$core.Deprecated('Use openScriptExtenderPageReplyDescriptor instead')
const OpenScriptExtenderPageReply$json = {
  '1': 'OpenScriptExtenderPageReply',
  '2': [
    {'1': 'problem', '3': 1, '4': 1, '5': 9, '10': 'problem'},
  ],
};

/// Descriptor for `OpenScriptExtenderPageReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openScriptExtenderPageReplyDescriptor =
    $convert.base64Decode(
        'ChtPcGVuU2NyaXB0RXh0ZW5kZXJQYWdlUmVwbHkSGAoHcHJvYmxlbRgBIAEoCVIHcHJvYmxlbQ'
        '==');
