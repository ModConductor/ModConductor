// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_library.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class InventoryModKind extends $pb.ProtobufEnum {
  static const InventoryModKind INVENTORY_MOD_KIND_UNSPECIFIED =
      InventoryModKind._(
          0, _omitEnumNames ? '' : 'INVENTORY_MOD_KIND_UNSPECIFIED');
  static const InventoryModKind INVENTORY_MOD_KIND_REGULAR =
      InventoryModKind._(1, _omitEnumNames ? '' : 'INVENTORY_MOD_KIND_REGULAR');
  static const InventoryModKind INVENTORY_MOD_KIND_SEPARATOR =
      InventoryModKind._(
          2, _omitEnumNames ? '' : 'INVENTORY_MOD_KIND_SEPARATOR');
  static const InventoryModKind INVENTORY_MOD_KIND_BACKUP =
      InventoryModKind._(3, _omitEnumNames ? '' : 'INVENTORY_MOD_KIND_BACKUP');
  static const InventoryModKind INVENTORY_MOD_KIND_UNMANAGED =
      InventoryModKind._(
          4, _omitEnumNames ? '' : 'INVENTORY_MOD_KIND_UNMANAGED');
  static const InventoryModKind INVENTORY_MOD_KIND_GENERATED_OUTPUT =
      InventoryModKind._(
          5, _omitEnumNames ? '' : 'INVENTORY_MOD_KIND_GENERATED_OUTPUT');

  static const $core.List<InventoryModKind> values = <InventoryModKind>[
    INVENTORY_MOD_KIND_UNSPECIFIED,
    INVENTORY_MOD_KIND_REGULAR,
    INVENTORY_MOD_KIND_SEPARATOR,
    INVENTORY_MOD_KIND_BACKUP,
    INVENTORY_MOD_KIND_UNMANAGED,
    INVENTORY_MOD_KIND_GENERATED_OUTPUT,
  ];

  static final $core.List<InventoryModKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static InventoryModKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InventoryModKind._(super.value, super.name);
}

class ModInventoryStatus extends $pb.ProtobufEnum {
  static const ModInventoryStatus MOD_INVENTORY_STATUS_UNSPECIFIED =
      ModInventoryStatus._(
          0, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_UNSPECIFIED');
  static const ModInventoryStatus MOD_INVENTORY_STATUS_READY =
      ModInventoryStatus._(
          1, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_READY');
  static const ModInventoryStatus MOD_INVENTORY_STATUS_DETACHED =
      ModInventoryStatus._(
          2, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_DETACHED');
  static const ModInventoryStatus MOD_INVENTORY_STATUS_CHANGED =
      ModInventoryStatus._(
          3, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_CHANGED');
  static const ModInventoryStatus MOD_INVENTORY_STATUS_UNPROVED =
      ModInventoryStatus._(
          4, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_UNPROVED');
  static const ModInventoryStatus MOD_INVENTORY_STATUS_PUBLISHING =
      ModInventoryStatus._(
          5, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_PUBLISHING');
  static const ModInventoryStatus MOD_INVENTORY_STATUS_DELETING =
      ModInventoryStatus._(
          6, _omitEnumNames ? '' : 'MOD_INVENTORY_STATUS_DELETING');

  static const $core.List<ModInventoryStatus> values = <ModInventoryStatus>[
    MOD_INVENTORY_STATUS_UNSPECIFIED,
    MOD_INVENTORY_STATUS_READY,
    MOD_INVENTORY_STATUS_DETACHED,
    MOD_INVENTORY_STATUS_CHANGED,
    MOD_INVENTORY_STATUS_UNPROVED,
    MOD_INVENTORY_STATUS_PUBLISHING,
    MOD_INVENTORY_STATUS_DELETING,
  ];

  static final $core.List<ModInventoryStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ModInventoryStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModInventoryStatus._(super.value, super.name);
}

class InventoryModAction extends $pb.ProtobufEnum {
  static const InventoryModAction INVENTORY_MOD_ACTION_UNSPECIFIED =
      InventoryModAction._(
          0, _omitEnumNames ? '' : 'INVENTORY_MOD_ACTION_UNSPECIFIED');
  static const InventoryModAction INVENTORY_MOD_ACTION_EDIT_METADATA =
      InventoryModAction._(
          1, _omitEnumNames ? '' : 'INVENTORY_MOD_ACTION_EDIT_METADATA');
  static const InventoryModAction INVENTORY_MOD_ACTION_PUBLISH =
      InventoryModAction._(
          2, _omitEnumNames ? '' : 'INVENTORY_MOD_ACTION_PUBLISH');
  static const InventoryModAction INVENTORY_MOD_ACTION_READ_VERSION =
      InventoryModAction._(
          3, _omitEnumNames ? '' : 'INVENTORY_MOD_ACTION_READ_VERSION');

  static const $core.List<InventoryModAction> values = <InventoryModAction>[
    INVENTORY_MOD_ACTION_UNSPECIFIED,
    INVENTORY_MOD_ACTION_EDIT_METADATA,
    INVENTORY_MOD_ACTION_PUBLISH,
    INVENTORY_MOD_ACTION_READ_VERSION,
  ];

  static final $core.List<InventoryModAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static InventoryModAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InventoryModAction._(super.value, super.name);
}

class ModLibraryFaultCode extends $pb.ProtobufEnum {
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_UNSPECIFIED =
      ModLibraryFaultCode._(
          0, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_UNSPECIFIED');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_NOT_FOUND =
      ModLibraryFaultCode._(
          1, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_NOT_FOUND');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_STALE_REVISION =
      ModLibraryFaultCode._(
          2, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_STALE_REVISION');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_IDENTITY_CONFLICT =
      ModLibraryFaultCode._(
          3, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_IDENTITY_CONFLICT');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_INVALID_METADATA =
      ModLibraryFaultCode._(
          4, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_INVALID_METADATA');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_INVALID_SOURCE =
      ModLibraryFaultCode._(
          5, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_INVALID_SOURCE');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_UNPROVED_OWNERSHIP =
      ModLibraryFaultCode._(
          6, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_UNPROVED_OWNERSHIP');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_SOURCE_CHANGED =
      ModLibraryFaultCode._(
          7, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_SOURCE_CHANGED');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_UNSUPPORTED_ACTION =
      ModLibraryFaultCode._(
          8, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_UNSUPPORTED_ACTION');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_BUSY =
      ModLibraryFaultCode._(
          9, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_BUSY');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_LIMIT_EXCEEDED =
      ModLibraryFaultCode._(
          10, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_LIMIT_EXCEEDED');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_FILE_UNAVAILABLE =
      ModLibraryFaultCode._(
          11, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_FILE_UNAVAILABLE');
  static const ModLibraryFaultCode MOD_LIBRARY_FAULT_CODE_CANCELLED =
      ModLibraryFaultCode._(
          12, _omitEnumNames ? '' : 'MOD_LIBRARY_FAULT_CODE_CANCELLED');

  static const $core.List<ModLibraryFaultCode> values = <ModLibraryFaultCode>[
    MOD_LIBRARY_FAULT_CODE_UNSPECIFIED,
    MOD_LIBRARY_FAULT_CODE_NOT_FOUND,
    MOD_LIBRARY_FAULT_CODE_STALE_REVISION,
    MOD_LIBRARY_FAULT_CODE_IDENTITY_CONFLICT,
    MOD_LIBRARY_FAULT_CODE_INVALID_METADATA,
    MOD_LIBRARY_FAULT_CODE_INVALID_SOURCE,
    MOD_LIBRARY_FAULT_CODE_UNPROVED_OWNERSHIP,
    MOD_LIBRARY_FAULT_CODE_SOURCE_CHANGED,
    MOD_LIBRARY_FAULT_CODE_UNSUPPORTED_ACTION,
    MOD_LIBRARY_FAULT_CODE_BUSY,
    MOD_LIBRARY_FAULT_CODE_LIMIT_EXCEEDED,
    MOD_LIBRARY_FAULT_CODE_FILE_UNAVAILABLE,
    MOD_LIBRARY_FAULT_CODE_CANCELLED,
  ];

  static final $core.List<ModLibraryFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static ModLibraryFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModLibraryFaultCode._(super.value, super.name);
}

class ModPublicationPhase extends $pb.ProtobufEnum {
  static const ModPublicationPhase MOD_PUBLICATION_PHASE_UNSPECIFIED =
      ModPublicationPhase._(
          0, _omitEnumNames ? '' : 'MOD_PUBLICATION_PHASE_UNSPECIFIED');
  static const ModPublicationPhase MOD_PUBLICATION_PHASE_INTENT =
      ModPublicationPhase._(
          1, _omitEnumNames ? '' : 'MOD_PUBLICATION_PHASE_INTENT');
  static const ModPublicationPhase MOD_PUBLICATION_PHASE_OBSERVED =
      ModPublicationPhase._(
          2, _omitEnumNames ? '' : 'MOD_PUBLICATION_PHASE_OBSERVED');
  static const ModPublicationPhase MOD_PUBLICATION_PHASE_COMPLETE =
      ModPublicationPhase._(
          3, _omitEnumNames ? '' : 'MOD_PUBLICATION_PHASE_COMPLETE');
  static const ModPublicationPhase MOD_PUBLICATION_PHASE_INTERRUPTED =
      ModPublicationPhase._(
          4, _omitEnumNames ? '' : 'MOD_PUBLICATION_PHASE_INTERRUPTED');
  static const ModPublicationPhase MOD_PUBLICATION_PHASE_CANCELLED =
      ModPublicationPhase._(
          5, _omitEnumNames ? '' : 'MOD_PUBLICATION_PHASE_CANCELLED');

  static const $core.List<ModPublicationPhase> values = <ModPublicationPhase>[
    MOD_PUBLICATION_PHASE_UNSPECIFIED,
    MOD_PUBLICATION_PHASE_INTENT,
    MOD_PUBLICATION_PHASE_OBSERVED,
    MOD_PUBLICATION_PHASE_COMPLETE,
    MOD_PUBLICATION_PHASE_INTERRUPTED,
    MOD_PUBLICATION_PHASE_CANCELLED,
  ];

  static final $core.List<ModPublicationPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ModPublicationPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModPublicationPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
