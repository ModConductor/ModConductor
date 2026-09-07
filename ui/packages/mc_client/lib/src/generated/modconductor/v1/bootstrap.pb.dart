// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bootstrap.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Public descriptor on the owned stdout pipe, not a network RPC.
class EngineReady extends $pb.GeneratedMessage {
  factory EngineReady({
    $core.int? protocolMajor,
    $core.int? port,
    $core.List<$core.int>? certificatePem,
  }) {
    final result = create();
    if (protocolMajor != null) result.protocolMajor = protocolMajor;
    if (port != null) result.port = port;
    if (certificatePem != null) result.certificatePem = certificatePem;
    return result;
  }

  EngineReady._();

  factory EngineReady.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineReady.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineReady',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protocolMajor',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'certificatePem', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineReady clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineReady copyWith(void Function(EngineReady) updates) =>
      super.copyWith((message) => updates(message as EngineReady))
          as EngineReady;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineReady create() => EngineReady._();
  @$core.override
  EngineReady createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineReady getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineReady>(create);
  static EngineReady? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolMajor => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolMajor($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolMajor() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolMajor() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get certificatePem => $_getN(2);
  @$pb.TagNumber(3)
  set certificatePem($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCertificatePem() => $_has(2);
  @$pb.TagNumber(3)
  void clearCertificatePem() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
