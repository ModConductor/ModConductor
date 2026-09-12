// This is a generated file - do not edit.
//
// Generated from modconductor/v1/downloads.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DownloadCommand extends $pb.ProtobufEnum {
  static const DownloadCommand DOWNLOAD_COMMAND_UNSPECIFIED = DownloadCommand._(
      0, _omitEnumNames ? '' : 'DOWNLOAD_COMMAND_UNSPECIFIED');
  static const DownloadCommand DOWNLOAD_COMMAND_PAUSE =
      DownloadCommand._(1, _omitEnumNames ? '' : 'DOWNLOAD_COMMAND_PAUSE');
  static const DownloadCommand DOWNLOAD_COMMAND_RESUME =
      DownloadCommand._(2, _omitEnumNames ? '' : 'DOWNLOAD_COMMAND_RESUME');
  static const DownloadCommand DOWNLOAD_COMMAND_RESTART =
      DownloadCommand._(3, _omitEnumNames ? '' : 'DOWNLOAD_COMMAND_RESTART');

  static const $core.List<DownloadCommand> values = <DownloadCommand>[
    DOWNLOAD_COMMAND_UNSPECIFIED,
    DOWNLOAD_COMMAND_PAUSE,
    DOWNLOAD_COMMAND_RESUME,
    DOWNLOAD_COMMAND_RESTART,
  ];

  static final $core.List<DownloadCommand?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static DownloadCommand? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DownloadCommand._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
