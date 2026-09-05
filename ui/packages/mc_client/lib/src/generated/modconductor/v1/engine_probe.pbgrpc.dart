// This is a generated file - do not edit.
//
// Generated from modconductor/v1/engine_probe.proto.

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

import 'engine_probe.pb.dart' as $0;

export 'engine_probe.pb.dart';

/// All methods require the capability from the private child bootstrap.
@$pb.GrpcServiceName('modconductor.v1.EngineProbe')
class EngineProbeClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EngineProbeClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.RuntimeInfo> inspectRuntime(
    $0.InspectRuntimeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectRuntime, request, options: options);
  }

  $grpc.ResponseStream<$0.Heartbeat> watchHeartbeat(
    $0.HeartbeatRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchHeartbeat, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$inspectRuntime =
      $grpc.ClientMethod<$0.InspectRuntimeRequest, $0.RuntimeInfo>(
          '/modconductor.v1.EngineProbe/InspectRuntime',
          ($0.InspectRuntimeRequest value) => value.writeToBuffer(),
          $0.RuntimeInfo.fromBuffer);
  static final _$watchHeartbeat =
      $grpc.ClientMethod<$0.HeartbeatRequest, $0.Heartbeat>(
          '/modconductor.v1.EngineProbe/WatchHeartbeat',
          ($0.HeartbeatRequest value) => value.writeToBuffer(),
          $0.Heartbeat.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.EngineProbe')
abstract class EngineProbeServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.EngineProbe';

  EngineProbeServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.InspectRuntimeRequest, $0.RuntimeInfo>(
        'InspectRuntime',
        inspectRuntime_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InspectRuntimeRequest.fromBuffer(value),
        ($0.RuntimeInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HeartbeatRequest, $0.Heartbeat>(
        'WatchHeartbeat',
        watchHeartbeat_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.HeartbeatRequest.fromBuffer(value),
        ($0.Heartbeat value) => value.writeToBuffer()));
  }

  $async.Future<$0.RuntimeInfo> inspectRuntime_Pre($grpc.ServiceCall $call,
      $async.Future<$0.InspectRuntimeRequest> $request) async {
    return inspectRuntime($call, await $request);
  }

  $async.Future<$0.RuntimeInfo> inspectRuntime(
      $grpc.ServiceCall call, $0.InspectRuntimeRequest request);

  $async.Stream<$0.Heartbeat> watchHeartbeat_Pre($grpc.ServiceCall $call,
      $async.Future<$0.HeartbeatRequest> $request) async* {
    yield* watchHeartbeat($call, await $request);
  }

  $async.Stream<$0.Heartbeat> watchHeartbeat(
      $grpc.ServiceCall call, $0.HeartbeatRequest request);
}
