// This is a generated file - do not edit.
//
// Generated from modconductor/v2/engine_probe.proto.

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

/// Every RPC requires the capability from the private child bootstrap.
@$pb.GrpcServiceName('modconductor.v2.EngineOperations')
class EngineOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EngineOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.OperationBatch> getState(
    $0.StateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getState, request, options: options);
  }

  $grpc.ResponseFuture<$0.OperationSnapshot> beginRuntimeCheck(
    $0.RuntimeCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$beginRuntimeCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.OperationSnapshot> getOperation(
    $0.OperationIdentity request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getOperation, request, options: options);
  }

  $grpc.ResponseFuture<$0.OperationSnapshot> cancelOperation(
    $0.OperationIdentity request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelOperation, request, options: options);
  }

  $grpc.ResponseStream<$0.OperationBatch> watchOperations(
    $0.WatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchOperations, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getState =
      $grpc.ClientMethod<$0.StateRequest, $0.OperationBatch>(
          '/modconductor.v2.EngineOperations/GetState',
          ($0.StateRequest value) => value.writeToBuffer(),
          $0.OperationBatch.fromBuffer);
  static final _$beginRuntimeCheck =
      $grpc.ClientMethod<$0.RuntimeCheckRequest, $0.OperationSnapshot>(
          '/modconductor.v2.EngineOperations/BeginRuntimeCheck',
          ($0.RuntimeCheckRequest value) => value.writeToBuffer(),
          $0.OperationSnapshot.fromBuffer);
  static final _$getOperation =
      $grpc.ClientMethod<$0.OperationIdentity, $0.OperationSnapshot>(
          '/modconductor.v2.EngineOperations/GetOperation',
          ($0.OperationIdentity value) => value.writeToBuffer(),
          $0.OperationSnapshot.fromBuffer);
  static final _$cancelOperation =
      $grpc.ClientMethod<$0.OperationIdentity, $0.OperationSnapshot>(
          '/modconductor.v2.EngineOperations/CancelOperation',
          ($0.OperationIdentity value) => value.writeToBuffer(),
          $0.OperationSnapshot.fromBuffer);
  static final _$watchOperations =
      $grpc.ClientMethod<$0.WatchRequest, $0.OperationBatch>(
          '/modconductor.v2.EngineOperations/WatchOperations',
          ($0.WatchRequest value) => value.writeToBuffer(),
          $0.OperationBatch.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v2.EngineOperations')
abstract class EngineOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v2.EngineOperations';

  EngineOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StateRequest, $0.OperationBatch>(
        'GetState',
        getState_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StateRequest.fromBuffer(value),
        ($0.OperationBatch value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RuntimeCheckRequest, $0.OperationSnapshot>(
            'BeginRuntimeCheck',
            beginRuntimeCheck_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RuntimeCheckRequest.fromBuffer(value),
            ($0.OperationSnapshot value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.OperationIdentity, $0.OperationSnapshot>(
        'GetOperation',
        getOperation_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.OperationIdentity.fromBuffer(value),
        ($0.OperationSnapshot value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.OperationIdentity, $0.OperationSnapshot>(
        'CancelOperation',
        cancelOperation_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.OperationIdentity.fromBuffer(value),
        ($0.OperationSnapshot value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchRequest, $0.OperationBatch>(
        'WatchOperations',
        watchOperations_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchRequest.fromBuffer(value),
        ($0.OperationBatch value) => value.writeToBuffer()));
  }

  $async.Future<$0.OperationBatch> getState_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.StateRequest> $request) async {
    return getState($call, await $request);
  }

  $async.Future<$0.OperationBatch> getState(
      $grpc.ServiceCall call, $0.StateRequest request);

  $async.Future<$0.OperationSnapshot> beginRuntimeCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RuntimeCheckRequest> $request) async {
    return beginRuntimeCheck($call, await $request);
  }

  $async.Future<$0.OperationSnapshot> beginRuntimeCheck(
      $grpc.ServiceCall call, $0.RuntimeCheckRequest request);

  $async.Future<$0.OperationSnapshot> getOperation_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OperationIdentity> $request) async {
    return getOperation($call, await $request);
  }

  $async.Future<$0.OperationSnapshot> getOperation(
      $grpc.ServiceCall call, $0.OperationIdentity request);

  $async.Future<$0.OperationSnapshot> cancelOperation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.OperationIdentity> $request) async {
    return cancelOperation($call, await $request);
  }

  $async.Future<$0.OperationSnapshot> cancelOperation(
      $grpc.ServiceCall call, $0.OperationIdentity request);

  $async.Stream<$0.OperationBatch> watchOperations_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.WatchRequest> $request) async* {
    yield* watchOperations($call, await $request);
  }

  $async.Stream<$0.OperationBatch> watchOperations(
      $grpc.ServiceCall call, $0.WatchRequest request);
}
