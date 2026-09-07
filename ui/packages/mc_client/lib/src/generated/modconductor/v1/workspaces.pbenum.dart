// This is a generated file - do not edit.
//
// Generated from modconductor/v1/workspaces.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class WorkspaceRootIssueReason extends $pb.ProtobufEnum {
  static const WorkspaceRootIssueReason
      WORKSPACE_ROOT_ISSUE_REASON_UNSPECIFIED = WorkspaceRootIssueReason._(
          0, _omitEnumNames ? '' : 'WORKSPACE_ROOT_ISSUE_REASON_UNSPECIFIED');
  static const WorkspaceRootIssueReason
      WORKSPACE_ROOT_ISSUE_REASON_INCOMPLETE_CREATION =
      WorkspaceRootIssueReason._(
          1,
          _omitEnumNames
              ? ''
              : 'WORKSPACE_ROOT_ISSUE_REASON_INCOMPLETE_CREATION');
  static const WorkspaceRootIssueReason
      WORKSPACE_ROOT_ISSUE_REASON_OWNERSHIP_UNPROVED =
      WorkspaceRootIssueReason._(
          2,
          _omitEnumNames
              ? ''
              : 'WORKSPACE_ROOT_ISSUE_REASON_OWNERSHIP_UNPROVED');
  static const WorkspaceRootIssueReason
      WORKSPACE_ROOT_ISSUE_REASON_IDENTITY_UNVERIFIED =
      WorkspaceRootIssueReason._(
          3,
          _omitEnumNames
              ? ''
              : 'WORKSPACE_ROOT_ISSUE_REASON_IDENTITY_UNVERIFIED');

  static const $core.List<WorkspaceRootIssueReason> values =
      <WorkspaceRootIssueReason>[
    WORKSPACE_ROOT_ISSUE_REASON_UNSPECIFIED,
    WORKSPACE_ROOT_ISSUE_REASON_INCOMPLETE_CREATION,
    WORKSPACE_ROOT_ISSUE_REASON_OWNERSHIP_UNPROVED,
    WORKSPACE_ROOT_ISSUE_REASON_IDENTITY_UNVERIFIED,
  ];

  static final $core.List<WorkspaceRootIssueReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static WorkspaceRootIssueReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WorkspaceRootIssueReason._(super.value, super.name);
}

class WorkspaceFaultCode extends $pb.ProtobufEnum {
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_UNSPECIFIED =
      WorkspaceFaultCode._(
          0, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_UNSPECIFIED');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_NOT_FOUND =
      WorkspaceFaultCode._(
          1, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_NOT_FOUND');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_STALE_REVISION =
      WorkspaceFaultCode._(
          2, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_STALE_REVISION');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_IDENTITY_CONFLICT =
      WorkspaceFaultCode._(
          3, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_IDENTITY_CONFLICT');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_SELECTED_PROFILE =
      WorkspaceFaultCode._(
          4, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_SELECTED_PROFILE');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_INVALID_NAME =
      WorkspaceFaultCode._(
          5, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_INVALID_NAME');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_INVALID_ROOT =
      WorkspaceFaultCode._(
          6, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_INVALID_ROOT');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_ROOT_UNRESOLVED =
      WorkspaceFaultCode._(
          7, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_ROOT_UNRESOLVED');
  static const WorkspaceFaultCode WORKSPACE_FAULT_CODE_BUSY =
      WorkspaceFaultCode._(
          8, _omitEnumNames ? '' : 'WORKSPACE_FAULT_CODE_BUSY');

  static const $core.List<WorkspaceFaultCode> values = <WorkspaceFaultCode>[
    WORKSPACE_FAULT_CODE_UNSPECIFIED,
    WORKSPACE_FAULT_CODE_NOT_FOUND,
    WORKSPACE_FAULT_CODE_STALE_REVISION,
    WORKSPACE_FAULT_CODE_IDENTITY_CONFLICT,
    WORKSPACE_FAULT_CODE_SELECTED_PROFILE,
    WORKSPACE_FAULT_CODE_INVALID_NAME,
    WORKSPACE_FAULT_CODE_INVALID_ROOT,
    WORKSPACE_FAULT_CODE_ROOT_UNRESOLVED,
    WORKSPACE_FAULT_CODE_BUSY,
  ];

  static final $core.List<WorkspaceFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static WorkspaceFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WorkspaceFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
