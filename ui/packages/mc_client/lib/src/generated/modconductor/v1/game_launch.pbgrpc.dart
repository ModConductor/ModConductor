// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_launch.proto.

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

import 'executables.pb.dart' as $1;
import 'game_launch.pb.dart' as $0;

export 'game_launch.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.GameLaunchOperations')
class GameLaunchOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GameLaunchOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GameLaunchStateReply> readGameLaunch(
    $0.GameLaunchStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readGameLaunch, request, options: options);
  }

  $grpc.ResponseFuture<$1.ExecutableRunReply> playGame(
    $1.GameRunRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$playGame, request, options: options);
  }

  $grpc.ResponseFuture<$1.ExecutableRunReply> playGameContinuingFnis(
    $1.GameRunRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$playGameContinuingFnis, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.ExecutableRunReply> cancelGameLaunch(
    $1.ExecutableRunRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelGameLaunch, request, options: options);
  }

  // method descriptors

  static final _$readGameLaunch =
      $grpc.ClientMethod<$0.GameLaunchStateRequest, $0.GameLaunchStateReply>(
          '/modconductor.v1.GameLaunchOperations/ReadGameLaunch',
          ($0.GameLaunchStateRequest value) => value.writeToBuffer(),
          $0.GameLaunchStateReply.fromBuffer);
  static final _$playGame =
      $grpc.ClientMethod<$1.GameRunRequest, $1.ExecutableRunReply>(
          '/modconductor.v1.GameLaunchOperations/PlayGame',
          ($1.GameRunRequest value) => value.writeToBuffer(),
          $1.ExecutableRunReply.fromBuffer);
  static final _$playGameContinuingFnis =
      $grpc.ClientMethod<$1.GameRunRequest, $1.ExecutableRunReply>(
          '/modconductor.v1.GameLaunchOperations/PlayGameContinuingFnis',
          ($1.GameRunRequest value) => value.writeToBuffer(),
          $1.ExecutableRunReply.fromBuffer);
  static final _$cancelGameLaunch =
      $grpc.ClientMethod<$1.ExecutableRunRef, $1.ExecutableRunReply>(
          '/modconductor.v1.GameLaunchOperations/CancelGameLaunch',
          ($1.ExecutableRunRef value) => value.writeToBuffer(),
          $1.ExecutableRunReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.GameLaunchOperations')
abstract class GameLaunchOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.GameLaunchOperations';

  GameLaunchOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GameLaunchStateRequest, $0.GameLaunchStateReply>(
            'ReadGameLaunch',
            readGameLaunch_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GameLaunchStateRequest.fromBuffer(value),
            ($0.GameLaunchStateReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GameRunRequest, $1.ExecutableRunReply>(
        'PlayGame',
        playGame_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GameRunRequest.fromBuffer(value),
        ($1.ExecutableRunReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GameRunRequest, $1.ExecutableRunReply>(
        'PlayGameContinuingFnis',
        playGameContinuingFnis_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GameRunRequest.fromBuffer(value),
        ($1.ExecutableRunReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ExecutableRunRef, $1.ExecutableRunReply>(
        'CancelGameLaunch',
        cancelGameLaunch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.ExecutableRunRef.fromBuffer(value),
        ($1.ExecutableRunReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.GameLaunchStateReply> readGameLaunch_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GameLaunchStateRequest> $request) async {
    return readGameLaunch($call, await $request);
  }

  $async.Future<$0.GameLaunchStateReply> readGameLaunch(
      $grpc.ServiceCall call, $0.GameLaunchStateRequest request);

  $async.Future<$1.ExecutableRunReply> playGame_Pre($grpc.ServiceCall $call,
      $async.Future<$1.GameRunRequest> $request) async {
    return playGame($call, await $request);
  }

  $async.Future<$1.ExecutableRunReply> playGame(
      $grpc.ServiceCall call, $1.GameRunRequest request);

  $async.Future<$1.ExecutableRunReply> playGameContinuingFnis_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.GameRunRequest> $request) async {
    return playGameContinuingFnis($call, await $request);
  }

  $async.Future<$1.ExecutableRunReply> playGameContinuingFnis(
      $grpc.ServiceCall call, $1.GameRunRequest request);

  $async.Future<$1.ExecutableRunReply> cancelGameLaunch_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ExecutableRunRef> $request) async {
    return cancelGameLaunch($call, await $request);
  }

  $async.Future<$1.ExecutableRunReply> cancelGameLaunch(
      $grpc.ServiceCall call, $1.ExecutableRunRef request);
}
