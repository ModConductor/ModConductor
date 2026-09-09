// This is a generated file - do not edit.
//
// Generated from modconductor/v1/executables.proto.

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

import 'executables.pb.dart' as $0;

export 'executables.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ExecutableOperations')
class ExecutableOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ExecutableOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ExecutablePresetPageReply> listExecutablePresets(
    $0.ExecutablePageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listExecutablePresets, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExecutablePresetReply> readExecutablePreset(
    $0.ExecutablePresetRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readExecutablePreset, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExecutablePresetReply> saveExecutablePreset(
    $0.ExecutablePreset request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveExecutablePreset, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExecutableMutationReply> deleteExecutablePreset(
    $0.DeleteExecutablePresetRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteExecutablePreset, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ExecutableRunReply> beginExecutableRun(
    $0.ExecutableRunRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$beginExecutableRun, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExecutableRunReply> readExecutableRun(
    $0.ExecutableRunRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readExecutableRun, request, options: options);
  }

  $grpc.ResponseStream<$0.ExecutableRunReply> observeExecutableRun(
    $0.ExecutableRunRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$observeExecutableRun, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ExecutableRunPageReply> readExecutableRuns(
    $0.ExecutablePageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readExecutableRuns, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExecutableRunReply> stopWaitingForExecutable(
    $0.ExecutableRunRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopWaitingForExecutable, request,
        options: options);
  }

  // method descriptors

  static final _$listExecutablePresets = $grpc.ClientMethod<
          $0.ExecutablePageRequest, $0.ExecutablePresetPageReply>(
      '/modconductor.v1.ExecutableOperations/ListExecutablePresets',
      ($0.ExecutablePageRequest value) => value.writeToBuffer(),
      $0.ExecutablePresetPageReply.fromBuffer);
  static final _$readExecutablePreset =
      $grpc.ClientMethod<$0.ExecutablePresetRef, $0.ExecutablePresetReply>(
          '/modconductor.v1.ExecutableOperations/ReadExecutablePreset',
          ($0.ExecutablePresetRef value) => value.writeToBuffer(),
          $0.ExecutablePresetReply.fromBuffer);
  static final _$saveExecutablePreset =
      $grpc.ClientMethod<$0.ExecutablePreset, $0.ExecutablePresetReply>(
          '/modconductor.v1.ExecutableOperations/SaveExecutablePreset',
          ($0.ExecutablePreset value) => value.writeToBuffer(),
          $0.ExecutablePresetReply.fromBuffer);
  static final _$deleteExecutablePreset = $grpc.ClientMethod<
          $0.DeleteExecutablePresetRequest, $0.ExecutableMutationReply>(
      '/modconductor.v1.ExecutableOperations/DeleteExecutablePreset',
      ($0.DeleteExecutablePresetRequest value) => value.writeToBuffer(),
      $0.ExecutableMutationReply.fromBuffer);
  static final _$beginExecutableRun =
      $grpc.ClientMethod<$0.ExecutableRunRequest, $0.ExecutableRunReply>(
          '/modconductor.v1.ExecutableOperations/BeginExecutableRun',
          ($0.ExecutableRunRequest value) => value.writeToBuffer(),
          $0.ExecutableRunReply.fromBuffer);
  static final _$readExecutableRun =
      $grpc.ClientMethod<$0.ExecutableRunRef, $0.ExecutableRunReply>(
          '/modconductor.v1.ExecutableOperations/ReadExecutableRun',
          ($0.ExecutableRunRef value) => value.writeToBuffer(),
          $0.ExecutableRunReply.fromBuffer);
  static final _$observeExecutableRun =
      $grpc.ClientMethod<$0.ExecutableRunRef, $0.ExecutableRunReply>(
          '/modconductor.v1.ExecutableOperations/ObserveExecutableRun',
          ($0.ExecutableRunRef value) => value.writeToBuffer(),
          $0.ExecutableRunReply.fromBuffer);
  static final _$readExecutableRuns =
      $grpc.ClientMethod<$0.ExecutablePageRequest, $0.ExecutableRunPageReply>(
          '/modconductor.v1.ExecutableOperations/ReadExecutableRuns',
          ($0.ExecutablePageRequest value) => value.writeToBuffer(),
          $0.ExecutableRunPageReply.fromBuffer);
  static final _$stopWaitingForExecutable =
      $grpc.ClientMethod<$0.ExecutableRunRef, $0.ExecutableRunReply>(
          '/modconductor.v1.ExecutableOperations/StopWaitingForExecutable',
          ($0.ExecutableRunRef value) => value.writeToBuffer(),
          $0.ExecutableRunReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ExecutableOperations')
abstract class ExecutableOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ExecutableOperations';

  ExecutableOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ExecutablePageRequest,
            $0.ExecutablePresetPageReply>(
        'ListExecutablePresets',
        listExecutablePresets_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExecutablePageRequest.fromBuffer(value),
        ($0.ExecutablePresetPageReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExecutablePresetRef, $0.ExecutablePresetReply>(
            'ReadExecutablePreset',
            readExecutablePreset_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ExecutablePresetRef.fromBuffer(value),
            ($0.ExecutablePresetReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExecutablePreset, $0.ExecutablePresetReply>(
            'SaveExecutablePreset',
            saveExecutablePreset_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ExecutablePreset.fromBuffer(value),
            ($0.ExecutablePresetReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteExecutablePresetRequest,
            $0.ExecutableMutationReply>(
        'DeleteExecutablePreset',
        deleteExecutablePreset_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteExecutablePresetRequest.fromBuffer(value),
        ($0.ExecutableMutationReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExecutableRunRequest, $0.ExecutableRunReply>(
            'BeginExecutableRun',
            beginExecutableRun_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ExecutableRunRequest.fromBuffer(value),
            ($0.ExecutableRunReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecutableRunRef, $0.ExecutableRunReply>(
        'ReadExecutableRun',
        readExecutableRun_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExecutableRunRef.fromBuffer(value),
        ($0.ExecutableRunReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecutableRunRef, $0.ExecutableRunReply>(
        'ObserveExecutableRun',
        observeExecutableRun_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ExecutableRunRef.fromBuffer(value),
        ($0.ExecutableRunReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecutablePageRequest,
            $0.ExecutableRunPageReply>(
        'ReadExecutableRuns',
        readExecutableRuns_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExecutablePageRequest.fromBuffer(value),
        ($0.ExecutableRunPageReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecutableRunRef, $0.ExecutableRunReply>(
        'StopWaitingForExecutable',
        stopWaitingForExecutable_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExecutableRunRef.fromBuffer(value),
        ($0.ExecutableRunReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.ExecutablePresetPageReply> listExecutablePresets_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutablePageRequest> $request) async {
    return listExecutablePresets($call, await $request);
  }

  $async.Future<$0.ExecutablePresetPageReply> listExecutablePresets(
      $grpc.ServiceCall call, $0.ExecutablePageRequest request);

  $async.Future<$0.ExecutablePresetReply> readExecutablePreset_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutablePresetRef> $request) async {
    return readExecutablePreset($call, await $request);
  }

  $async.Future<$0.ExecutablePresetReply> readExecutablePreset(
      $grpc.ServiceCall call, $0.ExecutablePresetRef request);

  $async.Future<$0.ExecutablePresetReply> saveExecutablePreset_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutablePreset> $request) async {
    return saveExecutablePreset($call, await $request);
  }

  $async.Future<$0.ExecutablePresetReply> saveExecutablePreset(
      $grpc.ServiceCall call, $0.ExecutablePreset request);

  $async.Future<$0.ExecutableMutationReply> deleteExecutablePreset_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteExecutablePresetRequest> $request) async {
    return deleteExecutablePreset($call, await $request);
  }

  $async.Future<$0.ExecutableMutationReply> deleteExecutablePreset(
      $grpc.ServiceCall call, $0.DeleteExecutablePresetRequest request);

  $async.Future<$0.ExecutableRunReply> beginExecutableRun_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutableRunRequest> $request) async {
    return beginExecutableRun($call, await $request);
  }

  $async.Future<$0.ExecutableRunReply> beginExecutableRun(
      $grpc.ServiceCall call, $0.ExecutableRunRequest request);

  $async.Future<$0.ExecutableRunReply> readExecutableRun_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutableRunRef> $request) async {
    return readExecutableRun($call, await $request);
  }

  $async.Future<$0.ExecutableRunReply> readExecutableRun(
      $grpc.ServiceCall call, $0.ExecutableRunRef request);

  $async.Stream<$0.ExecutableRunReply> observeExecutableRun_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutableRunRef> $request) async* {
    yield* observeExecutableRun($call, await $request);
  }

  $async.Stream<$0.ExecutableRunReply> observeExecutableRun(
      $grpc.ServiceCall call, $0.ExecutableRunRef request);

  $async.Future<$0.ExecutableRunPageReply> readExecutableRuns_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutablePageRequest> $request) async {
    return readExecutableRuns($call, await $request);
  }

  $async.Future<$0.ExecutableRunPageReply> readExecutableRuns(
      $grpc.ServiceCall call, $0.ExecutablePageRequest request);

  $async.Future<$0.ExecutableRunReply> stopWaitingForExecutable_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecutableRunRef> $request) async {
    return stopWaitingForExecutable($call, await $request);
  }

  $async.Future<$0.ExecutableRunReply> stopWaitingForExecutable(
      $grpc.ServiceCall call, $0.ExecutableRunRef request);
}
