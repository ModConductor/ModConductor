// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bain.proto.

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

@$core.Deprecated('Use archiveInstallerChangeDescriptor instead')
const ArchiveInstallerChange$json = {
  '1': 'ArchiveInstallerChange',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {
      '1': 'installer',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ArchiveInstaller',
      '10': 'installer'
    },
  ],
};

/// Descriptor for `ArchiveInstallerChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List archiveInstallerChangeDescriptor = $convert.base64Decode(
    'ChZBcmNoaXZlSW5zdGFsbGVyQ2hhbmdlEkkKCXJlZmVyZW5jZRgBIAEoCzIrLm1vZGNvbmR1Y3'
    'Rvci52MS5JbnN0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIJcmVmZXJlbmNlEj8KCWluc3RhbGxl'
    'chgCIAEoDjIhLm1vZGNvbmR1Y3Rvci52MS5BcmNoaXZlSW5zdGFsbGVyUglpbnN0YWxsZXI=');

@$core.Deprecated('Use bainFolderSelectionDescriptor instead')
const BainFolderSelection$json = {
  '1': 'BainFolderSelection',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
    {'1': 'selected', '3': 3, '4': 1, '5': 8, '10': 'selected'},
  ],
};

/// Descriptor for `BainFolderSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainFolderSelectionDescriptor = $convert.base64Decode(
    'ChNCYWluRm9sZGVyU2VsZWN0aW9uEkkKCXJlZmVyZW5jZRgBIAEoCzIrLm1vZGNvbmR1Y3Rvci'
    '52MS5JbnN0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIJcmVmZXJlbmNlEhQKBWluZGV4GAIgASgN'
    'UgVpbmRleBIaCghzZWxlY3RlZBgDIAEoCFIIc2VsZWN0ZWQ=');

@$core.Deprecated('Use bainAllFoldersSelectionDescriptor instead')
const BainAllFoldersSelection$json = {
  '1': 'BainAllFoldersSelection',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {'1': 'selected', '3': 2, '4': 1, '5': 8, '10': 'selected'},
  ],
};

/// Descriptor for `BainAllFoldersSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainAllFoldersSelectionDescriptor = $convert.base64Decode(
    'ChdCYWluQWxsRm9sZGVyc1NlbGVjdGlvbhJJCglyZWZlcmVuY2UYASABKAsyKy5tb2Rjb25kdW'
    'N0b3IudjEuSW5zdGFsbGF0aW9uRHJhZnRSZWZlcmVuY2VSCXJlZmVyZW5jZRIaCghzZWxlY3Rl'
    'ZBgCIAEoCFIIc2VsZWN0ZWQ=');

@$core.Deprecated('Use bainFileSelectionDescriptor instead')
const BainFileSelection$json = {
  '1': 'BainFileSelection',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {'1': 'path', '3': 2, '4': 3, '5': 9, '10': 'path'},
    {'1': 'included', '3': 3, '4': 1, '5': 8, '10': 'included'},
  ],
};

/// Descriptor for `BainFileSelection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainFileSelectionDescriptor = $convert.base64Decode(
    'ChFCYWluRmlsZVNlbGVjdGlvbhJJCglyZWZlcmVuY2UYASABKAsyKy5tb2Rjb25kdWN0b3Iudj'
    'EuSW5zdGFsbGF0aW9uRHJhZnRSZWZlcmVuY2VSCXJlZmVyZW5jZRISCgRwYXRoGAIgAygJUgRw'
    'YXRoEhoKCGluY2x1ZGVkGAMgASgIUghpbmNsdWRlZA==');

@$core.Deprecated('Use bainFolderReferenceDescriptor instead')
const BainFolderReference$json = {
  '1': 'BainFolderReference',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `BainFolderReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainFolderReferenceDescriptor = $convert.base64Decode(
    'ChNCYWluRm9sZGVyUmVmZXJlbmNlEkkKCXJlZmVyZW5jZRgBIAEoCzIrLm1vZGNvbmR1Y3Rvci'
    '52MS5JbnN0YWxsYXRpb25EcmFmdFJlZmVyZW5jZVIJcmVmZXJlbmNlEhQKBWluZGV4GAIgASgN'
    'UgVpbmRleA==');

@$core.Deprecated('Use bainPackageNotesDescriptor instead')
const BainPackageNotes$json = {
  '1': 'BainPackageNotes',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `BainPackageNotes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainPackageNotesDescriptor = $convert
    .base64Decode('ChBCYWluUGFja2FnZU5vdGVzEhIKBHRleHQYASABKAlSBHRleHQ=');

@$core.Deprecated('Use bainFolderFilesDescriptor instead')
const BainFolderFiles$json = {
  '1': 'BainFolderFiles',
  '2': [
    {
      '1': 'files',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.InstallationReviewedFile',
      '10': 'files'
    },
  ],
};

/// Descriptor for `BainFolderFiles`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainFolderFilesDescriptor = $convert.base64Decode(
    'Cg9CYWluRm9sZGVyRmlsZXMSPwoFZmlsZXMYASADKAsyKS5tb2Rjb25kdWN0b3IudjEuSW5zdG'
    'FsbGF0aW9uUmV2aWV3ZWRGaWxlUgVmaWxlcw==');

@$core.Deprecated('Use bainPackageDescriptor instead')
const BainPackage$json = {
  '1': 'BainPackage',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'files', '3': 3, '4': 1, '5': 13, '10': 'files'},
    {'1': 'bytes', '3': 4, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'selected', '3': 5, '4': 1, '5': 8, '10': 'selected'},
  ],
};

/// Descriptor for `BainPackage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainPackageDescriptor = $convert.base64Decode(
    'CgtCYWluUGFja2FnZRIUCgVpbmRleBgBIAEoDVIFaW5kZXgSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IUCgVmaWxlcxgDIAEoDVIFZmlsZXMSFAoFYnl0ZXMYBCABKARSBWJ5dGVzEhoKCHNlbGVjdGVk'
    'GAUgASgIUghzZWxlY3RlZA==');

@$core.Deprecated('Use bainReviewedFileDescriptor instead')
const BainReviewedFile$json = {
  '1': 'BainReviewedFile',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationReviewedFile',
      '10': 'file'
    },
    {'1': 'included', '3': 2, '4': 1, '5': 8, '10': 'included'},
  ],
};

/// Descriptor for `BainReviewedFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainReviewedFileDescriptor = $convert.base64Decode(
    'ChBCYWluUmV2aWV3ZWRGaWxlEj0KBGZpbGUYASABKAsyKS5tb2Rjb25kdWN0b3IudjEuSW5zdG'
    'FsbGF0aW9uUmV2aWV3ZWRGaWxlUgRmaWxlEhoKCGluY2x1ZGVkGAIgASgIUghpbmNsdWRlZA==');

@$core.Deprecated('Use bainChoicesDescriptor instead')
const BainChoices$json = {
  '1': 'BainChoices',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.InstallationDraftReference',
      '10': 'reference'
    },
    {
      '1': 'packages',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BainPackage',
      '10': 'packages'
    },
    {
      '1': 'files',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.modconductor.v1.BainReviewedFile',
      '10': 'files'
    },
    {'1': 'reviewing', '3': 4, '4': 1, '5': 8, '10': 'reviewing'},
    {'1': 'has_notes', '3': 5, '4': 1, '5': 8, '10': 'hasNotes'},
    {
      '1': 'problem',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'problem',
      '17': true
    },
    {
      '1': 'reviewed_draft',
      '3': 7,
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

/// Descriptor for `BainChoices`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bainChoicesDescriptor = $convert.base64Decode(
    'CgtCYWluQ2hvaWNlcxJJCglyZWZlcmVuY2UYASABKAsyKy5tb2Rjb25kdWN0b3IudjEuSW5zdG'
    'FsbGF0aW9uRHJhZnRSZWZlcmVuY2VSCXJlZmVyZW5jZRI4CghwYWNrYWdlcxgCIAMoCzIcLm1v'
    'ZGNvbmR1Y3Rvci52MS5CYWluUGFja2FnZVIIcGFja2FnZXMSNwoFZmlsZXMYAyADKAsyIS5tb2'
    'Rjb25kdWN0b3IudjEuQmFpblJldmlld2VkRmlsZVIFZmlsZXMSHAoJcmV2aWV3aW5nGAQgASgI'
    'UglyZXZpZXdpbmcSGwoJaGFzX25vdGVzGAUgASgIUghoYXNOb3RlcxIdCgdwcm9ibGVtGAYgAS'
    'gJSABSB3Byb2JsZW2IAQESUAoOcmV2aWV3ZWRfZHJhZnQYByABKAsyKS5tb2Rjb25kdWN0b3Iu'
    'djEuQXJjaGl2ZUluc3RhbGxhdGlvbkRyYWZ0Ug1yZXZpZXdlZERyYWZ0QgoKCF9wcm9ibGVt');
