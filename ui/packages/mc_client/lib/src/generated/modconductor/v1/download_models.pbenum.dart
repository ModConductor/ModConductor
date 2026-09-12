// This is a generated file - do not edit.
//
// Generated from modconductor/v1/download_models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DownloadPhase extends $pb.ProtobufEnum {
  static const DownloadPhase DOWNLOAD_PHASE_UNSPECIFIED =
      DownloadPhase._(0, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_UNSPECIFIED');
  static const DownloadPhase DOWNLOAD_PHASE_QUEUED =
      DownloadPhase._(1, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_QUEUED');
  static const DownloadPhase DOWNLOAD_PHASE_RUNNING =
      DownloadPhase._(2, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_RUNNING');
  static const DownloadPhase DOWNLOAD_PHASE_WAITING =
      DownloadPhase._(3, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_WAITING');
  static const DownloadPhase DOWNLOAD_PHASE_PAUSED =
      DownloadPhase._(4, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_PAUSED');
  static const DownloadPhase DOWNLOAD_PHASE_FAILED =
      DownloadPhase._(5, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_FAILED');
  static const DownloadPhase DOWNLOAD_PHASE_COMPLETE =
      DownloadPhase._(6, _omitEnumNames ? '' : 'DOWNLOAD_PHASE_COMPLETE');

  static const $core.List<DownloadPhase> values = <DownloadPhase>[
    DOWNLOAD_PHASE_UNSPECIFIED,
    DOWNLOAD_PHASE_QUEUED,
    DOWNLOAD_PHASE_RUNNING,
    DOWNLOAD_PHASE_WAITING,
    DOWNLOAD_PHASE_PAUSED,
    DOWNLOAD_PHASE_FAILED,
    DOWNLOAD_PHASE_COMPLETE,
  ];

  static final $core.List<DownloadPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static DownloadPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DownloadPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
