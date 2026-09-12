// This is a generated file - do not edit.
//
// Generated from modconductor/v1/download_models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'download_models.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'download_models.pbenum.dart';

class ArchiveDownload extends $pb.GeneratedMessage {
  factory ArchiveDownload({
    DownloadPhase? phase,
    $fixnum.Int64? bytes,
    $fixnum.Int64? total,
    $core.String? source,
    $core.String? expectedSha256,
    $core.bool? checksumMatched,
    $core.bool? restartRequired,
    $fixnum.Int64? retryAtUnixMs,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (bytes != null) result.bytes = bytes;
    if (total != null) result.total = total;
    if (source != null) result.source = source;
    if (expectedSha256 != null) result.expectedSha256 = expectedSha256;
    if (checksumMatched != null) result.checksumMatched = checksumMatched;
    if (restartRequired != null) result.restartRequired = restartRequired;
    if (retryAtUnixMs != null) result.retryAtUnixMs = retryAtUnixMs;
    return result;
  }

  ArchiveDownload._();

  factory ArchiveDownload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchiveDownload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchiveDownload',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<DownloadPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: DownloadPhase.values)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'source')
    ..aOS(5, _omitFieldNames ? '' : 'expectedSha256')
    ..aOB(6, _omitFieldNames ? '' : 'checksumMatched')
    ..aOB(7, _omitFieldNames ? '' : 'restartRequired')
    ..aInt64(8, _omitFieldNames ? '' : 'retryAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveDownload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveDownload copyWith(void Function(ArchiveDownload) updates) =>
      super.copyWith((message) => updates(message as ArchiveDownload))
          as ArchiveDownload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchiveDownload create() => ArchiveDownload._();
  @$core.override
  ArchiveDownload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchiveDownload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchiveDownload>(create);
  static ArchiveDownload? _defaultInstance;

  @$pb.TagNumber(1)
  DownloadPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(DownloadPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get source => $_getSZ(3);
  @$pb.TagNumber(4)
  set source($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get expectedSha256 => $_getSZ(4);
  @$pb.TagNumber(5)
  set expectedSha256($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpectedSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpectedSha256() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get checksumMatched => $_getBF(5);
  @$pb.TagNumber(6)
  set checksumMatched($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChecksumMatched() => $_has(5);
  @$pb.TagNumber(6)
  void clearChecksumMatched() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get restartRequired => $_getBF(6);
  @$pb.TagNumber(7)
  set restartRequired($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRestartRequired() => $_has(6);
  @$pb.TagNumber(7)
  void clearRestartRequired() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get retryAtUnixMs => $_getI64(7);
  @$pb.TagNumber(8)
  set retryAtUnixMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRetryAtUnixMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearRetryAtUnixMs() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
