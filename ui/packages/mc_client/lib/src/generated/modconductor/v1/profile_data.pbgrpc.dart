// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_data.proto.

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

import 'profile_data.pb.dart' as $0;

export 'profile_data.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ProfileDataOperations')
class ProfileDataOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProfileDataOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ProfileSaveReply> listProfileSaves(
    $0.ProfileSaveRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listProfileSaves, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileSaveGroupReply> listSaveGroups(
    $0.ProfileSaveGroupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSaveGroups, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileSaveInspectReply> inspectSave(
    $0.ProfileSaveInspectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectSave, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileSaveActionPreviewReply> previewSaveAction(
    $0.ProfileSaveActionPreviewRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewSaveAction, request, options: options);
  }

  $grpc.ResponseStream<$0.ProfileDataEvent> applySaveAction(
    $0.ProfileSaveActionApplyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$applySaveAction, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ProfileDataReply> readProfileData(
    $0.ProfileDataReadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readProfileData, request, options: options);
  }

  $grpc.ResponseStream<$0.ProfileDataEvent> editProfileData(
    $0.ProfileDataEditRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$editProfileData, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.ProfileDataEvent> restoreProfileData(
    $0.ProfileDataRestoreRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$restoreProfileData, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.ProfileDataEvent> resumeProfileData(
    $0.ProfileDataActionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$resumeProfileData, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$listProfileSaves =
      $grpc.ClientMethod<$0.ProfileSaveRequest, $0.ProfileSaveReply>(
          '/modconductor.v1.ProfileDataOperations/ListProfileSaves',
          ($0.ProfileSaveRequest value) => value.writeToBuffer(),
          $0.ProfileSaveReply.fromBuffer);
  static final _$listSaveGroups =
      $grpc.ClientMethod<$0.ProfileSaveGroupRequest, $0.ProfileSaveGroupReply>(
          '/modconductor.v1.ProfileDataOperations/ListSaveGroups',
          ($0.ProfileSaveGroupRequest value) => value.writeToBuffer(),
          $0.ProfileSaveGroupReply.fromBuffer);
  static final _$inspectSave = $grpc.ClientMethod<$0.ProfileSaveInspectRequest,
          $0.ProfileSaveInspectReply>(
      '/modconductor.v1.ProfileDataOperations/InspectSave',
      ($0.ProfileSaveInspectRequest value) => value.writeToBuffer(),
      $0.ProfileSaveInspectReply.fromBuffer);
  static final _$previewSaveAction = $grpc.ClientMethod<
          $0.ProfileSaveActionPreviewRequest, $0.ProfileSaveActionPreviewReply>(
      '/modconductor.v1.ProfileDataOperations/PreviewSaveAction',
      ($0.ProfileSaveActionPreviewRequest value) => value.writeToBuffer(),
      $0.ProfileSaveActionPreviewReply.fromBuffer);
  static final _$applySaveAction =
      $grpc.ClientMethod<$0.ProfileSaveActionApplyRequest, $0.ProfileDataEvent>(
          '/modconductor.v1.ProfileDataOperations/ApplySaveAction',
          ($0.ProfileSaveActionApplyRequest value) => value.writeToBuffer(),
          $0.ProfileDataEvent.fromBuffer);
  static final _$readProfileData =
      $grpc.ClientMethod<$0.ProfileDataReadRequest, $0.ProfileDataReply>(
          '/modconductor.v1.ProfileDataOperations/ReadProfileData',
          ($0.ProfileDataReadRequest value) => value.writeToBuffer(),
          $0.ProfileDataReply.fromBuffer);
  static final _$editProfileData =
      $grpc.ClientMethod<$0.ProfileDataEditRequest, $0.ProfileDataEvent>(
          '/modconductor.v1.ProfileDataOperations/EditProfileData',
          ($0.ProfileDataEditRequest value) => value.writeToBuffer(),
          $0.ProfileDataEvent.fromBuffer);
  static final _$restoreProfileData =
      $grpc.ClientMethod<$0.ProfileDataRestoreRequest, $0.ProfileDataEvent>(
          '/modconductor.v1.ProfileDataOperations/RestoreProfileData',
          ($0.ProfileDataRestoreRequest value) => value.writeToBuffer(),
          $0.ProfileDataEvent.fromBuffer);
  static final _$resumeProfileData =
      $grpc.ClientMethod<$0.ProfileDataActionRequest, $0.ProfileDataEvent>(
          '/modconductor.v1.ProfileDataOperations/ResumeProfileData',
          ($0.ProfileDataActionRequest value) => value.writeToBuffer(),
          $0.ProfileDataEvent.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ProfileDataOperations')
abstract class ProfileDataOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ProfileDataOperations';

  ProfileDataOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ProfileSaveRequest, $0.ProfileSaveReply>(
        'ListProfileSaves',
        listProfileSaves_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ProfileSaveRequest.fromBuffer(value),
        ($0.ProfileSaveReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProfileSaveGroupRequest,
            $0.ProfileSaveGroupReply>(
        'ListSaveGroups',
        listSaveGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ProfileSaveGroupRequest.fromBuffer(value),
        ($0.ProfileSaveGroupReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProfileSaveInspectRequest,
            $0.ProfileSaveInspectReply>(
        'InspectSave',
        inspectSave_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ProfileSaveInspectRequest.fromBuffer(value),
        ($0.ProfileSaveInspectReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProfileSaveActionPreviewRequest,
            $0.ProfileSaveActionPreviewReply>(
        'PreviewSaveAction',
        previewSaveAction_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ProfileSaveActionPreviewRequest.fromBuffer(value),
        ($0.ProfileSaveActionPreviewReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProfileSaveActionApplyRequest,
            $0.ProfileDataEvent>(
        'ApplySaveAction',
        applySaveAction_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.ProfileSaveActionApplyRequest.fromBuffer(value),
        ($0.ProfileDataEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ProfileDataReadRequest, $0.ProfileDataReply>(
            'ReadProfileData',
            readProfileData_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ProfileDataReadRequest.fromBuffer(value),
            ($0.ProfileDataReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ProfileDataEditRequest, $0.ProfileDataEvent>(
            'EditProfileData',
            editProfileData_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ProfileDataEditRequest.fromBuffer(value),
            ($0.ProfileDataEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ProfileDataRestoreRequest, $0.ProfileDataEvent>(
            'RestoreProfileData',
            restoreProfileData_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ProfileDataRestoreRequest.fromBuffer(value),
            ($0.ProfileDataEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ProfileDataActionRequest, $0.ProfileDataEvent>(
            'ResumeProfileData',
            resumeProfileData_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ProfileDataActionRequest.fromBuffer(value),
            ($0.ProfileDataEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.ProfileSaveReply> listProfileSaves_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileSaveRequest> $request) async {
    return listProfileSaves($call, await $request);
  }

  $async.Future<$0.ProfileSaveReply> listProfileSaves(
      $grpc.ServiceCall call, $0.ProfileSaveRequest request);

  $async.Future<$0.ProfileSaveGroupReply> listSaveGroups_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileSaveGroupRequest> $request) async {
    return listSaveGroups($call, await $request);
  }

  $async.Future<$0.ProfileSaveGroupReply> listSaveGroups(
      $grpc.ServiceCall call, $0.ProfileSaveGroupRequest request);

  $async.Future<$0.ProfileSaveInspectReply> inspectSave_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileSaveInspectRequest> $request) async {
    return inspectSave($call, await $request);
  }

  $async.Future<$0.ProfileSaveInspectReply> inspectSave(
      $grpc.ServiceCall call, $0.ProfileSaveInspectRequest request);

  $async.Future<$0.ProfileSaveActionPreviewReply> previewSaveAction_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileSaveActionPreviewRequest> $request) async {
    return previewSaveAction($call, await $request);
  }

  $async.Future<$0.ProfileSaveActionPreviewReply> previewSaveAction(
      $grpc.ServiceCall call, $0.ProfileSaveActionPreviewRequest request);

  $async.Stream<$0.ProfileDataEvent> applySaveAction_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileSaveActionApplyRequest> $request) async* {
    yield* applySaveAction($call, await $request);
  }

  $async.Stream<$0.ProfileDataEvent> applySaveAction(
      $grpc.ServiceCall call, $0.ProfileSaveActionApplyRequest request);

  $async.Future<$0.ProfileDataReply> readProfileData_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileDataReadRequest> $request) async {
    return readProfileData($call, await $request);
  }

  $async.Future<$0.ProfileDataReply> readProfileData(
      $grpc.ServiceCall call, $0.ProfileDataReadRequest request);

  $async.Stream<$0.ProfileDataEvent> editProfileData_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileDataEditRequest> $request) async* {
    yield* editProfileData($call, await $request);
  }

  $async.Stream<$0.ProfileDataEvent> editProfileData(
      $grpc.ServiceCall call, $0.ProfileDataEditRequest request);

  $async.Stream<$0.ProfileDataEvent> restoreProfileData_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileDataRestoreRequest> $request) async* {
    yield* restoreProfileData($call, await $request);
  }

  $async.Stream<$0.ProfileDataEvent> restoreProfileData(
      $grpc.ServiceCall call, $0.ProfileDataRestoreRequest request);

  $async.Stream<$0.ProfileDataEvent> resumeProfileData_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ProfileDataActionRequest> $request) async* {
    yield* resumeProfileData($call, await $request);
  }

  $async.Stream<$0.ProfileDataEvent> resumeProfileData(
      $grpc.ServiceCall call, $0.ProfileDataActionRequest request);
}
