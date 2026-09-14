// This is a generated file - do not edit.
//
// Generated from modconductor/v1/loot_sort.proto.

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

import 'loot_sort.pb.dart' as $0;
import 'plugin_order.pb.dart' as $1;

export 'loot_sort.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.LootSorting')
class LootSortingClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LootSortingClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.LootStateReply> readLootState(
    $0.ReadLootStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readLootState, request, options: options);
  }

  $grpc.ResponseFuture<$0.LootStateReply> previewLootSort(
    $0.PreviewLootSortRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewLootSort, request, options: options);
  }

  $grpc.ResponseFuture<$1.PluginOrderReply> applyLootSort(
    $0.ApplyLootSortRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyLootSort, request, options: options);
  }

  $grpc.ResponseFuture<$0.LootStateReply> dismissLootSort(
    $0.DismissLootSortRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$dismissLootSort, request, options: options);
  }

  $grpc.ResponseFuture<$0.LootStateReply> refreshLootMetadata(
    $0.RefreshLootMetadataRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshLootMetadata, request, options: options);
  }

  // method descriptors

  static final _$readLootState =
      $grpc.ClientMethod<$0.ReadLootStateRequest, $0.LootStateReply>(
          '/modconductor.v1.LootSorting/ReadLootState',
          ($0.ReadLootStateRequest value) => value.writeToBuffer(),
          $0.LootStateReply.fromBuffer);
  static final _$previewLootSort =
      $grpc.ClientMethod<$0.PreviewLootSortRequest, $0.LootStateReply>(
          '/modconductor.v1.LootSorting/PreviewLootSort',
          ($0.PreviewLootSortRequest value) => value.writeToBuffer(),
          $0.LootStateReply.fromBuffer);
  static final _$applyLootSort =
      $grpc.ClientMethod<$0.ApplyLootSortRequest, $1.PluginOrderReply>(
          '/modconductor.v1.LootSorting/ApplyLootSort',
          ($0.ApplyLootSortRequest value) => value.writeToBuffer(),
          $1.PluginOrderReply.fromBuffer);
  static final _$dismissLootSort =
      $grpc.ClientMethod<$0.DismissLootSortRequest, $0.LootStateReply>(
          '/modconductor.v1.LootSorting/DismissLootSort',
          ($0.DismissLootSortRequest value) => value.writeToBuffer(),
          $0.LootStateReply.fromBuffer);
  static final _$refreshLootMetadata =
      $grpc.ClientMethod<$0.RefreshLootMetadataRequest, $0.LootStateReply>(
          '/modconductor.v1.LootSorting/RefreshLootMetadata',
          ($0.RefreshLootMetadataRequest value) => value.writeToBuffer(),
          $0.LootStateReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.LootSorting')
abstract class LootSortingServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.LootSorting';

  LootSortingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ReadLootStateRequest, $0.LootStateReply>(
        'ReadLootState',
        readLootState_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReadLootStateRequest.fromBuffer(value),
        ($0.LootStateReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PreviewLootSortRequest, $0.LootStateReply>(
            'PreviewLootSort',
            previewLootSort_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PreviewLootSortRequest.fromBuffer(value),
            ($0.LootStateReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ApplyLootSortRequest, $1.PluginOrderReply>(
            'ApplyLootSort',
            applyLootSort_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ApplyLootSortRequest.fromBuffer(value),
            ($1.PluginOrderReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DismissLootSortRequest, $0.LootStateReply>(
            'DismissLootSort',
            dismissLootSort_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DismissLootSortRequest.fromBuffer(value),
            ($0.LootStateReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RefreshLootMetadataRequest, $0.LootStateReply>(
            'RefreshLootMetadata',
            refreshLootMetadata_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RefreshLootMetadataRequest.fromBuffer(value),
            ($0.LootStateReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.LootStateReply> readLootState_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadLootStateRequest> $request) async {
    return readLootState($call, await $request);
  }

  $async.Future<$0.LootStateReply> readLootState(
      $grpc.ServiceCall call, $0.ReadLootStateRequest request);

  $async.Future<$0.LootStateReply> previewLootSort_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PreviewLootSortRequest> $request) async {
    return previewLootSort($call, await $request);
  }

  $async.Future<$0.LootStateReply> previewLootSort(
      $grpc.ServiceCall call, $0.PreviewLootSortRequest request);

  $async.Future<$1.PluginOrderReply> applyLootSort_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ApplyLootSortRequest> $request) async {
    return applyLootSort($call, await $request);
  }

  $async.Future<$1.PluginOrderReply> applyLootSort(
      $grpc.ServiceCall call, $0.ApplyLootSortRequest request);

  $async.Future<$0.LootStateReply> dismissLootSort_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DismissLootSortRequest> $request) async {
    return dismissLootSort($call, await $request);
  }

  $async.Future<$0.LootStateReply> dismissLootSort(
      $grpc.ServiceCall call, $0.DismissLootSortRequest request);

  $async.Future<$0.LootStateReply> refreshLootMetadata_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshLootMetadataRequest> $request) async {
    return refreshLootMetadata($call, await $request);
  }

  $async.Future<$0.LootStateReply> refreshLootMetadata(
      $grpc.ServiceCall call, $0.RefreshLootMetadataRequest request);
}
