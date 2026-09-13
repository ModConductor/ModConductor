// This is a generated file - do not edit.
//
// Generated from modconductor/v1/credentials.proto.

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

@$core.Deprecated('Use credentialStorageModeDescriptor instead')
const CredentialStorageMode$json = {
  '1': 'CredentialStorageMode',
  '2': [
    {'1': 'CREDENTIAL_STORAGE_MODE_UNSPECIFIED', '2': 0},
    {'1': 'CREDENTIAL_STORAGE_MODE_SECURE', '2': 1},
    {'1': 'CREDENTIAL_STORAGE_MODE_SESSION_ONLY', '2': 2},
  ],
};

/// Descriptor for `CredentialStorageMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List credentialStorageModeDescriptor = $convert.base64Decode(
    'ChVDcmVkZW50aWFsU3RvcmFnZU1vZGUSJwojQ1JFREVOVElBTF9TVE9SQUdFX01PREVfVU5TUE'
    'VDSUZJRUQQABIiCh5DUkVERU5USUFMX1NUT1JBR0VfTU9ERV9TRUNVUkUQARIoCiRDUkVERU5U'
    'SUFMX1NUT1JBR0VfTU9ERV9TRVNTSU9OX09OTFkQAg==');

@$core.Deprecated('Use credentialStorageKindDescriptor instead')
const CredentialStorageKind$json = {
  '1': 'CredentialStorageKind',
  '2': [
    {'1': 'CREDENTIAL_STORAGE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CREDENTIAL_STORAGE_KIND_SECRET_SERVICE', '2': 1},
    {'1': 'CREDENTIAL_STORAGE_KIND_WINDOWS', '2': 2},
    {'1': 'CREDENTIAL_STORAGE_KIND_UNAVAILABLE', '2': 3},
  ],
};

/// Descriptor for `CredentialStorageKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List credentialStorageKindDescriptor = $convert.base64Decode(
    'ChVDcmVkZW50aWFsU3RvcmFnZUtpbmQSJwojQ1JFREVOVElBTF9TVE9SQUdFX0tJTkRfVU5TUE'
    'VDSUZJRUQQABIqCiZDUkVERU5USUFMX1NUT1JBR0VfS0lORF9TRUNSRVRfU0VSVklDRRABEiMK'
    'H0NSRURFTlRJQUxfU1RPUkFHRV9LSU5EX1dJTkRPV1MQAhInCiNDUkVERU5USUFMX1NUT1JBR0'
    'VfS0lORF9VTkFWQUlMQUJMRRAD');

@$core.Deprecated('Use credentialPresenceDescriptor instead')
const CredentialPresence$json = {
  '1': 'CredentialPresence',
  '2': [
    {'1': 'CREDENTIAL_PRESENCE_UNSPECIFIED', '2': 0},
    {'1': 'CREDENTIAL_PRESENCE_PRESENT', '2': 1},
    {'1': 'CREDENTIAL_PRESENCE_ABSENT', '2': 2},
    {'1': 'CREDENTIAL_PRESENCE_UNKNOWN', '2': 3},
  ],
};

/// Descriptor for `CredentialPresence`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List credentialPresenceDescriptor = $convert.base64Decode(
    'ChJDcmVkZW50aWFsUHJlc2VuY2USIwofQ1JFREVOVElBTF9QUkVTRU5DRV9VTlNQRUNJRklFRB'
    'AAEh8KG0NSRURFTlRJQUxfUFJFU0VOQ0VfUFJFU0VOVBABEh4KGkNSRURFTlRJQUxfUFJFU0VO'
    'Q0VfQUJTRU5UEAISHwobQ1JFREVOVElBTF9QUkVTRU5DRV9VTktOT1dOEAM=');

@$core.Deprecated('Use credentialStorageProblemDescriptor instead')
const CredentialStorageProblem$json = {
  '1': 'CredentialStorageProblem',
  '2': [
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_NONE', '2': 0},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_UNAVAILABLE', '2': 1},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_LOCKED', '2': 2},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_DENIED', '2': 3},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_TIMED_OUT', '2': 4},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_CANCELLED', '2': 5},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_TOO_LARGE', '2': 6},
    {'1': 'CREDENTIAL_STORAGE_PROBLEM_FAILED', '2': 7},
  ],
};

/// Descriptor for `CredentialStorageProblem`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List credentialStorageProblemDescriptor = $convert.base64Decode(
    'ChhDcmVkZW50aWFsU3RvcmFnZVByb2JsZW0SIwofQ1JFREVOVElBTF9TVE9SQUdFX1BST0JMRU'
    '1fTk9ORRAAEioKJkNSRURFTlRJQUxfU1RPUkFHRV9QUk9CTEVNX1VOQVZBSUxBQkxFEAESJQoh'
    'Q1JFREVOVElBTF9TVE9SQUdFX1BST0JMRU1fTE9DS0VEEAISJQohQ1JFREVOVElBTF9TVE9SQU'
    'dFX1BST0JMRU1fREVOSUVEEAMSKAokQ1JFREVOVElBTF9TVE9SQUdFX1BST0JMRU1fVElNRURf'
    'T1VUEAQSKAokQ1JFREVOVElBTF9TVE9SQUdFX1BST0JMRU1fQ0FOQ0VMTEVEEAUSKAokQ1JFRE'
    'VOVElBTF9TVE9SQUdFX1BST0JMRU1fVE9PX0xBUkdFEAYSJQohQ1JFREVOVElBTF9TVE9SQUdF'
    'X1BST0JMRU1fRkFJTEVEEAc=');

@$core.Deprecated('Use credentialStatusRequestDescriptor instead')
const CredentialStatusRequest$json = {
  '1': 'CredentialStatusRequest',
};

/// Descriptor for `CredentialStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List credentialStatusRequestDescriptor =
    $convert.base64Decode('ChdDcmVkZW50aWFsU3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use credentialModeRequestDescriptor instead')
const CredentialModeRequest$json = {
  '1': 'CredentialModeRequest',
  '2': [
    {
      '1': 'mode',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.CredentialStorageMode',
      '10': 'mode'
    },
  ],
};

/// Descriptor for `CredentialModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List credentialModeRequestDescriptor = $convert.base64Decode(
    'ChVDcmVkZW50aWFsTW9kZVJlcXVlc3QSOgoEbW9kZRgBIAEoDjImLm1vZGNvbmR1Y3Rvci52MS'
    '5DcmVkZW50aWFsU3RvcmFnZU1vZGVSBG1vZGU=');

@$core.Deprecated('Use credentialStorageStatusDescriptor instead')
const CredentialStorageStatus$json = {
  '1': 'CredentialStorageStatus',
  '2': [
    {
      '1': 'storage',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.CredentialStorageKind',
      '10': 'storage'
    },
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.CredentialStorageMode',
      '10': 'mode'
    },
    {
      '1': 'saved',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.CredentialPresence',
      '10': 'saved'
    },
    {'1': 'has_session', '3': 4, '4': 1, '5': 8, '10': 'hasSession'},
    {
      '1': 'problem',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.CredentialStorageProblem',
      '10': 'problem'
    },
    {
      '1': 'removal_problem',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.CredentialStorageProblem',
      '10': 'removalProblem'
    },
    {
      '1': 'diagnostic_report',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'diagnosticReport'
    },
  ],
};

/// Descriptor for `CredentialStorageStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List credentialStorageStatusDescriptor = $convert.base64Decode(
    'ChdDcmVkZW50aWFsU3RvcmFnZVN0YXR1cxJACgdzdG9yYWdlGAEgASgOMiYubW9kY29uZHVjdG'
    '9yLnYxLkNyZWRlbnRpYWxTdG9yYWdlS2luZFIHc3RvcmFnZRI6CgRtb2RlGAIgASgOMiYubW9k'
    'Y29uZHVjdG9yLnYxLkNyZWRlbnRpYWxTdG9yYWdlTW9kZVIEbW9kZRI5CgVzYXZlZBgDIAEoDj'
    'IjLm1vZGNvbmR1Y3Rvci52MS5DcmVkZW50aWFsUHJlc2VuY2VSBXNhdmVkEh8KC2hhc19zZXNz'
    'aW9uGAQgASgIUgpoYXNTZXNzaW9uEkMKB3Byb2JsZW0YBSABKA4yKS5tb2Rjb25kdWN0b3Iudj'
    'EuQ3JlZGVudGlhbFN0b3JhZ2VQcm9ibGVtUgdwcm9ibGVtElIKD3JlbW92YWxfcHJvYmxlbRgG'
    'IAEoDjIpLm1vZGNvbmR1Y3Rvci52MS5DcmVkZW50aWFsU3RvcmFnZVByb2JsZW1SDnJlbW92YW'
    'xQcm9ibGVtEisKEWRpYWdub3N0aWNfcmVwb3J0GAcgASgJUhBkaWFnbm9zdGljUmVwb3J0');
