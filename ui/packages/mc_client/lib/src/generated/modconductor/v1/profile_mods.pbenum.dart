// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_mods.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ProfileModRestriction extends $pb.ProtobufEnum {
  static const ProfileModRestriction PROFILE_MOD_RESTRICTION_UNSPECIFIED =
      ProfileModRestriction._(
          0, _omitEnumNames ? '' : 'PROFILE_MOD_RESTRICTION_UNSPECIFIED');
  static const ProfileModRestriction PROFILE_MOD_RESTRICTION_BACKUP =
      ProfileModRestriction._(
          1, _omitEnumNames ? '' : 'PROFILE_MOD_RESTRICTION_BACKUP');
  static const ProfileModRestriction PROFILE_MOD_RESTRICTION_UNMANAGED =
      ProfileModRestriction._(
          2, _omitEnumNames ? '' : 'PROFILE_MOD_RESTRICTION_UNMANAGED');
  static const ProfileModRestriction PROFILE_MOD_RESTRICTION_AUTOMATIC =
      ProfileModRestriction._(
          3, _omitEnumNames ? '' : 'PROFILE_MOD_RESTRICTION_AUTOMATIC');

  static const $core.List<ProfileModRestriction> values =
      <ProfileModRestriction>[
    PROFILE_MOD_RESTRICTION_UNSPECIFIED,
    PROFILE_MOD_RESTRICTION_BACKUP,
    PROFILE_MOD_RESTRICTION_UNMANAGED,
    PROFILE_MOD_RESTRICTION_AUTOMATIC,
  ];

  static final $core.List<ProfileModRestriction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ProfileModRestriction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProfileModRestriction._(super.value, super.name);
}

class ProfileModMove extends $pb.ProtobufEnum {
  static const ProfileModMove PROFILE_MOD_MOVE_UNSPECIFIED =
      ProfileModMove._(0, _omitEnumNames ? '' : 'PROFILE_MOD_MOVE_UNSPECIFIED');
  static const ProfileModMove PROFILE_MOD_MOVE_UP =
      ProfileModMove._(1, _omitEnumNames ? '' : 'PROFILE_MOD_MOVE_UP');
  static const ProfileModMove PROFILE_MOD_MOVE_DOWN =
      ProfileModMove._(2, _omitEnumNames ? '' : 'PROFILE_MOD_MOVE_DOWN');

  static const $core.List<ProfileModMove> values = <ProfileModMove>[
    PROFILE_MOD_MOVE_UNSPECIFIED,
    PROFILE_MOD_MOVE_UP,
    PROFILE_MOD_MOVE_DOWN,
  ];

  static final $core.List<ProfileModMove?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ProfileModMove? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProfileModMove._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
