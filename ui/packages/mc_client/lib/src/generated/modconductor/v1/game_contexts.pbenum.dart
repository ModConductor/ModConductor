// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_contexts.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GameContextPlatform extends $pb.ProtobufEnum {
  static const GameContextPlatform GAME_CONTEXT_PLATFORM_UNSPECIFIED =
      GameContextPlatform._(
          0, _omitEnumNames ? '' : 'GAME_CONTEXT_PLATFORM_UNSPECIFIED');
  static const GameContextPlatform GAME_CONTEXT_PLATFORM_WINDOWS =
      GameContextPlatform._(
          1, _omitEnumNames ? '' : 'GAME_CONTEXT_PLATFORM_WINDOWS');
  static const GameContextPlatform GAME_CONTEXT_PLATFORM_PROTON =
      GameContextPlatform._(
          2, _omitEnumNames ? '' : 'GAME_CONTEXT_PLATFORM_PROTON');

  static const $core.List<GameContextPlatform> values = <GameContextPlatform>[
    GAME_CONTEXT_PLATFORM_UNSPECIFIED,
    GAME_CONTEXT_PLATFORM_WINDOWS,
    GAME_CONTEXT_PLATFORM_PROTON,
  ];

  static final $core.List<GameContextPlatform?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static GameContextPlatform? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GameContextPlatform._(super.value, super.name);
}

class GameContextFaultCode extends $pb.ProtobufEnum {
  static const GameContextFaultCode GAME_CONTEXT_FAULT_UNSPECIFIED =
      GameContextFaultCode._(
          0, _omitEnumNames ? '' : 'GAME_CONTEXT_FAULT_UNSPECIFIED');
  static const GameContextFaultCode GAME_CONTEXT_FAULT_NOT_FOUND =
      GameContextFaultCode._(
          1, _omitEnumNames ? '' : 'GAME_CONTEXT_FAULT_NOT_FOUND');
  static const GameContextFaultCode GAME_CONTEXT_FAULT_STALE_REVISION =
      GameContextFaultCode._(
          2, _omitEnumNames ? '' : 'GAME_CONTEXT_FAULT_STALE_REVISION');
  static const GameContextFaultCode GAME_CONTEXT_FAULT_WORKSPACE_UNAVAILABLE =
      GameContextFaultCode._(
          3, _omitEnumNames ? '' : 'GAME_CONTEXT_FAULT_WORKSPACE_UNAVAILABLE');
  static const GameContextFaultCode GAME_CONTEXT_FAULT_INVALID_INSTALLATION =
      GameContextFaultCode._(
          4, _omitEnumNames ? '' : 'GAME_CONTEXT_FAULT_INVALID_INSTALLATION');
  static const GameContextFaultCode GAME_CONTEXT_FAULT_BUSY =
      GameContextFaultCode._(
          5, _omitEnumNames ? '' : 'GAME_CONTEXT_FAULT_BUSY');

  static const $core.List<GameContextFaultCode> values = <GameContextFaultCode>[
    GAME_CONTEXT_FAULT_UNSPECIFIED,
    GAME_CONTEXT_FAULT_NOT_FOUND,
    GAME_CONTEXT_FAULT_STALE_REVISION,
    GAME_CONTEXT_FAULT_WORKSPACE_UNAVAILABLE,
    GAME_CONTEXT_FAULT_INVALID_INSTALLATION,
    GAME_CONTEXT_FAULT_BUSY,
  ];

  static final $core.List<GameContextFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static GameContextFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GameContextFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
