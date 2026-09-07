// This is a generated file - do not edit.
//
// Generated from modconductor/v1/steam_discovery.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SteamDiscoveryProblem extends $pb.ProtobufEnum {
  static const SteamDiscoveryProblem STEAM_DISCOVERY_PROBLEM_UNSPECIFIED =
      SteamDiscoveryProblem._(
          0, _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_UNSPECIFIED');
  static const SteamDiscoveryProblem STEAM_DISCOVERY_PROBLEM_ROOT_UNAVAILABLE =
      SteamDiscoveryProblem._(
          1, _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_ROOT_UNAVAILABLE');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_LIBRARIES_UNREADABLE = SteamDiscoveryProblem._(2,
          _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_LIBRARIES_UNREADABLE');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_LIBRARIES_MALFORMED = SteamDiscoveryProblem._(3,
          _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_LIBRARIES_MALFORMED');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_LIBRARY_PATH_INVALID = SteamDiscoveryProblem._(4,
          _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_LIBRARY_PATH_INVALID');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_MANIFEST_UNREADABLE = SteamDiscoveryProblem._(5,
          _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_MANIFEST_UNREADABLE');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_MANIFEST_MALFORMED = SteamDiscoveryProblem._(6,
          _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_MANIFEST_MALFORMED');
  static const SteamDiscoveryProblem STEAM_DISCOVERY_PROBLEM_STALE_ENTRY =
      SteamDiscoveryProblem._(
          7, _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_STALE_ENTRY');
  static const SteamDiscoveryProblem STEAM_DISCOVERY_PROBLEM_APP_ID_MISMATCH =
      SteamDiscoveryProblem._(
          8, _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_APP_ID_MISMATCH');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_UNSAFE_INSTALL_DIRECTORY =
      SteamDiscoveryProblem._(
          9,
          _omitEnumNames
              ? ''
              : 'STEAM_DISCOVERY_PROBLEM_UNSAFE_INSTALL_DIRECTORY');
  static const SteamDiscoveryProblem
      STEAM_DISCOVERY_PROBLEM_INSTALLATION_UNAVAILABLE =
      SteamDiscoveryProblem._(
          10,
          _omitEnumNames
              ? ''
              : 'STEAM_DISCOVERY_PROBLEM_INSTALLATION_UNAVAILABLE');
  static const SteamDiscoveryProblem STEAM_DISCOVERY_PROBLEM_LIMIT_REACHED =
      SteamDiscoveryProblem._(
          11, _omitEnumNames ? '' : 'STEAM_DISCOVERY_PROBLEM_LIMIT_REACHED');

  static const $core.List<SteamDiscoveryProblem> values =
      <SteamDiscoveryProblem>[
    STEAM_DISCOVERY_PROBLEM_UNSPECIFIED,
    STEAM_DISCOVERY_PROBLEM_ROOT_UNAVAILABLE,
    STEAM_DISCOVERY_PROBLEM_LIBRARIES_UNREADABLE,
    STEAM_DISCOVERY_PROBLEM_LIBRARIES_MALFORMED,
    STEAM_DISCOVERY_PROBLEM_LIBRARY_PATH_INVALID,
    STEAM_DISCOVERY_PROBLEM_MANIFEST_UNREADABLE,
    STEAM_DISCOVERY_PROBLEM_MANIFEST_MALFORMED,
    STEAM_DISCOVERY_PROBLEM_STALE_ENTRY,
    STEAM_DISCOVERY_PROBLEM_APP_ID_MISMATCH,
    STEAM_DISCOVERY_PROBLEM_UNSAFE_INSTALL_DIRECTORY,
    STEAM_DISCOVERY_PROBLEM_INSTALLATION_UNAVAILABLE,
    STEAM_DISCOVERY_PROBLEM_LIMIT_REACHED,
  ];

  static final $core.List<SteamDiscoveryProblem?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static SteamDiscoveryProblem? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SteamDiscoveryProblem._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
