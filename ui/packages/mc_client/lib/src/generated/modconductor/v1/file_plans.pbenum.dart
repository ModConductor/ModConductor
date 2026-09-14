// This is a generated file - do not edit.
//
// Generated from modconductor/v1/file_plans.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FileSourceStanding extends $pb.ProtobufEnum {
  static const FileSourceStanding FILE_SOURCE_STANDING_UNSPECIFIED =
      FileSourceStanding._(
          0, _omitEnumNames ? '' : 'FILE_SOURCE_STANDING_UNSPECIFIED');
  static const FileSourceStanding FILE_SOURCE_STANDING_WINNER =
      FileSourceStanding._(
          1, _omitEnumNames ? '' : 'FILE_SOURCE_STANDING_WINNER');
  static const FileSourceStanding FILE_SOURCE_STANDING_ALTERNATIVE =
      FileSourceStanding._(
          2, _omitEnumNames ? '' : 'FILE_SOURCE_STANDING_ALTERNATIVE');
  static const FileSourceStanding FILE_SOURCE_STANDING_SELECTED =
      FileSourceStanding._(
          3, _omitEnumNames ? '' : 'FILE_SOURCE_STANDING_SELECTED');
  static const FileSourceStanding FILE_SOURCE_STANDING_PREVIOUS =
      FileSourceStanding._(
          4, _omitEnumNames ? '' : 'FILE_SOURCE_STANDING_PREVIOUS');
  static const FileSourceStanding FILE_SOURCE_STANDING_UNAVAILABLE =
      FileSourceStanding._(
          5, _omitEnumNames ? '' : 'FILE_SOURCE_STANDING_UNAVAILABLE');

  static const $core.List<FileSourceStanding> values = <FileSourceStanding>[
    FILE_SOURCE_STANDING_UNSPECIFIED,
    FILE_SOURCE_STANDING_WINNER,
    FILE_SOURCE_STANDING_ALTERNATIVE,
    FILE_SOURCE_STANDING_SELECTED,
    FILE_SOURCE_STANDING_PREVIOUS,
    FILE_SOURCE_STANDING_UNAVAILABLE,
  ];

  static final $core.List<FileSourceStanding?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static FileSourceStanding? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FileSourceStanding._(super.value, super.name);
}

class FilePreviewRepresentation extends $pb.ProtobufEnum {
  static const FilePreviewRepresentation
      FILE_PREVIEW_REPRESENTATION_UNSPECIFIED = FilePreviewRepresentation._(
          0, _omitEnumNames ? '' : 'FILE_PREVIEW_REPRESENTATION_UNSPECIFIED');
  static const FilePreviewRepresentation FILE_PREVIEW_REPRESENTATION_TEXT =
      FilePreviewRepresentation._(
          1, _omitEnumNames ? '' : 'FILE_PREVIEW_REPRESENTATION_TEXT');
  static const FilePreviewRepresentation FILE_PREVIEW_REPRESENTATION_IMAGE =
      FilePreviewRepresentation._(
          2, _omitEnumNames ? '' : 'FILE_PREVIEW_REPRESENTATION_IMAGE');
  static const FilePreviewRepresentation FILE_PREVIEW_REPRESENTATION_HEX =
      FilePreviewRepresentation._(
          3, _omitEnumNames ? '' : 'FILE_PREVIEW_REPRESENTATION_HEX');

  static const $core.List<FilePreviewRepresentation> values =
      <FilePreviewRepresentation>[
    FILE_PREVIEW_REPRESENTATION_UNSPECIFIED,
    FILE_PREVIEW_REPRESENTATION_TEXT,
    FILE_PREVIEW_REPRESENTATION_IMAGE,
    FILE_PREVIEW_REPRESENTATION_HEX,
  ];

  static final $core.List<FilePreviewRepresentation?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static FilePreviewRepresentation? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FilePreviewRepresentation._(super.value, super.name);
}

class FilePreviewStatus extends $pb.ProtobufEnum {
  static const FilePreviewStatus FILE_PREVIEW_STATUS_UNSPECIFIED =
      FilePreviewStatus._(
          0, _omitEnumNames ? '' : 'FILE_PREVIEW_STATUS_UNSPECIFIED');
  static const FilePreviewStatus FILE_PREVIEW_STATUS_READY =
      FilePreviewStatus._(1, _omitEnumNames ? '' : 'FILE_PREVIEW_STATUS_READY');
  static const FilePreviewStatus FILE_PREVIEW_STATUS_UNSUPPORTED =
      FilePreviewStatus._(
          2, _omitEnumNames ? '' : 'FILE_PREVIEW_STATUS_UNSUPPORTED');
  static const FilePreviewStatus FILE_PREVIEW_STATUS_TOO_LARGE =
      FilePreviewStatus._(
          3, _omitEnumNames ? '' : 'FILE_PREVIEW_STATUS_TOO_LARGE');
  static const FilePreviewStatus FILE_PREVIEW_STATUS_CHANGED =
      FilePreviewStatus._(
          4, _omitEnumNames ? '' : 'FILE_PREVIEW_STATUS_CHANGED');

  static const $core.List<FilePreviewStatus> values = <FilePreviewStatus>[
    FILE_PREVIEW_STATUS_UNSPECIFIED,
    FILE_PREVIEW_STATUS_READY,
    FILE_PREVIEW_STATUS_UNSUPPORTED,
    FILE_PREVIEW_STATUS_TOO_LARGE,
    FILE_PREVIEW_STATUS_CHANGED,
  ];

  static final $core.List<FilePreviewStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static FilePreviewStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FilePreviewStatus._(super.value, super.name);
}

class TextDocumentEncoding extends $pb.ProtobufEnum {
  static const TextDocumentEncoding TEXT_DOCUMENT_ENCODING_UNSPECIFIED =
      TextDocumentEncoding._(
          0, _omitEnumNames ? '' : 'TEXT_DOCUMENT_ENCODING_UNSPECIFIED');
  static const TextDocumentEncoding TEXT_DOCUMENT_ENCODING_UTF8 =
      TextDocumentEncoding._(
          1, _omitEnumNames ? '' : 'TEXT_DOCUMENT_ENCODING_UTF8');
  static const TextDocumentEncoding TEXT_DOCUMENT_ENCODING_UTF8_BOM =
      TextDocumentEncoding._(
          2, _omitEnumNames ? '' : 'TEXT_DOCUMENT_ENCODING_UTF8_BOM');
  static const TextDocumentEncoding TEXT_DOCUMENT_ENCODING_UTF16_LITTLE =
      TextDocumentEncoding._(
          3, _omitEnumNames ? '' : 'TEXT_DOCUMENT_ENCODING_UTF16_LITTLE');
  static const TextDocumentEncoding TEXT_DOCUMENT_ENCODING_UTF16_BIG =
      TextDocumentEncoding._(
          4, _omitEnumNames ? '' : 'TEXT_DOCUMENT_ENCODING_UTF16_BIG');

  static const $core.List<TextDocumentEncoding> values = <TextDocumentEncoding>[
    TEXT_DOCUMENT_ENCODING_UNSPECIFIED,
    TEXT_DOCUMENT_ENCODING_UTF8,
    TEXT_DOCUMENT_ENCODING_UTF8_BOM,
    TEXT_DOCUMENT_ENCODING_UTF16_LITTLE,
    TEXT_DOCUMENT_ENCODING_UTF16_BIG,
  ];

  static final $core.List<TextDocumentEncoding?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static TextDocumentEncoding? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TextDocumentEncoding._(super.value, super.name);
}

class TextDocumentNewline extends $pb.ProtobufEnum {
  static const TextDocumentNewline TEXT_DOCUMENT_NEWLINE_UNSPECIFIED =
      TextDocumentNewline._(
          0, _omitEnumNames ? '' : 'TEXT_DOCUMENT_NEWLINE_UNSPECIFIED');
  static const TextDocumentNewline TEXT_DOCUMENT_NEWLINE_NO_LINE_BREAKS =
      TextDocumentNewline._(
          1, _omitEnumNames ? '' : 'TEXT_DOCUMENT_NEWLINE_NO_LINE_BREAKS');
  static const TextDocumentNewline TEXT_DOCUMENT_NEWLINE_LF =
      TextDocumentNewline._(
          2, _omitEnumNames ? '' : 'TEXT_DOCUMENT_NEWLINE_LF');
  static const TextDocumentNewline TEXT_DOCUMENT_NEWLINE_CRLF =
      TextDocumentNewline._(
          3, _omitEnumNames ? '' : 'TEXT_DOCUMENT_NEWLINE_CRLF');

  static const $core.List<TextDocumentNewline> values = <TextDocumentNewline>[
    TEXT_DOCUMENT_NEWLINE_UNSPECIFIED,
    TEXT_DOCUMENT_NEWLINE_NO_LINE_BREAKS,
    TEXT_DOCUMENT_NEWLINE_LF,
    TEXT_DOCUMENT_NEWLINE_CRLF,
  ];

  static final $core.List<TextDocumentNewline?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TextDocumentNewline? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TextDocumentNewline._(super.value, super.name);
}

class PlannedFileDisposition extends $pb.ProtobufEnum {
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_UNSPECIFIED =
      PlannedFileDisposition._(
          0, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_UNSPECIFIED');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_PLANNED =
      PlannedFileDisposition._(
          1, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_PLANNED');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_ABSENT =
      PlannedFileDisposition._(
          2, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_ABSENT');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_UNRESOLVED =
      PlannedFileDisposition._(
          3, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_UNRESOLVED');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_WRITABLE =
      PlannedFileDisposition._(
          4, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_WRITABLE');

  static const $core.List<PlannedFileDisposition> values =
      <PlannedFileDisposition>[
    PLANNED_FILE_DISPOSITION_UNSPECIFIED,
    PLANNED_FILE_DISPOSITION_PLANNED,
    PLANNED_FILE_DISPOSITION_ABSENT,
    PLANNED_FILE_DISPOSITION_UNRESOLVED,
    PLANNED_FILE_DISPOSITION_WRITABLE,
  ];

  static final $core.List<PlannedFileDisposition?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PlannedFileDisposition? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlannedFileDisposition._(super.value, super.name);
}

class FilePlanFaultCode extends $pb.ProtobufEnum {
  static const FilePlanFaultCode FILE_PLAN_FAULT_UNSPECIFIED =
      FilePlanFaultCode._(
          0, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_UNSPECIFIED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_NOT_FOUND =
      FilePlanFaultCode._(1, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_NOT_FOUND');
  static const FilePlanFaultCode FILE_PLAN_FAULT_BUSY =
      FilePlanFaultCode._(2, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_BUSY');
  static const FilePlanFaultCode FILE_PLAN_FAULT_EXPIRED =
      FilePlanFaultCode._(3, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_EXPIRED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_STALE =
      FilePlanFaultCode._(4, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_STALE');
  static const FilePlanFaultCode FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE =
      FilePlanFaultCode._(
          5, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE');
  static const FilePlanFaultCode FILE_PLAN_FAULT_FILE_UNAVAILABLE =
      FilePlanFaultCode._(
          6, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_FILE_UNAVAILABLE');
  static const FilePlanFaultCode FILE_PLAN_FAULT_LIMIT_EXCEEDED =
      FilePlanFaultCode._(
          7, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_LIMIT_EXCEEDED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_CANCELLED =
      FilePlanFaultCode._(8, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_CANCELLED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_INVALID_COPY =
      FilePlanFaultCode._(
          9, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_INVALID_COPY');
  static const FilePlanFaultCode FILE_PLAN_FAULT_BLOCKED =
      FilePlanFaultCode._(10, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_BLOCKED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_UNSUPPORTED =
      FilePlanFaultCode._(
          11, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_UNSUPPORTED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_INVALID_EDIT =
      FilePlanFaultCode._(
          12, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_INVALID_EDIT');

  static const $core.List<FilePlanFaultCode> values = <FilePlanFaultCode>[
    FILE_PLAN_FAULT_UNSPECIFIED,
    FILE_PLAN_FAULT_NOT_FOUND,
    FILE_PLAN_FAULT_BUSY,
    FILE_PLAN_FAULT_EXPIRED,
    FILE_PLAN_FAULT_STALE,
    FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE,
    FILE_PLAN_FAULT_FILE_UNAVAILABLE,
    FILE_PLAN_FAULT_LIMIT_EXCEEDED,
    FILE_PLAN_FAULT_CANCELLED,
    FILE_PLAN_FAULT_INVALID_COPY,
    FILE_PLAN_FAULT_BLOCKED,
    FILE_PLAN_FAULT_UNSUPPORTED,
    FILE_PLAN_FAULT_INVALID_EDIT,
  ];

  static final $core.List<FilePlanFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static FilePlanFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FilePlanFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
