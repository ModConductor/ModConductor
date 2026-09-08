// This is a generated file - do not edit.
//
// Generated from modconductor/v1/generated_outputs.proto.

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

import 'generated_outputs.pb.dart' as $0;

export 'generated_outputs.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.GeneratedOutputOperations')
class GeneratedOutputOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GeneratedOutputOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.OutputScopeReply> readOutputs(
    $0.ReadOutputsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readOutputs, request, options: options);
  }

  $grpc.ResponseFuture<$0.OutputLocationReply> addOutputLocation(
    $0.AddOutputLocationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addOutputLocation, request, options: options);
  }

  $grpc.ResponseFuture<$0.OutputLocationReply> stopUsingOutputLocation(
    $0.StopOutputLocationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopUsingOutputLocation, request,
        options: options);
  }

  $grpc.ResponseStream<$0.OutputLoadEvent> observeOutputs(
    $0.ObserveOutputsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$observeOutputs, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.OutputPageReply> readOutputPage(
    $0.OutputPageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readOutputPage, request, options: options);
  }

  $grpc.ResponseFuture<$0.OutputPromotionReply> previewOutputPromotion(
    $0.OutputPromotionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewOutputPromotion, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.OutputActionReply> applyOutputAction(
    $0.ApplyOutputActionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyOutputAction, request, options: options);
  }

  $grpc.ResponseFuture<$0.OutputActionReply> readOutputAction(
    $0.OutputActionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readOutputAction, request, options: options);
  }

  $grpc.ResponseFuture<$0.OutputActionReply> resumeOutputAction(
    $0.OutputActionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resumeOutputAction, request, options: options);
  }

  // method descriptors

  static final _$readOutputs =
      $grpc.ClientMethod<$0.ReadOutputsRequest, $0.OutputScopeReply>(
          '/modconductor.v1.GeneratedOutputOperations/ReadOutputs',
          ($0.ReadOutputsRequest value) => value.writeToBuffer(),
          $0.OutputScopeReply.fromBuffer);
  static final _$addOutputLocation =
      $grpc.ClientMethod<$0.AddOutputLocationRequest, $0.OutputLocationReply>(
          '/modconductor.v1.GeneratedOutputOperations/AddOutputLocation',
          ($0.AddOutputLocationRequest value) => value.writeToBuffer(),
          $0.OutputLocationReply.fromBuffer);
  static final _$stopUsingOutputLocation =
      $grpc.ClientMethod<$0.StopOutputLocationRequest, $0.OutputLocationReply>(
          '/modconductor.v1.GeneratedOutputOperations/StopUsingOutputLocation',
          ($0.StopOutputLocationRequest value) => value.writeToBuffer(),
          $0.OutputLocationReply.fromBuffer);
  static final _$observeOutputs =
      $grpc.ClientMethod<$0.ObserveOutputsRequest, $0.OutputLoadEvent>(
          '/modconductor.v1.GeneratedOutputOperations/ObserveOutputs',
          ($0.ObserveOutputsRequest value) => value.writeToBuffer(),
          $0.OutputLoadEvent.fromBuffer);
  static final _$readOutputPage =
      $grpc.ClientMethod<$0.OutputPageRequest, $0.OutputPageReply>(
          '/modconductor.v1.GeneratedOutputOperations/ReadOutputPage',
          ($0.OutputPageRequest value) => value.writeToBuffer(),
          $0.OutputPageReply.fromBuffer);
  static final _$previewOutputPromotion =
      $grpc.ClientMethod<$0.OutputPromotionRequest, $0.OutputPromotionReply>(
          '/modconductor.v1.GeneratedOutputOperations/PreviewOutputPromotion',
          ($0.OutputPromotionRequest value) => value.writeToBuffer(),
          $0.OutputPromotionReply.fromBuffer);
  static final _$applyOutputAction =
      $grpc.ClientMethod<$0.ApplyOutputActionRequest, $0.OutputActionReply>(
          '/modconductor.v1.GeneratedOutputOperations/ApplyOutputAction',
          ($0.ApplyOutputActionRequest value) => value.writeToBuffer(),
          $0.OutputActionReply.fromBuffer);
  static final _$readOutputAction =
      $grpc.ClientMethod<$0.OutputActionRequest, $0.OutputActionReply>(
          '/modconductor.v1.GeneratedOutputOperations/ReadOutputAction',
          ($0.OutputActionRequest value) => value.writeToBuffer(),
          $0.OutputActionReply.fromBuffer);
  static final _$resumeOutputAction =
      $grpc.ClientMethod<$0.OutputActionRequest, $0.OutputActionReply>(
          '/modconductor.v1.GeneratedOutputOperations/ResumeOutputAction',
          ($0.OutputActionRequest value) => value.writeToBuffer(),
          $0.OutputActionReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.GeneratedOutputOperations')
abstract class GeneratedOutputOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.GeneratedOutputOperations';

  GeneratedOutputOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ReadOutputsRequest, $0.OutputScopeReply>(
        'ReadOutputs',
        readOutputs_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReadOutputsRequest.fromBuffer(value),
        ($0.OutputScopeReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddOutputLocationRequest,
            $0.OutputLocationReply>(
        'AddOutputLocation',
        addOutputLocation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AddOutputLocationRequest.fromBuffer(value),
        ($0.OutputLocationReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StopOutputLocationRequest,
            $0.OutputLocationReply>(
        'StopUsingOutputLocation',
        stopUsingOutputLocation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StopOutputLocationRequest.fromBuffer(value),
        ($0.OutputLocationReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ObserveOutputsRequest, $0.OutputLoadEvent>(
            'ObserveOutputs',
            observeOutputs_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ObserveOutputsRequest.fromBuffer(value),
            ($0.OutputLoadEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.OutputPageRequest, $0.OutputPageReply>(
        'ReadOutputPage',
        readOutputPage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.OutputPageRequest.fromBuffer(value),
        ($0.OutputPageReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.OutputPromotionRequest, $0.OutputPromotionReply>(
            'PreviewOutputPromotion',
            previewOutputPromotion_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.OutputPromotionRequest.fromBuffer(value),
            ($0.OutputPromotionReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ApplyOutputActionRequest, $0.OutputActionReply>(
            'ApplyOutputAction',
            applyOutputAction_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ApplyOutputActionRequest.fromBuffer(value),
            ($0.OutputActionReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.OutputActionRequest, $0.OutputActionReply>(
            'ReadOutputAction',
            readOutputAction_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.OutputActionRequest.fromBuffer(value),
            ($0.OutputActionReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.OutputActionRequest, $0.OutputActionReply>(
            'ResumeOutputAction',
            resumeOutputAction_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.OutputActionRequest.fromBuffer(value),
            ($0.OutputActionReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.OutputScopeReply> readOutputs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadOutputsRequest> $request) async {
    return readOutputs($call, await $request);
  }

  $async.Future<$0.OutputScopeReply> readOutputs(
      $grpc.ServiceCall call, $0.ReadOutputsRequest request);

  $async.Future<$0.OutputLocationReply> addOutputLocation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AddOutputLocationRequest> $request) async {
    return addOutputLocation($call, await $request);
  }

  $async.Future<$0.OutputLocationReply> addOutputLocation(
      $grpc.ServiceCall call, $0.AddOutputLocationRequest request);

  $async.Future<$0.OutputLocationReply> stopUsingOutputLocation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StopOutputLocationRequest> $request) async {
    return stopUsingOutputLocation($call, await $request);
  }

  $async.Future<$0.OutputLocationReply> stopUsingOutputLocation(
      $grpc.ServiceCall call, $0.StopOutputLocationRequest request);

  $async.Stream<$0.OutputLoadEvent> observeOutputs_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ObserveOutputsRequest> $request) async* {
    yield* observeOutputs($call, await $request);
  }

  $async.Stream<$0.OutputLoadEvent> observeOutputs(
      $grpc.ServiceCall call, $0.ObserveOutputsRequest request);

  $async.Future<$0.OutputPageReply> readOutputPage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OutputPageRequest> $request) async {
    return readOutputPage($call, await $request);
  }

  $async.Future<$0.OutputPageReply> readOutputPage(
      $grpc.ServiceCall call, $0.OutputPageRequest request);

  $async.Future<$0.OutputPromotionReply> previewOutputPromotion_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.OutputPromotionRequest> $request) async {
    return previewOutputPromotion($call, await $request);
  }

  $async.Future<$0.OutputPromotionReply> previewOutputPromotion(
      $grpc.ServiceCall call, $0.OutputPromotionRequest request);

  $async.Future<$0.OutputActionReply> applyOutputAction_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ApplyOutputActionRequest> $request) async {
    return applyOutputAction($call, await $request);
  }

  $async.Future<$0.OutputActionReply> applyOutputAction(
      $grpc.ServiceCall call, $0.ApplyOutputActionRequest request);

  $async.Future<$0.OutputActionReply> readOutputAction_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.OutputActionRequest> $request) async {
    return readOutputAction($call, await $request);
  }

  $async.Future<$0.OutputActionReply> readOutputAction(
      $grpc.ServiceCall call, $0.OutputActionRequest request);

  $async.Future<$0.OutputActionReply> resumeOutputAction_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.OutputActionRequest> $request) async {
    return resumeOutputAction($call, await $request);
  }

  $async.Future<$0.OutputActionReply> resumeOutputAction(
      $grpc.ServiceCall call, $0.OutputActionRequest request);
}
