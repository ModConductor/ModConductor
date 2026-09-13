// This is a generated file - do not edit.
//
// Generated from modconductor/v1/plugin_order.proto.

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

import 'plugin_order.pb.dart' as $0;

export 'plugin_order.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.PluginOrders')
class PluginOrdersClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  PluginOrdersClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.PluginOrderReply> readPluginOrder(
    $0.ReadPluginOrderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readPluginOrder, request, options: options);
  }

  $grpc.ResponseFuture<$0.PluginOrderReply> changePluginOrder(
    $0.ChangePluginOrderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changePluginOrder, request, options: options);
  }

  $grpc.ResponseFuture<$0.PluginOrderReply> useGamePluginOrder(
    $0.UseGamePluginOrderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$useGamePluginOrder, request, options: options);
  }

  // method descriptors

  static final _$readPluginOrder =
      $grpc.ClientMethod<$0.ReadPluginOrderRequest, $0.PluginOrderReply>(
          '/modconductor.v1.PluginOrders/ReadPluginOrder',
          ($0.ReadPluginOrderRequest value) => value.writeToBuffer(),
          $0.PluginOrderReply.fromBuffer);
  static final _$changePluginOrder =
      $grpc.ClientMethod<$0.ChangePluginOrderRequest, $0.PluginOrderReply>(
          '/modconductor.v1.PluginOrders/ChangePluginOrder',
          ($0.ChangePluginOrderRequest value) => value.writeToBuffer(),
          $0.PluginOrderReply.fromBuffer);
  static final _$useGamePluginOrder =
      $grpc.ClientMethod<$0.UseGamePluginOrderRequest, $0.PluginOrderReply>(
          '/modconductor.v1.PluginOrders/UseGamePluginOrder',
          ($0.UseGamePluginOrderRequest value) => value.writeToBuffer(),
          $0.PluginOrderReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.PluginOrders')
abstract class PluginOrdersServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.PluginOrders';

  PluginOrdersServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ReadPluginOrderRequest, $0.PluginOrderReply>(
            'ReadPluginOrder',
            readPluginOrder_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadPluginOrderRequest.fromBuffer(value),
            ($0.PluginOrderReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ChangePluginOrderRequest, $0.PluginOrderReply>(
            'ChangePluginOrder',
            changePluginOrder_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ChangePluginOrderRequest.fromBuffer(value),
            ($0.PluginOrderReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UseGamePluginOrderRequest, $0.PluginOrderReply>(
            'UseGamePluginOrder',
            useGamePluginOrder_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UseGamePluginOrderRequest.fromBuffer(value),
            ($0.PluginOrderReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.PluginOrderReply> readPluginOrder_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadPluginOrderRequest> $request) async {
    return readPluginOrder($call, await $request);
  }

  $async.Future<$0.PluginOrderReply> readPluginOrder(
      $grpc.ServiceCall call, $0.ReadPluginOrderRequest request);

  $async.Future<$0.PluginOrderReply> changePluginOrder_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangePluginOrderRequest> $request) async {
    return changePluginOrder($call, await $request);
  }

  $async.Future<$0.PluginOrderReply> changePluginOrder(
      $grpc.ServiceCall call, $0.ChangePluginOrderRequest request);

  $async.Future<$0.PluginOrderReply> useGamePluginOrder_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UseGamePluginOrderRequest> $request) async {
    return useGamePluginOrder($call, await $request);
  }

  $async.Future<$0.PluginOrderReply> useGamePluginOrder(
      $grpc.ServiceCall call, $0.UseGamePluginOrderRequest request);
}
