// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class InitialProfileSaves extends $pb.ProtobufEnum {
  static const InitialProfileSaves INITIAL_PROFILE_SAVES_UNSPECIFIED =
      InitialProfileSaves._(
          0, _omitEnumNames ? '' : 'INITIAL_PROFILE_SAVES_UNSPECIFIED');
  static const InitialProfileSaves INITIAL_PROFILE_SAVES_EMPTY =
      InitialProfileSaves._(
          1, _omitEnumNames ? '' : 'INITIAL_PROFILE_SAVES_EMPTY');
  static const InitialProfileSaves INITIAL_PROFILE_SAVES_COPY_GLOBAL =
      InitialProfileSaves._(
          2, _omitEnumNames ? '' : 'INITIAL_PROFILE_SAVES_COPY_GLOBAL');

  static const $core.List<InitialProfileSaves> values = <InitialProfileSaves>[
    INITIAL_PROFILE_SAVES_UNSPECIFIED,
    INITIAL_PROFILE_SAVES_EMPTY,
    INITIAL_PROFILE_SAVES_COPY_GLOBAL,
  ];

  static final $core.List<InitialProfileSaves?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static InitialProfileSaves? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InitialProfileSaves._(super.value, super.name);
}

class DisabledProfileFiles extends $pb.ProtobufEnum {
  static const DisabledProfileFiles DISABLED_PROFILE_FILES_UNSPECIFIED =
      DisabledProfileFiles._(
          0, _omitEnumNames ? '' : 'DISABLED_PROFILE_FILES_UNSPECIFIED');
  static const DisabledProfileFiles DISABLED_PROFILE_FILES_KEEP =
      DisabledProfileFiles._(
          1, _omitEnumNames ? '' : 'DISABLED_PROFILE_FILES_KEEP');
  static const DisabledProfileFiles DISABLED_PROFILE_FILES_DELETE =
      DisabledProfileFiles._(
          2, _omitEnumNames ? '' : 'DISABLED_PROFILE_FILES_DELETE');

  static const $core.List<DisabledProfileFiles> values = <DisabledProfileFiles>[
    DISABLED_PROFILE_FILES_UNSPECIFIED,
    DISABLED_PROFILE_FILES_KEEP,
    DISABLED_PROFILE_FILES_DELETE,
  ];

  static final $core.List<DisabledProfileFiles?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static DisabledProfileFiles? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DisabledProfileFiles._(super.value, super.name);
}

class ProfileDataProblemKind extends $pb.ProtobufEnum {
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_UNSPECIFIED =
      ProfileDataProblemKind._(
          0, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_UNSPECIFIED');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_NOT_FOUND =
      ProfileDataProblemKind._(
          1, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_NOT_FOUND');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_BUSY =
      ProfileDataProblemKind._(
          2, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_BUSY');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_STALE =
      ProfileDataProblemKind._(
          3, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_STALE');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_CANCELLED =
      ProfileDataProblemKind._(
          4, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_CANCELLED');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_INVALID =
      ProfileDataProblemKind._(
          5, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_INVALID');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_UNAVAILABLE =
      ProfileDataProblemKind._(
          6, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_UNAVAILABLE');
  static const ProfileDataProblemKind PROFILE_DATA_PROBLEM_CONFLICT =
      ProfileDataProblemKind._(
          7, _omitEnumNames ? '' : 'PROFILE_DATA_PROBLEM_CONFLICT');

  static const $core.List<ProfileDataProblemKind> values =
      <ProfileDataProblemKind>[
    PROFILE_DATA_PROBLEM_UNSPECIFIED,
    PROFILE_DATA_PROBLEM_NOT_FOUND,
    PROFILE_DATA_PROBLEM_BUSY,
    PROFILE_DATA_PROBLEM_STALE,
    PROFILE_DATA_PROBLEM_CANCELLED,
    PROFILE_DATA_PROBLEM_INVALID,
    PROFILE_DATA_PROBLEM_UNAVAILABLE,
    PROFILE_DATA_PROBLEM_CONFLICT,
  ];

  static final $core.List<ProfileDataProblemKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ProfileDataProblemKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProfileDataProblemKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
