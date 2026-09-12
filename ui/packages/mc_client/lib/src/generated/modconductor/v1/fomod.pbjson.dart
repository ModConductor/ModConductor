// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fomod.proto.

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

@$core.Deprecated('Use fomodGroupKindDescriptor instead')
const FomodGroupKind$json = {
  '1': 'FomodGroupKind',
  '2': [
    {'1': 'FOMOD_GROUP_KIND_ANY', '2': 0},
    {'1': 'FOMOD_GROUP_KIND_ALL', '2': 1},
    {'1': 'FOMOD_GROUP_KIND_AT_LEAST_ONE', '2': 2},
    {'1': 'FOMOD_GROUP_KIND_AT_MOST_ONE', '2': 3},
    {'1': 'FOMOD_GROUP_KIND_EXACTLY_ONE', '2': 4},
  ],
};

/// Descriptor for `FomodGroupKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fomodGroupKindDescriptor = $convert.base64Decode(
    'Cg5Gb21vZEdyb3VwS2luZBIYChRGT01PRF9HUk9VUF9LSU5EX0FOWRAAEhgKFEZPTU9EX0dST1'
    'VQX0tJTkRfQUxMEAESIQodRk9NT0RfR1JPVVBfS0lORF9BVF9MRUFTVF9PTkUQAhIgChxGT01P'
    'RF9HUk9VUF9LSU5EX0FUX01PU1RfT05FEAMSIAocRk9NT0RfR1JPVVBfS0lORF9FWEFDVExZX0'
    '9ORRAE');

@$core.Deprecated('Use fomodOptionKindDescriptor instead')
const FomodOptionKind$json = {
  '1': 'FomodOptionKind',
  '2': [
    {'1': 'FOMOD_OPTION_KIND_REQUIRED', '2': 0},
    {'1': 'FOMOD_OPTION_KIND_RECOMMENDED', '2': 1},
    {'1': 'FOMOD_OPTION_KIND_OPTIONAL', '2': 2},
    {'1': 'FOMOD_OPTION_KIND_NOT_USABLE', '2': 3},
    {'1': 'FOMOD_OPTION_KIND_COULD_BE_USABLE', '2': 4},
    {'1': 'FOMOD_OPTION_KIND_UNKNOWN', '2': 5},
  ],
};

/// Descriptor for `FomodOptionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fomodOptionKindDescriptor = $convert.base64Decode(
    'Cg9Gb21vZE9wdGlvbktpbmQSHgoaRk9NT0RfT1BUSU9OX0tJTkRfUkVRVUlSRUQQABIhCh1GT0'
    '1PRF9PUFRJT05fS0lORF9SRUNPTU1FTkRFRBABEh4KGkZPTU9EX09QVElPTl9LSU5EX09QVElP'
    'TkFMEAISIAocRk9NT0RfT1BUSU9OX0tJTkRfTk9UX1VTQUJMRRADEiUKIUZPTU9EX09QVElPTl'
    '9LSU5EX0NPVUxEX0JFX1VTQUJMRRAEEh0KGUZPTU9EX09QVElPTl9LSU5EX1VOS05PV04QBQ==');

@$core.Deprecated('Use openFomodChoicesDescriptor instead')
const OpenFomodChoices$json = {
  '1': 'OpenFomodChoices',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `OpenFomodChoices`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openFomodChoicesDescriptor = $convert.base64Decode(
    'ChBPcGVuRm9tb2RDaG9pY2VzEkEKBWRyYWZ0GAEgASgLMisubW9kY29uZHVjdG9yLnYxLkluc3'
    'RhbGxhdGlvbkRyYWZ0UmVmZXJlbmNlUgVkcmFmdBIdCgpwcm9maWxlX2lkGAIgASgJUglwcm9m'
    'aWxlSWQ=');

@$core.Deprecated('Use fomodChoiceChangeDescriptor instead')
const FomodChoiceChange$json = {
  '1': 'FomodChoiceChange',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'option_id', '3': 2, '4': 1, '5': 13, '10': 'optionId'},
    {'1': 'selected', '3': 3, '4': 1, '5': 8, '10': 'selected'},
  ],
};

/// Descriptor for `FomodChoiceChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fomodChoiceChangeDescriptor = $convert.base64Decode(
    'ChFGb21vZENob2ljZUNoYW5nZRJBCgVkcmFmdBgBIAEoCzIrLm1vZGNvbmR1Y3Rvci52MS5Jbn'
    'N0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIFZHJhZnQSGwoJb3B0aW9uX2lkGAIgASgNUghvcHRp'
    'b25JZBIaCghzZWxlY3RlZBgDIAEoCFIIc2VsZWN0ZWQ=');

@$core.Deprecated('Use fomodImageRequestDescriptor instead')
const FomodImageRequest$json = {
  '1': 'FomodImageRequest',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'draft'
    },
    {'1': 'path', '3': 2, '4': 3, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `FomodImageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fomodImageRequestDescriptor = $convert.base64Decode(
    'ChFGb21vZEltYWdlUmVxdWVzdBJBCgVkcmFmdBgBIAEoCzIrLm1vZGNvbmR1Y3Rvci52MS5Jbn'
    'N0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIFZHJhZnQSEgoEcGF0aBgCIAMoCVIEcGF0aA==');

@$core.Deprecated('Use fomodImageDescriptor instead')
const FomodImage$json = {
  '1': 'FomodImage',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 12, '10': 'content'},
  ],
};

/// Descriptor for `FomodImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fomodImageDescriptor = $convert
    .base64Decode('CgpGb21vZEltYWdlEhgKB2NvbnRlbnQYASABKAxSB2NvbnRlbnQ=');

@$core.Deprecated('Use fomodOptionDescriptor instead')
const FomodOption$json = {
  '1': 'FomodOption',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FomodOptionKind',
      '10': 'kind'
    },
    {'1': 'selected', '3': 5, '4': 1, '5': 8, '10': 'selected'},
    {'1': 'can_change', '3': 6, '4': 1, '5': 8, '10': 'canChange'},
    {'1': 'image', '3': 7, '4': 3, '5': 9, '10': 'image'},
    {
      '1': 'problem',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'problem',
      '17': true
    },
  ],
  '8': [
    {'1': '_problem'},
  ],
};

/// Descriptor for `FomodOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fomodOptionDescriptor = $convert.base64Decode(
    'CgtGb21vZE9wdGlvbhIOCgJpZBgBIAEoDVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIgCgtkZX'
    'NjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SNAoEa2luZBgEIAEoDjIgLm1vZGNvbmR1Y3Rv'
    'ci52MS5Gb21vZE9wdGlvbktpbmRSBGtpbmQSGgoIc2VsZWN0ZWQYBSABKAhSCHNlbGVjdGVkEh'
    '0KCmNhbl9jaGFuZ2UYBiABKAhSCWNhbkNoYW5nZRIUCgVpbWFnZRgHIAMoCVIFaW1hZ2USHQoH'
    'cHJvYmxlbRgIIAEoCUgAUgdwcm9ibGVtiAEBQgoKCF9wcm9ibGVt');

@$core.Deprecated('Use fomodGroupDescriptor instead')
const FomodGroup$json = {
  '1': 'FomodGroup',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.FomodGroupKind',
      '10': 'kind'
    },
    {
      '1': 'options',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.FomodOption',
      '10': 'options'
    },
  ],
};

/// Descriptor for `FomodGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fomodGroupDescriptor = $convert.base64Decode(
    'CgpGb21vZEdyb3VwEhIKBG5hbWUYASABKAlSBG5hbWUSMwoEa2luZBgCIAEoDjIfLm1vZGNvbm'
    'R1Y3Rvci52MS5Gb21vZEdyb3VwS2luZFIEa2luZBI2CgdvcHRpb25zGAMgAygLMhwubW9kY29u'
    'ZHVjdG9yLnYxLkZvbW9kT3B0aW9uUgdvcHRpb25z');

@$core.Deprecated('Use fomodChoicesDescriptor instead')
const FomodChoices$json = {
  '1': 'FomodChoices',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {'1': 'profile_id', '3': 2, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'step_name', '3': 4, '4': 1, '5': 9, '10': 'stepName'},
    {'1': 'step_number', '3': 5, '4': 1, '5': 13, '10': 'stepNumber'},
    {'1': 'visible_steps', '3': 6, '4': 1, '5': 13, '10': 'visibleSteps'},
    {'1': 'can_back', '3': 7, '4': 1, '5': 8, '10': 'canBack'},
    {'1': 'has_step', '3': 8, '4': 1, '5': 8, '10': 'hasStep'},
    {
      '1': 'groups',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.FomodGroup',
      '10': 'groups'
    },
    {
      '1': 'files',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InstallationReviewedFile',
      '10': 'files'
    },
    {'1': 'review_ready', '3': 11, '4': 1, '5': 8, '10': 'reviewReady'},
    {
      '1': 'problem',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'reviewed_draft',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.ArchiveInstallationDraft',
      '10': 'reviewedDraft'
    },
  ],
  '8': [
    {'1': '_problem'},
  ],
};

/// Descriptor for `FomodChoices`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fomodChoicesDescriptor = $convert.base64Decode(
    'CgxGb21vZENob2ljZXMSSQoJcmVmZXJlbmNlGAEgASgLMisubW9kY29uZHVjdG9yLnYxLkluc3'
    'RhbGxhdGlvbkRyYWZ0UmVmZXJlbmNlUglyZWZlcmVuY2USHQoKcHJvZmlsZV9pZBgCIAEoCVIJ'
    'cHJvZmlsZUlkEhIKBG5hbWUYAyABKAlSBG5hbWUSGwoJc3RlcF9uYW1lGAQgASgJUghzdGVwTm'
    'FtZRIfCgtzdGVwX251bWJlchgFIAEoDVIKc3RlcE51bWJlchIjCg12aXNpYmxlX3N0ZXBzGAYg'
    'ASgNUgx2aXNpYmxlU3RlcHMSGQoIY2FuX2JhY2sYByABKAhSB2NhbkJhY2sSGQoIaGFzX3N0ZX'
    'AYCCABKAhSB2hhc1N0ZXASMwoGZ3JvdXBzGAkgAygLMhsubW9kY29uZHVjdG9yLnYxLkZvbW9k'
    'R3JvdXBSBmdyb3VwcxI/CgVmaWxlcxgKIAMoCzIpLm1vZGNvbmR1Y3Rvci52MS5JbnN0YWxsYX'
    'Rpb25SZXZpZXdlZEZpbGVSBWZpbGVzEiEKDHJldmlld19yZWFkeRgLIAEoCFILcmV2aWV3UmVh'
    'ZHkSHQoHcHJvYmxlbRgMIAEoCUgAUgdwcm9ibGVtiAEBElAKDnJldmlld2VkX2RyYWZ0GA0gAS'
    'gLMikubW9kY29uZHVjdG9yLnYxLkFyY2hpdmVJbnN0YWxsYXRpb25EcmFmdFINcmV2aWV3ZWRE'
    'cmFmdEIKCghfcHJvYmxlbQ==');
