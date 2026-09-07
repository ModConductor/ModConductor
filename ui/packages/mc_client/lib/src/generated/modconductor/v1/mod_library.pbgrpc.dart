// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_library.proto.

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

import 'mod_library.pb.dart' as $0;

export 'mod_library.pb.dart';

/// Workspace-owned directory inventory. No archive, deployment or game-folder actions.
@$pb.GrpcServiceName('modconductor.v1.ModLibraryOperations')
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
          '/modconductor.v1.ModLibraryOperations/RegisterMod',
          ($0.RegisterModRequest value) => value.writeToBuffer(),
          $0.ModReply.fromBuffer);
  static final _$editMod = $grpc.ClientMethod<$0.EditModRequest, $0.ModReply>(
      '/modconductor.v1.ModLibraryOperations/EditMod',
      ($0.EditModRequest value) => value.writeToBuffer(),
      $0.ModReply.fromBuffer);
  static final _$scanInventory =
      $grpc.ClientMethod<$0.ScanInventoryRequest, $0.InventoryScanReply>(
          '/modconductor.v1.ModLibraryOperations/ScanInventory',
          ($0.ScanInventoryRequest value) => value.writeToBuffer(),
          $0.InventoryScanReply.fromBuffer);
  static final _$publishMod =
      $grpc.ClientMethod<$0.PublishModRequest, $0.ModReply>(
          '/modconductor.v1.ModLibraryOperations/PublishMod',
          ($0.PublishModRequest value) => value.writeToBuffer(),
          $0.ModReply.fromBuffer);
  static final _$readPublication =
      $grpc.ClientMethod<$0.PublicationRequest, $0.PublicationReply>(
          '/modconductor.v1.ModLibraryOperations/ReadPublication',
          ($0.PublicationRequest value) => value.writeToBuffer(),
          $0.PublicationReply.fromBuffer);
  static final _$cancelPublication =
      $grpc.ClientMethod<$0.PublicationRequest, $0.PublicationReply>(
          '/modconductor.v1.ModLibraryOperations/CancelPublication',
          ($0.PublicationRequest value) => value.writeToBuffer(),
          $0.PublicationReply.fromBuffer);
  static final _$readModVersion =
      $grpc.ClientMethod<$0.ReadModVersionRequest, $0.ModVersionReply>(
          '/modconductor.v1.ModLibraryOperations/ReadModVersion',
          ($0.ReadModVersionRequest value) => value.writeToBuffer(),
          $0.ModVersionReply.fromBuffer);
  static final _$readModPayload =
      $grpc.ClientMethod<$0.ReadModPayloadRequest, $0.ModPayloadReply>(
          '/modconductor.v1.ModLibraryOperations/ReadModPayload',
          ($0.ReadModPayloadRequest value) => value.writeToBuffer(),
          $0.ModPayloadReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ModLibraryOperations')
abstract class ModLibraryOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ModLibraryOperations';

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
