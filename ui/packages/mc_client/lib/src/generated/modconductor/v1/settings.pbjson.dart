// This is a generated file - do not edit.
//
// Generated from modconductor/v1/settings.proto.

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

@$core.Deprecated('Use appearancePreferenceDescriptor instead')
const AppearancePreference$json = {
  '1': 'AppearancePreference',
  '2': [
    {'1': 'APPEARANCE_PREFERENCE_UNSPECIFIED', '2': 0},
    {'1': 'APPEARANCE_PREFERENCE_SYSTEM', '2': 1},
    {'1': 'APPEARANCE_PREFERENCE_LIGHT', '2': 2},
    {'1': 'APPEARANCE_PREFERENCE_DARK', '2': 3},
  ],
};

/// Descriptor for `AppearancePreference`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List appearancePreferenceDescriptor = $convert.base64Decode(
    'ChRBcHBlYXJhbmNlUHJlZmVyZW5jZRIlCiFBUFBFQVJBTkNFX1BSRUZFUkVOQ0VfVU5TUEVDSU'
    'ZJRUQQABIgChxBUFBFQVJBTkNFX1BSRUZFUkVOQ0VfU1lTVEVNEAESHwobQVBQRUFSQU5DRV9Q'
    'UkVGRVJFTkNFX0xJR0hUEAISHgoaQVBQRUFSQU5DRV9QUkVGRVJFTkNFX0RBUksQAw==');

@$core.Deprecated('Use contrastPreferenceDescriptor instead')
const ContrastPreference$json = {
  '1': 'ContrastPreference',
  '2': [
    {'1': 'CONTRAST_PREFERENCE_UNSPECIFIED', '2': 0},
    {'1': 'CONTRAST_PREFERENCE_SYSTEM', '2': 1},
    {'1': 'CONTRAST_PREFERENCE_STANDARD', '2': 2},
    {'1': 'CONTRAST_PREFERENCE_HIGH', '2': 3},
  ],
};

/// Descriptor for `ContrastPreference`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List contrastPreferenceDescriptor = $convert.base64Decode(
    'ChJDb250cmFzdFByZWZlcmVuY2USIwofQ09OVFJBU1RfUFJFRkVSRU5DRV9VTlNQRUNJRklFRB'
    'AAEh4KGkNPTlRSQVNUX1BSRUZFUkVOQ0VfU1lTVEVNEAESIAocQ09OVFJBU1RfUFJFRkVSRU5D'
    'RV9TVEFOREFSRBACEhwKGENPTlRSQVNUX1BSRUZFUkVOQ0VfSElHSBAD');

@$core.Deprecated('Use settingsFaultCodeDescriptor instead')
const SettingsFaultCode$json = {
  '1': 'SettingsFaultCode',
  '2': [
    {'1': 'SETTINGS_FAULT_CODE_UNSPECIFIED', '2': 0},
    {'1': 'SETTINGS_FAULT_CODE_INVALID_SCOPE', '2': 1},
    {'1': 'SETTINGS_FAULT_CODE_INVALID_DOCUMENT', '2': 2},
    {'1': 'SETTINGS_FAULT_CODE_UNSUPPORTED_VERSION', '2': 3},
    {'1': 'SETTINGS_FAULT_CODE_INVALID_VALUE', '2': 4},
    {'1': 'SETTINGS_FAULT_CODE_UNAVAILABLE', '2': 5},
    {'1': 'SETTINGS_FAULT_CODE_WORKSPACE_NOT_FOUND', '2': 6},
  ],
};

/// Descriptor for `SettingsFaultCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List settingsFaultCodeDescriptor = $convert.base64Decode(
    'ChFTZXR0aW5nc0ZhdWx0Q29kZRIjCh9TRVRUSU5HU19GQVVMVF9DT0RFX1VOU1BFQ0lGSUVEEA'
    'ASJQohU0VUVElOR1NfRkFVTFRfQ09ERV9JTlZBTElEX1NDT1BFEAESKAokU0VUVElOR1NfRkFV'
    'TFRfQ09ERV9JTlZBTElEX0RPQ1VNRU5UEAISKwonU0VUVElOR1NfRkFVTFRfQ09ERV9VTlNVUF'
    'BPUlRFRF9WRVJTSU9OEAMSJQohU0VUVElOR1NfRkFVTFRfQ09ERV9JTlZBTElEX1ZBTFVFEAQS'
    'IwofU0VUVElOR1NfRkFVTFRfQ09ERV9VTkFWQUlMQUJMRRAFEisKJ1NFVFRJTkdTX0ZBVUxUX0'
    'NPREVfV09SS1NQQUNFX05PVF9GT1VORBAG');

@$core.Deprecated('Use settingsTargetDescriptor instead')
const SettingsTarget$json = {
  '1': 'SettingsTarget',
  '2': [
    {'1': 'application', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'application'},
    {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'workspaceId'},
  ],
  '8': [
    {'1': 'target'},
  ],
};

/// Descriptor for `SettingsTarget`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsTargetDescriptor = $convert.base64Decode(
    'Cg5TZXR0aW5nc1RhcmdldBIiCgthcHBsaWNhdGlvbhgBIAEoCEgAUgthcHBsaWNhdGlvbhIjCg'
    'x3b3Jrc3BhY2VfaWQYAiABKAlIAFILd29ya3NwYWNlSWRCCAoGdGFyZ2V0');

@$core.Deprecated('Use presentationSettingsDescriptor instead')
const PresentationSettings$json = {
  '1': 'PresentationSettings',
  '2': [
    {
      '1': 'appearance',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.AppearancePreference',
      '10': 'appearance'
    },
    {'1': 'text_scale', '3': 2, '4': 1, '5': 1, '10': 'textScale'},
    {
      '1': 'contrast',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.ContrastPreference',
      '10': 'contrast'
    },
  ],
};

/// Descriptor for `PresentationSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presentationSettingsDescriptor = $convert.base64Decode(
    'ChRQcmVzZW50YXRpb25TZXR0aW5ncxJFCgphcHBlYXJhbmNlGAEgASgOMiUubW9kY29uZHVjdG'
    '9yLnYxLkFwcGVhcmFuY2VQcmVmZXJlbmNlUgphcHBlYXJhbmNlEh0KCnRleHRfc2NhbGUYAiAB'
    'KAFSCXRleHRTY2FsZRI/Cghjb250cmFzdBgDIAEoDjIjLm1vZGNvbmR1Y3Rvci52MS5Db250cm'
    'FzdFByZWZlcmVuY2VSCGNvbnRyYXN0');

@$core.Deprecated('Use settingsSnapshotDescriptor instead')
const SettingsSnapshot$json = {
  '1': 'SettingsSnapshot',
  '2': [
    {
      '1': 'presentation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.PresentationSettings',
      '10': 'presentation'
    },
    {
      '1': 'inherits_application',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'inheritsApplication'
    },
  ],
};

/// Descriptor for `SettingsSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsSnapshotDescriptor = $convert.base64Decode(
    'ChBTZXR0aW5nc1NuYXBzaG90EkkKDHByZXNlbnRhdGlvbhgBIAEoCzIlLm1vZGNvbmR1Y3Rvci'
    '52MS5QcmVzZW50YXRpb25TZXR0aW5nc1IMcHJlc2VudGF0aW9uEjEKFGluaGVyaXRzX2FwcGxp'
    'Y2F0aW9uGAIgASgIUhNpbmhlcml0c0FwcGxpY2F0aW9u');

@$core.Deprecated('Use settingsFaultDescriptor instead')
const SettingsFault$json = {
  '1': 'SettingsFault',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.SettingsFaultCode',
      '10': 'code'
    },
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `SettingsFault`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsFaultDescriptor = $convert.base64Decode(
    'Cg1TZXR0aW5nc0ZhdWx0EjYKBGNvZGUYASABKA4yIi5tb2Rjb25kdWN0b3IudjEuU2V0dGluZ3'
    'NGYXVsdENvZGVSBGNvZGUSFgoGZGV0YWlsGAIgASgJUgZkZXRhaWw=');

@$core.Deprecated('Use readSettingsRequestDescriptor instead')
const ReadSettingsRequest$json = {
  '1': 'ReadSettingsRequest',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SettingsTarget',
      '10': 'target'
    },
  ],
};

/// Descriptor for `ReadSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readSettingsRequestDescriptor = $convert.base64Decode(
    'ChNSZWFkU2V0dGluZ3NSZXF1ZXN0EjcKBnRhcmdldBgBIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS'
    '5TZXR0aW5nc1RhcmdldFIGdGFyZ2V0');

@$core.Deprecated('Use saveSettingsRequestDescriptor instead')
const SaveSettingsRequest$json = {
  '1': 'SaveSettingsRequest',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SettingsTarget',
      '10': 'target'
    },
    {
      '1': 'settings',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SettingsSnapshot',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `SaveSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSettingsRequestDescriptor = $convert.base64Decode(
    'ChNTYXZlU2V0dGluZ3NSZXF1ZXN0EjcKBnRhcmdldBgBIAEoCzIfLm1vZGNvbmR1Y3Rvci52MS'
    '5TZXR0aW5nc1RhcmdldFIGdGFyZ2V0Ej0KCHNldHRpbmdzGAIgASgLMiEubW9kY29uZHVjdG9y'
    'LnYxLlNldHRpbmdzU25hcHNob3RSCHNldHRpbmdz');

@$core.Deprecated('Use settingsReplyDescriptor instead')
const SettingsReply$json = {
  '1': 'SettingsReply',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SettingsSnapshot',
      '9': 0,
      '10': 'settings'
    },
    {
      '1': 'fault',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.modconductor.v1.SettingsFault',
      '9': 0,
      '10': 'fault'
    },
  ],
  '8': [
    {'1': 'outcome'},
  ],
};

/// Descriptor for `SettingsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsReplyDescriptor = $convert.base64Decode(
    'Cg1TZXR0aW5nc1JlcGx5Ej8KCHNldHRpbmdzGAEgASgLMiEubW9kY29uZHVjdG9yLnYxLlNldH'
    'RpbmdzU25hcHNob3RIAFIIc2V0dGluZ3MSNgoFZmF1bHQYAiABKAsyHi5tb2Rjb25kdWN0b3Iu'
    'djEuU2V0dGluZ3NGYXVsdEgAUgVmYXVsdEIJCgdvdXRjb21l');
