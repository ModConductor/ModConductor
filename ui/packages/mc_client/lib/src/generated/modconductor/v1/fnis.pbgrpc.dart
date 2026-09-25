// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fnis.proto.

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

import 'fnis.pb.dart' as $0;

export 'fnis.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.FnisOperations')
class FnisOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  FnisOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.FnisState> readFnis(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readFnis, request, options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> installFnis(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$installFnis, request, options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> cancelFnis(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelFnis, request, options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> updateFnis(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateFnis, request, options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> removeFnis(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeFnis, request, options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> recoverFnis(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$recoverFnis, request, options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> runFnis(
    $0.FnisRunRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$runFnis, request, options: options);
  }

  $grpc.ResponseStream<$0.FnisState> observeFnisRun(
    $0.FnisRunRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$observeFnisRun, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.FnisState> cancelFnisRun(
    $0.FnisRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelFnisRun, request, options: options);
  }

  // method descriptors

  static final _$readFnis = $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/ReadFnis',
      ($0.FnisRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$installFnis = $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/InstallFnis',
      ($0.FnisRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$cancelFnis = $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/CancelFnis',
      ($0.FnisRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$updateFnis = $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/UpdateFnis',
      ($0.FnisRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$removeFnis = $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/RemoveFnis',
      ($0.FnisRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$recoverFnis = $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/RecoverFnis',
      ($0.FnisRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$runFnis = $grpc.ClientMethod<$0.FnisRunRequest, $0.FnisState>(
      '/modconductor.v1.FnisOperations/RunFnis',
      ($0.FnisRunRequest value) => value.writeToBuffer(),
      $0.FnisState.fromBuffer);
  static final _$observeFnisRun =
      $grpc.ClientMethod<$0.FnisRunRequest, $0.FnisState>(
          '/modconductor.v1.FnisOperations/ObserveFnisRun',
          ($0.FnisRunRequest value) => value.writeToBuffer(),
          $0.FnisState.fromBuffer);
  static final _$cancelFnisRun =
      $grpc.ClientMethod<$0.FnisRequest, $0.FnisState>(
          '/modconductor.v1.FnisOperations/CancelFnisRun',
          ($0.FnisRequest value) => value.writeToBuffer(),
          $0.FnisState.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.FnisOperations')
abstract class FnisOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.FnisOperations';

  FnisOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'ReadFnis',
        readFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'InstallFnis',
        installFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'CancelFnis',
        cancelFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'UpdateFnis',
        updateFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'RemoveFnis',
        removeFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'RecoverFnis',
        recoverFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRunRequest, $0.FnisState>(
        'RunFnis',
        runFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRunRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRunRequest, $0.FnisState>(
        'ObserveFnisRun',
        observeFnisRun_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.FnisRunRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FnisRequest, $0.FnisState>(
        'CancelFnisRun',
        cancelFnisRun_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FnisRequest.fromBuffer(value),
        ($0.FnisState value) => value.writeToBuffer()));
  }

  $async.Future<$0.FnisState> readFnis_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return readFnis($call, await $request);
  }

  $async.Future<$0.FnisState> readFnis(
      $grpc.ServiceCall call, $0.FnisRequest request);

  $async.Future<$0.FnisState> installFnis_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return installFnis($call, await $request);
  }

  $async.Future<$0.FnisState> installFnis(
      $grpc.ServiceCall call, $0.FnisRequest request);

  $async.Future<$0.FnisState> cancelFnis_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return cancelFnis($call, await $request);
  }

  $async.Future<$0.FnisState> cancelFnis(
      $grpc.ServiceCall call, $0.FnisRequest request);

  $async.Future<$0.FnisState> updateFnis_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return updateFnis($call, await $request);
  }

  $async.Future<$0.FnisState> updateFnis(
      $grpc.ServiceCall call, $0.FnisRequest request);

  $async.Future<$0.FnisState> removeFnis_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return removeFnis($call, await $request);
  }

  $async.Future<$0.FnisState> removeFnis(
      $grpc.ServiceCall call, $0.FnisRequest request);

  $async.Future<$0.FnisState> recoverFnis_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return recoverFnis($call, await $request);
  }

  $async.Future<$0.FnisState> recoverFnis(
      $grpc.ServiceCall call, $0.FnisRequest request);

  $async.Future<$0.FnisState> runFnis_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FnisRunRequest> $request) async {
    return runFnis($call, await $request);
  }

  $async.Future<$0.FnisState> runFnis(
      $grpc.ServiceCall call, $0.FnisRunRequest request);

  $async.Stream<$0.FnisState> observeFnisRun_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FnisRunRequest> $request) async* {
    yield* observeFnisRun($call, await $request);
  }

  $async.Stream<$0.FnisState> observeFnisRun(
      $grpc.ServiceCall call, $0.FnisRunRequest request);

  $async.Future<$0.FnisState> cancelFnisRun_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FnisRequest> $request) async {
    return cancelFnisRun($call, await $request);
  }

  $async.Future<$0.FnisState> cancelFnisRun(
      $grpc.ServiceCall call, $0.FnisRequest request);
}
