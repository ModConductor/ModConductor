// This is a generated file - do not edit.
//
// Generated from modconductor/v1/steam_discovery.proto.

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

@$core.Deprecated('Use steamDiscoveryProblemDescriptor instead')
const SteamDiscoveryProblem$json = {
  '1': 'SteamDiscoveryProblem',
  '2': [
    {'1': 'STEAM_DISCOVERY_PROBLEM_UNSPECIFIED', '2': 0},
    {'1': 'STEAM_DISCOVERY_PROBLEM_ROOT_UNAVAILABLE', '2': 1},
    {'1': 'STEAM_DISCOVERY_PROBLEM_LIBRARIES_UNREADABLE', '2': 2},
    {'1': 'STEAM_DISCOVERY_PROBLEM_LIBRARIES_MALFORMED', '2': 3},
    {'1': 'STEAM_DISCOVERY_PROBLEM_LIBRARY_PATH_INVALID', '2': 4},
    {'1': 'STEAM_DISCOVERY_PROBLEM_MANIFEST_UNREADABLE', '2': 5},
    {'1': 'STEAM_DISCOVERY_PROBLEM_MANIFEST_MALFORMED', '2': 6},
    {'1': 'STEAM_DISCOVERY_PROBLEM_STALE_ENTRY', '2': 7},
    {'1': 'STEAM_DISCOVERY_PROBLEM_APP_ID_MISMATCH', '2': 8},
    {'1': 'STEAM_DISCOVERY_PROBLEM_UNSAFE_INSTALL_DIRECTORY', '2': 9},
    {'1': 'STEAM_DISCOVERY_PROBLEM_INSTALLATION_UNAVAILABLE', '2': 10},
    {'1': 'STEAM_DISCOVERY_PROBLEM_LIMIT_REACHED', '2': 11},
  ],
};

/// Descriptor for `SteamDiscoveryProblem`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List steamDiscoveryProblemDescriptor = $convert.base64Decode(
    'ChVTdGVhbURpc2NvdmVyeVByb2JsZW0SJwojU1RFQU1fRElTQ09WRVJZX1BST0JMRU1fVU5TUE'
    'VDSUZJRUQQABIsCihTVEVBTV9ESVNDT1ZFUllfUFJPQkxFTV9ST09UX1VOQVZBSUxBQkxFEAES'
    'MAosU1RFQU1fRElTQ09WRVJZX1BST0JMRU1fTElCUkFSSUVTX1VOUkVBREFCTEUQAhIvCitTVE'
    'VBTV9ESVNDT1ZFUllfUFJPQkxFTV9MSUJSQVJJRVNfTUFMRk9STUVEEAMSMAosU1RFQU1fRElT'
    'Q09WRVJZX1BST0JMRU1fTElCUkFSWV9QQVRIX0lOVkFMSUQQBBIvCitTVEVBTV9ESVNDT1ZFUl'
    'lfUFJPQkxFTV9NQU5JRkVTVF9VTlJFQURBQkxFEAUSLgoqU1RFQU1fRElTQ09WRVJZX1BST0JM'
    'RU1fTUFOSUZFU1RfTUFMRk9STUVEEAYSJwojU1RFQU1fRElTQ09WRVJZX1BST0JMRU1fU1RBTE'
    'VfRU5UUlkQBxIrCidTVEVBTV9ESVNDT1ZFUllfUFJPQkxFTV9BUFBfSURfTUlTTUFUQ0gQCBI0'
    'CjBTVEVBTV9ESVNDT1ZFUllfUFJPQkxFTV9VTlNBRkVfSU5TVEFMTF9ESVJFQ1RPUlkQCRI0Cj'
    'BTVEVBTV9ESVNDT1ZFUllfUFJPQkxFTV9JTlNUQUxMQVRJT05fVU5BVkFJTEFCTEUQChIpCiVT'
    'VEVBTV9ESVNDT1ZFUllfUFJPQkxFTV9MSU1JVF9SRUFDSEVEEAs=');

@$core.Deprecated('Use steamSearchRequestDescriptor instead')
const SteamSearchRequest$json = {
  '1': 'SteamSearchRequest',
  '2': [
    {'1': 'definition_id', '3': 1, '4': 1, '5': 9, '10': 'definitionId'},
    {'1': 'additional_roots', '3': 2, '4': 3, '5': 9, '10': 'additionalRoots'},
  ],
};

/// Descriptor for `SteamSearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamSearchRequestDescriptor = $convert.base64Decode(
    'ChJTdGVhbVNlYXJjaFJlcXVlc3QSIwoNZGVmaW5pdGlvbl9pZBgBIAEoCVIMZGVmaW5pdGlvbk'
    'lkEikKEGFkZGl0aW9uYWxfcm9vdHMYAiADKAlSD2FkZGl0aW9uYWxSb290cw==');

@$core.Deprecated('Use steamSearchRootDescriptor instead')
const SteamSearchRoot$json = {
  '1': 'SteamSearchRoot',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'origin', '3': 2, '4': 1, '5': 9, '10': 'origin'},
  ],
};

/// Descriptor for `SteamSearchRoot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamSearchRootDescriptor = $convert.base64Decode(
    'Cg9TdGVhbVNlYXJjaFJvb3QSEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZvcmlnaW4YAiABKAlSBm'
    '9yaWdpbg==');

@$core.Deprecated('Use steamDirectoryDescriptor instead')
const SteamDirectory$json = {
  '1': 'SteamDirectory',
  '2': [
    {'1': 'declared_path', '3': 1, '4': 1, '5': 9, '10': 'declaredPath'},
    {'1': 'canonical_path', '3': 2, '4': 1, '5': 9, '10': 'canonicalPath'},
    {
      '1': 'native_identity',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nativeIdentity',
      '17': true
    },
  ],
  '8': [
    {'1': '_native_identity'},
  ],
};

/// Descriptor for `SteamDirectory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamDirectoryDescriptor = $convert.base64Decode(
    'Cg5TdGVhbURpcmVjdG9yeRIjCg1kZWNsYXJlZF9wYXRoGAEgASgJUgxkZWNsYXJlZFBhdGgSJQ'
    'oOY2Fub25pY2FsX3BhdGgYAiABKAlSDWNhbm9uaWNhbFBhdGgSLAoPbmF0aXZlX2lkZW50aXR5'
    'GAMgASgJSABSDm5hdGl2ZUlkZW50aXR5iAEBQhIKEF9uYXRpdmVfaWRlbnRpdHk=');

@$core.Deprecated('Use steamManifestEvidenceDescriptor instead')
const SteamManifestEvidence$json = {
  '1': 'SteamManifestEvidence',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'native_identity', '3': 2, '4': 1, '5': 9, '10': 'nativeIdentity'},
    {'1': 'sha256', '3': 3, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'app_id', '3': 4, '4': 1, '5': 13, '10': 'appId'},
    {
      '1': 'install_directory',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'installDirectory'
    },
    {'1': 'name', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'build_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'buildId',
      '17': true
    },
    {
      '1': 'state_flags',
      '3': 8,
      '4': 1,
      '5': 4,
      '9': 2,
      '10': 'stateFlags',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_build_id'},
    {'1': '_state_flags'},
  ],
};

/// Descriptor for `SteamManifestEvidence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamManifestEvidenceDescriptor = $convert.base64Decode(
    'ChVTdGVhbU1hbmlmZXN0RXZpZGVuY2USEgoEcGF0aBgBIAEoCVIEcGF0aBInCg9uYXRpdmVfaW'
    'RlbnRpdHkYAiABKAlSDm5hdGl2ZUlkZW50aXR5EhYKBnNoYTI1NhgDIAEoCVIGc2hhMjU2EhUK'
    'BmFwcF9pZBgEIAEoDVIFYXBwSWQSKwoRaW5zdGFsbF9kaXJlY3RvcnkYBSABKAlSEGluc3RhbG'
    'xEaXJlY3RvcnkSFwoEbmFtZRgGIAEoCUgAUgRuYW1liAEBEh4KCGJ1aWxkX2lkGAcgASgJSAFS'
    'B2J1aWxkSWSIAQESJAoLc3RhdGVfZmxhZ3MYCCABKARIAlIKc3RhdGVGbGFnc4gBAUIHCgVfbm'
    'FtZUILCglfYnVpbGRfaWRCDgoMX3N0YXRlX2ZsYWdz');

@$core.Deprecated('Use steamInstallationOriginDescriptor instead')
const SteamInstallationOrigin$json = {
  '1': 'SteamInstallationOrigin',
  '2': [
    {
      '1': 'root',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SteamSearchRoot',
      '10': 'root'
    },
    {
      '1': 'steam_root',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SteamDirectory',
      '10': 'steamRoot'
    },
    {
      '1': 'library',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SteamDirectory',
      '10': 'library'
    },
    {
      '1': 'library_entry',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'libraryEntry',
      '17': true
    },
    {
      '1': 'manifest',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SteamManifestEvidence',
      '10': 'manifest'
    },
  ],
  '8': [
    {'1': '_library_entry'},
  ],
};

/// Descriptor for `SteamInstallationOrigin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamInstallationOriginDescriptor = $convert.base64Decode(
    'ChdTdGVhbUluc3RhbGxhdGlvbk9yaWdpbhI0CgRyb290GAEgASgLMiAubW9kY29uZHVjdG9yLn'
    'YxLlN0ZWFtU2VhcmNoUm9vdFIEcm9vdBI+CgpzdGVhbV9yb290GAIgASgLMh8ubW9kY29uZHVj'
    'dG9yLnYxLlN0ZWFtRGlyZWN0b3J5UglzdGVhbVJvb3QSOQoHbGlicmFyeRgDIAEoCzIfLm1vZG'
    'NvbmR1Y3Rvci52MS5TdGVhbURpcmVjdG9yeVIHbGlicmFyeRIoCg1saWJyYXJ5X2VudHJ5GAQg'
    'ASgJSABSDGxpYnJhcnlFbnRyeYgBARJCCghtYW5pZmVzdBgFIAEoCzImLm1vZGNvbmR1Y3Rvci'
    '52MS5TdGVhbU1hbmlmZXN0RXZpZGVuY2VSCG1hbmlmZXN0QhAKDl9saWJyYXJ5X2VudHJ5');

@$core.Deprecated('Use steamInstallationCandidateDescriptor instead')
const SteamInstallationCandidate$json = {
  '1': 'SteamInstallationCandidate',
  '2': [
    {'1': 'candidate_id', '3': 1, '4': 1, '5': 9, '10': 'candidateId'},
    {
      '1': 'directory',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SteamDirectory',
      '10': 'directory'
    },
    {
      '1': 'origins',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SteamInstallationOrigin',
      '10': 'origins'
    },
  ],
};

/// Descriptor for `SteamInstallationCandidate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamInstallationCandidateDescriptor = $convert.base64Decode(
    'ChpTdGVhbUluc3RhbGxhdGlvbkNhbmRpZGF0ZRIhCgxjYW5kaWRhdGVfaWQYASABKAlSC2Nhbm'
    'RpZGF0ZUlkEj0KCWRpcmVjdG9yeRgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5TdGVhbURpcmVj'
    'dG9yeVIJZGlyZWN0b3J5EkIKB29yaWdpbnMYAyADKAsyKC5tb2Rjb25kdWN0b3IudjEuU3RlYW'
    '1JbnN0YWxsYXRpb25PcmlnaW5SB29yaWdpbnM=');

@$core.Deprecated('Use steamSearchDiagnosticDescriptor instead')
const SteamSearchDiagnostic$json = {
  '1': 'SteamSearchDiagnostic',
  '2': [
    {'1': 'root_path', '3': 1, '4': 1, '5': 9, '10': 'rootPath'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SteamDiscoveryProblem',
      '10': 'kind'
    },
    {'1': 'detail', '3': 4, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `SteamSearchDiagnostic`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamSearchDiagnosticDescriptor = $convert.base64Decode(
    'ChVTdGVhbVNlYXJjaERpYWdub3N0aWMSGwoJcm9vdF9wYXRoGAEgASgJUghyb290UGF0aBISCg'
    'RwYXRoGAIgASgJUgRwYXRoEjoKBGtpbmQYAyABKA4yJi5tb2Rjb25kdWN0b3IudjEuU3RlYW1E'
    'aXNjb3ZlcnlQcm9ibGVtUgRraW5kEhYKBmRldGFpbBgEIAEoCVIGZGV0YWls');

@$core.Deprecated('Use steamSearchResultDescriptor instead')
const SteamSearchResult$json = {
  '1': 'SteamSearchResult',
  '2': [
    {'1': 'app_id', '3': 1, '4': 1, '5': 13, '10': 'appId'},
    {
      '1': 'roots',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SteamSearchRoot',
      '10': 'roots'
    },
    {
      '1': 'candidates',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SteamInstallationCandidate',
      '10': 'candidates'
    },
    {
      '1': 'diagnostics',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.SteamSearchDiagnostic',
      '10': 'diagnostics'
    },
    {'1': 'limited', '3': 5, '4': 1, '5': 8, '10': 'limited'},
  ],
};

/// Descriptor for `SteamSearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List steamSearchResultDescriptor = $convert.base64Decode(
    'ChFTdGVhbVNlYXJjaFJlc3VsdBIVCgZhcHBfaWQYASABKA1SBWFwcElkEjYKBXJvb3RzGAIgAy'
    'gLMiAubW9kY29uZHVjdG9yLnYxLlN0ZWFtU2VhcmNoUm9vdFIFcm9vdHMSSwoKY2FuZGlkYXRl'
    'cxgDIAMoCzIrLm1vZGNvbmR1Y3Rvci52MS5TdGVhbUluc3RhbGxhdGlvbkNhbmRpZGF0ZVIKY2'
    'FuZGlkYXRlcxJICgtkaWFnbm9zdGljcxgEIAMoCzImLm1vZGNvbmR1Y3Rvci52MS5TdGVhbVNl'
    'YXJjaERpYWdub3N0aWNSC2RpYWdub3N0aWNzEhgKB2xpbWl0ZWQYBSABKAhSB2xpbWl0ZWQ=');
