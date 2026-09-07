// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_library.proto.

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

@$core.Deprecated('Use inventoryModKindDescriptor instead')
const InventoryModKind$json = {
  '1': 'InventoryModKind',
  '2': [
    {'1': 'INVENTORY_MOD_KIND_UNSPECIFIED', '2': 0},
    {'1': 'INVENTORY_MOD_KIND_REGULAR', '2': 1},
    {'1': 'INVENTORY_MOD_KIND_SEPARATOR', '2': 2},
    {'1': 'INVENTORY_MOD_KIND_BACKUP', '2': 3},
    {'1': 'INVENTORY_MOD_KIND_UNMANAGED', '2': 4},
    {'1': 'INVENTORY_MOD_KIND_GENERATED_OUTPUT', '2': 5},
  ],
};

/// Descriptor for `InventoryModKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List inventoryModKindDescriptor = $convert.base64Decode(
    'ChBJbnZlbnRvcnlNb2RLaW5kEiIKHklOVkVOVE9SWV9NT0RfS0lORF9VTlNQRUNJRklFRBAAEh'
    '4KGklOVkVOVE9SWV9NT0RfS0lORF9SRUdVTEFSEAESIAocSU5WRU5UT1JZX01PRF9LSU5EX1NF'
    'UEFSQVRPUhACEh0KGUlOVkVOVE9SWV9NT0RfS0lORF9CQUNLVVAQAxIgChxJTlZFTlRPUllfTU'
    '9EX0tJTkRfVU5NQU5BR0VEEAQSJwojSU5WRU5UT1JZX01PRF9LSU5EX0dFTkVSQVRFRF9PVVRQ'
    'VVQQBQ==');

@$core.Deprecated('Use modInventoryStatusDescriptor instead')
const ModInventoryStatus$json = {
  '1': 'ModInventoryStatus',
  '2': [
    {'1': 'MOD_INVENTORY_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'MOD_INVENTORY_STATUS_READY', '2': 1},
    {'1': 'MOD_INVENTORY_STATUS_DETACHED', '2': 2},
    {'1': 'MOD_INVENTORY_STATUS_CHANGED', '2': 3},
    {'1': 'MOD_INVENTORY_STATUS_UNPROVED', '2': 4},
    {'1': 'MOD_INVENTORY_STATUS_PUBLISHING', '2': 5},
  ],
};

/// Descriptor for `ModInventoryStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modInventoryStatusDescriptor = $convert.base64Decode(
    'ChJNb2RJbnZlbnRvcnlTdGF0dXMSJAogTU9EX0lOVkVOVE9SWV9TVEFUVVNfVU5TUEVDSUZJRU'
    'QQABIeChpNT0RfSU5WRU5UT1JZX1NUQVRVU19SRUFEWRABEiEKHU1PRF9JTlZFTlRPUllfU1RB'
    'VFVTX0RFVEFDSEVEEAISIAocTU9EX0lOVkVOVE9SWV9TVEFUVVNfQ0hBTkdFRBADEiEKHU1PRF'
    '9JTlZFTlRPUllfU1RBVFVTX1VOUFJPVkVEEAQSIwofTU9EX0lOVkVOVE9SWV9TVEFUVVNfUFVC'
    'TElTSElORxAF');

@$core.Deprecated('Use inventoryModActionDescriptor instead')
const InventoryModAction$json = {
  '1': 'InventoryModAction',
  '2': [
    {'1': 'INVENTORY_MOD_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'INVENTORY_MOD_ACTION_EDIT_METADATA', '2': 1},
    {'1': 'INVENTORY_MOD_ACTION_PUBLISH', '2': 2},
    {'1': 'INVENTORY_MOD_ACTION_READ_VERSION', '2': 3},
  ],
};

/// Descriptor for `InventoryModAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List inventoryModActionDescriptor = $convert.base64Decode(
    'ChJJbnZlbnRvcnlNb2RBY3Rpb24SJAogSU5WRU5UT1JZX01PRF9BQ1RJT05fVU5TUEVDSUZJRU'
    'QQABImCiJJTlZFTlRPUllfTU9EX0FDVElPTl9FRElUX01FVEFEQVRBEAESIAocSU5WRU5UT1JZ'
    'X01PRF9BQ1RJT05fUFVCTElTSBACEiUKIUlOVkVOVE9SWV9NT0RfQUNUSU9OX1JFQURfVkVSU0'
    'lPThAD');

@$core.Deprecated('Use modLibraryFaultCodeDescriptor instead')
const ModLibraryFaultCode$json = {
  '1': 'ModLibraryFaultCode',
  '2': [
    {'1': 'MOD_LIBRARY_FAULT_CODE_UNSPECIFIED', '2': 0},
    {'1': 'MOD_LIBRARY_FAULT_CODE_NOT_FOUND', '2': 1},
    {'1': 'MOD_LIBRARY_FAULT_CODE_STALE_REVISION', '2': 2},
    {'1': 'MOD_LIBRARY_FAULT_CODE_IDENTITY_CONFLICT', '2': 3},
    {'1': 'MOD_LIBRARY_FAULT_CODE_INVALID_METADATA', '2': 4},
    {'1': 'MOD_LIBRARY_FAULT_CODE_INVALID_SOURCE', '2': 5},
    {'1': 'MOD_LIBRARY_FAULT_CODE_UNPROVED_OWNERSHIP', '2': 6},
    {'1': 'MOD_LIBRARY_FAULT_CODE_SOURCE_CHANGED', '2': 7},
    {'1': 'MOD_LIBRARY_FAULT_CODE_UNSUPPORTED_ACTION', '2': 8},
    {'1': 'MOD_LIBRARY_FAULT_CODE_BUSY', '2': 9},
    {'1': 'MOD_LIBRARY_FAULT_CODE_LIMIT_EXCEEDED', '2': 10},
    {'1': 'MOD_LIBRARY_FAULT_CODE_FILE_UNAVAILABLE', '2': 11},
    {'1': 'MOD_LIBRARY_FAULT_CODE_CANCELLED', '2': 12},
  ],
};

/// Descriptor for `ModLibraryFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modLibraryFaultCodeDescriptor = $convert.base64Decode(
    'ChNNb2RMaWJyYXJ5RmF1bHRDb2RlEiYKIk1PRF9MSUJSQVJZX0ZBVUxUX0NPREVfVU5TUEVDSU'
    'ZJRUQQABIkCiBNT0RfTElCUkFSWV9GQVVMVF9DT0RFX05PVF9GT1VORBABEikKJU1PRF9MSUJS'
    'QVJZX0ZBVUxUX0NPREVfU1RBTEVfUkVWSVNJT04QAhIsCihNT0RfTElCUkFSWV9GQVVMVF9DT0'
    'RFX0lERU5USVRZX0NPTkZMSUNUEAMSKwonTU9EX0xJQlJBUllfRkFVTFRfQ09ERV9JTlZBTElE'
    'X01FVEFEQVRBEAQSKQolTU9EX0xJQlJBUllfRkFVTFRfQ09ERV9JTlZBTElEX1NPVVJDRRAFEi'
    '0KKU1PRF9MSUJSQVJZX0ZBVUxUX0NPREVfVU5QUk9WRURfT1dORVJTSElQEAYSKQolTU9EX0xJ'
    'QlJBUllfRkFVTFRfQ09ERV9TT1VSQ0VfQ0hBTkdFRBAHEi0KKU1PRF9MSUJSQVJZX0ZBVUxUX0'
    'NPREVfVU5TVVBQT1JURURfQUNUSU9OEAgSHwobTU9EX0xJQlJBUllfRkFVTFRfQ09ERV9CVVNZ'
    'EAkSKQolTU9EX0xJQlJBUllfRkFVTFRfQ09ERV9MSU1JVF9FWENFRURFRBAKEisKJ01PRF9MSU'
    'JSQVJZX0ZBVUxUX0NPREVfRklMRV9VTkFWQUlMQUJMRRALEiQKIE1PRF9MSUJSQVJZX0ZBVUxU'
    'X0NPREVfQ0FOQ0VMTEVEEAw=');

@$core.Deprecated('Use modPublicationPhaseDescriptor instead')
const ModPublicationPhase$json = {
  '1': 'ModPublicationPhase',
  '2': [
    {'1': 'MOD_PUBLICATION_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'MOD_PUBLICATION_PHASE_INTENT', '2': 1},
    {'1': 'MOD_PUBLICATION_PHASE_OBSERVED', '2': 2},
    {'1': 'MOD_PUBLICATION_PHASE_COMPLETE', '2': 3},
    {'1': 'MOD_PUBLICATION_PHASE_INTERRUPTED', '2': 4},
    {'1': 'MOD_PUBLICATION_PHASE_CANCELLED', '2': 5},
  ],
};

/// Descriptor for `ModPublicationPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modPublicationPhaseDescriptor = $convert.base64Decode(
    'ChNNb2RQdWJsaWNhdGlvblBoYXNlEiUKIU1PRF9QVUJMSUNBVElPTl9QSEFTRV9VTlNQRUNJRk'
    'lFRBAAEiAKHE1PRF9QVUJMSUNBVElPTl9QSEFTRV9JTlRFTlQQARIiCh5NT0RfUFVCTElDQVRJ'
    'T05fUEhBU0VfT0JTRVJWRUQQAhIiCh5NT0RfUFVCTElDQVRJT05fUEhBU0VfQ09NUExFVEUQAx'
    'IlCiFNT0RfUFVCTElDQVRJT05fUEhBU0VfSU5URVJSVVBURUQQBBIjCh9NT0RfUFVCTElDQVRJ'
    'T05fUEhBU0VfQ0FOQ0VMTEVEEAU=');

@$core.Deprecated('Use modLogicalPathDescriptor instead')
const ModLogicalPath$json = {
  '1': 'ModLogicalPath',
  '2': [
    {'1': 'components', '3': 1, '4': 3, '5': 9, '10': 'components'},
  ],
};

/// Descriptor for `ModLogicalPath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modLogicalPathDescriptor = $convert.base64Decode(
    'Cg5Nb2RMb2dpY2FsUGF0aBIeCgpjb21wb25lbnRzGAEgAygJUgpjb21wb25lbnRz');

@$core.Deprecated('Use inventoryModMetadataDescriptor instead')
const InventoryModMetadata$json = {
  '1': 'InventoryModMetadata',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'notes', '3': 2, '4': 1, '5': 9, '10': 'notes'},
    {'1': 'comment', '3': 3, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'version', '3': 4, '4': 1, '5': 9, '10': 'version'},
    {'1': 'source', '3': 5, '4': 1, '5': 9, '10': 'source'},
    {'1': 'category', '3': 6, '4': 1, '5': 9, '10': 'category'},
  ],
};

/// Descriptor for `InventoryModMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryModMetadataDescriptor = $convert.base64Decode(
    'ChRJbnZlbnRvcnlNb2RNZXRhZGF0YRISCgRuYW1lGAEgASgJUgRuYW1lEhQKBW5vdGVzGAIgAS'
    'gJUgVub3RlcxIYCgdjb21tZW50GAMgASgJUgdjb21tZW50EhgKB3ZlcnNpb24YBCABKAlSB3Zl'
    'cnNpb24SFgoGc291cmNlGAUgASgJUgZzb3VyY2USGgoIY2F0ZWdvcnkYBiABKAlSCGNhdGVnb3'
    'J5');

@$core.Deprecated('Use inventoryModDescriptor instead')
const InventoryMod$json = {
  '1': 'InventoryMod',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InventoryModKind',
      '10': 'kind'
    },
    {
      '1': 'metadata',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryModMetadata',
      '10': 'metadata'
    },
    {'1': 'revision', '3': 5, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'source_path',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'sourcePath'
    },
    {
      '1': 'current_version_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'currentVersionId',
      '17': true
    },
    {
      '1': 'status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModInventoryStatus',
      '10': 'status'
    },
    {
      '1': 'actions',
      '3': 9,
      '4': 3,
      '5': 14,
      '6': '.modconductor.v1.InventoryModAction',
      '10': 'actions'
    },
  ],
  '8': [
    {'1': '_current_version_id'},
  ],
};

/// Descriptor for `InventoryMod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryModDescriptor = $convert.base64Decode(
    'CgxJbnZlbnRvcnlNb2QSFQoGbW9kX2lkGAEgASgJUgVtb2RJZBIhCgx3b3Jrc3BhY2VfaWQYAi'
    'ABKAlSC3dvcmtzcGFjZUlkEjUKBGtpbmQYAyABKA4yIS5tb2Rjb25kdWN0b3IudjEuSW52ZW50'
    'b3J5TW9kS2luZFIEa2luZBJBCghtZXRhZGF0YRgEIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS5Jbn'
    'ZlbnRvcnlNb2RNZXRhZGF0YVIIbWV0YWRhdGESGgoIcmV2aXNpb24YBSABKARSCHJldmlzaW9u'
    'EkAKC3NvdXJjZV9wYXRoGAYgASgLMh8ubW9kY29uZHVjdG9yLnYxLk1vZExvZ2ljYWxQYXRoUg'
    'pzb3VyY2VQYXRoEjEKEmN1cnJlbnRfdmVyc2lvbl9pZBgHIAEoCUgAUhBjdXJyZW50VmVyc2lv'
    'bklkiAEBEjsKBnN0YXR1cxgIIAEoDjIjLm1vZGNvbmR1Y3Rvci52MS5Nb2RJbnZlbnRvcnlTdG'
    'F0dXNSBnN0YXR1cxI9CgdhY3Rpb25zGAkgAygOMiMubW9kY29uZHVjdG9yLnYxLkludmVudG9y'
    'eU1vZEFjdGlvblIHYWN0aW9uc0IVChNfY3VycmVudF92ZXJzaW9uX2lk');

@$core.Deprecated('Use modLibraryFaultDescriptor instead')
const ModLibraryFault$json = {
  '1': 'ModLibraryFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModLibraryFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `ModLibraryFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modLibraryFaultDescriptor = $convert.base64Decode(
    'Cg9Nb2RMaWJyYXJ5RmF1bHQSOAoEY29kZRgBIAEoDjIkLm1vZGNvbmR1Y3Rvci52MS5Nb2RMaW'
    'JyYXJ5RmF1bHRDb2RlUgRjb2RlEhYKBmRldGFpbBgCIAEoCVIGZGV0YWls');

@$core.Deprecated('Use modReplyDescriptor instead')
const ModReply$json = {
  '1': 'ModReply',
  '2': [
    {
      '1': 'mod',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryMod',
      '9': 0,
      '10': 'mod'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ModReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modReplyDescriptor = $convert.base64Decode(
    'CghNb2RSZXBseRIxCgNtb2QYASABKAsyHS5tb2Rjb25kdWN0b3IudjEuSW52ZW50b3J5TW9kSA'
    'BSA21vZBI4CgVmYXVsdBgCIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS5Nb2RMaWJyYXJ5RmF1bHRI'
    'AFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use registerModRequestDescriptor instead')
const RegisterModRequest$json = {
  '1': 'RegisterModRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryModMetadata',
      '10': 'metadata'
    },
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InventoryModKind',
      '10': 'kind'
    },
    {
      '1': 'source_path',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'sourcePath'
    },
    {
      '1': 'backup_version_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'backupVersionId',
      '17': true
    },
    {
      '1': 'native_source_path',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'nativeSourcePath',
      '17': true
    },
  ],
  '8': [
    {'1': '_backup_version_id'},
    {'1': '_native_source_path'},
  ],
};

/// Descriptor for `RegisterModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerModRequestDescriptor = $convert.base64Decode(
    'ChJSZWdpc3Rlck1vZFJlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZB'
    'IVCgZtb2RfaWQYAiABKAlSBW1vZElkEkEKCG1ldGFkYXRhGAMgASgLMiUubW9kY29uZHVjdG9y'
    'LnYxLkludmVudG9yeU1vZE1ldGFkYXRhUghtZXRhZGF0YRI1CgRraW5kGAQgASgOMiEubW9kY2'
    '9uZHVjdG9yLnYxLkludmVudG9yeU1vZEtpbmRSBGtpbmQSQAoLc291cmNlX3BhdGgYBSABKAsy'
    'Hy5tb2Rjb25kdWN0b3IudjEuTW9kTG9naWNhbFBhdGhSCnNvdXJjZVBhdGgSLwoRYmFja3VwX3'
    'ZlcnNpb25faWQYBiABKAlIAFIPYmFja3VwVmVyc2lvbklkiAEBEjEKEm5hdGl2ZV9zb3VyY2Vf'
    'cGF0aBgHIAEoCUgBUhBuYXRpdmVTb3VyY2VQYXRoiAEBQhQKEl9iYWNrdXBfdmVyc2lvbl9pZE'
    'IVChNfbmF0aXZlX3NvdXJjZV9wYXRo');

@$core.Deprecated('Use editModRequestDescriptor instead')
const EditModRequest$json = {
  '1': 'EditModRequest',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {
      '1': 'metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InventoryModMetadata',
      '10': 'metadata'
    },
  ],
};

/// Descriptor for `EditModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editModRequestDescriptor = $convert.base64Decode(
    'Cg5FZGl0TW9kUmVxdWVzdBIVCgZtb2RfaWQYASABKAlSBW1vZElkEisKEWV4cGVjdGVkX3Jldm'
    'lzaW9uGAIgASgEUhBleHBlY3RlZFJldmlzaW9uEkEKCG1ldGFkYXRhGAMgASgLMiUubW9kY29u'
    'ZHVjdG9yLnYxLkludmVudG9yeU1vZE1ldGFkYXRhUghtZXRhZGF0YQ==');

@$core.Deprecated('Use readInventoryRequestDescriptor instead')
const ReadInventoryRequest$json = {
  '1': 'ReadInventoryRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'after_mod_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'afterModId',
      '17': true
    },
  ],
  '8': [
    {'1': '_after_mod_id'},
  ],
};

/// Descriptor for `ReadInventoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readInventoryRequestDescriptor = $convert.base64Decode(
    'ChRSZWFkSW52ZW50b3J5UmVxdWVzdBIdCgpwcm9maWxlX2lkGAEgASgJUglwcm9maWxlSWQSJQ'
    'oMYWZ0ZXJfbW9kX2lkGAIgASgJSABSCmFmdGVyTW9kSWSIAQFCDwoNX2FmdGVyX21vZF9pZA==');

@$core.Deprecated('Use modInventoryPageDescriptor instead')
const ModInventoryPage$json = {
  '1': 'ModInventoryPage',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InventoryMod',
      '10': 'entries'
    },
    {
      '1': 'next_mod_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextModId',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_mod_id'},
  ],
};

/// Descriptor for `ModInventoryPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modInventoryPageDescriptor = $convert.base64Decode(
    'ChBNb2RJbnZlbnRvcnlQYWdlEjcKB2VudHJpZXMYASADKAsyHS5tb2Rjb25kdWN0b3IudjEuSW'
    '52ZW50b3J5TW9kUgdlbnRyaWVzEiMKC25leHRfbW9kX2lkGAIgASgJSABSCW5leHRNb2RJZIgB'
    'AUIOCgxfbmV4dF9tb2RfaWQ=');

@$core.Deprecated('Use inventoryReplyDescriptor instead')
const InventoryReply$json = {
  '1': 'InventoryReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModInventoryPage',
      '9': 0,
      '10': 'page'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `InventoryReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryReplyDescriptor = $convert.base64Decode(
    'Cg5JbnZlbnRvcnlSZXBseRI3CgRwYWdlGAEgASgLMiEubW9kY29uZHVjdG9yLnYxLk1vZEludm'
    'VudG9yeVBhZ2VIAFIEcGFnZRI4CgVmYXVsdBgCIAEoCzIgLm1vZGNvbmR1Y3Rvci52MS5Nb2RM'
    'aWJyYXJ5RmF1bHRIAFIFZmF1bHRCCQoHb3V0Y29tZQ==');

@$core.Deprecated('Use scanInventoryRequestDescriptor instead')
const ScanInventoryRequest$json = {
  '1': 'ScanInventoryRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {'1': 'candidate_limit', '3': 2, '4': 1, '5': 13, '10': 'candidateLimit'},
  ],
};

/// Descriptor for `ScanInventoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanInventoryRequestDescriptor = $convert.base64Decode(
    'ChRTY2FuSW52ZW50b3J5UmVxdWVzdBIhCgx3b3Jrc3BhY2VfaWQYASABKAlSC3dvcmtzcGFjZU'
    'lkEicKD2NhbmRpZGF0ZV9saW1pdBgCIAEoDVIOY2FuZGlkYXRlTGltaXQ=');

@$core.Deprecated('Use unmanagedModPathDescriptor instead')
const UnmanagedModPath$json = {
  '1': 'UnmanagedModPath',
  '2': [
    {
      '1': 'path',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
    {'1': 'directory', '3': 2, '4': 1, '5': 8, '10': 'directory'},
    {'1': 'unsupported', '3': 3, '4': 1, '5': 8, '10': 'unsupported'},
  ],
};

/// Descriptor for `UnmanagedModPath`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unmanagedModPathDescriptor = $convert.base64Decode(
    'ChBVbm1hbmFnZWRNb2RQYXRoEjMKBHBhdGgYASABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG'
    '9naWNhbFBhdGhSBHBhdGgSHAoJZGlyZWN0b3J5GAIgASgIUglkaXJlY3RvcnkSIAoLdW5zdXBw'
    'b3J0ZWQYAyABKAhSC3Vuc3VwcG9ydGVk');

@$core.Deprecated('Use modInventoryScanDescriptor instead')
const ModInventoryScan$json = {
  '1': 'ModInventoryScan',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InventoryMod',
      '10': 'entries'
    },
    {
      '1': 'unmanaged',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.UnmanagedModPath',
      '10': 'unmanaged'
    },
    {'1': 'limited', '3': 3, '4': 1, '5': 8, '10': 'limited'},
  ],
};

/// Descriptor for `ModInventoryScan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modInventoryScanDescriptor = $convert.base64Decode(
    'ChBNb2RJbnZlbnRvcnlTY2FuEjcKB2VudHJpZXMYASADKAsyHS5tb2Rjb25kdWN0b3IudjEuSW'
    '52ZW50b3J5TW9kUgdlbnRyaWVzEj8KCXVubWFuYWdlZBgCIAMoCzIhLm1vZGNvbmR1Y3Rvci52'
    'MS5Vbm1hbmFnZWRNb2RQYXRoUgl1bm1hbmFnZWQSGAoHbGltaXRlZBgDIAEoCFIHbGltaXRlZA'
    '==');

@$core.Deprecated('Use inventoryScanReplyDescriptor instead')
const InventoryScanReply$json = {
  '1': 'InventoryScanReply',
  '2': [
    {
      '1': 'scan',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModInventoryScan',
      '9': 0,
      '10': 'scan'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `InventoryScanReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inventoryScanReplyDescriptor = $convert.base64Decode(
    'ChJJbnZlbnRvcnlTY2FuUmVwbHkSNwoEc2NhbhgBIAEoCzIhLm1vZGNvbmR1Y3Rvci52MS5Nb2'
    'RJbnZlbnRvcnlTY2FuSABSBHNjYW4SOAoFZmF1bHQYAiABKAsyIC5tb2Rjb25kdWN0b3IudjEu'
    'TW9kTGlicmFyeUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use publishModRequestDescriptor instead')
const PublishModRequest$json = {
  '1': 'PublishModRequest',
  '2': [
    {'1': 'mod_id', '3': 1, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {'1': 'version_id', '3': 3, '4': 1, '5': 9, '10': 'versionId'},
  ],
};

/// Descriptor for `PublishModRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishModRequestDescriptor = $convert.base64Decode(
    'ChFQdWJsaXNoTW9kUmVxdWVzdBIVCgZtb2RfaWQYASABKAlSBW1vZElkEisKEWV4cGVjdGVkX3'
    'JldmlzaW9uGAIgASgEUhBleHBlY3RlZFJldmlzaW9uEh0KCnZlcnNpb25faWQYAyABKAlSCXZl'
    'cnNpb25JZA==');

@$core.Deprecated('Use publicationRequestDescriptor instead')
const PublicationRequest$json = {
  '1': 'PublicationRequest',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 9, '10': 'versionId'},
  ],
};

/// Descriptor for `PublicationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicationRequestDescriptor =
    $convert.base64Decode(
        'ChJQdWJsaWNhdGlvblJlcXVlc3QSHQoKdmVyc2lvbl9pZBgBIAEoCVIJdmVyc2lvbklk');

@$core.Deprecated('Use modPublicationReceiptDescriptor instead')
const ModPublicationReceipt$json = {
  '1': 'ModPublicationReceipt',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'expected_revision',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {
      '1': 'phase',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModPublicationPhase',
      '10': 'phase'
    },
  ],
};

/// Descriptor for `ModPublicationReceipt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modPublicationReceiptDescriptor = $convert.base64Decode(
    'ChVNb2RQdWJsaWNhdGlvblJlY2VpcHQSHQoKdmVyc2lvbl9pZBgBIAEoCVIJdmVyc2lvbklkEh'
    'UKBm1vZF9pZBgCIAEoCVIFbW9kSWQSKwoRZXhwZWN0ZWRfcmV2aXNpb24YAyABKARSEGV4cGVj'
    'dGVkUmV2aXNpb24SOgoFcGhhc2UYBCABKA4yJC5tb2Rjb25kdWN0b3IudjEuTW9kUHVibGljYX'
    'Rpb25QaGFzZVIFcGhhc2U=');

@$core.Deprecated('Use publicationReplyDescriptor instead')
const PublicationReply$json = {
  '1': 'PublicationReply',
  '2': [
    {
      '1': 'receipt',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModPublicationReceipt',
      '9': 0,
      '10': 'receipt'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `PublicationReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicationReplyDescriptor = $convert.base64Decode(
    'ChBQdWJsaWNhdGlvblJlcGx5EkIKB3JlY2VpcHQYASABKAsyJi5tb2Rjb25kdWN0b3IudjEuTW'
    '9kUHVibGljYXRpb25SZWNlaXB0SABSB3JlY2VpcHQSOAoFZmF1bHQYAiABKAsyIC5tb2Rjb25k'
    'dWN0b3IudjEuTW9kTGlicmFyeUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use readModVersionRequestDescriptor instead')
const ReadModVersionRequest$json = {
  '1': 'ReadModVersionRequest',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'offset', '3': 2, '4': 1, '5': 13, '10': 'offset'},
  ],
};

/// Descriptor for `ReadModVersionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readModVersionRequestDescriptor = $convert.base64Decode(
    'ChVSZWFkTW9kVmVyc2lvblJlcXVlc3QSHQoKdmVyc2lvbl9pZBgBIAEoCVIJdmVyc2lvbklkEh'
    'YKBm9mZnNldBgCIAEoDVIGb2Zmc2V0');

@$core.Deprecated('Use modPayloadDescriptor instead')
const ModPayload$json = {
  '1': 'ModPayload',
  '2': [
    {'1': 'payload_id', '3': 1, '4': 1, '5': 9, '10': 'payloadId'},
    {'1': 'length', '3': 2, '4': 1, '5': 4, '10': 'length'},
    {'1': 'sha256', '3': 3, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `ModPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modPayloadDescriptor = $convert.base64Decode(
    'CgpNb2RQYXlsb2FkEh0KCnBheWxvYWRfaWQYASABKAlSCXBheWxvYWRJZBIWCgZsZW5ndGgYAi'
    'ABKARSBmxlbmd0aBIWCgZzaGEyNTYYAyABKAlSBnNoYTI1Ng==');

@$core.Deprecated('Use modManifestEntryDescriptor instead')
const ModManifestEntry$json = {
  '1': 'ModManifestEntry',
  '2': [
    {
      '1': 'path',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLogicalPath',
      '10': 'path'
    },
    {
      '1': 'payload',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModPayload',
      '10': 'payload'
    },
  ],
};

/// Descriptor for `ModManifestEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modManifestEntryDescriptor = $convert.base64Decode(
    'ChBNb2RNYW5pZmVzdEVudHJ5EjMKBHBhdGgYASABKAsyHy5tb2Rjb25kdWN0b3IudjEuTW9kTG'
    '9naWNhbFBhdGhSBHBhdGgSNQoHcGF5bG9hZBgCIAEoCzIbLm1vZGNvbmR1Y3Rvci52MS5Nb2RQ'
    'YXlsb2FkUgdwYXlsb2Fk');

@$core.Deprecated('Use modVersionPageDescriptor instead')
const ModVersionPage$json = {
  '1': 'ModVersionPage',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'mod_id', '3': 2, '4': 1, '5': 9, '10': 'modId'},
    {
      '1': 'entries',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModManifestEntry',
      '10': 'entries'
    },
    {
      '1': 'next_offset',
      '3': 4,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'nextOffset',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_offset'},
  ],
};

/// Descriptor for `ModVersionPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modVersionPageDescriptor = $convert.base64Decode(
    'Cg5Nb2RWZXJzaW9uUGFnZRIdCgp2ZXJzaW9uX2lkGAEgASgJUgl2ZXJzaW9uSWQSFQoGbW9kX2'
    'lkGAIgASgJUgVtb2RJZBI7CgdlbnRyaWVzGAMgAygLMiEubW9kY29uZHVjdG9yLnYxLk1vZE1h'
    'bmlmZXN0RW50cnlSB2VudHJpZXMSJAoLbmV4dF9vZmZzZXQYBCABKA1IAFIKbmV4dE9mZnNldI'
    'gBAUIOCgxfbmV4dF9vZmZzZXQ=');

@$core.Deprecated('Use modVersionReplyDescriptor instead')
const ModVersionReply$json = {
  '1': 'ModVersionReply',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModVersionPage',
      '9': 0,
      '10': 'version'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ModVersionReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modVersionReplyDescriptor = $convert.base64Decode(
    'Cg9Nb2RWZXJzaW9uUmVwbHkSOwoHdmVyc2lvbhgBIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2'
    'RWZXJzaW9uUGFnZUgAUgd2ZXJzaW9uEjgKBWZhdWx0GAIgASgLMiAubW9kY29uZHVjdG9yLnYx'
    'Lk1vZExpYnJhcnlGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use readModPayloadRequestDescriptor instead')
const ReadModPayloadRequest$json = {
  '1': 'ReadModPayloadRequest',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'payload_id', '3': 2, '4': 1, '5': 9, '10': 'payloadId'},
    {'1': 'offset', '3': 3, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'count', '3': 4, '4': 1, '5': 13, '10': 'count'},
  ],
};

/// Descriptor for `ReadModPayloadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readModPayloadRequestDescriptor = $convert.base64Decode(
    'ChVSZWFkTW9kUGF5bG9hZFJlcXVlc3QSHQoKdmVyc2lvbl9pZBgBIAEoCVIJdmVyc2lvbklkEh'
    '0KCnBheWxvYWRfaWQYAiABKAlSCXBheWxvYWRJZBIWCgZvZmZzZXQYAyABKARSBm9mZnNldBIU'
    'CgVjb3VudBgEIAEoDVIFY291bnQ=');

@$core.Deprecated('Use modPayloadReplyDescriptor instead')
const ModPayloadReply$json = {
  '1': 'ModPayloadReply',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '9': 0, '10': 'data'},
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModLibraryFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `ModPayloadReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modPayloadReplyDescriptor = $convert.base64Decode(
    'Cg9Nb2RQYXlsb2FkUmVwbHkSFAoEZGF0YRgBIAEoDEgAUgRkYXRhEjgKBWZhdWx0GAIgASgLMi'
    'AubW9kY29uZHVjdG9yLnYxLk1vZExpYnJhcnlGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');
