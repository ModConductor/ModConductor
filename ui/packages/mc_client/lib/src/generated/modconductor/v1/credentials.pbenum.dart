// This is a generated file - do not edit.
//
// Generated from modconductor/v1/credentials.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CredentialStorageMode extends $pb.ProtobufEnum {
  static const CredentialStorageMode CREDENTIAL_STORAGE_MODE_UNSPECIFIED =
      CredentialStorageMode._(
          0, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_MODE_UNSPECIFIED');
  static const CredentialStorageMode CREDENTIAL_STORAGE_MODE_SECURE =
      CredentialStorageMode._(
          1, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_MODE_SECURE');
  static const CredentialStorageMode CREDENTIAL_STORAGE_MODE_SESSION_ONLY =
      CredentialStorageMode._(
          2, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_MODE_SESSION_ONLY');

  static const $core.List<CredentialStorageMode> values =
      <CredentialStorageMode>[
    CREDENTIAL_STORAGE_MODE_UNSPECIFIED,
    CREDENTIAL_STORAGE_MODE_SECURE,
    CREDENTIAL_STORAGE_MODE_SESSION_ONLY,
  ];

  static final $core.List<CredentialStorageMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CredentialStorageMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CredentialStorageMode._(super.value, super.name);
}

class CredentialStorageKind extends $pb.ProtobufEnum {
  static const CredentialStorageKind CREDENTIAL_STORAGE_KIND_UNSPECIFIED =
      CredentialStorageKind._(
          0, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_KIND_UNSPECIFIED');
  static const CredentialStorageKind CREDENTIAL_STORAGE_KIND_SECRET_SERVICE =
      CredentialStorageKind._(
          1, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_KIND_SECRET_SERVICE');
  static const CredentialStorageKind CREDENTIAL_STORAGE_KIND_WINDOWS =
      CredentialStorageKind._(
          2, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_KIND_WINDOWS');
  static const CredentialStorageKind CREDENTIAL_STORAGE_KIND_UNAVAILABLE =
      CredentialStorageKind._(
          3, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_KIND_UNAVAILABLE');

  static const $core.List<CredentialStorageKind> values =
      <CredentialStorageKind>[
    CREDENTIAL_STORAGE_KIND_UNSPECIFIED,
    CREDENTIAL_STORAGE_KIND_SECRET_SERVICE,
    CREDENTIAL_STORAGE_KIND_WINDOWS,
    CREDENTIAL_STORAGE_KIND_UNAVAILABLE,
  ];

  static final $core.List<CredentialStorageKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CredentialStorageKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CredentialStorageKind._(super.value, super.name);
}

class CredentialPresence extends $pb.ProtobufEnum {
  static const CredentialPresence CREDENTIAL_PRESENCE_UNSPECIFIED =
      CredentialPresence._(
          0, _omitEnumNames ? '' : 'CREDENTIAL_PRESENCE_UNSPECIFIED');
  static const CredentialPresence CREDENTIAL_PRESENCE_PRESENT =
      CredentialPresence._(
          1, _omitEnumNames ? '' : 'CREDENTIAL_PRESENCE_PRESENT');
  static const CredentialPresence CREDENTIAL_PRESENCE_ABSENT =
      CredentialPresence._(
          2, _omitEnumNames ? '' : 'CREDENTIAL_PRESENCE_ABSENT');
  static const CredentialPresence CREDENTIAL_PRESENCE_UNKNOWN =
      CredentialPresence._(
          3, _omitEnumNames ? '' : 'CREDENTIAL_PRESENCE_UNKNOWN');

  static const $core.List<CredentialPresence> values = <CredentialPresence>[
    CREDENTIAL_PRESENCE_UNSPECIFIED,
    CREDENTIAL_PRESENCE_PRESENT,
    CREDENTIAL_PRESENCE_ABSENT,
    CREDENTIAL_PRESENCE_UNKNOWN,
  ];

  static final $core.List<CredentialPresence?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CredentialPresence? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CredentialPresence._(super.value, super.name);
}

class CredentialStorageProblem extends $pb.ProtobufEnum {
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_NONE =
      CredentialStorageProblem._(
          0, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_NONE');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_UNAVAILABLE =
      CredentialStorageProblem._(
          1, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_UNAVAILABLE');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_LOCKED =
      CredentialStorageProblem._(
          2, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_LOCKED');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_DENIED =
      CredentialStorageProblem._(
          3, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_DENIED');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_TIMED_OUT =
      CredentialStorageProblem._(
          4, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_TIMED_OUT');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_CANCELLED =
      CredentialStorageProblem._(
          5, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_CANCELLED');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_TOO_LARGE =
      CredentialStorageProblem._(
          6, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_TOO_LARGE');
  static const CredentialStorageProblem CREDENTIAL_STORAGE_PROBLEM_FAILED =
      CredentialStorageProblem._(
          7, _omitEnumNames ? '' : 'CREDENTIAL_STORAGE_PROBLEM_FAILED');

  static const $core.List<CredentialStorageProblem> values =
      <CredentialStorageProblem>[
    CREDENTIAL_STORAGE_PROBLEM_NONE,
    CREDENTIAL_STORAGE_PROBLEM_UNAVAILABLE,
    CREDENTIAL_STORAGE_PROBLEM_LOCKED,
    CREDENTIAL_STORAGE_PROBLEM_DENIED,
    CREDENTIAL_STORAGE_PROBLEM_TIMED_OUT,
    CREDENTIAL_STORAGE_PROBLEM_CANCELLED,
    CREDENTIAL_STORAGE_PROBLEM_TOO_LARGE,
    CREDENTIAL_STORAGE_PROBLEM_FAILED,
  ];

  static final $core.List<CredentialStorageProblem?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static CredentialStorageProblem? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CredentialStorageProblem._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
