// This is a generated file - do not edit.
//
// Generated from modconductor/v1/workspaces.proto.

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

import 'workspaces.pb.dart' as $0;

export 'workspaces.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.WorkspaceOperations')
class WorkspaceOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  WorkspaceOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.WorkspaceReply> createWorkspace(
    $0.CreateWorkspaceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createWorkspace, request, options: options);
  }

  $grpc.ResponseFuture<$0.WorkspaceReply> openWorkspace(
    $0.OpenWorkspaceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openWorkspace, request, options: options);
  }

  $grpc.ResponseFuture<$0.WorkspaceReply> readWorkspace(
    $0.ReadWorkspaceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readWorkspace, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileReply> editProfile(
    $0.EditProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$editProfile, request, options: options);
  }

  $grpc.ResponseStream<$0.ProfileEditEvent> editProfileWithProgress(
    $0.EditProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$editProfileWithProgress, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.ProfileEditEvent> resumeProfileEdit(
    $0.ResumeProfileEditRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$resumeProfileEdit, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.WorkspaceReply> checkWorkspace(
    $0.CheckWorkspaceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkWorkspace, request, options: options);
  }

  $grpc.ResponseFuture<$0.RecentWorkspacesReply> recentWorkspaces(
    $0.RecentWorkspacesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$recentWorkspaces, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileImageReply> readProfileImage(
    $0.ReadProfileImageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readProfileImage, request, options: options);
  }

  $grpc.ResponseFuture<$0.ProfileImageUpdateReply> setProfileImage(
    $0.SetProfileImageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setProfileImage, request, options: options);
  }

  // method descriptors

  static final _$createWorkspace =
      $grpc.ClientMethod<$0.CreateWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v1.WorkspaceOperations/CreateWorkspace',
          ($0.CreateWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$openWorkspace =
      $grpc.ClientMethod<$0.OpenWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v1.WorkspaceOperations/OpenWorkspace',
          ($0.OpenWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$readWorkspace =
      $grpc.ClientMethod<$0.ReadWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v1.WorkspaceOperations/ReadWorkspace',
          ($0.ReadWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$editProfile =
      $grpc.ClientMethod<$0.EditProfileRequest, $0.ProfileReply>(
          '/modconductor.v1.WorkspaceOperations/EditProfile',
          ($0.EditProfileRequest value) => value.writeToBuffer(),
          $0.ProfileReply.fromBuffer);
  static final _$editProfileWithProgress =
      $grpc.ClientMethod<$0.EditProfileRequest, $0.ProfileEditEvent>(
          '/modconductor.v1.WorkspaceOperations/EditProfileWithProgress',
          ($0.EditProfileRequest value) => value.writeToBuffer(),
          $0.ProfileEditEvent.fromBuffer);
  static final _$resumeProfileEdit =
      $grpc.ClientMethod<$0.ResumeProfileEditRequest, $0.ProfileEditEvent>(
          '/modconductor.v1.WorkspaceOperations/ResumeProfileEdit',
          ($0.ResumeProfileEditRequest value) => value.writeToBuffer(),
          $0.ProfileEditEvent.fromBuffer);
  static final _$checkWorkspace =
      $grpc.ClientMethod<$0.CheckWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v1.WorkspaceOperations/CheckWorkspace',
          ($0.CheckWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$recentWorkspaces =
      $grpc.ClientMethod<$0.RecentWorkspacesRequest, $0.RecentWorkspacesReply>(
          '/modconductor.v1.WorkspaceOperations/RecentWorkspaces',
          ($0.RecentWorkspacesRequest value) => value.writeToBuffer(),
          $0.RecentWorkspacesReply.fromBuffer);
  static final _$readProfileImage =
      $grpc.ClientMethod<$0.ReadProfileImageRequest, $0.ProfileImageReply>(
          '/modconductor.v1.WorkspaceOperations/ReadProfileImage',
          ($0.ReadProfileImageRequest value) => value.writeToBuffer(),
          $0.ProfileImageReply.fromBuffer);
  static final _$setProfileImage =
      $grpc.ClientMethod<$0.SetProfileImageRequest, $0.ProfileImageUpdateReply>(
          '/modconductor.v1.WorkspaceOperations/SetProfileImage',
          ($0.SetProfileImageRequest value) => value.writeToBuffer(),
          $0.ProfileImageUpdateReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.WorkspaceOperations')
abstract class WorkspaceOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.WorkspaceOperations';

  WorkspaceOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.CreateWorkspaceRequest, $0.WorkspaceReply>(
            'CreateWorkspace',
            createWorkspace_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateWorkspaceRequest.fromBuffer(value),
            ($0.WorkspaceReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.OpenWorkspaceRequest, $0.WorkspaceReply>(
        'OpenWorkspace',
        openWorkspace_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.OpenWorkspaceRequest.fromBuffer(value),
        ($0.WorkspaceReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReadWorkspaceRequest, $0.WorkspaceReply>(
        'ReadWorkspace',
        readWorkspace_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReadWorkspaceRequest.fromBuffer(value),
        ($0.WorkspaceReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EditProfileRequest, $0.ProfileReply>(
        'EditProfile',
        editProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.EditProfileRequest.fromBuffer(value),
        ($0.ProfileReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EditProfileRequest, $0.ProfileEditEvent>(
        'EditProfileWithProgress',
        editProfileWithProgress_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.EditProfileRequest.fromBuffer(value),
        ($0.ProfileEditEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ResumeProfileEditRequest, $0.ProfileEditEvent>(
            'ResumeProfileEdit',
            resumeProfileEdit_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ResumeProfileEditRequest.fromBuffer(value),
            ($0.ProfileEditEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CheckWorkspaceRequest, $0.WorkspaceReply>(
        'CheckWorkspace',
        checkWorkspace_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CheckWorkspaceRequest.fromBuffer(value),
        ($0.WorkspaceReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RecentWorkspacesRequest,
            $0.RecentWorkspacesReply>(
        'RecentWorkspaces',
        recentWorkspaces_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RecentWorkspacesRequest.fromBuffer(value),
        ($0.RecentWorkspacesReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadProfileImageRequest, $0.ProfileImageReply>(
            'ReadProfileImage',
            readProfileImage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadProfileImageRequest.fromBuffer(value),
            ($0.ProfileImageReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetProfileImageRequest,
            $0.ProfileImageUpdateReply>(
        'SetProfileImage',
        setProfileImage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetProfileImageRequest.fromBuffer(value),
        ($0.ProfileImageUpdateReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.WorkspaceReply> createWorkspace_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateWorkspaceRequest> $request) async {
    return createWorkspace($call, await $request);
  }

  $async.Future<$0.WorkspaceReply> createWorkspace(
      $grpc.ServiceCall call, $0.CreateWorkspaceRequest request);

  $async.Future<$0.WorkspaceReply> openWorkspace_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OpenWorkspaceRequest> $request) async {
    return openWorkspace($call, await $request);
  }

  $async.Future<$0.WorkspaceReply> openWorkspace(
      $grpc.ServiceCall call, $0.OpenWorkspaceRequest request);

  $async.Future<$0.WorkspaceReply> readWorkspace_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadWorkspaceRequest> $request) async {
    return readWorkspace($call, await $request);
  }

  $async.Future<$0.WorkspaceReply> readWorkspace(
      $grpc.ServiceCall call, $0.ReadWorkspaceRequest request);

  $async.Future<$0.ProfileReply> editProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EditProfileRequest> $request) async {
    return editProfile($call, await $request);
  }

  $async.Future<$0.ProfileReply> editProfile(
      $grpc.ServiceCall call, $0.EditProfileRequest request);

  $async.Stream<$0.ProfileEditEvent> editProfileWithProgress_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.EditProfileRequest> $request) async* {
    yield* editProfileWithProgress($call, await $request);
  }

  $async.Stream<$0.ProfileEditEvent> editProfileWithProgress(
      $grpc.ServiceCall call, $0.EditProfileRequest request);

  $async.Stream<$0.ProfileEditEvent> resumeProfileEdit_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ResumeProfileEditRequest> $request) async* {
    yield* resumeProfileEdit($call, await $request);
  }

  $async.Stream<$0.ProfileEditEvent> resumeProfileEdit(
      $grpc.ServiceCall call, $0.ResumeProfileEditRequest request);

  $async.Future<$0.WorkspaceReply> checkWorkspace_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CheckWorkspaceRequest> $request) async {
    return checkWorkspace($call, await $request);
  }

  $async.Future<$0.WorkspaceReply> checkWorkspace(
      $grpc.ServiceCall call, $0.CheckWorkspaceRequest request);

  $async.Future<$0.RecentWorkspacesReply> recentWorkspaces_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RecentWorkspacesRequest> $request) async {
    return recentWorkspaces($call, await $request);
  }

  $async.Future<$0.RecentWorkspacesReply> recentWorkspaces(
      $grpc.ServiceCall call, $0.RecentWorkspacesRequest request);

  $async.Future<$0.ProfileImageReply> readProfileImage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadProfileImageRequest> $request) async {
    return readProfileImage($call, await $request);
  }

  $async.Future<$0.ProfileImageReply> readProfileImage(
      $grpc.ServiceCall call, $0.ReadProfileImageRequest request);

  $async.Future<$0.ProfileImageUpdateReply> setProfileImage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetProfileImageRequest> $request) async {
    return setProfileImage($call, await $request);
  }

  $async.Future<$0.ProfileImageUpdateReply> setProfileImage(
      $grpc.ServiceCall call, $0.SetProfileImageRequest request);
}
