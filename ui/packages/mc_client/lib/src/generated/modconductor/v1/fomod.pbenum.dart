// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fomod.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FomodGroupKind extends $pb.ProtobufEnum {
  static const FomodGroupKind FOMOD_GROUP_KIND_ANY =
      FomodGroupKind._(0, _omitEnumNames ? '' : 'FOMOD_GROUP_KIND_ANY');
  static const FomodGroupKind FOMOD_GROUP_KIND_ALL =
      FomodGroupKind._(1, _omitEnumNames ? '' : 'FOMOD_GROUP_KIND_ALL');
  static const FomodGroupKind FOMOD_GROUP_KIND_AT_LEAST_ONE = FomodGroupKind._(
      2, _omitEnumNames ? '' : 'FOMOD_GROUP_KIND_AT_LEAST_ONE');
  static const FomodGroupKind FOMOD_GROUP_KIND_AT_MOST_ONE =
      FomodGroupKind._(3, _omitEnumNames ? '' : 'FOMOD_GROUP_KIND_AT_MOST_ONE');
  static const FomodGroupKind FOMOD_GROUP_KIND_EXACTLY_ONE =
      FomodGroupKind._(4, _omitEnumNames ? '' : 'FOMOD_GROUP_KIND_EXACTLY_ONE');

  static const $core.List<FomodGroupKind> values = <FomodGroupKind>[
    FOMOD_GROUP_KIND_ANY,
    FOMOD_GROUP_KIND_ALL,
    FOMOD_GROUP_KIND_AT_LEAST_ONE,
    FOMOD_GROUP_KIND_AT_MOST_ONE,
    FOMOD_GROUP_KIND_EXACTLY_ONE,
  ];

  static final $core.List<FomodGroupKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static FomodGroupKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FomodGroupKind._(super.value, super.name);
}

class FomodOptionKind extends $pb.ProtobufEnum {
  static const FomodOptionKind FOMOD_OPTION_KIND_REQUIRED =
      FomodOptionKind._(0, _omitEnumNames ? '' : 'FOMOD_OPTION_KIND_REQUIRED');
  static const FomodOptionKind FOMOD_OPTION_KIND_RECOMMENDED =
      FomodOptionKind._(
          1, _omitEnumNames ? '' : 'FOMOD_OPTION_KIND_RECOMMENDED');
  static const FomodOptionKind FOMOD_OPTION_KIND_OPTIONAL =
      FomodOptionKind._(2, _omitEnumNames ? '' : 'FOMOD_OPTION_KIND_OPTIONAL');
  static const FomodOptionKind FOMOD_OPTION_KIND_NOT_USABLE = FomodOptionKind._(
      3, _omitEnumNames ? '' : 'FOMOD_OPTION_KIND_NOT_USABLE');
  static const FomodOptionKind FOMOD_OPTION_KIND_COULD_BE_USABLE =
      FomodOptionKind._(
          4, _omitEnumNames ? '' : 'FOMOD_OPTION_KIND_COULD_BE_USABLE');
  static const FomodOptionKind FOMOD_OPTION_KIND_UNKNOWN =
      FomodOptionKind._(5, _omitEnumNames ? '' : 'FOMOD_OPTION_KIND_UNKNOWN');

  static const $core.List<FomodOptionKind> values = <FomodOptionKind>[
    FOMOD_OPTION_KIND_REQUIRED,
    FOMOD_OPTION_KIND_RECOMMENDED,
    FOMOD_OPTION_KIND_OPTIONAL,
    FOMOD_OPTION_KIND_NOT_USABLE,
    FOMOD_OPTION_KIND_COULD_BE_USABLE,
    FOMOD_OPTION_KIND_UNKNOWN,
  ];

  static final $core.List<FomodOptionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static FomodOptionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FomodOptionKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
