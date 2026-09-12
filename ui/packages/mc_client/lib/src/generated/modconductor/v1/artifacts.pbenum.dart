// This is a generated file - do not edit.
//
// Generated from modconductor/v1/artifacts.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ArchiveStorage extends $pb.ProtobufEnum {
  static const ArchiveStorage ARCHIVE_STORAGE_UNSPECIFIED =
      ArchiveStorage._(0, _omitEnumNames ? '' : 'ARCHIVE_STORAGE_UNSPECIFIED');
  static const ArchiveStorage ARCHIVE_STORAGE_REFERENCE =
      ArchiveStorage._(1, _omitEnumNames ? '' : 'ARCHIVE_STORAGE_REFERENCE');
  static const ArchiveStorage ARCHIVE_STORAGE_COPY =
      ArchiveStorage._(2, _omitEnumNames ? '' : 'ARCHIVE_STORAGE_COPY');

  static const $core.List<ArchiveStorage> values = <ArchiveStorage>[
    ARCHIVE_STORAGE_UNSPECIFIED,
    ARCHIVE_STORAGE_REFERENCE,
    ARCHIVE_STORAGE_COPY,
  ];

  static final $core.List<ArchiveStorage?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ArchiveStorage? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ArchiveStorage._(super.value, super.name);
}

class ArchiveState extends $pb.ProtobufEnum {
  static const ArchiveState ARCHIVE_STATE_UNSPECIFIED =
      ArchiveState._(0, _omitEnumNames ? '' : 'ARCHIVE_STATE_UNSPECIFIED');
  static const ArchiveState ARCHIVE_STATE_INCOMPLETE =
      ArchiveState._(1, _omitEnumNames ? '' : 'ARCHIVE_STATE_INCOMPLETE');
  static const ArchiveState ARCHIVE_STATE_READY =
      ArchiveState._(2, _omitEnumNames ? '' : 'ARCHIVE_STATE_READY');
  static const ArchiveState ARCHIVE_STATE_DETACHED =
      ArchiveState._(3, _omitEnumNames ? '' : 'ARCHIVE_STATE_DETACHED');
  static const ArchiveState ARCHIVE_STATE_INSTALLED =
      ArchiveState._(4, _omitEnumNames ? '' : 'ARCHIVE_STATE_INSTALLED');

  static const $core.List<ArchiveState> values = <ArchiveState>[
    ARCHIVE_STATE_UNSPECIFIED,
    ARCHIVE_STATE_INCOMPLETE,
    ARCHIVE_STATE_READY,
    ARCHIVE_STATE_DETACHED,
    ARCHIVE_STATE_INSTALLED,
  ];

  static final $core.List<ArchiveState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ArchiveState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ArchiveState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
