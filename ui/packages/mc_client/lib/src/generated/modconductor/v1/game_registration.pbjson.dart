// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_registration.proto.

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

@$core.Deprecated('Use listInstalledGamesRequestDescriptor instead')
const ListInstalledGamesRequest$json = {
  '1': 'ListInstalledGamesRequest',
  '2': [
    {'1': 'additional_roots', '3': 1, '4': 3, '5': 9, '10': 'additionalRoots'},
  ],
};

/// Descriptor for `ListInstalledGamesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInstalledGamesRequestDescriptor =
    $convert.base64Decode(
        'ChlMaXN0SW5zdGFsbGVkR2FtZXNSZXF1ZXN0EikKEGFkZGl0aW9uYWxfcm9vdHMYASADKAlSD2'
        'FkZGl0aW9uYWxSb290cw==');

@$core.Deprecated('Use searchThunderstoreGamesRequestDescriptor instead')
const SearchThunderstoreGamesRequest$json = {
  '1': 'SearchThunderstoreGamesRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
  ],
};

/// Descriptor for `SearchThunderstoreGamesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchThunderstoreGamesRequestDescriptor =
    $convert.base64Decode(
        'Ch5TZWFyY2hUaHVuZGVyc3RvcmVHYW1lc1JlcXVlc3QSFAoFcXVlcnkYASABKAlSBXF1ZXJ5');

@$core.Deprecated('Use thunderstoreGameInfoDescriptor instead')
const ThunderstoreGameInfo$json = {
  '1': 'ThunderstoreGameInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'community', '3': 3, '4': 1, '5': 9, '10': 'community'},
    {'1': 'supplies_setup', '3': 4, '4': 1, '5': 8, '10': 'suppliesSetup'},
  ],
};

/// Descriptor for `ThunderstoreGameInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreGameInfoDescriptor = $convert.base64Decode(
    'ChRUaHVuZGVyc3RvcmVHYW1lSW5mbxIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIcCgljb21tdW5pdHkYAyABKAlSCWNvbW11bml0eRIlCg5zdXBwbGllc19zZXR1cBgEIAEo'
    'CFINc3VwcGxpZXNTZXR1cA==');

@$core.Deprecated('Use thunderstoreGamesReplyDescriptor instead')
const ThunderstoreGamesReply$json = {
  '1': 'ThunderstoreGamesReply',
  '2': [
    {
      '1': 'games',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ThunderstoreGameInfo',
      '10': 'games'
    },
    {'1': 'problem', '3': 2, '4': 1, '5': 9, '10': 'problem'},
  ],
};

/// Descriptor for `ThunderstoreGamesReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thunderstoreGamesReplyDescriptor = $convert.base64Decode(
    'ChZUaHVuZGVyc3RvcmVHYW1lc1JlcGx5EjsKBWdhbWVzGAEgAygLMiUubW9kY29uZHVjdG9yLn'
    'YxLlRodW5kZXJzdG9yZUdhbWVJbmZvUgVnYW1lcxIYCgdwcm9ibGVtGAIgASgJUgdwcm9ibGVt');

@$core.Deprecated('Use detectGameRequestDescriptor instead')
const DetectGameRequest$json = {
  '1': 'DetectGameRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'steam_app_id', '3': 3, '4': 1, '5': 13, '10': 'steamAppId'},
    {'1': 'thunderstore_id', '3': 4, '4': 1, '5': 9, '10': 'thunderstoreId'},
  ],
};

/// Descriptor for `DetectGameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detectGameRequestDescriptor = $convert.base64Decode(
    'ChFEZXRlY3RHYW1lUmVxdWVzdBISCgRwYXRoGAEgASgJUgRwYXRoEhIKBG5hbWUYAiABKAlSBG'
    '5hbWUSIAoMc3RlYW1fYXBwX2lkGAMgASgNUgpzdGVhbUFwcElkEicKD3RodW5kZXJzdG9yZV9p'
    'ZBgEIAEoCVIOdGh1bmRlcnN0b3JlSWQ=');

@$core.Deprecated('Use detectGameReplyDescriptor instead')
const DetectGameReply$json = {
  '1': 'DetectGameReply',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CustomGameDraft',
      '10': 'draft'
    },
    {
      '1': 'executable_choices',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'executableChoices'
    },
    {'1': 'problem', '3': 3, '4': 1, '5': 9, '10': 'problem'},
    {'1': 'detected_engine', '3': 4, '4': 1, '5': 9, '10': 'detectedEngine'},
  ],
};

/// Descriptor for `DetectGameReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detectGameReplyDescriptor = $convert.base64Decode(
    'Cg9EZXRlY3RHYW1lUmVwbHkSNgoFZHJhZnQYASABKAsyIC5tb2Rjb25kdWN0b3IudjEuQ3VzdG'
    '9tR2FtZURyYWZ0UgVkcmFmdBItChJleGVjdXRhYmxlX2Nob2ljZXMYAiADKAlSEWV4ZWN1dGFi'
    'bGVDaG9pY2VzEhgKB3Byb2JsZW0YAyABKAlSB3Byb2JsZW0SJwoPZGV0ZWN0ZWRfZW5naW5lGA'
    'QgASgJUg5kZXRlY3RlZEVuZ2luZQ==');

@$core.Deprecated('Use readCustomGameRequestDescriptor instead')
const ReadCustomGameRequest$json = {
  '1': 'ReadCustomGameRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ReadCustomGameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readCustomGameRequestDescriptor = $convert
    .base64Decode('ChVSZWFkQ3VzdG9tR2FtZVJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use saveCustomGameRequestDescriptor instead')
const SaveCustomGameRequest$json = {
  '1': 'SaveCustomGameRequest',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CustomGameDraft',
      '10': 'draft'
    },
  ],
};

/// Descriptor for `SaveCustomGameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveCustomGameRequestDescriptor = $convert.base64Decode(
    'ChVTYXZlQ3VzdG9tR2FtZVJlcXVlc3QSNgoFZHJhZnQYASABKAsyIC5tb2Rjb25kdWN0b3Iudj'
    'EuQ3VzdG9tR2FtZURyYWZ0UgVkcmFmdA==');

@$core.Deprecated('Use customGameReplyDescriptor instead')
const CustomGameReply$json = {
  '1': 'CustomGameReply',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CustomGameDraft',
      '10': 'draft'
    },
    {
      '1': 'game',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.GameDefinitionInfo',
      '10': 'game'
    },
    {'1': 'problem', '3': 3, '4': 1, '5': 9, '10': 'problem'},
  ],
};

/// Descriptor for `CustomGameReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customGameReplyDescriptor = $convert.base64Decode(
    'Cg9DdXN0b21HYW1lUmVwbHkSNgoFZHJhZnQYASABKAsyIC5tb2Rjb25kdWN0b3IudjEuQ3VzdG'
    '9tR2FtZURyYWZ0UgVkcmFmdBI3CgRnYW1lGAIgASgLMiMubW9kY29uZHVjdG9yLnYxLkdhbWVE'
    'ZWZpbml0aW9uSW5mb1IEZ2FtZRIYCgdwcm9ibGVtGAMgASgJUgdwcm9ibGVt');

@$core.Deprecated('Use customGameDraftDescriptor instead')
const CustomGameDraft$json = {
  '1': 'CustomGameDraft',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'revision', '3': 2, '4': 1, '5': 5, '10': 'revision'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'steam_app_id', '3': 4, '4': 1, '5': 13, '10': 'steamAppId'},
    {'1': 'mechanism', '3': 5, '4': 1, '5': 9, '10': 'mechanism'},
    {'1': 'executable', '3': 6, '4': 1, '5': 9, '10': 'executable'},
    {'1': 'linux_executable', '3': 7, '4': 1, '5': 9, '10': 'linuxExecutable'},
    {'1': 'content', '3': 8, '4': 1, '5': 9, '10': 'content'},
    {'1': 'windows_runtime', '3': 9, '4': 1, '5': 9, '10': 'windowsRuntime'},
    {'1': 'linux_runtime', '3': 10, '4': 1, '5': 9, '10': 'linuxRuntime'},
    {'1': 'metadata', '3': 11, '4': 1, '5': 9, '10': 'metadata'},
    {'1': 'unity_metadata', '3': 12, '4': 1, '5': 9, '10': 'unityMetadata'},
    {'1': 'linux_wrapper', '3': 13, '4': 1, '5': 9, '10': 'linuxWrapper'},
    {'1': 'community', '3': 14, '4': 1, '5': 9, '10': 'community'},
    {'1': 'loader_namespace', '3': 15, '4': 1, '5': 9, '10': 'loaderNamespace'},
    {'1': 'loader_package', '3': 16, '4': 1, '5': 9, '10': 'loaderPackage'},
    {'1': 'loader_version', '3': 17, '4': 1, '5': 9, '10': 'loaderVersion'},
    {'1': 'archive_root', '3': 18, '4': 1, '5': 9, '10': 'archiveRoot'},
    {'1': 'loader_page', '3': 19, '4': 1, '5': 9, '10': 'loaderPage'},
    {'1': 'loader_download', '3': 20, '4': 1, '5': 9, '10': 'loaderDownload'},
    {'1': 'loader_license', '3': 21, '4': 1, '5': 9, '10': 'loaderLicense'},
    {'1': 'proxy', '3': 22, '4': 1, '5': 9, '10': 'proxy'},
    {'1': 'core', '3': 23, '4': 1, '5': 9, '10': 'core'},
    {'1': 'mods', '3': 24, '4': 1, '5': 9, '10': 'mods'},
    {'1': 'settings_file', '3': 25, '4': 1, '5': 9, '10': 'settingsFile'},
    {'1': 'log', '3': 26, '4': 1, '5': 9, '10': 'log'},
    {'1': 'game_features', '3': 27, '4': 1, '5': 9, '10': 'gameFeatures'},
    {'1': 'configs', '3': 28, '4': 1, '5': 9, '10': 'configs'},
    {
      '1': 'game_feature_field',
      '3': 29,
      '4': 1,
      '5': 9,
      '10': 'gameFeatureField'
    },
    {'1': 'arguments', '3': 30, '4': 3, '5': 9, '10': 'arguments'},
    {'1': 'excluded', '3': 31, '4': 3, '5': 9, '10': 'excluded'},
  ],
};

/// Descriptor for `CustomGameDraft`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customGameDraftDescriptor = $convert.base64Decode(
    'Cg9DdXN0b21HYW1lRHJhZnQSDgoCaWQYASABKAlSAmlkEhoKCHJldmlzaW9uGAIgASgFUghyZX'
    'Zpc2lvbhISCgRuYW1lGAMgASgJUgRuYW1lEiAKDHN0ZWFtX2FwcF9pZBgEIAEoDVIKc3RlYW1B'
    'cHBJZBIcCgltZWNoYW5pc20YBSABKAlSCW1lY2hhbmlzbRIeCgpleGVjdXRhYmxlGAYgASgJUg'
    'pleGVjdXRhYmxlEikKEGxpbnV4X2V4ZWN1dGFibGUYByABKAlSD2xpbnV4RXhlY3V0YWJsZRIY'
    'Cgdjb250ZW50GAggASgJUgdjb250ZW50EicKD3dpbmRvd3NfcnVudGltZRgJIAEoCVIOd2luZG'
    '93c1J1bnRpbWUSIwoNbGludXhfcnVudGltZRgKIAEoCVIMbGludXhSdW50aW1lEhoKCG1ldGFk'
    'YXRhGAsgASgJUghtZXRhZGF0YRIlCg51bml0eV9tZXRhZGF0YRgMIAEoCVINdW5pdHlNZXRhZG'
    'F0YRIjCg1saW51eF93cmFwcGVyGA0gASgJUgxsaW51eFdyYXBwZXISHAoJY29tbXVuaXR5GA4g'
    'ASgJUgljb21tdW5pdHkSKQoQbG9hZGVyX25hbWVzcGFjZRgPIAEoCVIPbG9hZGVyTmFtZXNwYW'
    'NlEiUKDmxvYWRlcl9wYWNrYWdlGBAgASgJUg1sb2FkZXJQYWNrYWdlEiUKDmxvYWRlcl92ZXJz'
    'aW9uGBEgASgJUg1sb2FkZXJWZXJzaW9uEiEKDGFyY2hpdmVfcm9vdBgSIAEoCVILYXJjaGl2ZV'
    'Jvb3QSHwoLbG9hZGVyX3BhZ2UYEyABKAlSCmxvYWRlclBhZ2USJwoPbG9hZGVyX2Rvd25sb2Fk'
    'GBQgASgJUg5sb2FkZXJEb3dubG9hZBIlCg5sb2FkZXJfbGljZW5zZRgVIAEoCVINbG9hZGVyTG'
    'ljZW5zZRIUCgVwcm94eRgWIAEoCVIFcHJveHkSEgoEY29yZRgXIAEoCVIEY29yZRISCgRtb2Rz'
    'GBggASgJUgRtb2RzEiMKDXNldHRpbmdzX2ZpbGUYGSABKAlSDHNldHRpbmdzRmlsZRIQCgNsb2'
    'cYGiABKAlSA2xvZxIjCg1nYW1lX2ZlYXR1cmVzGBsgASgJUgxnYW1lRmVhdHVyZXMSGAoHY29u'
    'ZmlncxgcIAEoCVIHY29uZmlncxIsChJnYW1lX2ZlYXR1cmVfZmllbGQYHSABKAlSEGdhbWVGZW'
    'F0dXJlRmllbGQSHAoJYXJndW1lbnRzGB4gAygJUglhcmd1bWVudHMSGgoIZXhjbHVkZWQYHyAD'
    'KAlSCGV4Y2x1ZGVk');
