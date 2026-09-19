// This is a generated file - do not edit.
//
// Generated from modconductor/v1/migration.proto.

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

@$core.Deprecated('Use migrationManagerDescriptor instead')
const MigrationManager$json = {
  '1': 'MigrationManager',
  '2': [
    {'1': 'MIGRATION_MANAGER_UNSPECIFIED', '2': 0},
    {'1': 'MIGRATION_MANAGER_MOD_ORGANIZER', '2': 1},
    {'1': 'MIGRATION_MANAGER_VORTEX', '2': 2},
  ],
};

/// Descriptor for `MigrationManager`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List migrationManagerDescriptor = $convert.base64Decode(
    'ChBNaWdyYXRpb25NYW5hZ2VyEiEKHU1JR1JBVElPTl9NQU5BR0VSX1VOU1BFQ0lGSUVEEAASIw'
    'ofTUlHUkFUSU9OX01BTkFHRVJfTU9EX09SR0FOSVpFUhABEhwKGE1JR1JBVElPTl9NQU5BR0VS'
    'X1ZPUlRFWBAC');

@$core.Deprecated('Use migrationErrorCodeDescriptor instead')
const MigrationErrorCode$json = {
  '1': 'MigrationErrorCode',
  '2': [
    {'1': 'MIGRATION_ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'MIGRATION_ERROR_CODE_INVALID_SOURCE', '2': 1},
    {'1': 'MIGRATION_ERROR_CODE_TARGET_NOT_EMPTY', '2': 2},
    {'1': 'MIGRATION_ERROR_CODE_UNSAFE_SOURCE', '2': 3},
    {'1': 'MIGRATION_ERROR_CODE_CASE_COLLISION', '2': 4},
    {'1': 'MIGRATION_ERROR_CODE_UNSUPPORTED_DATA', '2': 5},
    {'1': 'MIGRATION_ERROR_CODE_SOURCE_CHANGED', '2': 6},
    {'1': 'MIGRATION_ERROR_CODE_CANCELLED', '2': 7},
    {'1': 'MIGRATION_ERROR_CODE_BUSY', '2': 8},
    {'1': 'MIGRATION_ERROR_CODE_UNAVAILABLE', '2': 9},
  ],
};

/// Descriptor for `MigrationErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List migrationErrorCodeDescriptor = $convert.base64Decode(
    'ChJNaWdyYXRpb25FcnJvckNvZGUSJAogTUlHUkFUSU9OX0VSUk9SX0NPREVfVU5TUEVDSUZJRU'
    'QQABInCiNNSUdSQVRJT05fRVJST1JfQ09ERV9JTlZBTElEX1NPVVJDRRABEikKJU1JR1JBVElP'
    'Tl9FUlJPUl9DT0RFX1RBUkdFVF9OT1RfRU1QVFkQAhImCiJNSUdSQVRJT05fRVJST1JfQ09ERV'
    '9VTlNBRkVfU09VUkNFEAMSJwojTUlHUkFUSU9OX0VSUk9SX0NPREVfQ0FTRV9DT0xMSVNJT04Q'
    'BBIpCiVNSUdSQVRJT05fRVJST1JfQ09ERV9VTlNVUFBPUlRFRF9EQVRBEAUSJwojTUlHUkFUSU'
    '9OX0VSUk9SX0NPREVfU09VUkNFX0NIQU5HRUQQBhIiCh5NSUdSQVRJT05fRVJST1JfQ09ERV9D'
    'QU5DRUxMRUQQBxIdChlNSUdSQVRJT05fRVJST1JfQ09ERV9CVVNZEAgSJAogTUlHUkFUSU9OX0'
    'VSUk9SX0NPREVfVU5BVkFJTEFCTEUQCQ==');

@$core.Deprecated('Use migrationRequestDescriptor instead')
const MigrationRequest$json = {
  '1': 'MigrationRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'manager',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.MigrationManager',
      '10': 'manager'
    },
    {'1': 'source_folder', '3': 3, '4': 1, '5': 9, '10': 'sourceFolder'},
    {'1': 'profile_id', '3': 4, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'staging_root', '3': 5, '4': 1, '5': 9, '10': 'stagingRoot'},
    {'1': 'download_root', '3': 6, '4': 1, '5': 9, '10': 'downloadRoot'},
  ],
};

/// Descriptor for `MigrationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationRequestDescriptor = $convert.base64Decode(
    'ChBNaWdyYXRpb25SZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSOw'
    'oHbWFuYWdlchgCIAEoDjIhLm1vZGNvbmR1Y3Rvci52MS5NaWdyYXRpb25NYW5hZ2VyUgdtYW5h'
    'Z2VyEiMKDXNvdXJjZV9mb2xkZXIYAyABKAlSDHNvdXJjZUZvbGRlchIdCgpwcm9maWxlX2lkGA'
    'QgASgJUglwcm9maWxlSWQSIQoMc3RhZ2luZ19yb290GAUgASgJUgtzdGFnaW5nUm9vdBIjCg1k'
    'b3dubG9hZF9yb290GAYgASgJUgxkb3dubG9hZFJvb3Q=');

@$core.Deprecated('Use profileRequestDescriptor instead')
const ProfileRequest$json = {
  '1': 'ProfileRequest',
  '2': [
    {
      '1': 'manager',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.MigrationManager',
      '10': 'manager'
    },
    {'1': 'source_file', '3': 2, '4': 1, '5': 9, '10': 'sourceFile'},
  ],
};

/// Descriptor for `ProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileRequestDescriptor = $convert.base64Decode(
    'Cg5Qcm9maWxlUmVxdWVzdBI7CgdtYW5hZ2VyGAEgASgOMiEubW9kY29uZHVjdG9yLnYxLk1pZ3'
    'JhdGlvbk1hbmFnZXJSB21hbmFnZXISHwoLc291cmNlX2ZpbGUYAiABKAlSCnNvdXJjZUZpbGU=');

@$core.Deprecated('Use backupProfileDescriptor instead')
const BackupProfile$json = {
  '1': 'BackupProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'game_id', '3': 3, '4': 1, '5': 9, '10': 'gameId'},
  ],
};

/// Descriptor for `BackupProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backupProfileDescriptor = $convert.base64Decode(
    'Cg1CYWNrdXBQcm9maWxlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhcKB2'
    'dhbWVfaWQYAyABKAlSBmdhbWVJZA==');

@$core.Deprecated('Use profileListDescriptor instead')
const ProfileList$json = {
  '1': 'ProfileList',
  '2': [
    {
      '1': 'profiles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BackupProfile',
      '10': 'profiles'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrationError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ProfileList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileListDescriptor = $convert.base64Decode(
    'CgtQcm9maWxlTGlzdBI6Cghwcm9maWxlcxgBIAMoCzIeLm1vZGNvbmR1Y3Rvci52MS5CYWNrdX'
    'BQcm9maWxlUghwcm9maWxlcxI1CgVlcnJvchgCIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5NaWdy'
    'YXRpb25FcnJvclIFZXJyb3I=');

@$core.Deprecated('Use migrationProgressDescriptor instead')
const MigrationProgress$json = {
  '1': 'MigrationProgress',
  '2': [
    {'1': 'completed', '3': 1, '4': 1, '5': 13, '10': 'completed'},
    {'1': 'total', '3': 2, '4': 1, '5': 13, '10': 'total'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MigrationProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationProgressDescriptor = $convert.base64Decode(
    'ChFNaWdyYXRpb25Qcm9ncmVzcxIcCgljb21wbGV0ZWQYASABKA1SCWNvbXBsZXRlZBIUCgV0b3'
    'RhbBgCIAEoDVIFdG90YWwSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use migrationErrorDescriptor instead')
const MigrationError$json = {
  '1': 'MigrationError',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.MigrationErrorCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `MigrationError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationErrorDescriptor = $convert.base64Decode(
    'Cg5NaWdyYXRpb25FcnJvchI3CgRjb2RlGAEgASgOMiMubW9kY29uZHVjdG9yLnYxLk1pZ3JhdG'
    'lvbkVycm9yQ29kZVIEY29kZRIWCgZkZXRhaWwYAiABKAlSBmRldGFpbA==');

@$core.Deprecated('Use migrationResultDescriptor instead')
const MigrationResult$json = {
  '1': 'MigrationResult',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profiles', '3': 2, '4': 1, '5': 13, '10': 'profiles'},
    {'1': 'mods', '3': 3, '4': 1, '5': 13, '10': 'mods'},
    {'1': 'artifacts', '3': 4, '4': 1, '5': 13, '10': 'artifacts'},
  ],
};

/// Descriptor for `MigrationResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationResultDescriptor = $convert.base64Decode(
    'Cg9NaWdyYXRpb25SZXN1bHQSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBIaCg'
    'hwcm9maWxlcxgCIAEoDVIIcHJvZmlsZXMSEgoEbW9kcxgDIAEoDVIEbW9kcxIcCglhcnRpZmFj'
    'dHMYBCABKA1SCWFydGlmYWN0cw==');

@$core.Deprecated('Use migrationEventDescriptor instead')
const MigrationEvent$json = {
  '1': 'MigrationEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrationProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrationError',
      '9': 0,
      '10': 'error'
    },
    {
      '1': 'result',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrationResult',
      '9': 0,
      '10': 'result'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `MigrationEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationEventDescriptor = $convert.base64Decode(
    'Cg5NaWdyYXRpb25FdmVudBJACghwcm9ncmVzcxgBIAEoCzIiLm1vZGNvbmR1Y3Rvci52MS5NaW'
    'dyYXRpb25Qcm9ncmVzc0gAUghwcm9ncmVzcxI3CgVlcnJvchgCIAEoCzIfLm1vZGNvbmR1Y3Rv'
    'ci52MS5NaWdyYXRpb25FcnJvckgAUgVlcnJvchI6CgZyZXN1bHQYAyABKAsyIC5tb2Rjb25kdW'
    'N0b3IudjEuTWlncmF0aW9uUmVzdWx0SABSBnJlc3VsdEIHCgVldmVudA==');
