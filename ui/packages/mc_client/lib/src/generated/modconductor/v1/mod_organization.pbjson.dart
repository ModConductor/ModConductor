// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_organization.proto.

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

@$core.Deprecated('Use modFilterModeDescriptor instead')
const ModFilterMode$json = {
  '1': 'ModFilterMode',
  '2': [
    {'1': 'MOD_FILTER_MODE_UNSPECIFIED', '2': 0},
    {'1': 'MOD_FILTER_MODE_ALL', '2': 1},
    {'1': 'MOD_FILTER_MODE_ANY', '2': 2},
  ],
};

/// Descriptor for `ModFilterMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modFilterModeDescriptor = $convert.base64Decode(
    'Cg1Nb2RGaWx0ZXJNb2RlEh8KG01PRF9GSUxURVJfTU9ERV9VTlNQRUNJRklFRBAAEhcKE01PRF'
    '9GSUxURVJfTU9ERV9BTEwQARIXChNNT0RfRklMVEVSX01PREVfQU5ZEAI=');

@$core.Deprecated('Use modQueryViewDescriptor instead')
const ModQueryView$json = {
  '1': 'ModQueryView',
  '2': [
    {'1': 'MOD_QUERY_VIEW_UNSPECIFIED', '2': 0},
    {'1': 'MOD_QUERY_VIEW_FLAT', '2': 1},
    {'1': 'MOD_QUERY_VIEW_GROUPS', '2': 2},
  ],
};

/// Descriptor for `ModQueryView`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modQueryViewDescriptor = $convert.base64Decode(
    'CgxNb2RRdWVyeVZpZXcSHgoaTU9EX1FVRVJZX1ZJRVdfVU5TUEVDSUZJRUQQABIXChNNT0RfUV'
    'VFUllfVklFV19GTEFUEAESGQoVTU9EX1FVRVJZX1ZJRVdfR1JPVVBTEAI=');

@$core.Deprecated('Use modQuerySortDescriptor instead')
const ModQuerySort$json = {
  '1': 'ModQuerySort',
  '2': [
    {'1': 'MOD_QUERY_SORT_UNSPECIFIED', '2': 0},
    {'1': 'MOD_QUERY_SORT_PRIORITY', '2': 1},
    {'1': 'MOD_QUERY_SORT_NAME', '2': 2},
  ],
};

/// Descriptor for `ModQuerySort`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modQuerySortDescriptor = $convert.base64Decode(
    'CgxNb2RRdWVyeVNvcnQSHgoaTU9EX1FVRVJZX1NPUlRfVU5TUEVDSUZJRUQQABIbChdNT0RfUV'
    'VFUllfU09SVF9QUklPUklUWRABEhcKE01PRF9RVUVSWV9TT1JUX05BTUUQAg==');

@$core.Deprecated('Use modEnabledFilterDescriptor instead')
const ModEnabledFilter$json = {
  '1': 'ModEnabledFilter',
  '2': [
    {'1': 'MOD_ENABLED_FILTER_UNSPECIFIED', '2': 0},
    {'1': 'MOD_ENABLED_FILTER_YES', '2': 1},
    {'1': 'MOD_ENABLED_FILTER_NO', '2': 2},
    {'1': 'MOD_ENABLED_FILTER_NOT_APPLICABLE', '2': 3},
  ],
};

/// Descriptor for `ModEnabledFilter`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modEnabledFilterDescriptor = $convert.base64Decode(
    'ChBNb2RFbmFibGVkRmlsdGVyEiIKHk1PRF9FTkFCTEVEX0ZJTFRFUl9VTlNQRUNJRklFRBAAEh'
    'oKFk1PRF9FTkFCTEVEX0ZJTFRFUl9ZRVMQARIZChVNT0RfRU5BQkxFRF9GSUxURVJfTk8QAhIl'
    'CiFNT0RfRU5BQkxFRF9GSUxURVJfTk9UX0FQUExJQ0FCTEUQAw==');

@$core.Deprecated('Use modCategoryDescriptor instead')
const ModCategory$json = {
  '1': 'ModCategory',
  '2': [
    {'1': 'category_id', '3': 1, '4': 1, '5': 9, '10': 'categoryId'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'parent_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'parentId',
      '17': true
    },
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'missing', '3': 5, '4': 1, '5': 8, '10': 'missing'},
    {'1': 'assigned_count', '3': 6, '4': 1, '5': 13, '10': 'assignedCount'},
    {'1': 'has_children', '3': 7, '4': 1, '5': 8, '10': 'hasChildren'},
  ],
  '8': [
    {'1': '_parent_id'},
  ],
};

/// Descriptor for `ModCategory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modCategoryDescriptor = $convert.base64Decode(
    'CgtNb2RDYXRlZ29yeRIfCgtjYXRlZ29yeV9pZBgBIAEoCVIKY2F0ZWdvcnlJZBIhCgx3b3Jrc3'
    'BhY2VfaWQYAiABKAlSC3dvcmtzcGFjZUlkEiAKCXBhcmVudF9pZBgDIAEoCUgAUghwYXJlbnRJ'
    'ZIgBARIUCgVsYWJlbBgEIAEoCVIFbGFiZWwSGAoHbWlzc2luZxgFIAEoCFIHbWlzc2luZxIlCg'
    '5hc3NpZ25lZF9jb3VudBgGIAEoDVINYXNzaWduZWRDb3VudBIhCgxoYXNfY2hpbGRyZW4YByAB'
    'KAhSC2hhc0NoaWxkcmVuQgwKCl9wYXJlbnRfaWQ=');

@$core.Deprecated('Use readCategoriesRequestDescriptor instead')
const ReadCategoriesRequest$json = {
  '1': 'ReadCategoriesRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'parent_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'parentId',
      '17': true
    },
    {
      '1': 'after_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'afterId',
      '17': true
    },
    {
      '1': 'expected_revision',
      '3': 4,
      '4': 1,
      '5': 4,
      '9': 2,
      '10': 'expectedRevision',
      '17': true
    },
  ],
  '8': [
    {'1': '_parent_id'},
    {'1': '_after_id'},
    {'1': '_expected_revision'},
  ],
};

/// Descriptor for `ReadCategoriesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readCategoriesRequestDescriptor = $convert.base64Decode(
    'ChVSZWFkQ2F0ZWdvcmllc1JlcXVlc3QSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2'
    'VJZBIgCglwYXJlbnRfaWQYAiABKAlIAFIIcGFyZW50SWSIAQESHgoIYWZ0ZXJfaWQYAyABKAlI'
    'AVIHYWZ0ZXJJZIgBARIwChFleHBlY3RlZF9yZXZpc2lvbhgEIAEoBEgCUhBleHBlY3RlZFJldm'
    'lzaW9uiAEBQgwKCl9wYXJlbnRfaWRCCwoJX2FmdGVyX2lkQhQKEl9leHBlY3RlZF9yZXZpc2lv'
    'bg==');

@$core.Deprecated('Use categoriesPageDescriptor instead')
const CategoriesPage$json = {
  '1': 'CategoriesPage',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 4, '10': 'revision'},
    {
      '1': 'entries',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModCategory',
      '10': 'entries'
    },
    {
      '1': 'ancestors',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModCategory',
      '10': 'ancestors'
    },
    {
      '1': 'next_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nextId',
      '17': true
    },
  ],
  '8': [
    {'1': '_next_id'},
  ],
};

/// Descriptor for `CategoriesPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoriesPageDescriptor = $convert.base64Decode(
    'Cg5DYXRlZ29yaWVzUGFnZRIaCghyZXZpc2lvbhgBIAEoBFIIcmV2aXNpb24SNgoHZW50cmllcx'
    'gCIAMoCzIcLm1vZGNvbmR1Y3Rvci52MS5Nb2RDYXRlZ29yeVIHZW50cmllcxI6CglhbmNlc3Rv'
    'cnMYAyADKAsyHC5tb2Rjb25kdWN0b3IudjEuTW9kQ2F0ZWdvcnlSCWFuY2VzdG9ycxIcCgduZX'
    'h0X2lkGAQgASgJSABSBm5leHRJZIgBAUIKCghfbmV4dF9pZA==');

@$core.Deprecated('Use categoriesReplyDescriptor instead')
const CategoriesReply$json = {
  '1': 'CategoriesReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CategoriesPage',
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

/// Descriptor for `CategoriesReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoriesReplyDescriptor = $convert.base64Decode(
    'Cg9DYXRlZ29yaWVzUmVwbHkSNQoEcGFnZRgBIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5DYXRlZ2'
    '9yaWVzUGFnZUgAUgRwYWdlEjgKBWZhdWx0GAIgASgLMiAubW9kY29uZHVjdG9yLnYxLk1vZExp'
    'YnJhcnlGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');

@$core.Deprecated('Use categoryDefinitionDescriptor instead')
const CategoryDefinition$json = {
  '1': 'CategoryDefinition',
  '2': [
    {'1': 'category_id', '3': 1, '4': 1, '5': 9, '10': 'categoryId'},
    {
      '1': 'parent_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'parentId',
      '17': true
    },
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
  ],
  '8': [
    {'1': '_parent_id'},
  ],
};

/// Descriptor for `CategoryDefinition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryDefinitionDescriptor = $convert.base64Decode(
    'ChJDYXRlZ29yeURlZmluaXRpb24SHwoLY2F0ZWdvcnlfaWQYASABKAlSCmNhdGVnb3J5SWQSIA'
    'oJcGFyZW50X2lkGAIgASgJSABSCHBhcmVudElkiAEBEhQKBWxhYmVsGAMgASgJUgVsYWJlbEIM'
    'CgpfcGFyZW50X2lk');

@$core.Deprecated('Use editCategoryRequestDescriptor instead')
const EditCategoryRequest$json = {
  '1': 'EditCategoryRequest',
  '2': [
    {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    {
      '1': 'expected_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'expectedRevision'
    },
    {
      '1': 'create',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CategoryDefinition',
      '9': 0,
      '10': 'create'
    },
    {
      '1': 'update',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.CategoryDefinition',
      '9': 0,
      '10': 'update'
    },
    {'1': 'delete_id', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'deleteId'},
  ],
  '8': [
    {'1': 'edit'},
  ],
};

/// Descriptor for `EditCategoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editCategoryRequestDescriptor = $convert.base64Decode(
    'ChNFZGl0Q2F0ZWdvcnlSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSW'
    'QSKwoRZXhwZWN0ZWRfcmV2aXNpb24YAiABKARSEGV4cGVjdGVkUmV2aXNpb24SPQoGY3JlYXRl'
    'GAMgASgLMiMubW9kY29uZHVjdG9yLnYxLkNhdGVnb3J5RGVmaW5pdGlvbkgAUgZjcmVhdGUSPQ'
    'oGdXBkYXRlGAQgASgLMiMubW9kY29uZHVjdG9yLnYxLkNhdGVnb3J5RGVmaW5pdGlvbkgAUgZ1'
    'cGRhdGUSHQoJZGVsZXRlX2lkGAUgASgJSABSCGRlbGV0ZUlkQgYKBGVkaXQ=');

@$core.Deprecated('Use organizationRevisionDescriptor instead')
const OrganizationRevision$json = {
  '1': 'OrganizationRevision',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 4, '10': 'revision'},
  ],
};

/// Descriptor for `OrganizationRevision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizationRevisionDescriptor =
    $convert.base64Decode(
        'ChRPcmdhbml6YXRpb25SZXZpc2lvbhIaCghyZXZpc2lvbhgBIAEoBFIIcmV2aXNpb24=');

@$core.Deprecated('Use organizationChangeReplyDescriptor instead')
const OrganizationChangeReply$json = {
  '1': 'OrganizationChangeReply',
  '2': [
    {
      '1': 'changed',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OrganizationRevision',
      '9': 0,
      '10': 'changed'
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

/// Descriptor for `OrganizationChangeReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizationChangeReplyDescriptor = $convert.base64Decode(
    'ChdPcmdhbml6YXRpb25DaGFuZ2VSZXBseRJBCgdjaGFuZ2VkGAEgASgLMiUubW9kY29uZHVjdG'
    '9yLnYxLk9yZ2FuaXphdGlvblJldmlzaW9uSABSB2NoYW5nZWQSOAoFZmF1bHQYAiABKAsyIC5t'
    'b2Rjb25kdWN0b3IudjEuTW9kTGlicmFyeUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');

@$core.Deprecated('Use modCategoryFilterDescriptor instead')
const ModCategoryFilter$json = {
  '1': 'ModCategoryFilter',
  '2': [
    {
      '1': 'category',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModCategoryReference',
      '10': 'category'
    },
    {'1': 'descendants', '3': 2, '4': 1, '5': 8, '10': 'descendants'},
  ],
};

/// Descriptor for `ModCategoryFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modCategoryFilterDescriptor = $convert.base64Decode(
    'ChFNb2RDYXRlZ29yeUZpbHRlchJBCghjYXRlZ29yeRgBIAEoCzIlLm1vZGNvbmR1Y3Rvci52MS'
    '5Nb2RDYXRlZ29yeVJlZmVyZW5jZVIIY2F0ZWdvcnkSIAoLZGVzY2VuZGFudHMYAiABKAhSC2Rl'
    'c2NlbmRhbnRz');

@$core.Deprecated('Use modFilterPredicateDescriptor instead')
const ModFilterPredicate$json = {
  '1': 'ModFilterPredicate',
  '2': [
    {
      '1': 'category',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModCategoryFilter',
      '9': 0,
      '10': 'category'
    },
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.InventoryModKind',
      '9': 0,
      '10': 'kind'
    },
    {
      '1': 'status',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModInventoryStatus',
      '9': 0,
      '10': 'status'
    },
    {
      '1': 'enabled',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModEnabledFilter',
      '9': 0,
      '10': 'enabled'
    },
    {
      '1': 'uncategorized',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'uncategorized'
    },
    {
      '1': 'missing_category',
      '3': 6,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'missingCategory'
    },
  ],
  '8': [
    {'1': 'predicate'},
  ],
};

/// Descriptor for `ModFilterPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modFilterPredicateDescriptor = $convert.base64Decode(
    'ChJNb2RGaWx0ZXJQcmVkaWNhdGUSQAoIY2F0ZWdvcnkYASABKAsyIi5tb2Rjb25kdWN0b3Iudj'
    'EuTW9kQ2F0ZWdvcnlGaWx0ZXJIAFIIY2F0ZWdvcnkSNwoEa2luZBgCIAEoDjIhLm1vZGNvbmR1'
    'Y3Rvci52MS5JbnZlbnRvcnlNb2RLaW5kSABSBGtpbmQSPQoGc3RhdHVzGAMgASgOMiMubW9kY2'
    '9uZHVjdG9yLnYxLk1vZEludmVudG9yeVN0YXR1c0gAUgZzdGF0dXMSPQoHZW5hYmxlZBgEIAEo'
    'DjIhLm1vZGNvbmR1Y3Rvci52MS5Nb2RFbmFibGVkRmlsdGVySABSB2VuYWJsZWQSJgoNdW5jYX'
    'RlZ29yaXplZBgFIAEoCEgAUg11bmNhdGVnb3JpemVkEisKEG1pc3NpbmdfY2F0ZWdvcnkYBiAB'
    'KAhIAFIPbWlzc2luZ0NhdGVnb3J5QgsKCXByZWRpY2F0ZQ==');

@$core.Deprecated('Use modQueryDefinitionDescriptor instead')
const ModQueryDefinition$json = {
  '1': 'ModQueryDefinition',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModFilterMode',
      '10': 'mode'
    },
    {
      '1': 'filters',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.ModFilterPredicate',
      '10': 'filters'
    },
    {
      '1': 'view',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModQueryView',
      '10': 'view'
    },
    {
      '1': 'sort',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ModQuerySort',
      '10': 'sort'
    },
  ],
};

/// Descriptor for `ModQueryDefinition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modQueryDefinitionDescriptor = $convert.base64Decode(
    'ChJNb2RRdWVyeURlZmluaXRpb24SEgoEdGV4dBgBIAEoCVIEdGV4dBIyCgRtb2RlGAIgASgOMh'
    '4ubW9kY29uZHVjdG9yLnYxLk1vZEZpbHRlck1vZGVSBG1vZGUSPQoHZmlsdGVycxgDIAMoCzIj'
    'Lm1vZGNvbmR1Y3Rvci52MS5Nb2RGaWx0ZXJQcmVkaWNhdGVSB2ZpbHRlcnMSMQoEdmlldxgEIA'
    'EoDjIdLm1vZGNvbmR1Y3Rvci52MS5Nb2RRdWVyeVZpZXdSBHZpZXcSMQoEc29ydBgFIAEoDjId'
    'Lm1vZGNvbmR1Y3Rvci52MS5Nb2RRdWVyeVNvcnRSBHNvcnQ=');

@$core.Deprecated('Use modQueryCursorDescriptor instead')
const ModQueryCursor$json = {
  '1': 'ModQueryCursor',
  '2': [
    {
      '1': 'catalogue_revision',
      '3': 1,
      '4': 1,
      '5': 4,
      '10': 'catalogueRevision'
    },
    {
      '1': 'selection_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'selectionRevision'
    },
    {'1': 'query_identity', '3': 3, '4': 1, '5': 9, '10': 'queryIdentity'},
    {'1': 'offset', '3': 4, '4': 1, '5': 13, '10': 'offset'},
  ],
};

/// Descriptor for `ModQueryCursor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modQueryCursorDescriptor = $convert.base64Decode(
    'Cg5Nb2RRdWVyeUN1cnNvchItChJjYXRhbG9ndWVfcmV2aXNpb24YASABKARSEWNhdGFsb2d1ZV'
    'JldmlzaW9uEi0KEnNlbGVjdGlvbl9yZXZpc2lvbhgCIAEoBFIRc2VsZWN0aW9uUmV2aXNpb24S'
    'JQoOcXVlcnlfaWRlbnRpdHkYAyABKAlSDXF1ZXJ5SWRlbnRpdHkSFgoGb2Zmc2V0GAQgASgNUg'
    'ZvZmZzZXQ=');

@$core.Deprecated('Use queryModsRequestDescriptor instead')
const QueryModsRequest$json = {
  '1': 'QueryModsRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {
      '1': 'query',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModQueryDefinition',
      '10': 'query'
    },
    {
      '1': 'cursor',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModQueryCursor',
      '10': 'cursor'
    },
    {
      '1': 'inspected_mod_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'inspectedModId',
      '17': true
    },
  ],
  '8': [
    {'1': '_inspected_mod_id'},
  ],
};

/// Descriptor for `QueryModsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryModsRequestDescriptor = $convert.base64Decode(
    'ChBRdWVyeU1vZHNSZXF1ZXN0Eh0KCnByb2ZpbGVfaWQYASABKAlSCXByb2ZpbGVJZBI5CgVxdW'
    'VyeRgCIAEoCzIjLm1vZGNvbmR1Y3Rvci52MS5Nb2RRdWVyeURlZmluaXRpb25SBXF1ZXJ5EjcK'
    'BmN1cnNvchgDIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS5Nb2RRdWVyeUN1cnNvclIGY3Vyc29yEi'
    '0KEGluc3BlY3RlZF9tb2RfaWQYBCABKAlIAFIOaW5zcGVjdGVkTW9kSWSIAQFCEwoRX2luc3Bl'
    'Y3RlZF9tb2RfaWQ=');

@$core.Deprecated('Use separatorGroupSizeDescriptor instead')
const SeparatorGroupSize$json = {
  '1': 'SeparatorGroupSize',
  '2': [
    {'1': 'matching', '3': 1, '4': 1, '5': 13, '10': 'matching'},
    {'1': 'total', '3': 2, '4': 1, '5': 13, '10': 'total'},
  ],
};

/// Descriptor for `SeparatorGroupSize`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List separatorGroupSizeDescriptor = $convert.base64Decode(
    'ChJTZXBhcmF0b3JHcm91cFNpemUSGgoIbWF0Y2hpbmcYASABKA1SCG1hdGNoaW5nEhQKBXRvdG'
    'FsGAIgASgNUgV0b3RhbA==');

@$core.Deprecated('Use organizedModViewDescriptor instead')
const OrganizedModView$json = {
  '1': 'OrganizedModView',
  '2': [
    {
      '1': 'entry',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ProfileModView',
      '10': 'entry'
    },
    {
      '1': 'group_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupId',
      '17': true
    },
    {
      '1': 'group_size',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SeparatorGroupSize',
      '10': 'groupSize'
    },
  ],
  '8': [
    {'1': '_group_id'},
  ],
};

/// Descriptor for `OrganizedModView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List organizedModViewDescriptor = $convert.base64Decode(
    'ChBPcmdhbml6ZWRNb2RWaWV3EjUKBWVudHJ5GAEgASgLMh8ubW9kY29uZHVjdG9yLnYxLlByb2'
    'ZpbGVNb2RWaWV3UgVlbnRyeRIeCghncm91cF9pZBgCIAEoCUgAUgdncm91cElkiAEBEkIKCmdy'
    'b3VwX3NpemUYAyABKAsyIy5tb2Rjb25kdWN0b3IudjEuU2VwYXJhdG9yR3JvdXBTaXplUglncm'
    '91cFNpemVCCwoJX2dyb3VwX2lk');

@$core.Deprecated('Use modQueryPageDescriptor instead')
const ModQueryPage$json = {
  '1': 'ModQueryPage',
  '2': [
    {
      '1': 'catalogue_revision',
      '3': 1,
      '4': 1,
      '5': 4,
      '10': 'catalogueRevision'
    },
    {
      '1': 'selection_revision',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'selectionRevision'
    },
    {'1': 'query_identity', '3': 3, '4': 1, '5': 9, '10': 'queryIdentity'},
    {
      '1': 'entries',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OrganizedModView',
      '10': 'entries'
    },
    {
      '1': 'context',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.OrganizedModView',
      '10': 'context'
    },
    {
      '1': 'inspected',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.OrganizedModView',
      '10': 'inspected'
    },
    {
      '1': 'next',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModQueryCursor',
      '10': 'next'
    },
    {'1': 'matching_mods', '3': 8, '4': 1, '5': 13, '10': 'matchingMods'},
    {
      '1': 'matching_separators',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'matchingSeparators'
    },
    {'1': 'total_mods', '3': 10, '4': 1, '5': 13, '10': 'totalMods'},
    {'1': 'enabled_count', '3': 11, '4': 1, '5': 13, '10': 'enabledCount'},
    {'1': 'matching_groups', '3': 12, '4': 1, '5': 13, '10': 'matchingGroups'},
  ],
};

/// Descriptor for `ModQueryPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modQueryPageDescriptor = $convert.base64Decode(
    'CgxNb2RRdWVyeVBhZ2USLQoSY2F0YWxvZ3VlX3JldmlzaW9uGAEgASgEUhFjYXRhbG9ndWVSZX'
    'Zpc2lvbhItChJzZWxlY3Rpb25fcmV2aXNpb24YAiABKARSEXNlbGVjdGlvblJldmlzaW9uEiUK'
    'DnF1ZXJ5X2lkZW50aXR5GAMgASgJUg1xdWVyeUlkZW50aXR5EjsKB2VudHJpZXMYBCADKAsyIS'
    '5tb2Rjb25kdWN0b3IudjEuT3JnYW5pemVkTW9kVmlld1IHZW50cmllcxI7Cgdjb250ZXh0GAUg'
    'AygLMiEubW9kY29uZHVjdG9yLnYxLk9yZ2FuaXplZE1vZFZpZXdSB2NvbnRleHQSPwoJaW5zcG'
    'VjdGVkGAYgASgLMiEubW9kY29uZHVjdG9yLnYxLk9yZ2FuaXplZE1vZFZpZXdSCWluc3BlY3Rl'
    'ZBIzCgRuZXh0GAcgASgLMh8ubW9kY29uZHVjdG9yLnYxLk1vZFF1ZXJ5Q3Vyc29yUgRuZXh0Ei'
    'MKDW1hdGNoaW5nX21vZHMYCCABKA1SDG1hdGNoaW5nTW9kcxIvChNtYXRjaGluZ19zZXBhcmF0'
    'b3JzGAkgASgNUhJtYXRjaGluZ1NlcGFyYXRvcnMSHQoKdG90YWxfbW9kcxgKIAEoDVIJdG90YW'
    'xNb2RzEiMKDWVuYWJsZWRfY291bnQYCyABKA1SDGVuYWJsZWRDb3VudBInCg9tYXRjaGluZ19n'
    'cm91cHMYDCABKA1SDm1hdGNoaW5nR3JvdXBz');

@$core.Deprecated('Use modQueryReplyDescriptor instead')
const ModQueryReply$json = {
  '1': 'ModQueryReply',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ModQueryPage',
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

/// Descriptor for `ModQueryReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modQueryReplyDescriptor = $convert.base64Decode(
    'Cg1Nb2RRdWVyeVJlcGx5EjMKBHBhZ2UYASABKAsyHS5tb2Rjb25kdWN0b3IudjEuTW9kUXVlcn'
    'lQYWdlSABSBHBhZ2USOAoFZmF1bHQYAiABKAsyIC5tb2Rjb25kdWN0b3IudjEuTW9kTGlicmFy'
    'eUZhdWx0SABSBWZhdWx0QgkKB291dGNvbWU=');
