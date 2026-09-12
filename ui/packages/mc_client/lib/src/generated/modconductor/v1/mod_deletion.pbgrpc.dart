// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_deletion.proto.

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

import 'mod_deletion.pb.dart' as $0;

export 'mod_deletion.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ModDeletion')
class ModDeletionClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ModDeletionClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ModDeletionPreview> prepareModDeletion(
    $0.PrepareModDeletionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$prepareModDeletion, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModDeletionPreviewClosed> closeModDeletionPreview(
    $0.ModDeletionReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeModDeletionPreview, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ModDeletionStatus> startModDeletion(
    $0.StartModDeletionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startModDeletion, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModDeletionStatus> continueModDeletion(
    $0.ModDeletionReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$continueModDeletion, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModDeletionList> recentModDeletions(
    $0.ModDeletionWorkspace request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$recentModDeletions, request, options: options);
  }

  $grpc.ResponseStream<$0.ModDeletionStatus> watchModDeletion(
    $0.ModDeletionReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchModDeletion, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$prepareModDeletion =
      $grpc.ClientMethod<$0.PrepareModDeletionRequest, $0.ModDeletionPreview>(
          '/modconductor.v1.ModDeletion/PrepareModDeletion',
          ($0.PrepareModDeletionRequest value) => value.writeToBuffer(),
          $0.ModDeletionPreview.fromBuffer);
  static final _$closeModDeletionPreview =
      $grpc.ClientMethod<$0.ModDeletionReference, $0.ModDeletionPreviewClosed>(
          '/modconductor.v1.ModDeletion/CloseModDeletionPreview',
          ($0.ModDeletionReference value) => value.writeToBuffer(),
          $0.ModDeletionPreviewClosed.fromBuffer);
  static final _$startModDeletion =
      $grpc.ClientMethod<$0.StartModDeletionRequest, $0.ModDeletionStatus>(
          '/modconductor.v1.ModDeletion/StartModDeletion',
          ($0.StartModDeletionRequest value) => value.writeToBuffer(),
          $0.ModDeletionStatus.fromBuffer);
  static final _$continueModDeletion =
      $grpc.ClientMethod<$0.ModDeletionReference, $0.ModDeletionStatus>(
          '/modconductor.v1.ModDeletion/ContinueModDeletion',
          ($0.ModDeletionReference value) => value.writeToBuffer(),
          $0.ModDeletionStatus.fromBuffer);
  static final _$recentModDeletions =
      $grpc.ClientMethod<$0.ModDeletionWorkspace, $0.ModDeletionList>(
          '/modconductor.v1.ModDeletion/RecentModDeletions',
          ($0.ModDeletionWorkspace value) => value.writeToBuffer(),
          $0.ModDeletionList.fromBuffer);
  static final _$watchModDeletion =
      $grpc.ClientMethod<$0.ModDeletionReference, $0.ModDeletionStatus>(
          '/modconductor.v1.ModDeletion/WatchModDeletion',
          ($0.ModDeletionReference value) => value.writeToBuffer(),
          $0.ModDeletionStatus.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ModDeletion')
abstract class ModDeletionServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ModDeletion';

  ModDeletionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PrepareModDeletionRequest,
            $0.ModDeletionPreview>(
        'PrepareModDeletion',
        prepareModDeletion_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PrepareModDeletionRequest.fromBuffer(value),
        ($0.ModDeletionPreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ModDeletionReference,
            $0.ModDeletionPreviewClosed>(
        'CloseModDeletionPreview',
        closeModDeletionPreview_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ModDeletionReference.fromBuffer(value),
        ($0.ModDeletionPreviewClosed value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StartModDeletionRequest, $0.ModDeletionStatus>(
            'StartModDeletion',
            startModDeletion_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StartModDeletionRequest.fromBuffer(value),
            ($0.ModDeletionStatus value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ModDeletionReference, $0.ModDeletionStatus>(
            'ContinueModDeletion',
            continueModDeletion_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ModDeletionReference.fromBuffer(value),
            ($0.ModDeletionStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ModDeletionWorkspace, $0.ModDeletionList>(
        'RecentModDeletions',
        recentModDeletions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ModDeletionWorkspace.fromBuffer(value),
        ($0.ModDeletionList value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ModDeletionReference, $0.ModDeletionStatus>(
            'WatchModDeletion',
            watchModDeletion_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ModDeletionReference.fromBuffer(value),
            ($0.ModDeletionStatus value) => value.writeToBuffer()));
  }

  $async.Future<$0.ModDeletionPreview> prepareModDeletion_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PrepareModDeletionRequest> $request) async {
    return prepareModDeletion($call, await $request);
  }

  $async.Future<$0.ModDeletionPreview> prepareModDeletion(
      $grpc.ServiceCall call, $0.PrepareModDeletionRequest request);

  $async.Future<$0.ModDeletionPreviewClosed> closeModDeletionPreview_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ModDeletionReference> $request) async {
    return closeModDeletionPreview($call, await $request);
  }

  $async.Future<$0.ModDeletionPreviewClosed> closeModDeletionPreview(
      $grpc.ServiceCall call, $0.ModDeletionReference request);

  $async.Future<$0.ModDeletionStatus> startModDeletion_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartModDeletionRequest> $request) async {
    return startModDeletion($call, await $request);
  }

  $async.Future<$0.ModDeletionStatus> startModDeletion(
      $grpc.ServiceCall call, $0.StartModDeletionRequest request);

  $async.Future<$0.ModDeletionStatus> continueModDeletion_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ModDeletionReference> $request) async {
    return continueModDeletion($call, await $request);
  }

  $async.Future<$0.ModDeletionStatus> continueModDeletion(
      $grpc.ServiceCall call, $0.ModDeletionReference request);

  $async.Future<$0.ModDeletionList> recentModDeletions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ModDeletionWorkspace> $request) async {
    return recentModDeletions($call, await $request);
  }

  $async.Future<$0.ModDeletionList> recentModDeletions(
      $grpc.ServiceCall call, $0.ModDeletionWorkspace request);

  $async.Stream<$0.ModDeletionStatus> watchModDeletion_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ModDeletionReference> $request) async* {
    yield* watchModDeletion($call, await $request);
  }

  $async.Stream<$0.ModDeletionStatus> watchModDeletion(
      $grpc.ServiceCall call, $0.ModDeletionReference request);
}
