// This is a generated file - do not edit.
//
// Generated from modconductor/v1/link_setup.proto.

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

@$core.Deprecated('Use linkDefaultDescriptor instead')
const LinkDefault$json = {
  '1': 'LinkDefault',
  '2': [
    {'1': 'LINK_DEFAULT_UNKNOWN', '2': 0},
    {'1': 'LINK_DEFAULT_MC', '2': 1},
    {'1': 'LINK_DEFAULT_OTHER', '2': 2},
    {'1': 'LINK_DEFAULT_NONE', '2': 3},
  ],
};

/// Descriptor for `LinkDefault`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List linkDefaultDescriptor = $convert.base64Decode(
    'CgtMaW5rRGVmYXVsdBIYChRMSU5LX0RFRkFVTFRfVU5LTk9XThAAEhMKD0xJTktfREVGQVVMVF'
    '9NQxABEhYKEkxJTktfREVGQVVMVF9PVEhFUhACEhUKEUxJTktfREVGQVVMVF9OT05FEAM=');

@$core.Deprecated('Use linkSetupRequestDescriptor instead')
const LinkSetupRequest$json = {
  '1': 'LinkSetupRequest',
};

/// Descriptor for `LinkSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkSetupRequestDescriptor =
    $convert.base64Decode('ChBMaW5rU2V0dXBSZXF1ZXN0');

@$core.Deprecated('Use addLinkSetupRequestDescriptor instead')
const AddLinkSetupRequest$json = {
  '1': 'AddLinkSetupRequest',
  '2': [
    {'1': 'executable', '3': 1, '4': 1, '5': 9, '10': 'executable'},
  ],
};

/// Descriptor for `AddLinkSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addLinkSetupRequestDescriptor = $convert.base64Decode(
    'ChNBZGRMaW5rU2V0dXBSZXF1ZXN0Eh4KCmV4ZWN1dGFibGUYASABKAlSCmV4ZWN1dGFibGU=');

@$core.Deprecated('Use linkSetupReplyDescriptor instead')
const LinkSetupReply$json = {
  '1': 'LinkSetupReply',
  '2': [
    {'1': 'windows', '3': 1, '4': 1, '5': 8, '10': 'windows'},
    {
      '1': 'available',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'available',
      '17': true
    },
    {
      '1': 'default_app',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.modconductor.v1.LinkDefault',
      '10': 'defaultApp'
    },
    {'1': 'changed', '3': 4, '4': 1, '5': 8, '10': 'changed'},
    {
      '1': 'problem',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'problem',
      '17': true
    },
    {'1': 'can_remove', '3': 6, '4': 1, '5': 8, '10': 'canRemove'},
  ],
  '8': [
    {'1': '_available'},
    {'1': '_problem'},
  ],
};

/// Descriptor for `LinkSetupReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkSetupReplyDescriptor = $convert.base64Decode(
    'Cg5MaW5rU2V0dXBSZXBseRIYCgd3aW5kb3dzGAEgASgIUgd3aW5kb3dzEiEKCWF2YWlsYWJsZR'
    'gCIAEoCEgAUglhdmFpbGFibGWIAQESPQoLZGVmYXVsdF9hcHAYAyABKA4yHC5tb2Rjb25kdWN0'
    'b3IudjEuTGlua0RlZmF1bHRSCmRlZmF1bHRBcHASGAoHY2hhbmdlZBgEIAEoCFIHY2hhbmdlZB'
    'IdCgdwcm9ibGVtGAUgASgJSAFSB3Byb2JsZW2IAQESHQoKY2FuX3JlbW92ZRgGIAEoCFIJY2Fu'
    'UmVtb3ZlQgwKCl9hdmFpbGFibGVCCgoIX3Byb2JsZW0=');
