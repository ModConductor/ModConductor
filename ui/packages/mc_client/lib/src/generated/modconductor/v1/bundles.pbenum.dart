// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bundles.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class BundleModState extends $pb.ProtobufEnum {
  static const BundleModState BUNDLE_MOD_STATE_UNSPECIFIED =
      BundleModState._(0, _omitEnumNames ? '' : 'BUNDLE_MOD_STATE_UNSPECIFIED');
  static const BundleModState BUNDLE_MOD_STATE_NEEDS_REVIEW = BundleModState._(
      1, _omitEnumNames ? '' : 'BUNDLE_MOD_STATE_NEEDS_REVIEW');
  static const BundleModState BUNDLE_MOD_STATE_INSTALLED =
      BundleModState._(2, _omitEnumNames ? '' : 'BUNDLE_MOD_STATE_INSTALLED');
  static const BundleModState BUNDLE_MOD_STATE_FAILED =
      BundleModState._(3, _omitEnumNames ? '' : 'BUNDLE_MOD_STATE_FAILED');
  static const BundleModState BUNDLE_MOD_STATE_INSTALLING =
      BundleModState._(4, _omitEnumNames ? '' : 'BUNDLE_MOD_STATE_INSTALLING');

  static const $core.List<BundleModState> values = <BundleModState>[
    BUNDLE_MOD_STATE_UNSPECIFIED,
    BUNDLE_MOD_STATE_NEEDS_REVIEW,
    BUNDLE_MOD_STATE_INSTALLED,
    BUNDLE_MOD_STATE_FAILED,
    BUNDLE_MOD_STATE_INSTALLING,
  ];

  static final $core.List<BundleModState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static BundleModState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BundleModState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
