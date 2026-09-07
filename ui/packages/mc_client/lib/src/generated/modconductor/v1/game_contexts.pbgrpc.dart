// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_contexts.proto.

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

import 'game_contexts.pb.dart' as $0;

export 'game_contexts.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.GameContextOperations')
class GameContextOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GameContextOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GameContextReply> readGameContext(
    $0.ReadGameContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readGameContext, request, options: options);
  }

  $grpc.ResponseFuture<$0.GameContextReply> saveGameContext(
    $0.SaveGameContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveGameContext, request, options: options);
  }

  $grpc.ResponseFuture<$0.GameContextReply> refreshGameContext(
    $0.RefreshGameContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshGameContext, request, options: options);
  }

  // method descriptors

  static final _$readGameContext =
      $grpc.ClientMethod<$0.ReadGameContextRequest, $0.GameContextReply>(
          '/modconductor.v1.GameContextOperations/ReadGameContext',
          ($0.ReadGameContextRequest value) => value.writeToBuffer(),
          $0.GameContextReply.fromBuffer);
  static final _$saveGameContext =
      $grpc.ClientMethod<$0.SaveGameContextRequest, $0.GameContextReply>(
          '/modconductor.v1.GameContextOperations/SaveGameContext',
          ($0.SaveGameContextRequest value) => value.writeToBuffer(),
          $0.GameContextReply.fromBuffer);
  static final _$refreshGameContext =
      $grpc.ClientMethod<$0.RefreshGameContextRequest, $0.GameContextReply>(
          '/modconductor.v1.GameContextOperations/RefreshGameContext',
          ($0.RefreshGameContextRequest value) => value.writeToBuffer(),
          $0.GameContextReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.GameContextOperations')
abstract class GameContextOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.GameContextOperations';

  GameContextOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ReadGameContextRequest, $0.GameContextReply>(
            'ReadGameContext',
            readGameContext_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadGameContextRequest.fromBuffer(value),
            ($0.GameContextReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveGameContextRequest, $0.GameContextReply>(
            'SaveGameContext',
            saveGameContext_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveGameContextRequest.fromBuffer(value),
            ($0.GameContextReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RefreshGameContextRequest, $0.GameContextReply>(
            'RefreshGameContext',
            refreshGameContext_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RefreshGameContextRequest.fromBuffer(value),
            ($0.GameContextReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.GameContextReply> readGameContext_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadGameContextRequest> $request) async {
    return readGameContext($call, await $request);
  }

  $async.Future<$0.GameContextReply> readGameContext(
      $grpc.ServiceCall call, $0.ReadGameContextRequest request);

  $async.Future<$0.GameContextReply> saveGameContext_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SaveGameContextRequest> $request) async {
    return saveGameContext($call, await $request);
  }

  $async.Future<$0.GameContextReply> saveGameContext(
      $grpc.ServiceCall call, $0.SaveGameContextRequest request);

  $async.Future<$0.GameContextReply> refreshGameContext_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshGameContextRequest> $request) async {
    return refreshGameContext($call, await $request);
  }

  $async.Future<$0.GameContextReply> refreshGameContext(
      $grpc.ServiceCall call, $0.RefreshGameContextRequest request);
}
