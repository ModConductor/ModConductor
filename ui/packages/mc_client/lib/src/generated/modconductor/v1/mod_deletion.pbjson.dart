// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_deletion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use deleteModRequestDescriptor instead')
const DeleteModRequest$json = {
  '1': 'DeleteModRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'revision', '3': 3, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `DeleteModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteModRequestDescriptor = $convert.base64Decode(
    'ChBEZWxldGVNb2RSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSFQ'
    'oGbW9kX2lkGAIgASgJUgVtb2RJZBIaCghyZXZpc2lvbhgDIAEoBFIIcmV2aXNpb24=');

@$core.Deprecated('Use modDeletedDescriptor instead')
const ModDeleted$json = {
  '1': 'ModDeleted',
};

/// Descriptor for `ModDeleted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modDeletedDescriptor =
    $convert.base64Decode('CgpNb2REZWxldGVk');
