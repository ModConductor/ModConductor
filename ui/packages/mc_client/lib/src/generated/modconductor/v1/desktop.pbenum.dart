// This is a generated file - do not edit.
//
// Generated from modconductor/v1/desktop.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DesktopIntentKind extends $pb.ProtobufEnum {
  static const DesktopIntentKind DESKTOP_INTENT_KIND_UNSPECIFIED =
      DesktopIntentKind._(
          0, _omitEnumNames ? '' : 'DESKTOP_INTENT_KIND_UNSPECIFIED');
  static const DesktopIntentKind DESKTOP_INTENT_KIND_SHOW =
      DesktopIntentKind._(1, _omitEnumNames ? '' : 'DESKTOP_INTENT_KIND_SHOW');
  static const DesktopIntentKind DESKTOP_INTENT_KIND_WORKSPACE =
      DesktopIntentKind._(
          2, _omitEnumNames ? '' : 'DESKTOP_INTENT_KIND_WORKSPACE');
  static const DesktopIntentKind DESKTOP_INTENT_KIND_ARCHIVE =
      DesktopIntentKind._(
          3, _omitEnumNames ? '' : 'DESKTOP_INTENT_KIND_ARCHIVE');
  static const DesktopIntentKind DESKTOP_INTENT_KIND_ARCHIVES =
      DesktopIntentKind._(
          4, _omitEnumNames ? '' : 'DESKTOP_INTENT_KIND_ARCHIVES');
  static const DesktopIntentKind DESKTOP_INTENT_KIND_PROFILE =
      DesktopIntentKind._(
          5, _omitEnumNames ? '' : 'DESKTOP_INTENT_KIND_PROFILE');

  static const $core.List<DesktopIntentKind> values = <DesktopIntentKind>[
    DESKTOP_INTENT_KIND_UNSPECIFIED,
    DESKTOP_INTENT_KIND_SHOW,
    DESKTOP_INTENT_KIND_WORKSPACE,
    DESKTOP_INTENT_KIND_ARCHIVE,
    DESKTOP_INTENT_KIND_ARCHIVES,
    DESKTOP_INTENT_KIND_PROFILE,
  ];

  static final $core.List<DesktopIntentKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static DesktopIntentKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DesktopIntentKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
