// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skyrim_setup.proto.

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

import 'skyrim_setup.pb.dart' as $0;

export 'skyrim_setup.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.SkyrimSetupOperations')
class SkyrimSetupOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SkyrimSetupOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SkyrimSetupState> readSkyrimSetup(
    $0.ReadSkyrimSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readSkyrimSetup, request, options: options);
  }

  $grpc.ResponseStream<$0.SkyrimSetupState> watchSkyrimSetup(
    $0.ReadSkyrimSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchSkyrimSetup, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.SkyrimSetupState> startSkyrimSetup(
    $0.StartSkyrimSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startSkyrimSetup, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkyrimSetupState> continueSkyrimSetup(
    $0.SkyrimSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$continueSkyrimSetup, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkyrimSetupState> cancelSkyrimSetup(
    $0.SkyrimSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelSkyrimSetup, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkyrimSetupPageReply> openSkyrimSetupPage(
    $0.SkyrimSetupPageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openSkyrimSetupPage, request, options: options);
  }

  // method descriptors

  static final _$readSkyrimSetup =
      $grpc.ClientMethod<$0.ReadSkyrimSetupRequest, $0.SkyrimSetupState>(
          '/modconductor.v1.SkyrimSetupOperations/ReadSkyrimSetup',
          ($0.ReadSkyrimSetupRequest value) => value.writeToBuffer(),
          $0.SkyrimSetupState.fromBuffer);
  static final _$watchSkyrimSetup =
      $grpc.ClientMethod<$0.ReadSkyrimSetupRequest, $0.SkyrimSetupState>(
          '/modconductor.v1.SkyrimSetupOperations/WatchSkyrimSetup',
          ($0.ReadSkyrimSetupRequest value) => value.writeToBuffer(),
          $0.SkyrimSetupState.fromBuffer);
  static final _$startSkyrimSetup =
      $grpc.ClientMethod<$0.StartSkyrimSetupRequest, $0.SkyrimSetupState>(
          '/modconductor.v1.SkyrimSetupOperations/StartSkyrimSetup',
          ($0.StartSkyrimSetupRequest value) => value.writeToBuffer(),
          $0.SkyrimSetupState.fromBuffer);
  static final _$continueSkyrimSetup =
      $grpc.ClientMethod<$0.SkyrimSetupRequest, $0.SkyrimSetupState>(
          '/modconductor.v1.SkyrimSetupOperations/ContinueSkyrimSetup',
          ($0.SkyrimSetupRequest value) => value.writeToBuffer(),
          $0.SkyrimSetupState.fromBuffer);
  static final _$cancelSkyrimSetup =
      $grpc.ClientMethod<$0.SkyrimSetupRequest, $0.SkyrimSetupState>(
          '/modconductor.v1.SkyrimSetupOperations/CancelSkyrimSetup',
          ($0.SkyrimSetupRequest value) => value.writeToBuffer(),
          $0.SkyrimSetupState.fromBuffer);
  static final _$openSkyrimSetupPage =
      $grpc.ClientMethod<$0.SkyrimSetupPageRequest, $0.SkyrimSetupPageReply>(
          '/modconductor.v1.SkyrimSetupOperations/OpenSkyrimSetupPage',
          ($0.SkyrimSetupPageRequest value) => value.writeToBuffer(),
          $0.SkyrimSetupPageReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.SkyrimSetupOperations')
abstract class SkyrimSetupOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.SkyrimSetupOperations';

  SkyrimSetupOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ReadSkyrimSetupRequest, $0.SkyrimSetupState>(
            'ReadSkyrimSetup',
            readSkyrimSetup_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadSkyrimSetupRequest.fromBuffer(value),
            ($0.SkyrimSetupState value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadSkyrimSetupRequest, $0.SkyrimSetupState>(
            'WatchSkyrimSetup',
            watchSkyrimSetup_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ReadSkyrimSetupRequest.fromBuffer(value),
            ($0.SkyrimSetupState value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StartSkyrimSetupRequest, $0.SkyrimSetupState>(
            'StartSkyrimSetup',
            startSkyrimSetup_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StartSkyrimSetupRequest.fromBuffer(value),
            ($0.SkyrimSetupState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SkyrimSetupRequest, $0.SkyrimSetupState>(
        'ContinueSkyrimSetup',
        continueSkyrimSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SkyrimSetupRequest.fromBuffer(value),
        ($0.SkyrimSetupState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SkyrimSetupRequest, $0.SkyrimSetupState>(
        'CancelSkyrimSetup',
        cancelSkyrimSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SkyrimSetupRequest.fromBuffer(value),
        ($0.SkyrimSetupState value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SkyrimSetupPageRequest, $0.SkyrimSetupPageReply>(
            'OpenSkyrimSetupPage',
            openSkyrimSetupPage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SkyrimSetupPageRequest.fromBuffer(value),
            ($0.SkyrimSetupPageReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.SkyrimSetupState> readSkyrimSetup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadSkyrimSetupRequest> $request) async {
    return readSkyrimSetup($call, await $request);
  }

  $async.Future<$0.SkyrimSetupState> readSkyrimSetup(
      $grpc.ServiceCall call, $0.ReadSkyrimSetupRequest request);

  $async.Stream<$0.SkyrimSetupState> watchSkyrimSetup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadSkyrimSetupRequest> $request) async* {
    yield* watchSkyrimSetup($call, await $request);
  }

  $async.Stream<$0.SkyrimSetupState> watchSkyrimSetup(
      $grpc.ServiceCall call, $0.ReadSkyrimSetupRequest request);

  $async.Future<$0.SkyrimSetupState> startSkyrimSetup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartSkyrimSetupRequest> $request) async {
    return startSkyrimSetup($call, await $request);
  }

  $async.Future<$0.SkyrimSetupState> startSkyrimSetup(
      $grpc.ServiceCall call, $0.StartSkyrimSetupRequest request);

  $async.Future<$0.SkyrimSetupState> continueSkyrimSetup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SkyrimSetupRequest> $request) async {
    return continueSkyrimSetup($call, await $request);
  }

  $async.Future<$0.SkyrimSetupState> continueSkyrimSetup(
      $grpc.ServiceCall call, $0.SkyrimSetupRequest request);

  $async.Future<$0.SkyrimSetupState> cancelSkyrimSetup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SkyrimSetupRequest> $request) async {
    return cancelSkyrimSetup($call, await $request);
  }

  $async.Future<$0.SkyrimSetupState> cancelSkyrimSetup(
      $grpc.ServiceCall call, $0.SkyrimSetupRequest request);

  $async.Future<$0.SkyrimSetupPageReply> openSkyrimSetupPage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SkyrimSetupPageRequest> $request) async {
    return openSkyrimSetupPage($call, await $request);
  }

  $async.Future<$0.SkyrimSetupPageReply> openSkyrimSetupPage(
      $grpc.ServiceCall call, $0.SkyrimSetupPageRequest request);
}
