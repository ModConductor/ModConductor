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

class ProfileSaveSource extends $pb.ProtobufEnum {
  static const ProfileSaveSource PROFILE_SAVE_SOURCE_UNSPECIFIED =
      ProfileSaveSource._(
          0, _omitEnumNames ? '' : 'PROFILE_SAVE_SOURCE_UNSPECIFIED');
  static const ProfileSaveSource PROFILE_SAVE_SOURCE_GLOBAL =
      ProfileSaveSource._(
          1, _omitEnumNames ? '' : 'PROFILE_SAVE_SOURCE_GLOBAL');
  static const ProfileSaveSource PROFILE_SAVE_SOURCE_PROFILE =
      ProfileSaveSource._(
          2, _omitEnumNames ? '' : 'PROFILE_SAVE_SOURCE_PROFILE');

  static const $core.List<ProfileSaveSource> values = <ProfileSaveSource>[
    PROFILE_SAVE_SOURCE_UNSPECIFIED,
    PROFILE_SAVE_SOURCE_GLOBAL,
    PROFILE_SAVE_SOURCE_PROFILE,
  ];

  static final $core.List<ProfileSaveSource?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ProfileSaveSource? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProfileSaveSource._(super.value, super.name);
}

class ProfileSaveEntryKind extends $pb.ProtobufEnum {
  static const ProfileSaveEntryKind PROFILE_SAVE_ENTRY_KIND_UNSPECIFIED =
      ProfileSaveEntryKind._(
          0, _omitEnumNames ? '' : 'PROFILE_SAVE_ENTRY_KIND_UNSPECIFIED');
  static const ProfileSaveEntryKind PROFILE_SAVE_ENTRY_KIND_SAVE =
      ProfileSaveEntryKind._(
          1, _omitEnumNames ? '' : 'PROFILE_SAVE_ENTRY_KIND_SAVE');
  static const ProfileSaveEntryKind PROFILE_SAVE_ENTRY_KIND_DIRECTORY =
      ProfileSaveEntryKind._(
          2, _omitEnumNames ? '' : 'PROFILE_SAVE_ENTRY_KIND_DIRECTORY');
  static const ProfileSaveEntryKind PROFILE_SAVE_ENTRY_KIND_OTHER =
      ProfileSaveEntryKind._(
          3, _omitEnumNames ? '' : 'PROFILE_SAVE_ENTRY_KIND_OTHER');

  static const $core.List<ProfileSaveEntryKind> values = <ProfileSaveEntryKind>[
    PROFILE_SAVE_ENTRY_KIND_UNSPECIFIED,
    PROFILE_SAVE_ENTRY_KIND_SAVE,
    PROFILE_SAVE_ENTRY_KIND_DIRECTORY,
    PROFILE_SAVE_ENTRY_KIND_OTHER,
  ];

  static final $core.List<ProfileSaveEntryKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ProfileSaveEntryKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProfileSaveEntryKind._(super.value, super.name);
}

class SkyrimSaveCompression extends $pb.ProtobufEnum {
  static const SkyrimSaveCompression SKYRIM_SAVE_COMPRESSION_UNSPECIFIED =
      SkyrimSaveCompression._(
          0, _omitEnumNames ? '' : 'SKYRIM_SAVE_COMPRESSION_UNSPECIFIED');
  static const SkyrimSaveCompression SKYRIM_SAVE_COMPRESSION_UNCOMPRESSED =
      SkyrimSaveCompression._(
          1, _omitEnumNames ? '' : 'SKYRIM_SAVE_COMPRESSION_UNCOMPRESSED');
  static const SkyrimSaveCompression SKYRIM_SAVE_COMPRESSION_ZLIB =
      SkyrimSaveCompression._(
          2, _omitEnumNames ? '' : 'SKYRIM_SAVE_COMPRESSION_ZLIB');
  static const SkyrimSaveCompression SKYRIM_SAVE_COMPRESSION_LZ4 =
      SkyrimSaveCompression._(
          3, _omitEnumNames ? '' : 'SKYRIM_SAVE_COMPRESSION_LZ4');

  static const $core.List<SkyrimSaveCompression> values =
      <SkyrimSaveCompression>[
    SKYRIM_SAVE_COMPRESSION_UNSPECIFIED,
    SKYRIM_SAVE_COMPRESSION_UNCOMPRESSED,
    SKYRIM_SAVE_COMPRESSION_ZLIB,
    SKYRIM_SAVE_COMPRESSION_LZ4,
  ];

  static final $core.List<SkyrimSaveCompression?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SkyrimSaveCompression? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SkyrimSaveCompression._(super.value, super.name);
}

class SavePluginState extends $pb.ProtobufEnum {
  static const SavePluginState SAVE_PLUGIN_STATE_UNSPECIFIED =
      SavePluginState._(
          0, _omitEnumNames ? '' : 'SAVE_PLUGIN_STATE_UNSPECIFIED');
  static const SavePluginState SAVE_PLUGIN_STATE_MISSING =
      SavePluginState._(1, _omitEnumNames ? '' : 'SAVE_PLUGIN_STATE_MISSING');
  static const SavePluginState SAVE_PLUGIN_STATE_INACTIVE =
      SavePluginState._(2, _omitEnumNames ? '' : 'SAVE_PLUGIN_STATE_INACTIVE');

  static const $core.List<SavePluginState> values = <SavePluginState>[
    SAVE_PLUGIN_STATE_UNSPECIFIED,
    SAVE_PLUGIN_STATE_MISSING,
    SAVE_PLUGIN_STATE_INACTIVE,
  ];

  static final $core.List<SavePluginState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SavePluginState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SavePluginState._(super.value, super.name);
}

class ProfileSaveAction extends $pb.ProtobufEnum {
  static const ProfileSaveAction PROFILE_SAVE_ACTION_UNSPECIFIED =
      ProfileSaveAction._(
          0, _omitEnumNames ? '' : 'PROFILE_SAVE_ACTION_UNSPECIFIED');
  static const ProfileSaveAction PROFILE_SAVE_ACTION_COPY_TO_PROFILE =
      ProfileSaveAction._(
          1, _omitEnumNames ? '' : 'PROFILE_SAVE_ACTION_COPY_TO_PROFILE');
  static const ProfileSaveAction PROFILE_SAVE_ACTION_DELETE_FROM_PROFILE =
      ProfileSaveAction._(
          2, _omitEnumNames ? '' : 'PROFILE_SAVE_ACTION_DELETE_FROM_PROFILE');

  static const $core.List<ProfileSaveAction> values = <ProfileSaveAction>[
    PROFILE_SAVE_ACTION_UNSPECIFIED,
    PROFILE_SAVE_ACTION_COPY_TO_PROFILE,
    PROFILE_SAVE_ACTION_DELETE_FROM_PROFILE,
  ];

  static final $core.List<ProfileSaveAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ProfileSaveAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProfileSaveAction._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
