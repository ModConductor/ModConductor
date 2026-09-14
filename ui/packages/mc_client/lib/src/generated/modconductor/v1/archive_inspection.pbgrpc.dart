// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_inspection.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_inspection.pb.dart' as $1;
import 'artifacts.pb.dart' as $0;
import 'file_plans.pb.dart' as $2;

export 'archive_inspection.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ArchiveInspection')
class ArchiveInspectionClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ArchiveInspectionClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.InspectedArchive> inspectArchive(
    $0.ArtifactReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectArchive, request, options: options);
  }

  $grpc.ResponseFuture<$2.FilePreviewReply> previewArchiveEntry(
    $1.PreviewArchiveEntryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewArchiveEntry, request, options: options);
  }

  // method descriptors

  static final _$inspectArchive =
      $grpc.ClientMethod<$0.ArtifactReference, $1.InspectedArchive>(
          '/modconductor.v1.ArchiveInspection/InspectArchive',
          ($0.ArtifactReference value) => value.writeToBuffer(),
          $1.InspectedArchive.fromBuffer);
  static final _$previewArchiveEntry =
      $grpc.ClientMethod<$1.PreviewArchiveEntryRequest, $2.FilePreviewReply>(
          '/modconductor.v1.ArchiveInspection/PreviewArchiveEntry',
          ($1.PreviewArchiveEntryRequest value) => value.writeToBuffer(),
          $2.FilePreviewReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ArchiveInspection')
abstract class ArchiveInspectionServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ArchiveInspection';

  ArchiveInspectionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ArtifactReference, $1.InspectedArchive>(
        'InspectArchive',
        inspectArchive_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ArtifactReference.fromBuffer(value),
        ($1.InspectedArchive value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.PreviewArchiveEntryRequest, $2.FilePreviewReply>(
            'PreviewArchiveEntry',
            previewArchiveEntry_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.PreviewArchiveEntryRequest.fromBuffer(value),
            ($2.FilePreviewReply value) => value.writeToBuffer()));
  }

  $async.Future<$1.InspectedArchive> inspectArchive_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReference> $request) async {
    return inspectArchive($call, await $request);
  }

  $async.Future<$1.InspectedArchive> inspectArchive(
      $grpc.ServiceCall call, $0.ArtifactReference request);

  $async.Future<$2.FilePreviewReply> previewArchiveEntry_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.PreviewArchiveEntryRequest> $request) async {
    return previewArchiveEntry($call, await $request);
  }

  $async.Future<$2.FilePreviewReply> previewArchiveEntry(
      $grpc.ServiceCall call, $1.PreviewArchiveEntryRequest request);
}
