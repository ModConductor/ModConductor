// This is a generated file - do not edit.
//
// Generated from modconductor/v1/downloads.proto.

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

import 'artifacts.pb.dart' as $1;
import 'downloads.pb.dart' as $0;

export 'downloads.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ArtifactDownloads')
class ArtifactDownloadsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ArtifactDownloadsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.ArchiveArtifact> startDownload(
    $0.DownloadStartRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startDownload, request, options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveArtifact> controlDownload(
    $0.DownloadControlRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$controlDownload, request, options: options);
  }

  $grpc.ResponseStream<$1.ArchiveArtifact> watchDownloads(
    $0.DownloadWatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchDownloads, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$startDownload =
      $grpc.ClientMethod<$0.DownloadStartRequest, $1.ArchiveArtifact>(
          '/modconductor.v1.ArtifactDownloads/StartDownload',
          ($0.DownloadStartRequest value) => value.writeToBuffer(),
          $1.ArchiveArtifact.fromBuffer);
  static final _$controlDownload =
      $grpc.ClientMethod<$0.DownloadControlRequest, $1.ArchiveArtifact>(
          '/modconductor.v1.ArtifactDownloads/ControlDownload',
          ($0.DownloadControlRequest value) => value.writeToBuffer(),
          $1.ArchiveArtifact.fromBuffer);
  static final _$watchDownloads =
      $grpc.ClientMethod<$0.DownloadWatchRequest, $1.ArchiveArtifact>(
          '/modconductor.v1.ArtifactDownloads/WatchDownloads',
          ($0.DownloadWatchRequest value) => value.writeToBuffer(),
          $1.ArchiveArtifact.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ArtifactDownloads')
abstract class ArtifactDownloadsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ArtifactDownloads';

  ArtifactDownloadsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.DownloadStartRequest, $1.ArchiveArtifact>(
        'StartDownload',
        startDownload_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DownloadStartRequest.fromBuffer(value),
        ($1.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DownloadControlRequest, $1.ArchiveArtifact>(
            'ControlDownload',
            controlDownload_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DownloadControlRequest.fromBuffer(value),
            ($1.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadWatchRequest, $1.ArchiveArtifact>(
        'WatchDownloads',
        watchDownloads_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.DownloadWatchRequest.fromBuffer(value),
        ($1.ArchiveArtifact value) => value.writeToBuffer()));
  }

  $async.Future<$1.ArchiveArtifact> startDownload_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadStartRequest> $request) async {
    return startDownload($call, await $request);
  }

  $async.Future<$1.ArchiveArtifact> startDownload(
      $grpc.ServiceCall call, $0.DownloadStartRequest request);

  $async.Future<$1.ArchiveArtifact> controlDownload_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadControlRequest> $request) async {
    return controlDownload($call, await $request);
  }

  $async.Future<$1.ArchiveArtifact> controlDownload(
      $grpc.ServiceCall call, $0.DownloadControlRequest request);

  $async.Stream<$1.ArchiveArtifact> watchDownloads_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadWatchRequest> $request) async* {
    yield* watchDownloads($call, await $request);
  }

  $async.Stream<$1.ArchiveArtifact> watchDownloads(
      $grpc.ServiceCall call, $0.DownloadWatchRequest request);
}
