// This is a generated file - do not edit.
//
// Generated from modconductor/v1/deployments.proto.

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

import 'deployments.pb.dart' as $0;

export 'deployments.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.DeploymentOperations')
class DeploymentOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DeploymentOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.DeploymentStateReply> readDeployment(
    $0.ReadDeploymentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readDeployment, request, options: options);
  }

  $grpc.ResponseFuture<$0.SavedDeploymentsReply> readSavedDeployments(
    $0.SavedDeploymentsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readSavedDeployments, request, options: options);
  }

  $grpc.ResponseStream<$0.DeploymentPrepareEvent> prepareDeployment(
    $0.PrepareDeploymentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$prepareDeployment, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.DeploymentRunEvent> activateDeployment(
    $0.ActivateDeploymentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$activateDeployment, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.DeploymentRunEvent> recoverDeployment(
    $0.RecoverDeploymentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$recoverDeployment, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.DeploymentReceiptReply> readDeploymentReceipt(
    $0.DeploymentReceiptRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readDeploymentReceipt, request, options: options);
  }

  // method descriptors

  static final _$readDeployment =
      $grpc.ClientMethod<$0.ReadDeploymentRequest, $0.DeploymentStateReply>(
          '/modconductor.v1.DeploymentOperations/ReadDeployment',
          ($0.ReadDeploymentRequest value) => value.writeToBuffer(),
          $0.DeploymentStateReply.fromBuffer);
  static final _$readSavedDeployments =
      $grpc.ClientMethod<$0.SavedDeploymentsRequest, $0.SavedDeploymentsReply>(
          '/modconductor.v1.DeploymentOperations/ReadSavedDeployments',
          ($0.SavedDeploymentsRequest value) => value.writeToBuffer(),
          $0.SavedDeploymentsReply.fromBuffer);
  static final _$prepareDeployment = $grpc.ClientMethod<
          $0.PrepareDeploymentRequest, $0.DeploymentPrepareEvent>(
      '/modconductor.v1.DeploymentOperations/PrepareDeployment',
      ($0.PrepareDeploymentRequest value) => value.writeToBuffer(),
      $0.DeploymentPrepareEvent.fromBuffer);
  static final _$activateDeployment =
      $grpc.ClientMethod<$0.ActivateDeploymentRequest, $0.DeploymentRunEvent>(
          '/modconductor.v1.DeploymentOperations/ActivateDeployment',
          ($0.ActivateDeploymentRequest value) => value.writeToBuffer(),
          $0.DeploymentRunEvent.fromBuffer);
  static final _$recoverDeployment =
      $grpc.ClientMethod<$0.RecoverDeploymentRequest, $0.DeploymentRunEvent>(
          '/modconductor.v1.DeploymentOperations/RecoverDeployment',
          ($0.RecoverDeploymentRequest value) => value.writeToBuffer(),
          $0.DeploymentRunEvent.fromBuffer);
  static final _$readDeploymentReceipt = $grpc.ClientMethod<
          $0.DeploymentReceiptRequest, $0.DeploymentReceiptReply>(
      '/modconductor.v1.DeploymentOperations/ReadDeploymentReceipt',
      ($0.DeploymentReceiptRequest value) => value.writeToBuffer(),
      $0.DeploymentReceiptReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.DeploymentOperations')
abstract class DeploymentOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.DeploymentOperations';

  DeploymentOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ReadDeploymentRequest, $0.DeploymentStateReply>(
            'ReadDeployment',
            readDeployment_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadDeploymentRequest.fromBuffer(value),
            ($0.DeploymentStateReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SavedDeploymentsRequest,
            $0.SavedDeploymentsReply>(
        'ReadSavedDeployments',
        readSavedDeployments_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SavedDeploymentsRequest.fromBuffer(value),
        ($0.SavedDeploymentsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PrepareDeploymentRequest,
            $0.DeploymentPrepareEvent>(
        'PrepareDeployment',
        prepareDeployment_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.PrepareDeploymentRequest.fromBuffer(value),
        ($0.DeploymentPrepareEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ActivateDeploymentRequest,
            $0.DeploymentRunEvent>(
        'ActivateDeployment',
        activateDeployment_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.ActivateDeploymentRequest.fromBuffer(value),
        ($0.DeploymentRunEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RecoverDeploymentRequest, $0.DeploymentRunEvent>(
            'RecoverDeployment',
            recoverDeployment_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.RecoverDeploymentRequest.fromBuffer(value),
            ($0.DeploymentRunEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeploymentReceiptRequest,
            $0.DeploymentReceiptReply>(
        'ReadDeploymentReceipt',
        readDeploymentReceipt_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeploymentReceiptRequest.fromBuffer(value),
        ($0.DeploymentReceiptReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.DeploymentStateReply> readDeployment_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadDeploymentRequest> $request) async {
    return readDeployment($call, await $request);
  }

  $async.Future<$0.DeploymentStateReply> readDeployment(
      $grpc.ServiceCall call, $0.ReadDeploymentRequest request);

  $async.Future<$0.SavedDeploymentsReply> readSavedDeployments_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SavedDeploymentsRequest> $request) async {
    return readSavedDeployments($call, await $request);
  }

  $async.Future<$0.SavedDeploymentsReply> readSavedDeployments(
      $grpc.ServiceCall call, $0.SavedDeploymentsRequest request);

  $async.Stream<$0.DeploymentPrepareEvent> prepareDeployment_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PrepareDeploymentRequest> $request) async* {
    yield* prepareDeployment($call, await $request);
  }

  $async.Stream<$0.DeploymentPrepareEvent> prepareDeployment(
      $grpc.ServiceCall call, $0.PrepareDeploymentRequest request);

  $async.Stream<$0.DeploymentRunEvent> activateDeployment_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ActivateDeploymentRequest> $request) async* {
    yield* activateDeployment($call, await $request);
  }

  $async.Stream<$0.DeploymentRunEvent> activateDeployment(
      $grpc.ServiceCall call, $0.ActivateDeploymentRequest request);

  $async.Stream<$0.DeploymentRunEvent> recoverDeployment_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RecoverDeploymentRequest> $request) async* {
    yield* recoverDeployment($call, await $request);
  }

  $async.Stream<$0.DeploymentRunEvent> recoverDeployment(
      $grpc.ServiceCall call, $0.RecoverDeploymentRequest request);

  $async.Future<$0.DeploymentReceiptReply> readDeploymentReceipt_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeploymentReceiptRequest> $request) async {
    return readDeploymentReceipt($call, await $request);
  }

  $async.Future<$0.DeploymentReceiptReply> readDeploymentReceipt(
      $grpc.ServiceCall call, $0.DeploymentReceiptRequest request);
}
