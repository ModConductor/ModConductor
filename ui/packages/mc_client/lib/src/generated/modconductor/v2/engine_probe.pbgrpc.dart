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

@$pb.GrpcServiceName('modconductor.v2.WorkspaceOperations')
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

  // method descriptors

  static final _$createWorkspace =
      $grpc.ClientMethod<$0.CreateWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v2.WorkspaceOperations/CreateWorkspace',
          ($0.CreateWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$openWorkspace =
      $grpc.ClientMethod<$0.OpenWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v2.WorkspaceOperations/OpenWorkspace',
          ($0.OpenWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$readWorkspace =
      $grpc.ClientMethod<$0.ReadWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v2.WorkspaceOperations/ReadWorkspace',
          ($0.ReadWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$editProfile =
      $grpc.ClientMethod<$0.EditProfileRequest, $0.ProfileReply>(
          '/modconductor.v2.WorkspaceOperations/EditProfile',
          ($0.EditProfileRequest value) => value.writeToBuffer(),
          $0.ProfileReply.fromBuffer);
  static final _$checkWorkspace =
      $grpc.ClientMethod<$0.CheckWorkspaceRequest, $0.WorkspaceReply>(
          '/modconductor.v2.WorkspaceOperations/CheckWorkspace',
          ($0.CheckWorkspaceRequest value) => value.writeToBuffer(),
          $0.WorkspaceReply.fromBuffer);
  static final _$recentWorkspaces =
      $grpc.ClientMethod<$0.RecentWorkspacesRequest, $0.RecentWorkspacesReply>(
          '/modconductor.v2.WorkspaceOperations/RecentWorkspaces',
          ($0.RecentWorkspacesRequest value) => value.writeToBuffer(),
          $0.RecentWorkspacesReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v2.WorkspaceOperations')
abstract class WorkspaceOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v2.WorkspaceOperations';

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
}

/// Workspace-owned directory inventory. No archive, deployment or game-folder actions.
@$pb.GrpcServiceName('modconductor.v2.ModLibraryOperations')
class ModLibraryOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ModLibraryOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ModReply> registerMod(
    $0.RegisterModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$registerMod, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModReply> editMod(
    $0.EditModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$editMod, request, options: options);
  }

  $grpc.ResponseFuture<$0.InventoryReply> readInventory(
    $0.ReadInventoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readInventory, request, options: options);
  }

  $grpc.ResponseFuture<$0.InventoryScanReply> scanInventory(
    $0.ScanInventoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$scanInventory, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModReply> publishMod(
    $0.PublishModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$publishMod, request, options: options);
  }

  $grpc.ResponseFuture<$0.PublicationReply> readPublication(
    $0.PublicationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readPublication, request, options: options);
  }

  $grpc.ResponseFuture<$0.PublicationReply> cancelPublication(
    $0.PublicationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelPublication, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModVersionReply> readModVersion(
    $0.ReadModVersionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readModVersion, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModPayloadReply> readModPayload(
    $0.ReadModPayloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readModPayload, request, options: options);
  }

  // method descriptors

  static final _$registerMod =
      $grpc.ClientMethod<$0.RegisterModRequest, $0.ModReply>(
          '/modconductor.v2.ModLibraryOperations/RegisterMod',
          ($0.RegisterModRequest value) => value.writeToBuffer(),
          $0.ModReply.fromBuffer);
  static final _$editMod = $grpc.ClientMethod<$0.EditModRequest, $0.ModReply>(
      '/modconductor.v2.ModLibraryOperations/EditMod',
      ($0.EditModRequest value) => value.writeToBuffer(),
      $0.ModReply.fromBuffer);
  static final _$readInventory =
      $grpc.ClientMethod<$0.ReadInventoryRequest, $0.InventoryReply>(
          '/modconductor.v2.ModLibraryOperations/ReadInventory',
          ($0.ReadInventoryRequest value) => value.writeToBuffer(),
          $0.InventoryReply.fromBuffer);
  static final _$scanInventory =
      $grpc.ClientMethod<$0.ScanInventoryRequest, $0.InventoryScanReply>(
          '/modconductor.v2.ModLibraryOperations/ScanInventory',
          ($0.ScanInventoryRequest value) => value.writeToBuffer(),
          $0.InventoryScanReply.fromBuffer);
  static final _$publishMod =
      $grpc.ClientMethod<$0.PublishModRequest, $0.ModReply>(
          '/modconductor.v2.ModLibraryOperations/PublishMod',
          ($0.PublishModRequest value) => value.writeToBuffer(),
          $0.ModReply.fromBuffer);
  static final _$readPublication =
      $grpc.ClientMethod<$0.PublicationRequest, $0.PublicationReply>(
          '/modconductor.v2.ModLibraryOperations/ReadPublication',
          ($0.PublicationRequest value) => value.writeToBuffer(),
          $0.PublicationReply.fromBuffer);
  static final _$cancelPublication =
      $grpc.ClientMethod<$0.PublicationRequest, $0.PublicationReply>(
          '/modconductor.v2.ModLibraryOperations/CancelPublication',
          ($0.PublicationRequest value) => value.writeToBuffer(),
          $0.PublicationReply.fromBuffer);
  static final _$readModVersion =
      $grpc.ClientMethod<$0.ReadModVersionRequest, $0.ModVersionReply>(
          '/modconductor.v2.ModLibraryOperations/ReadModVersion',
          ($0.ReadModVersionRequest value) => value.writeToBuffer(),
          $0.ModVersionReply.fromBuffer);
  static final _$readModPayload =
      $grpc.ClientMethod<$0.ReadModPayloadRequest, $0.ModPayloadReply>(
          '/modconductor.v2.ModLibraryOperations/ReadModPayload',
          ($0.ReadModPayloadRequest value) => value.writeToBuffer(),
          $0.ModPayloadReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v2.ModLibraryOperations')
abstract class ModLibraryOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v2.ModLibraryOperations';

  ModLibraryOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.RegisterModRequest, $0.ModReply>(
        'RegisterMod',
        registerMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RegisterModRequest.fromBuffer(value),
        ($0.ModReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EditModRequest, $0.ModReply>(
        'EditMod',
        editMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EditModRequest.fromBuffer(value),
        ($0.ModReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReadInventoryRequest, $0.InventoryReply>(
        'ReadInventory',
        readInventory_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReadInventoryRequest.fromBuffer(value),
        ($0.InventoryReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ScanInventoryRequest, $0.InventoryScanReply>(
            'ScanInventory',
            scanInventory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ScanInventoryRequest.fromBuffer(value),
            ($0.InventoryScanReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PublishModRequest, $0.ModReply>(
        'PublishMod',
        publishMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PublishModRequest.fromBuffer(value),
        ($0.ModReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PublicationRequest, $0.PublicationReply>(
        'ReadPublication',
        readPublication_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PublicationRequest.fromBuffer(value),
        ($0.PublicationReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PublicationRequest, $0.PublicationReply>(
        'CancelPublication',
        cancelPublication_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PublicationRequest.fromBuffer(value),
        ($0.PublicationReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadModVersionRequest, $0.ModVersionReply>(
            'ReadModVersion',
            readModVersion_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadModVersionRequest.fromBuffer(value),
            ($0.ModVersionReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadModPayloadRequest, $0.ModPayloadReply>(
            'ReadModPayload',
            readModPayload_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadModPayloadRequest.fromBuffer(value),
            ($0.ModPayloadReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.ModReply> registerMod_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RegisterModRequest> $request) async {
    return registerMod($call, await $request);
  }

  $async.Future<$0.ModReply> registerMod(
      $grpc.ServiceCall call, $0.RegisterModRequest request);

  $async.Future<$0.ModReply> editMod_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EditModRequest> $request) async {
    return editMod($call, await $request);
  }

  $async.Future<$0.ModReply> editMod(
      $grpc.ServiceCall call, $0.EditModRequest request);

  $async.Future<$0.InventoryReply> readInventory_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadInventoryRequest> $request) async {
    return readInventory($call, await $request);
  }

  $async.Future<$0.InventoryReply> readInventory(
      $grpc.ServiceCall call, $0.ReadInventoryRequest request);

  $async.Future<$0.InventoryScanReply> scanInventory_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ScanInventoryRequest> $request) async {
    return scanInventory($call, await $request);
  }

  $async.Future<$0.InventoryScanReply> scanInventory(
      $grpc.ServiceCall call, $0.ScanInventoryRequest request);

  $async.Future<$0.ModReply> publishMod_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PublishModRequest> $request) async {
    return publishMod($call, await $request);
  }

  $async.Future<$0.ModReply> publishMod(
      $grpc.ServiceCall call, $0.PublishModRequest request);

  $async.Future<$0.PublicationReply> readPublication_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PublicationRequest> $request) async {
    return readPublication($call, await $request);
  }

  $async.Future<$0.PublicationReply> readPublication(
      $grpc.ServiceCall call, $0.PublicationRequest request);

  $async.Future<$0.PublicationReply> cancelPublication_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PublicationRequest> $request) async {
    return cancelPublication($call, await $request);
  }

  $async.Future<$0.PublicationReply> cancelPublication(
      $grpc.ServiceCall call, $0.PublicationRequest request);

  $async.Future<$0.ModVersionReply> readModVersion_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadModVersionRequest> $request) async {
    return readModVersion($call, await $request);
  }

  $async.Future<$0.ModVersionReply> readModVersion(
      $grpc.ServiceCall call, $0.ReadModVersionRequest request);

  $async.Future<$0.ModPayloadReply> readModPayload_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadModPayloadRequest> $request) async {
    return readModPayload($call, await $request);
  }

  $async.Future<$0.ModPayloadReply> readModPayload(
      $grpc.ServiceCall call, $0.ReadModPayloadRequest request);
}
