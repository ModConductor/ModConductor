// This is a generated file - do not edit.
//
// Generated from modconductor/v1/link_setup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LinkDefault extends $pb.ProtobufEnum {
  static const LinkDefault LINK_DEFAULT_UNKNOWN =
      LinkDefault._(0, _omitEnumNames ? '' : 'LINK_DEFAULT_UNKNOWN');
  static const LinkDefault LINK_DEFAULT_MC =
      LinkDefault._(1, _omitEnumNames ? '' : 'LINK_DEFAULT_MC');
  static const LinkDefault LINK_DEFAULT_OTHER =
      LinkDefault._(2, _omitEnumNames ? '' : 'LINK_DEFAULT_OTHER');
  static const LinkDefault LINK_DEFAULT_NONE =
      LinkDefault._(3, _omitEnumNames ? '' : 'LINK_DEFAULT_NONE');

  static const $core.List<LinkDefault> values = <LinkDefault>[
    LINK_DEFAULT_UNKNOWN,
    LINK_DEFAULT_MC,
    LINK_DEFAULT_OTHER,
    LINK_DEFAULT_NONE,
  ];

  static final $core.List<LinkDefault?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static LinkDefault? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LinkDefault._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
