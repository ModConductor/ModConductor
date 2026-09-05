// This is a generated file - do not edit.
//
// Generated from modconductor/v1/engine_probe.proto.

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

@$core.Deprecated('Use inspectRuntimeRequestDescriptor instead')
const InspectRuntimeRequest$json = {
  '1': 'InspectRuntimeRequest',
  '2': [
    {'1': 'protocol_major', '3': 1, '4': 1, '5': 13, '10': 'protocolMajor'},
  ],
};

/// Descriptor for `InspectRuntimeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inspectRuntimeRequestDescriptor = $convert.base64Decode(
    'ChVJbnNwZWN0UnVudGltZVJlcXVlc3QSJQoOcHJvdG9jb2xfbWFqb3IYASABKA1SDXByb3RvY2'
    '9sTWFqb3I=');

@$core.Deprecated('Use runtimeInfoDescriptor instead')
const RuntimeInfo$json = {
  '1': 'RuntimeInfo',
  '2': [
    {'1': 'protocol_major', '3': 1, '4': 1, '5': 13, '10': 'protocolMajor'},
    {'1': 'architecture', '3': 2, '4': 1, '5': 9, '10': 'architecture'},
    {'1': 'native_aot', '3': 3, '4': 1, '5': 8, '10': 'nativeAot'},
  ],
};

/// Descriptor for `RuntimeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runtimeInfoDescriptor = $convert.base64Decode(
    'CgtSdW50aW1lSW5mbxIlCg5wcm90b2NvbF9tYWpvchgBIAEoDVINcHJvdG9jb2xNYWpvchIiCg'
    'xhcmNoaXRlY3R1cmUYAiABKAlSDGFyY2hpdGVjdHVyZRIdCgpuYXRpdmVfYW90GAMgASgIUglu'
    'YXRpdmVBb3Q=');

@$core.Deprecated('Use heartbeatRequestDescriptor instead')
const HeartbeatRequest$json = {
  '1': 'HeartbeatRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'count', '3': 2, '4': 1, '5': 13, '10': 'count'},
  ],
};

/// Descriptor for `HeartbeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatRequestDescriptor = $convert.base64Decode(
    'ChBIZWFydGJlYXRSZXF1ZXN0Eh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3RJZBIUCgVjb3'
    'VudBgCIAEoDVIFY291bnQ=');

@$core.Deprecated('Use heartbeatDescriptor instead')
const Heartbeat$json = {
  '1': 'Heartbeat',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'sequence', '3': 2, '4': 1, '5': 13, '10': 'sequence'},
    {'1': 'complete', '3': 3, '4': 1, '5': 8, '10': 'complete'},
  ],
};

/// Descriptor for `Heartbeat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatDescriptor = $convert.base64Decode(
    'CglIZWFydGJlYXQSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdWVzdElkEhoKCHNlcXVlbmNlGA'
    'IgASgNUghzZXF1ZW5jZRIaCghjb21wbGV0ZRgDIAEoCFIIY29tcGxldGU=');

@$core.Deprecated('Use engineReadyDescriptor instead')
const EngineReady$json = {
  '1': 'EngineReady',
  '2': [
    {'1': 'protocol_major', '3': 1, '4': 1, '5': 13, '10': 'protocolMajor'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
    {'1': 'certificate_pem', '3': 3, '4': 1, '5': 12, '10': 'certificatePem'},
  ],
};

/// Descriptor for `EngineReady`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineReadyDescriptor = $convert.base64Decode(
    'CgtFbmdpbmVSZWFkeRIlCg5wcm90b2NvbF9tYWpvchgBIAEoDVINcHJvdG9jb2xNYWpvchISCg'
    'Rwb3J0GAIgASgNUgRwb3J0EicKD2NlcnRpZmljYXRlX3BlbRgDIAEoDFIOY2VydGlmaWNhdGVQ'
    'ZW0=');
