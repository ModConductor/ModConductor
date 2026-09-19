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

@$core.Deprecated('Use managerDescriptor instead')
const Manager$json = {
  '1': 'Manager',
  '2': [
    {'1': 'MANAGER_UNSPECIFIED', '2': 0},
    {'1': 'MANAGER_MOD_ORGANIZER', '2': 1},
  ],
};

/// Descriptor for `Manager`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List managerDescriptor = $convert.base64Decode(
    'CgdNYW5hZ2VyEhcKE01BTkFHRVJfVU5TUEVDSUZJRUQQABIZChVNQU5BR0VSX01PRF9PUkdBTk'
    'laRVIQAQ==');

@$core.Deprecated('Use migrateErrorCodeDescriptor instead')
const MigrateErrorCode$json = {
  '1': 'MigrateErrorCode',
  '2': [
    {'1': 'MIGRATE_ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'MIGRATE_ERROR_CODE_INVALID_SOURCE', '2': 1},
    {'1': 'MIGRATE_ERROR_CODE_TARGET_NOT_EMPTY', '2': 2},
    {'1': 'MIGRATE_ERROR_CODE_UNSAFE_SOURCE', '2': 3},
    {'1': 'MIGRATE_ERROR_CODE_CASE_COLLISION', '2': 4},
    {'1': 'MIGRATE_ERROR_CODE_UNSUPPORTED_DATA', '2': 5},
    {'1': 'MIGRATE_ERROR_CODE_SOURCE_CHANGED', '2': 6},
    {'1': 'MIGRATE_ERROR_CODE_CANCELLED', '2': 7},
    {'1': 'MIGRATE_ERROR_CODE_BUSY', '2': 8},
    {'1': 'MIGRATE_ERROR_CODE_UNAVAILABLE', '2': 9},
  ],
};

/// Descriptor for `MigrateErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List migrateErrorCodeDescriptor = $convert.base64Decode(
    'ChBNaWdyYXRlRXJyb3JDb2RlEiIKHk1JR1JBVEVfRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEi'
    'UKIU1JR1JBVEVfRVJST1JfQ09ERV9JTlZBTElEX1NPVVJDRRABEicKI01JR1JBVEVfRVJST1Jf'
    'Q09ERV9UQVJHRVRfTk9UX0VNUFRZEAISJAogTUlHUkFURV9FUlJPUl9DT0RFX1VOU0FGRV9TT1'
    'VSQ0UQAxIlCiFNSUdSQVRFX0VSUk9SX0NPREVfQ0FTRV9DT0xMSVNJT04QBBInCiNNSUdSQVRF'
    'X0VSUk9SX0NPREVfVU5TVVBQT1JURURfREFUQRAFEiUKIU1JR1JBVEVfRVJST1JfQ09ERV9TT1'
    'VSQ0VfQ0hBTkdFRBAGEiAKHE1JR1JBVEVfRVJST1JfQ09ERV9DQU5DRUxMRUQQBxIbChdNSUdS'
    'QVRFX0VSUk9SX0NPREVfQlVTWRAIEiIKHk1JR1JBVEVfRVJST1JfQ09ERV9VTkFWQUlMQUJMRR'
    'AJ');

@$core.Deprecated('Use migrateRequestDescriptor instead')
const MigrateRequest$json = {
  '1': 'MigrateRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'manager',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.Manager',
      '10': 'manager'
    },
    {'1': 'source_folder', '3': 3, '4': 1, '5': 9, '10': 'sourceFolder'},
  ],
};

/// Descriptor for `MigrateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateRequestDescriptor = $convert.base64Decode(
    'Cg5NaWdyYXRlUmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZUlkEjIKB2'
    '1hbmFnZXIYAiABKA4yGC5tb2Rjb25kdWN0b3IudjEuTWFuYWdlclIHbWFuYWdlchIjCg1zb3Vy'
    'Y2VfZm9sZGVyGAMgASgJUgxzb3VyY2VGb2xkZXI=');

@$core.Deprecated('Use migrateProgressDescriptor instead')
const MigrateProgress$json = {
  '1': 'MigrateProgress',
  '2': [
    {'1': 'completed', '3': 1, '4': 1, '5': 13, '10': 'completed'},
    {'1': 'total', '3': 2, '4': 1, '5': 13, '10': 'total'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MigrateProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateProgressDescriptor = $convert.base64Decode(
    'Cg9NaWdyYXRlUHJvZ3Jlc3MSHAoJY29tcGxldGVkGAEgASgNUgljb21wbGV0ZWQSFAoFdG90YW'
    'wYAiABKA1SBXRvdGFsEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use migrateErrorDescriptor instead')
const MigrateError$json = {
  '1': 'MigrateError',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.MigrateErrorCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `MigrateError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateErrorDescriptor = $convert.base64Decode(
    'CgxNaWdyYXRlRXJyb3ISNQoEY29kZRgBIAEoDjIhLm1vZGNvbmR1Y3Rvci52MS5NaWdyYXRlRX'
    'Jyb3JDb2RlUgRjb2RlEhYKBmRldGFpbBgCIAEoCVIGZGV0YWls');

@$core.Deprecated('Use migrateResultDescriptor instead')
const MigrateResult$json = {
  '1': 'MigrateResult',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'profiles', '3': 2, '4': 1, '5': 13, '10': 'profiles'},
    {'1': 'mods', '3': 3, '4': 1, '5': 13, '10': 'mods'},
    {'1': 'artifacts', '3': 4, '4': 1, '5': 13, '10': 'artifacts'},
  ],
};

/// Descriptor for `MigrateResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateResultDescriptor = $convert.base64Decode(
    'Cg1NaWdyYXRlUmVzdWx0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSGgoIcH'
    'JvZmlsZXMYAiABKA1SCHByb2ZpbGVzEhIKBG1vZHMYAyABKA1SBG1vZHMSHAoJYXJ0aWZhY3Rz'
    'GAQgASgNUglhcnRpZmFjdHM=');

@$core.Deprecated('Use migrateEventDescriptor instead')
const MigrateEvent$json = {
  '1': 'MigrateEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrateProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrateError',
      '9': 0,
      '10': 'error'
    },
    {
      '1': 'result',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.MigrateResult',
      '9': 0,
      '10': 'result'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `MigrateEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrateEventDescriptor = $convert.base64Decode(
    'CgxNaWdyYXRlRXZlbnQSPgoIcHJvZ3Jlc3MYASABKAsyIC5tb2Rjb25kdWN0b3IudjEuTWlncm'
    'F0ZVByb2dyZXNzSABSCHByb2dyZXNzEjUKBWVycm9yGAIgASgLMh0ubW9kY29uZHVjdG9yLnYx'
    'Lk1pZ3JhdGVFcnJvckgAUgVlcnJvchI4CgZyZXN1bHQYAyABKAsyHi5tb2Rjb25kdWN0b3Iudj'
    'EuTWlncmF0ZVJlc3VsdEgAUgZyZXN1bHRCBwoFZXZlbnQ=');
