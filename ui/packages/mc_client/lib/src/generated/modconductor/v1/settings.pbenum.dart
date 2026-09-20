// This is a generated file - do not edit.
//
// Generated from modconductor/v1/settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AppearancePreference extends $pb.ProtobufEnum {
  static const AppearancePreference APPEARANCE_PREFERENCE_UNSPECIFIED =
      AppearancePreference._(
          0, _omitEnumNames ? '' : 'APPEARANCE_PREFERENCE_UNSPECIFIED');
  static const AppearancePreference APPEARANCE_PREFERENCE_SYSTEM =
      AppearancePreference._(
          1, _omitEnumNames ? '' : 'APPEARANCE_PREFERENCE_SYSTEM');
  static const AppearancePreference APPEARANCE_PREFERENCE_LIGHT =
      AppearancePreference._(
          2, _omitEnumNames ? '' : 'APPEARANCE_PREFERENCE_LIGHT');
  static const AppearancePreference APPEARANCE_PREFERENCE_DARK =
      AppearancePreference._(
          3, _omitEnumNames ? '' : 'APPEARANCE_PREFERENCE_DARK');

  static const $core.List<AppearancePreference> values = <AppearancePreference>[
    APPEARANCE_PREFERENCE_UNSPECIFIED,
    APPEARANCE_PREFERENCE_SYSTEM,
    APPEARANCE_PREFERENCE_LIGHT,
    APPEARANCE_PREFERENCE_DARK,
  ];

  static final $core.List<AppearancePreference?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AppearancePreference? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AppearancePreference._(super.value, super.name);
}

class ContrastPreference extends $pb.ProtobufEnum {
  static const ContrastPreference CONTRAST_PREFERENCE_UNSPECIFIED =
      ContrastPreference._(
          0, _omitEnumNames ? '' : 'CONTRAST_PREFERENCE_UNSPECIFIED');
  static const ContrastPreference CONTRAST_PREFERENCE_SYSTEM =
      ContrastPreference._(
          1, _omitEnumNames ? '' : 'CONTRAST_PREFERENCE_SYSTEM');
  static const ContrastPreference CONTRAST_PREFERENCE_STANDARD =
      ContrastPreference._(
          2, _omitEnumNames ? '' : 'CONTRAST_PREFERENCE_STANDARD');
  static const ContrastPreference CONTRAST_PREFERENCE_HIGH =
      ContrastPreference._(3, _omitEnumNames ? '' : 'CONTRAST_PREFERENCE_HIGH');

  static const $core.List<ContrastPreference> values = <ContrastPreference>[
    CONTRAST_PREFERENCE_UNSPECIFIED,
    CONTRAST_PREFERENCE_SYSTEM,
    CONTRAST_PREFERENCE_STANDARD,
    CONTRAST_PREFERENCE_HIGH,
  ];

  static final $core.List<ContrastPreference?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ContrastPreference? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ContrastPreference._(super.value, super.name);
}

class SettingsFaultCode extends $pb.ProtobufEnum {
  static const SettingsFaultCode SETTINGS_FAULT_CODE_UNSPECIFIED =
      SettingsFaultCode._(
          0, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_UNSPECIFIED');
  static const SettingsFaultCode SETTINGS_FAULT_CODE_INVALID_SCOPE =
      SettingsFaultCode._(
          1, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_INVALID_SCOPE');
  static const SettingsFaultCode SETTINGS_FAULT_CODE_INVALID_DOCUMENT =
      SettingsFaultCode._(
          2, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_INVALID_DOCUMENT');
  static const SettingsFaultCode SETTINGS_FAULT_CODE_UNSUPPORTED_VERSION =
      SettingsFaultCode._(
          3, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_UNSUPPORTED_VERSION');
  static const SettingsFaultCode SETTINGS_FAULT_CODE_INVALID_VALUE =
      SettingsFaultCode._(
          4, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_INVALID_VALUE');
  static const SettingsFaultCode SETTINGS_FAULT_CODE_UNAVAILABLE =
      SettingsFaultCode._(
          5, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_UNAVAILABLE');
  static const SettingsFaultCode SETTINGS_FAULT_CODE_WORKSPACE_NOT_FOUND =
      SettingsFaultCode._(
          6, _omitEnumNames ? '' : 'SETTINGS_FAULT_CODE_WORKSPACE_NOT_FOUND');

  static const $core.List<SettingsFaultCode> values = <SettingsFaultCode>[
    SETTINGS_FAULT_CODE_UNSPECIFIED,
    SETTINGS_FAULT_CODE_INVALID_SCOPE,
    SETTINGS_FAULT_CODE_INVALID_DOCUMENT,
    SETTINGS_FAULT_CODE_UNSUPPORTED_VERSION,
    SETTINGS_FAULT_CODE_INVALID_VALUE,
    SETTINGS_FAULT_CODE_UNAVAILABLE,
    SETTINGS_FAULT_CODE_WORKSPACE_NOT_FOUND,
  ];

  static final $core.List<SettingsFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static SettingsFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SettingsFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
