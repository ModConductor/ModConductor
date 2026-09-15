// This is a generated file - do not edit.
//
// Generated from modconductor/v1/inventory_export.proto.

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

@$core.Deprecated('Use inventoryExportScopeDescriptor instead')
const InventoryExportScope$json = {
  '1': 'InventoryExportScope',
  '2': [
    {'1': 'INVENTORY_EXPORT_SCOPE_UNSPECIFIED', '2': 0},
    {'1': 'INVENTORY_EXPORT_SCOPE_SELECTED', '2': 1},
    {'1': 'INVENTORY_EXPORT_SCOPE_ENABLED', '2': 2},
    {'1': 'INVENTORY_EXPORT_SCOPE_CURRENT_QUERY', '2': 3},
    {'1': 'INVENTORY_EXPORT_SCOPE_ALL', '2': 4},
  ],
};

/// Descriptor for `InventoryExportScope`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List inventoryExportScopeDescriptor = $convert.base64Decode(
    'ChRJbnZlbnRvcnlFeHBvcnRTY29wZRImCiJJTlZFTlRPUllfRVhQT1JUX1NDT1BFX1VOU1BFQ0'
    'lGSUVEEAASIwofSU5WRU5UT1JZX0VYUE9SVF9TQ09QRV9TRUxFQ1RFRBABEiIKHklOVkVOVE9S'
    'WV9FWFBPUlRfU0NPUEVfRU5BQkxFRBACEigKJElOVkVOVE9SWV9FWFBPUlRfU0NPUEVfQ1VSUk'
    'VOVF9RVUVSWRADEh4KGklOVkVOVE9SWV9FWFBPUlRfU0NPUEVfQUxMEAQ=');

@$core.Deprecated('Use inventoryExportFieldDescriptor instead')
const InventoryExportField$json = {
  '1': 'InventoryExportField',
  '2': [
    {'1': 'INVENTORY_EXPORT_FIELD_UNSPECIFIED', '2': 0},
    {'1': 'INVENTORY_EXPORT_FIELD_MOD_ID', '2': 1},
    {'1': 'INVENTORY_EXPORT_FIELD_NAME', '2': 2},
    {'1': 'INVENTORY_EXPORT_FIELD_KIND', '2': 3},
    {'1': 'INVENTORY_EXPORT_FIELD_STATUS', '2': 4},
    {'1': 'INVENTORY_EXPORT_FIELD_PRIORITY', '2': 5},
    {'1': 'INVENTORY_EXPORT_FIELD_ENABLED', '2': 6},
    {'1': 'INVENTORY_EXPORT_FIELD_VERSION', '2': 7},
    {'1': 'INVENTORY_EXPORT_FIELD_SOURCE', '2': 8},
    {'1': 'INVENTORY_EXPORT_FIELD_SOURCE_PATH', '2': 9},
    {'1': 'INVENTORY_EXPORT_FIELD_NOTES', '2': 10},
    {'1': 'INVENTORY_EXPORT_FIELD_COMMENT', '2': 11},
    {'1': 'INVENTORY_EXPORT_FIELD_CATEGORIES', '2': 12},
  ],
};

/// Descriptor for `InventoryExportField`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List inventoryExportFieldDescriptor = $convert.base64Decode(
    'ChRJbnZlbnRvcnlFeHBvcnRGaWVsZBImCiJJTlZFTlRPUllfRVhQT1JUX0ZJRUxEX1VOU1BFQ0'
    'lGSUVEEAASIQodSU5WRU5UT1JZX0VYUE9SVF9GSUVMRF9NT0RfSUQQARIfChtJTlZFTlRPUllf'
    'RVhQT1JUX0ZJRUxEX05BTUUQAhIfChtJTlZFTlRPUllfRVhQT1JUX0ZJRUxEX0tJTkQQAxIhCh'
    '1JTlZFTlRPUllfRVhQT1JUX0ZJRUxEX1NUQVRVUxAEEiMKH0lOVkVOVE9SWV9FWFBPUlRfRklF'
    'TERfUFJJT1JJVFkQBRIiCh5JTlZFTlRPUllfRVhQT1JUX0ZJRUxEX0VOQUJMRUQQBhIiCh5JTl'
    'ZFTlRPUllfRVhQT1JUX0ZJRUxEX1ZFUlNJT04QBxIhCh1JTlZFTlRPUllfRVhQT1JUX0ZJRUxE'
    'X1NPVVJDRRAIEiYKIklOVkVOVE9SWV9FWFBPUlRfRklFTERfU09VUkNFX1BBVEgQCRIgChxJTl'
    'ZFTlRPUllfRVhQT1JUX0ZJRUxEX05PVEVTEAoSIgoeSU5WRU5UT1JZX0VYUE9SVF9GSUVMRF9D'
    'T01NRU5UEAsSJQohSU5WRU5UT1JZX0VYUE9SVF9GSUVMRF9DQVRFR09SSUVTEAw=');

@$core.Deprecated('Use inventoryExportFaultCodeDescriptor instead')
const InventoryExportFaultCode$json = {
  '1': 'InventoryExportFaultCode',
  '2': [
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_UNSPECIFIED', '2': 0},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_INVALID_REQUEST', '2': 1},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_NOT_FOUND', '2': 2},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_STALE', '2': 3},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_BUSY', '2': 4},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_LIMIT_EXCEEDED', '2': 5},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_DESTINATION_UNAVAILABLE', '2': 6},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_DESTINATION_CHANGED', '2': 7},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_REPLACEMENT_REQUIRED', '2': 8},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_CANCELLED', '2': 9},
    {'1': 'INVENTORY_EXPORT_FAULT_CODE_WRITE_FAILED', '2': 10},
  ],
};

/// Descriptor for `InventoryExportFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List inventoryExportFaultCodeDescriptor = $convert.base64Decode(
    'ChhJbnZlbnRvcnlFeHBvcnRGYXVsdENvZGUSKwonSU5WRU5UT1JZX0VYUE9SVF9GQVVMVF9DT0'
    'RFX1VOU1BFQ0lGSUVEEAASLworSU5WRU5UT1JZX0VYUE9SVF9GQVVMVF9DT0RFX0lOVkFMSURf'
    'UkVRVUVTVBABEikKJUlOVkVOVE9SWV9FWFBPUlRfRkFVTFRfQ09ERV9OT1RfRk9VTkQQAhIlCi'
    'FJTlZFTlRPUllfRVhQT1JUX0ZBVUxUX0NPREVfU1RBTEUQAxIkCiBJTlZFTlRPUllfRVhQT1JU'
    'X0ZBVUxUX0NPREVfQlVTWRAEEi4KKklOVkVOVE9SWV9FWFBPUlRfRkFVTFRfQ09ERV9MSU1JVF'
    '9FWENFRURFRBAFEjcKM0lOVkVOVE9SWV9FWFBPUlRfRkFVTFRfQ09ERV9ERVNUSU5BVElPTl9V'
    'TkFWQUlMQUJMRRAGEjMKL0lOVkVOVE9SWV9FWFBPUlRfRkFVTFRfQ09ERV9ERVNUSU5BVElPTl'
    '9DSEFOR0VEEAcSNAowSU5WRU5UT1JZX0VYUE9SVF9GQVVMVF9DT0RFX1JFUExBQ0VNRU5UX1JF'
    'UVVJUkVEEAgSKQolSU5WRU5UT1JZX0VYUE9SVF9GQVVMVF9DT0RFX0NBTkNFTExFRBAJEiwKKE'
    'lOVkVOVE9SWV9FWFBPUlRfRkFVTFRfQ09ERV9XUklURV9GQUlMRUQQCg==');

@$core.Deprecated('Use inventoryExportFaultDescriptor instead')
const InventoryExportFault$json = {
  '1': 'InventoryExportFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InventoryExportFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `InventoryExportFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryExportFaultDescriptor = $convert.base64Decode(
    'ChRJbnZlbnRvcnlFeHBvcnRGYXVsdBI9CgRjb2RlGAEgASgOMikubW9kY29uZHVjdG9yLnYxLk'
    'ludmVudG9yeUV4cG9ydEZhdWx0Q29kZVIEY29kZRIWCgZkZXRhaWwYAiABKAlSBmRldGFpbA==');

@$core.Deprecated('Use prepareInventoryExportRequestDescriptor instead')
const PrepareInventoryExportRequest$json = {
  '1': 'PrepareInventoryExportRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'workspace_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'workspaceRevision'
    },
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'scope',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InventoryExportScope',
      '10': 'scope'
    },
    {'1': 'selected_mod_ids', '3': 5, '4': 3, '5': 9, '10': 'selectedModIds'},
    {
      '1': 'query',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModQueryDefinition',
      '10': 'query'
    },
    {'1': 'query_identity', '3': 7, '4': 1, '5': 9, '10': 'queryIdentity'},
    {
      '1': 'catalogue_revision',
      '3': 8,
      '4': 1,
      '5': 4,
      '10': 'catalogueRevision'
    },
    {
      '1': 'selection_revision',
      '3': 9,
      '4': 1,
      '5': 4,
      '10': 'selectionRevision'
    },
    {
      '1': 'fields',
      '3': 10,
      '4': 3,
      '5': 14,
      '6': '.modconductor.v1.InventoryExportField',
      '10': 'fields'
    },
  ],
};

/// Descriptor for `PrepareInventoryExportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareInventoryExportRequestDescriptor = $convert.base64Decode(
    'Ch1QcmVwYXJlSW52ZW50b3J5RXhwb3J0UmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3'
    'dvcmtzcGFjZUlkEi0KEndvcmtzcGFjZV9yZXZpc2lvbhgCIAEoBFIRd29ya3NwYWNlUmV2aXNp'
    'b24SHQoKcHJvZmlsZV9pZBgDIAEoCVIJcHJvZmlsZUlkEjsKBXNjb3BlGAQgASgOMiUubW9kY2'
    '9uZHVjdG9yLnYxLkludmVudG9yeUV4cG9ydFNjb3BlUgVzY29wZRIoChBzZWxlY3RlZF9tb2Rf'
    'aWRzGAUgAygJUg5zZWxlY3RlZE1vZElkcxI5CgVxdWVyeRgGIAEoCzIjLm1vZGNvbmR1Y3Rvci'
    '52MS5Nb2RRdWVyeURlZmluaXRpb25SBXF1ZXJ5EiUKDnF1ZXJ5X2lkZW50aXR5GAcgASgJUg1x'
    'dWVyeUlkZW50aXR5Ei0KEmNhdGFsb2d1ZV9yZXZpc2lvbhgIIAEoBFIRY2F0YWxvZ3VlUmV2aX'
    'Npb24SLQoSc2VsZWN0aW9uX3JldmlzaW9uGAkgASgEUhFzZWxlY3Rpb25SZXZpc2lvbhI9CgZm'
    'aWVsZHMYCiADKA4yJS5tb2Rjb25kdWN0b3IudjEuSW52ZW50b3J5RXhwb3J0RmllbGRSBmZpZW'
    'xkcw==');

@$core.Deprecated('Use preparedInventoryExportDescriptor instead')
const PreparedInventoryExport$json = {
  '1': 'PreparedInventoryExport',
  '2': [
    {'1': 'export_id', '3': 1, '4': 1, '5': 9, '10': 'exportId'},
    {'1': 'row_count', '3': 2, '4': 1, '5': 13, '10': 'rowCount'},
    {
      '1': 'fields',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.modconductor.v1.InventoryExportField',
      '10': 'fields'
    },
  ],
};

/// Descriptor for `PreparedInventoryExport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparedInventoryExportDescriptor = $convert.base64Decode(
    'ChdQcmVwYXJlZEludmVudG9yeUV4cG9ydBIbCglleHBvcnRfaWQYASABKAlSCGV4cG9ydElkEh'
    'sKCXJvd19jb3VudBgCIAEoDVIIcm93Q291bnQSPQoGZmllbGRzGAMgAygOMiUubW9kY29uZHVj'
    'dG9yLnYxLkludmVudG9yeUV4cG9ydEZpZWxkUgZmaWVsZHM=');

@$core.Deprecated('Use prepareInventoryExportReplyDescriptor instead')
const PrepareInventoryExportReply$json = {
  '1': 'PrepareInventoryExportReply',
  '2': [
    {
      '1': 'prepared',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PreparedInventoryExport',
      '9': 0,
      '10': 'prepared'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryExportFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `PrepareInventoryExportReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareInventoryExportReplyDescriptor = $convert.base64Decode(
    'ChtQcmVwYXJlSW52ZW50b3J5RXhwb3J0UmVwbHkSRgoIcHJlcGFyZWQYASABKAsyKC5tb2Rjb2'
    '5kdWN0b3IudjEuUHJlcGFyZWRJbnZlbnRvcnlFeHBvcnRIAFIIcHJlcGFyZWQSPQoFZmF1bHQY'
    'AiABKAsyJS5tb2Rjb25kdWN0b3IudjEuSW52ZW50b3J5RXhwb3J0RmF1bHRIAFIFZmF1bHRCCQ'
    'oHb3V0Y29tZQ==');

@$core.Deprecated(
    'Use inspectInventoryExportDestinationRequestDescriptor instead')
const InspectInventoryExportDestinationRequest$json = {
  '1': 'InspectInventoryExportDestinationRequest',
  '2': [
    {'1': 'export_id', '3': 1, '4': 1, '5': 9, '10': 'exportId'},
    {'1': 'destination_path', '3': 2, '4': 1, '5': 9, '10': 'destinationPath'},
  ],
};

/// Descriptor for `InspectInventoryExportDestinationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectInventoryExportDestinationRequestDescriptor =
    $convert.base64Decode(
        'CihJbnNwZWN0SW52ZW50b3J5RXhwb3J0RGVzdGluYXRpb25SZXF1ZXN0EhsKCWV4cG9ydF9pZB'
        'gBIAEoCVIIZXhwb3J0SWQSKQoQZGVzdGluYXRpb25fcGF0aBgCIAEoCVIPZGVzdGluYXRpb25Q'
        'YXRo');

@$core.Deprecated('Use inventoryExportDestinationDescriptor instead')
const InventoryExportDestination$json = {
  '1': 'InventoryExportDestination',
  '2': [
    {'1': 'destination_id', '3': 1, '4': 1, '5': 9, '10': 'destinationId'},
    {'1': 'file_name', '3': 2, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'exists', '3': 3, '4': 1, '5': 8, '10': 'exists'},
  ],
};

/// Descriptor for `InventoryExportDestination`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryExportDestinationDescriptor =
    $convert.base64Decode(
        'ChpJbnZlbnRvcnlFeHBvcnREZXN0aW5hdGlvbhIlCg5kZXN0aW5hdGlvbl9pZBgBIAEoCVINZG'
        'VzdGluYXRpb25JZBIbCglmaWxlX25hbWUYAiABKAlSCGZpbGVOYW1lEhYKBmV4aXN0cxgDIAEo'
        'CFIGZXhpc3Rz');

@$core
    .Deprecated('Use inspectInventoryExportDestinationReplyDescriptor instead')
const InspectInventoryExportDestinationReply$json = {
  '1': 'InspectInventoryExportDestinationReply',
  '2': [
    {
      '1': 'destination',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryExportDestination',
      '9': 0,
      '10': 'destination'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryExportFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `InspectInventoryExportDestinationReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectInventoryExportDestinationReplyDescriptor =
    $convert.base64Decode(
        'CiZJbnNwZWN0SW52ZW50b3J5RXhwb3J0RGVzdGluYXRpb25SZXBseRJPCgtkZXN0aW5hdGlvbh'
        'gBIAEoCzIrLm1vZGNvbmR1Y3Rvci52MS5JbnZlbnRvcnlFeHBvcnREZXN0aW5hdGlvbkgAUgtk'
        'ZXN0aW5hdGlvbhI9CgVmYXVsdBgCIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS5JbnZlbnRvcnlFeH'
        'BvcnRGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use writeInventoryExportRequestDescriptor instead')
const WriteInventoryExportRequest$json = {
  '1': 'WriteInventoryExportRequest',
  '2': [
    {'1': 'export_id', '3': 1, '4': 1, '5': 9, '10': 'exportId'},
    {'1': 'destination_id', '3': 2, '4': 1, '5': 9, '10': 'destinationId'},
    {'1': 'replace_existing', '3': 3, '4': 1, '5': 8, '10': 'replaceExisting'},
  ],
};

/// Descriptor for `WriteInventoryExportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeInventoryExportRequestDescriptor =
    $convert.base64Decode(
        'ChtXcml0ZUludmVudG9yeUV4cG9ydFJlcXVlc3QSGwoJZXhwb3J0X2lkGAEgASgJUghleHBvcn'
        'RJZBIlCg5kZXN0aW5hdGlvbl9pZBgCIAEoCVINZGVzdGluYXRpb25JZBIpChByZXBsYWNlX2V4'
        'aXN0aW5nGAMgASgIUg9yZXBsYWNlRXhpc3Rpbmc=');

@$core.Deprecated('Use inventoryExportWriteProgressDescriptor instead')
const InventoryExportWriteProgress$json = {
  '1': 'InventoryExportWriteProgress',
  '2': [
    {'1': 'written_rows', '3': 1, '4': 1, '5': 13, '10': 'writtenRows'},
    {'1': 'total_rows', '3': 2, '4': 1, '5': 13, '10': 'totalRows'},
  ],
};

/// Descriptor for `InventoryExportWriteProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryExportWriteProgressDescriptor =
    $convert.base64Decode(
        'ChxJbnZlbnRvcnlFeHBvcnRXcml0ZVByb2dyZXNzEiEKDHdyaXR0ZW5fcm93cxgBIAEoDVILd3'
        'JpdHRlblJvd3MSHQoKdG90YWxfcm93cxgCIAEoDVIJdG90YWxSb3dz');

@$core.Deprecated('Use completedInventoryExportDescriptor instead')
const CompletedInventoryExport$json = {
  '1': 'CompletedInventoryExport',
  '2': [
    {'1': 'file_name', '3': 1, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'row_count', '3': 2, '4': 1, '5': 13, '10': 'rowCount'},
    {'1': 'byte_count', '3': 3, '4': 1, '5': 4, '10': 'byteCount'},
  ],
};

/// Descriptor for `CompletedInventoryExport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completedInventoryExportDescriptor = $convert.base64Decode(
    'ChhDb21wbGV0ZWRJbnZlbnRvcnlFeHBvcnQSGwoJZmlsZV9uYW1lGAEgASgJUghmaWxlTmFtZR'
    'IbCglyb3dfY291bnQYAiABKA1SCHJvd0NvdW50Eh0KCmJ5dGVfY291bnQYAyABKARSCWJ5dGVD'
    'b3VudA==');

@$core.Deprecated('Use inventoryExportEventDescriptor instead')
const InventoryExportEvent$json = {
  '1': 'InventoryExportEvent',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryExportWriteProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'completed',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CompletedInventoryExport',
      '9': 0,
      '10': 'completed'
    },
    {
      '1': 'fault',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryExportFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `InventoryExportEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryExportEventDescriptor = $convert.base64Decode(
    'ChRJbnZlbnRvcnlFeHBvcnRFdmVudBJLCghwcm9ncmVzcxgBIAEoCzItLm1vZGNvbmR1Y3Rvci'
    '52MS5JbnZlbnRvcnlFeHBvcnRXcml0ZVByb2dyZXNzSABSCHByb2dyZXNzEkkKCWNvbXBsZXRl'
    'ZBgCIAEoCzIpLm1vZGNvbmR1Y3Rvci52MS5Db21wbGV0ZWRJbnZlbnRvcnlFeHBvcnRIAFIJY2'
    '9tcGxldGVkEj0KBWZhdWx0GAMgASgLMiUubW9kY29uZHVjdG9yLnYxLkludmVudG9yeUV4cG9y'
    'dEZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use cancelInventoryExportRequestDescriptor instead')
const CancelInventoryExportRequest$json = {
  '1': 'CancelInventoryExportRequest',
  '2': [
    {'1': 'export_id', '3': 1, '4': 1, '5': 9, '10': 'exportId'},
  ],
};

/// Descriptor for `CancelInventoryExportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelInventoryExportRequestDescriptor =
    $convert.base64Decode(
        'ChxDYW5jZWxJbnZlbnRvcnlFeHBvcnRSZXF1ZXN0EhsKCWV4cG9ydF9pZBgBIAEoCVIIZXhwb3'
        'J0SWQ=');

@$core.Deprecated('Use cancelInventoryExportReplyDescriptor instead')
const CancelInventoryExportReply$json = {
  '1': 'CancelInventoryExportReply',
  '2': [
    {'1': 'requested', '3': 1, '4': 1, '5': 8, '10': 'requested'},
  ],
};

/// Descriptor for `CancelInventoryExportReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelInventoryExportReplyDescriptor =
    $convert.base64Decode(
        'ChpDYW5jZWxJbnZlbnRvcnlFeHBvcnRSZXBseRIcCglyZXF1ZXN0ZWQYASABKAhSCXJlcXVlc3'
        'RlZA==');

@$core.Deprecated('Use discardInventoryExportRequestDescriptor instead')
const DiscardInventoryExportRequest$json = {
  '1': 'DiscardInventoryExportRequest',
  '2': [
    {'1': 'export_id', '3': 1, '4': 1, '5': 9, '10': 'exportId'},
  ],
};

/// Descriptor for `DiscardInventoryExportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discardInventoryExportRequestDescriptor =
    $convert.base64Decode(
        'Ch1EaXNjYXJkSW52ZW50b3J5RXhwb3J0UmVxdWVzdBIbCglleHBvcnRfaWQYASABKAlSCGV4cG'
        '9ydElk');

@$core.Deprecated('Use discardInventoryExportReplyDescriptor instead')
const DiscardInventoryExportReply$json = {
  '1': 'DiscardInventoryExportReply',
  '2': [
    {'1': 'discarded', '3': 1, '4': 1, '5': 8, '10': 'discarded'},
  ],
};

/// Descriptor for `DiscardInventoryExportReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discardInventoryExportReplyDescriptor =
    $convert.base64Decode(
        'ChtEaXNjYXJkSW52ZW50b3J5RXhwb3J0UmVwbHkSHAoJZGlzY2FyZGVkGAEgASgIUglkaXNjYX'
        'JkZWQ=');
