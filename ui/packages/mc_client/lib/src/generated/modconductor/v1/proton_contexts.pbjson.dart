// This is a generated file - do not edit.
//
// Generated from modconductor/v1/proton_contexts.proto.

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

@$core.Deprecated('Use searchProtonContextsRequestDescriptor instead')
const SearchProtonContextsRequest$json = {
  '1': 'SearchProtonContextsRequest',
  '2': [
    {'1': 'definition_id', '3': 1, '4': 1, '5': 9, '10': 'definitionId'},
    {'1': 'game_path', '3': 2, '4': 1, '5': 9, '10': 'gamePath'},
    {'1': 'additional_roots', '3': 3, '4': 3, '5': 9, '10': 'additionalRoots'},
  ],
};

/// Descriptor for `SearchProtonContextsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchProtonContextsRequestDescriptor =
    $convert.base64Decode(
        'ChtTZWFyY2hQcm90b25Db250ZXh0c1JlcXVlc3QSIwoNZGVmaW5pdGlvbl9pZBgBIAEoCVIMZG'
        'VmaW5pdGlvbklkEhsKCWdhbWVfcGF0aBgCIAEoCVIIZ2FtZVBhdGgSKQoQYWRkaXRpb25hbF9y'
        'b290cxgDIAMoCVIPYWRkaXRpb25hbFJvb3Rz');

@$core.Deprecated('Use protonSteamAssociationDescriptor instead')
const ProtonSteamAssociation$json = {
  '1': 'ProtonSteamAssociation',
  '2': [
    {'1': 'steam_root', '3': 1, '4': 1, '5': 9, '10': 'steamRoot'},
    {'1': 'library', '3': 2, '4': 1, '5': 9, '10': 'library'},
  ],
};

/// Descriptor for `ProtonSteamAssociation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonSteamAssociationDescriptor =
    $convert.base64Decode(
        'ChZQcm90b25TdGVhbUFzc29jaWF0aW9uEh0KCnN0ZWFtX3Jvb3QYASABKAlSCXN0ZWFtUm9vdB'
        'IYCgdsaWJyYXJ5GAIgASgJUgdsaWJyYXJ5');

@$core.Deprecated('Use protonSelectionInfoDescriptor instead')
const ProtonSelectionInfo$json = {
  '1': 'ProtonSelectionInfo',
  '2': [
    {'1': 'app_id', '3': 1, '4': 1, '5': 13, '10': 'appId'},
    {'1': 'manual', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'manual'},
    {
      '1': 'steam',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonSteamAssociation',
      '9': 0,
      '10': 'steam'
    },
    {'1': 'compat_data', '3': 4, '4': 1, '5': 9, '10': 'compatData'},
    {
      '1': 'runtime_directory',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'runtimeDirectory'
    },
    {'1': 'tool_id', '3': 6, '4': 1, '5': 9, '10': 'toolId'},
  ],
  '8': [
    {'1': 'association'},
  ],
};

/// Descriptor for `ProtonSelectionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonSelectionInfoDescriptor = $convert.base64Decode(
    'ChNQcm90b25TZWxlY3Rpb25JbmZvEhUKBmFwcF9pZBgBIAEoDVIFYXBwSWQSGAoGbWFudWFsGA'
    'IgASgISABSBm1hbnVhbBI/CgVzdGVhbRgDIAEoCzInLm1vZGNvbmR1Y3Rvci52MS5Qcm90b25T'
    'dGVhbUFzc29jaWF0aW9uSABSBXN0ZWFtEh8KC2NvbXBhdF9kYXRhGAQgASgJUgpjb21wYXREYX'
    'RhEisKEXJ1bnRpbWVfZGlyZWN0b3J5GAUgASgJUhBydW50aW1lRGlyZWN0b3J5EhcKB3Rvb2xf'
    'aWQYBiABKAlSBnRvb2xJZEINCgthc3NvY2lhdGlvbg==');

@$core.Deprecated('Use protonContextFileDescriptor instead')
const ProtonContextFile$json = {
  '1': 'ProtonContextFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'native_identity', '3': 2, '4': 1, '5': 9, '10': 'nativeIdentity'},
    {'1': 'sha256', '3': 3, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `ProtonContextFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonContextFileDescriptor = $convert.base64Decode(
    'ChFQcm90b25Db250ZXh0RmlsZRISCgRwYXRoGAEgASgJUgRwYXRoEicKD25hdGl2ZV9pZGVudG'
    'l0eRgCIAEoCVIObmF0aXZlSWRlbnRpdHkSFgoGc2hhMjU2GAMgASgJUgZzaGEyNTY=');

@$core.Deprecated('Use protonLocatedPathDescriptor instead')
const ProtonLocatedPath$json = {
  '1': 'ProtonLocatedPath',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'exists', '3': 2, '4': 1, '5': 8, '10': 'exists'},
  ],
};

/// Descriptor for `ProtonLocatedPath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonLocatedPathDescriptor = $convert.base64Decode(
    'ChFQcm90b25Mb2NhdGVkUGF0aBISCgRwYXRoGAEgASgJUgRwYXRoEhYKBmV4aXN0cxgCIAEoCF'
    'IGZXhpc3Rz');

@$core.Deprecated('Use protonUserPathDescriptor instead')
const ProtonUserPath$json = {
  '1': 'ProtonUserPath',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'windows_path',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'windowsPath',
      '17': true
    },
    {
      '1': 'located',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonLocatedPath',
      '9': 0,
      '10': 'located'
    },
    {
      '1': 'unavailable_reason',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'unavailableReason'
    },
  ],
  '8': [
    {'1': 'result'},
    {'1': '_windows_path'},
  ],
};

/// Descriptor for `ProtonUserPath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonUserPathDescriptor = $convert.base64Decode(
    'Cg5Qcm90b25Vc2VyUGF0aBISCgRuYW1lGAEgASgJUgRuYW1lEiYKDHdpbmRvd3NfcGF0aBgCIA'
    'EoCUgBUgt3aW5kb3dzUGF0aIgBARI+Cgdsb2NhdGVkGAMgASgLMiIubW9kY29uZHVjdG9yLnYx'
    'LlByb3RvbkxvY2F0ZWRQYXRoSABSB2xvY2F0ZWQSLwoSdW5hdmFpbGFibGVfcmVhc29uGAQgAS'
    'gJSABSEXVuYXZhaWxhYmxlUmVhc29uQggKBnJlc3VsdEIPCg1fd2luZG93c19wYXRo');

@$core.Deprecated('Use protonContextEvidenceDescriptor instead')
const ProtonContextEvidence$json = {
  '1': 'ProtonContextEvidence',
  '2': [
    {
      '1': 'selection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonSelectionInfo',
      '10': 'selection'
    },
    {'1': 'prefix_path', '3': 2, '4': 1, '5': 9, '10': 'prefixPath'},
    {'1': 'prefix_identity', '3': 3, '4': 1, '5': 9, '10': 'prefixIdentity'},
    {
      '1': 'compat_data_identity',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'compatDataIdentity'
    },
    {'1': 'runtime_identity', '3': 5, '4': 1, '5': 9, '10': 'runtimeIdentity'},
    {'1': 'runtime_name', '3': 6, '4': 1, '5': 9, '10': 'runtimeName'},
    {'1': 'runtime_version', '3': 7, '4': 1, '5': 9, '10': 'runtimeVersion'},
    {
      '1': 'prefix_version',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'prefixVersion',
      '17': true
    },
    {
      '1': 'launcher',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonContextFile',
      '10': 'launcher'
    },
    {
      '1': 'metadata',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProtonContextFile',
      '10': 'metadata'
    },
    {
      '1': 'per_game_tool',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'perGameTool',
      '17': true
    },
    {
      '1': 'global_tool',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'globalTool',
      '17': true
    },
    {
      '1': 'paths',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProtonUserPath',
      '10': 'paths'
    },
    {
      '1': 'mapping_problem',
      '3': 14,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'mappingProblem',
      '17': true
    },
  ],
  '8': [
    {'1': '_prefix_version'},
    {'1': '_per_game_tool'},
    {'1': '_global_tool'},
    {'1': '_mapping_problem'},
  ],
};

/// Descriptor for `ProtonContextEvidence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonContextEvidenceDescriptor = $convert.base64Decode(
    'ChVQcm90b25Db250ZXh0RXZpZGVuY2USQgoJc2VsZWN0aW9uGAEgASgLMiQubW9kY29uZHVjdG'
    '9yLnYxLlByb3RvblNlbGVjdGlvbkluZm9SCXNlbGVjdGlvbhIfCgtwcmVmaXhfcGF0aBgCIAEo'
    'CVIKcHJlZml4UGF0aBInCg9wcmVmaXhfaWRlbnRpdHkYAyABKAlSDnByZWZpeElkZW50aXR5Ej'
    'AKFGNvbXBhdF9kYXRhX2lkZW50aXR5GAQgASgJUhJjb21wYXREYXRhSWRlbnRpdHkSKQoQcnVu'
    'dGltZV9pZGVudGl0eRgFIAEoCVIPcnVudGltZUlkZW50aXR5EiEKDHJ1bnRpbWVfbmFtZRgGIA'
    'EoCVILcnVudGltZU5hbWUSJwoPcnVudGltZV92ZXJzaW9uGAcgASgJUg5ydW50aW1lVmVyc2lv'
    'bhIqCg5wcmVmaXhfdmVyc2lvbhgIIAEoCUgAUg1wcmVmaXhWZXJzaW9uiAEBEj4KCGxhdW5jaG'
    'VyGAkgASgLMiIubW9kY29uZHVjdG9yLnYxLlByb3RvbkNvbnRleHRGaWxlUghsYXVuY2hlchI+'
    'CghtZXRhZGF0YRgKIAMoCzIiLm1vZGNvbmR1Y3Rvci52MS5Qcm90b25Db250ZXh0RmlsZVIIbW'
    'V0YWRhdGESJwoNcGVyX2dhbWVfdG9vbBgLIAEoCUgBUgtwZXJHYW1lVG9vbIgBARIkCgtnbG9i'
    'YWxfdG9vbBgMIAEoCUgCUgpnbG9iYWxUb29siAEBEjUKBXBhdGhzGA0gAygLMh8ubW9kY29uZH'
    'VjdG9yLnYxLlByb3RvblVzZXJQYXRoUgVwYXRocxIsCg9tYXBwaW5nX3Byb2JsZW0YDiABKAlI'
    'A1IObWFwcGluZ1Byb2JsZW2IAQFCEQoPX3ByZWZpeF92ZXJzaW9uQhAKDl9wZXJfZ2FtZV90b2'
    '9sQg4KDF9nbG9iYWxfdG9vbEISChBfbWFwcGluZ19wcm9ibGVt');

@$core.Deprecated('Use protonPrefixCandidateDescriptor instead')
const ProtonPrefixCandidate$json = {
  '1': 'ProtonPrefixCandidate',
  '2': [
    {'1': 'candidate_id', '3': 1, '4': 1, '5': 9, '10': 'candidateId'},
    {'1': 'compat_data', '3': 2, '4': 1, '5': 9, '10': 'compatData'},
    {'1': 'prefix_path', '3': 3, '4': 1, '5': 9, '10': 'prefixPath'},
    {
      '1': 'origins',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SteamInstallationOrigin',
      '10': 'origins'
    },
  ],
};

/// Descriptor for `ProtonPrefixCandidate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonPrefixCandidateDescriptor = $convert.base64Decode(
    'ChVQcm90b25QcmVmaXhDYW5kaWRhdGUSIQoMY2FuZGlkYXRlX2lkGAEgASgJUgtjYW5kaWRhdG'
    'VJZBIfCgtjb21wYXRfZGF0YRgCIAEoCVIKY29tcGF0RGF0YRIfCgtwcmVmaXhfcGF0aBgDIAEo'
    'CVIKcHJlZml4UGF0aBJCCgdvcmlnaW5zGAQgAygLMigubW9kY29uZHVjdG9yLnYxLlN0ZWFtSW'
    '5zdGFsbGF0aW9uT3JpZ2luUgdvcmlnaW5z');

@$core.Deprecated('Use protonInstalledToolDescriptor instead')
const ProtonInstalledTool$json = {
  '1': 'ProtonInstalledTool',
  '2': [
    {'1': 'tool_id', '3': 1, '4': 1, '5': 9, '10': 'toolId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'directory', '3': 3, '4': 1, '5': 9, '10': 'directory'},
    {
      '1': 'source',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonContextFile',
      '10': 'source'
    },
  ],
};

/// Descriptor for `ProtonInstalledTool`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonInstalledToolDescriptor = $convert.base64Decode(
    'ChNQcm90b25JbnN0YWxsZWRUb29sEhcKB3Rvb2xfaWQYASABKAlSBnRvb2xJZBISCgRuYW1lGA'
    'IgASgJUgRuYW1lEhwKCWRpcmVjdG9yeRgDIAEoCVIJZGlyZWN0b3J5EjoKBnNvdXJjZRgEIAEo'
    'CzIiLm1vZGNvbmR1Y3Rvci52MS5Qcm90b25Db250ZXh0RmlsZVIGc291cmNl');

@$core.Deprecated('Use protonToolMappingDescriptor instead')
const ProtonToolMapping$json = {
  '1': 'ProtonToolMapping',
  '2': [
    {
      '1': 'per_game',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'perGame',
      '17': true
    },
    {
      '1': 'global_default',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'globalDefault',
      '17': true
    },
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProtonContextFile',
      '10': 'source'
    },
  ],
  '8': [
    {'1': '_per_game'},
    {'1': '_global_default'},
  ],
};

/// Descriptor for `ProtonToolMapping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonToolMappingDescriptor = $convert.base64Decode(
    'ChFQcm90b25Ub29sTWFwcGluZxIeCghwZXJfZ2FtZRgBIAEoCUgAUgdwZXJHYW1liAEBEioKDm'
    'dsb2JhbF9kZWZhdWx0GAIgASgJSAFSDWdsb2JhbERlZmF1bHSIAQESOgoGc291cmNlGAMgASgL'
    'MiIubW9kY29uZHVjdG9yLnYxLlByb3RvbkNvbnRleHRGaWxlUgZzb3VyY2VCCwoJX3Blcl9nYW'
    '1lQhEKD19nbG9iYWxfZGVmYXVsdA==');

@$core.Deprecated('Use protonSearchProblemDescriptor instead')
const ProtonSearchProblem$json = {
  '1': 'ProtonSearchProblem',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `ProtonSearchProblem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonSearchProblemDescriptor = $convert.base64Decode(
    'ChNQcm90b25TZWFyY2hQcm9ibGVtEhIKBHBhdGgYASABKAlSBHBhdGgSFgoGZGV0YWlsGAIgAS'
    'gJUgZkZXRhaWw=');

@$core.Deprecated('Use protonSearchResultDescriptor instead')
const ProtonSearchResult$json = {
  '1': 'ProtonSearchResult',
  '2': [
    {
      '1': 'prefixes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProtonPrefixCandidate',
      '10': 'prefixes'
    },
    {
      '1': 'tools',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProtonInstalledTool',
      '10': 'tools'
    },
    {
      '1': 'mappings',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProtonToolMapping',
      '10': 'mappings'
    },
    {
      '1': 'problems',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ProtonSearchProblem',
      '10': 'problems'
    },
    {'1': 'limited', '3': 5, '4': 1, '5': 8, '10': 'limited'},
  ],
};

/// Descriptor for `ProtonSearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protonSearchResultDescriptor = $convert.base64Decode(
    'ChJQcm90b25TZWFyY2hSZXN1bHQSQgoIcHJlZml4ZXMYASADKAsyJi5tb2Rjb25kdWN0b3Iudj'
    'EuUHJvdG9uUHJlZml4Q2FuZGlkYXRlUghwcmVmaXhlcxI6CgV0b29scxgCIAMoCzIkLm1vZGNv'
    'bmR1Y3Rvci52MS5Qcm90b25JbnN0YWxsZWRUb29sUgV0b29scxI+CghtYXBwaW5ncxgDIAMoCz'
    'IiLm1vZGNvbmR1Y3Rvci52MS5Qcm90b25Ub29sTWFwcGluZ1IIbWFwcGluZ3MSQAoIcHJvYmxl'
    'bXMYBCADKAsyJC5tb2Rjb25kdWN0b3IudjEuUHJvdG9uU2VhcmNoUHJvYmxlbVIIcHJvYmxlbX'
    'MSGAoHbGltaXRlZBgFIAEoCFIHbGltaXRlZA==');
