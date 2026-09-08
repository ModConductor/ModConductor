// This is a generated file - do not edit.
//
// Generated from modconductor/v1/generated_outputs.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class OutputLocationKind extends $pb.ProtobufEnum {
  static const OutputLocationKind OUTPUT_LOCATION_KIND_UNSPECIFIED =
      OutputLocationKind._(
          0, _omitEnumNames ? '' : 'OUTPUT_LOCATION_KIND_UNSPECIFIED');
  static const OutputLocationKind OUTPUT_LOCATION_KIND_TOOL_FOLDER =
      OutputLocationKind._(
          1, _omitEnumNames ? '' : 'OUTPUT_LOCATION_KIND_TOOL_FOLDER');
  static const OutputLocationKind OUTPUT_LOCATION_KIND_WRITABLE_FILE =
      OutputLocationKind._(
          2, _omitEnumNames ? '' : 'OUTPUT_LOCATION_KIND_WRITABLE_FILE');

  static const $core.List<OutputLocationKind> values = <OutputLocationKind>[
    OUTPUT_LOCATION_KIND_UNSPECIFIED,
    OUTPUT_LOCATION_KIND_TOOL_FOLDER,
    OUTPUT_LOCATION_KIND_WRITABLE_FILE,
  ];

  static final $core.List<OutputLocationKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static OutputLocationKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputLocationKind._(super.value, super.name);
}

class OutputLocationStatus extends $pb.ProtobufEnum {
  static const OutputLocationStatus OUTPUT_LOCATION_STATUS_UNSPECIFIED =
      OutputLocationStatus._(
          0, _omitEnumNames ? '' : 'OUTPUT_LOCATION_STATUS_UNSPECIFIED');
  static const OutputLocationStatus OUTPUT_LOCATION_STATUS_UNINITIALIZED =
      OutputLocationStatus._(
          1, _omitEnumNames ? '' : 'OUTPUT_LOCATION_STATUS_UNINITIALIZED');
  static const OutputLocationStatus OUTPUT_LOCATION_STATUS_READY =
      OutputLocationStatus._(
          2, _omitEnumNames ? '' : 'OUTPUT_LOCATION_STATUS_READY');
  static const OutputLocationStatus OUTPUT_LOCATION_STATUS_STOPPED =
      OutputLocationStatus._(
          3, _omitEnumNames ? '' : 'OUTPUT_LOCATION_STATUS_STOPPED');

  static const $core.List<OutputLocationStatus> values = <OutputLocationStatus>[
    OUTPUT_LOCATION_STATUS_UNSPECIFIED,
    OUTPUT_LOCATION_STATUS_UNINITIALIZED,
    OUTPUT_LOCATION_STATUS_READY,
    OUTPUT_LOCATION_STATUS_STOPPED,
  ];

  static final $core.List<OutputLocationStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static OutputLocationStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputLocationStatus._(super.value, super.name);
}

class OutputFileStatus extends $pb.ProtobufEnum {
  static const OutputFileStatus OUTPUT_FILE_STATUS_UNSPECIFIED =
      OutputFileStatus._(
          0, _omitEnumNames ? '' : 'OUTPUT_FILE_STATUS_UNSPECIFIED');
  static const OutputFileStatus OUTPUT_FILE_STATUS_NEW =
      OutputFileStatus._(1, _omitEnumNames ? '' : 'OUTPUT_FILE_STATUS_NEW');
  static const OutputFileStatus OUTPUT_FILE_STATUS_CHANGED =
      OutputFileStatus._(2, _omitEnumNames ? '' : 'OUTPUT_FILE_STATUS_CHANGED');
  static const OutputFileStatus OUTPUT_FILE_STATUS_KEPT =
      OutputFileStatus._(3, _omitEnumNames ? '' : 'OUTPUT_FILE_STATUS_KEPT');
  static const OutputFileStatus OUTPUT_FILE_STATUS_ABSENT =
      OutputFileStatus._(4, _omitEnumNames ? '' : 'OUTPUT_FILE_STATUS_ABSENT');

  static const $core.List<OutputFileStatus> values = <OutputFileStatus>[
    OUTPUT_FILE_STATUS_UNSPECIFIED,
    OUTPUT_FILE_STATUS_NEW,
    OUTPUT_FILE_STATUS_CHANGED,
    OUTPUT_FILE_STATUS_KEPT,
    OUTPUT_FILE_STATUS_ABSENT,
  ];

  static final $core.List<OutputFileStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static OutputFileStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputFileStatus._(super.value, super.name);
}

class OutputActionKind extends $pb.ProtobufEnum {
  static const OutputActionKind OUTPUT_ACTION_KIND_UNSPECIFIED =
      OutputActionKind._(
          0, _omitEnumNames ? '' : 'OUTPUT_ACTION_KIND_UNSPECIFIED');
  static const OutputActionKind OUTPUT_ACTION_KIND_KEEP =
      OutputActionKind._(1, _omitEnumNames ? '' : 'OUTPUT_ACTION_KIND_KEEP');
  static const OutputActionKind OUTPUT_ACTION_KIND_DISCARD =
      OutputActionKind._(2, _omitEnumNames ? '' : 'OUTPUT_ACTION_KIND_DISCARD');
  static const OutputActionKind OUTPUT_ACTION_KIND_MOVE_TO_MOD =
      OutputActionKind._(
          3, _omitEnumNames ? '' : 'OUTPUT_ACTION_KIND_MOVE_TO_MOD');
  static const OutputActionKind OUTPUT_ACTION_KIND_SAVE_COPY_TO_MOD =
      OutputActionKind._(
          4, _omitEnumNames ? '' : 'OUTPUT_ACTION_KIND_SAVE_COPY_TO_MOD');

  static const $core.List<OutputActionKind> values = <OutputActionKind>[
    OUTPUT_ACTION_KIND_UNSPECIFIED,
    OUTPUT_ACTION_KIND_KEEP,
    OUTPUT_ACTION_KIND_DISCARD,
    OUTPUT_ACTION_KIND_MOVE_TO_MOD,
    OUTPUT_ACTION_KIND_SAVE_COPY_TO_MOD,
  ];

  static final $core.List<OutputActionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static OutputActionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputActionKind._(super.value, super.name);
}

class OutputDisposition extends $pb.ProtobufEnum {
  static const OutputDisposition OUTPUT_DISPOSITION_UNSPECIFIED =
      OutputDisposition._(
          0, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_UNSPECIFIED');
  static const OutputDisposition OUTPUT_DISPOSITION_KEPT =
      OutputDisposition._(1, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_KEPT');
  static const OutputDisposition OUTPUT_DISPOSITION_DISCARDED =
      OutputDisposition._(
          2, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_DISCARDED');
  static const OutputDisposition OUTPUT_DISPOSITION_MOVED =
      OutputDisposition._(3, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_MOVED');
  static const OutputDisposition OUTPUT_DISPOSITION_COPIED =
      OutputDisposition._(4, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_COPIED');
  static const OutputDisposition OUTPUT_DISPOSITION_CHANGED =
      OutputDisposition._(
          5, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_CHANGED');
  static const OutputDisposition OUTPUT_DISPOSITION_PENDING =
      OutputDisposition._(
          6, _omitEnumNames ? '' : 'OUTPUT_DISPOSITION_PENDING');

  static const $core.List<OutputDisposition> values = <OutputDisposition>[
    OUTPUT_DISPOSITION_UNSPECIFIED,
    OUTPUT_DISPOSITION_KEPT,
    OUTPUT_DISPOSITION_DISCARDED,
    OUTPUT_DISPOSITION_MOVED,
    OUTPUT_DISPOSITION_COPIED,
    OUTPUT_DISPOSITION_CHANGED,
    OUTPUT_DISPOSITION_PENDING,
  ];

  static final $core.List<OutputDisposition?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static OutputDisposition? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputDisposition._(super.value, super.name);
}

class OutputFaultCode extends $pb.ProtobufEnum {
  static const OutputFaultCode OUTPUT_FAULT_UNSPECIFIED =
      OutputFaultCode._(0, _omitEnumNames ? '' : 'OUTPUT_FAULT_UNSPECIFIED');
  static const OutputFaultCode OUTPUT_FAULT_NOT_FOUND =
      OutputFaultCode._(1, _omitEnumNames ? '' : 'OUTPUT_FAULT_NOT_FOUND');
  static const OutputFaultCode OUTPUT_FAULT_BUSY =
      OutputFaultCode._(2, _omitEnumNames ? '' : 'OUTPUT_FAULT_BUSY');
  static const OutputFaultCode OUTPUT_FAULT_STALE =
      OutputFaultCode._(3, _omitEnumNames ? '' : 'OUTPUT_FAULT_STALE');
  static const OutputFaultCode OUTPUT_FAULT_CANCELLED =
      OutputFaultCode._(4, _omitEnumNames ? '' : 'OUTPUT_FAULT_CANCELLED');
  static const OutputFaultCode OUTPUT_FAULT_INVALID =
      OutputFaultCode._(5, _omitEnumNames ? '' : 'OUTPUT_FAULT_INVALID');
  static const OutputFaultCode OUTPUT_FAULT_UNAVAILABLE =
      OutputFaultCode._(6, _omitEnumNames ? '' : 'OUTPUT_FAULT_UNAVAILABLE');
  static const OutputFaultCode OUTPUT_FAULT_LIMIT_EXCEEDED =
      OutputFaultCode._(7, _omitEnumNames ? '' : 'OUTPUT_FAULT_LIMIT_EXCEEDED');

  static const $core.List<OutputFaultCode> values = <OutputFaultCode>[
    OUTPUT_FAULT_UNSPECIFIED,
    OUTPUT_FAULT_NOT_FOUND,
    OUTPUT_FAULT_BUSY,
    OUTPUT_FAULT_STALE,
    OUTPUT_FAULT_CANCELLED,
    OUTPUT_FAULT_INVALID,
    OUTPUT_FAULT_UNAVAILABLE,
    OUTPUT_FAULT_LIMIT_EXCEEDED,
  ];

  static final $core.List<OutputFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static OutputFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
