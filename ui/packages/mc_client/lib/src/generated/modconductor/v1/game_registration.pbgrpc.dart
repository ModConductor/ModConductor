// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_registration.proto.

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

import 'game_registration.pb.dart' as $0;
import 'steam_discovery.pb.dart' as $1;

export 'game_registration.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.GameRegistration')
class GameRegistrationClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GameRegistrationClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.SteamSearchResult> listInstalledGames(
    $0.ListInstalledGamesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listInstalledGames, request, options: options);
  }

  $grpc.ResponseFuture<$0.ThunderstoreGamesReply> searchThunderstoreGames(
    $0.SearchThunderstoreGamesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchThunderstoreGames, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.DetectGameReply> detectGame(
    $0.DetectGameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$detectGame, request, options: options);
  }

  $grpc.ResponseFuture<$0.CustomGameReply> readCustomGame(
    $0.ReadCustomGameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readCustomGame, request, options: options);
  }

  $grpc.ResponseFuture<$0.CustomGameReply> saveCustomGame(
    $0.SaveCustomGameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveCustomGame, request, options: options);
  }

  // method descriptors

  static final _$listInstalledGames =
      $grpc.ClientMethod<$0.ListInstalledGamesRequest, $1.SteamSearchResult>(
          '/modconductor.v1.GameRegistration/ListInstalledGames',
          ($0.ListInstalledGamesRequest value) => value.writeToBuffer(),
          $1.SteamSearchResult.fromBuffer);
  static final _$searchThunderstoreGames = $grpc.ClientMethod<
          $0.SearchThunderstoreGamesRequest, $0.ThunderstoreGamesReply>(
      '/modconductor.v1.GameRegistration/SearchThunderstoreGames',
      ($0.SearchThunderstoreGamesRequest value) => value.writeToBuffer(),
      $0.ThunderstoreGamesReply.fromBuffer);
  static final _$detectGame =
      $grpc.ClientMethod<$0.DetectGameRequest, $0.DetectGameReply>(
          '/modconductor.v1.GameRegistration/DetectGame',
          ($0.DetectGameRequest value) => value.writeToBuffer(),
          $0.DetectGameReply.fromBuffer);
  static final _$readCustomGame =
      $grpc.ClientMethod<$0.ReadCustomGameRequest, $0.CustomGameReply>(
          '/modconductor.v1.GameRegistration/ReadCustomGame',
          ($0.ReadCustomGameRequest value) => value.writeToBuffer(),
          $0.CustomGameReply.fromBuffer);
  static final _$saveCustomGame =
      $grpc.ClientMethod<$0.SaveCustomGameRequest, $0.CustomGameReply>(
          '/modconductor.v1.GameRegistration/SaveCustomGame',
          ($0.SaveCustomGameRequest value) => value.writeToBuffer(),
          $0.CustomGameReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.GameRegistration')
abstract class GameRegistrationServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.GameRegistration';

  GameRegistrationServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListInstalledGamesRequest, $1.SteamSearchResult>(
            'ListInstalledGames',
            listInstalledGames_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListInstalledGamesRequest.fromBuffer(value),
            ($1.SteamSearchResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchThunderstoreGamesRequest,
            $0.ThunderstoreGamesReply>(
        'SearchThunderstoreGames',
        searchThunderstoreGames_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SearchThunderstoreGamesRequest.fromBuffer(value),
        ($0.ThunderstoreGamesReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DetectGameRequest, $0.DetectGameReply>(
        'DetectGame',
        detectGame_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DetectGameRequest.fromBuffer(value),
        ($0.DetectGameReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadCustomGameRequest, $0.CustomGameReply>(
            'ReadCustomGame',
            readCustomGame_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadCustomGameRequest.fromBuffer(value),
            ($0.CustomGameReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveCustomGameRequest, $0.CustomGameReply>(
            'SaveCustomGame',
            saveCustomGame_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveCustomGameRequest.fromBuffer(value),
            ($0.CustomGameReply value) => value.writeToBuffer()));
  }

  $async.Future<$1.SteamSearchResult> listInstalledGames_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListInstalledGamesRequest> $request) async {
    return listInstalledGames($call, await $request);
  }

  $async.Future<$1.SteamSearchResult> listInstalledGames(
      $grpc.ServiceCall call, $0.ListInstalledGamesRequest request);

  $async.Future<$0.ThunderstoreGamesReply> searchThunderstoreGames_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SearchThunderstoreGamesRequest> $request) async {
    return searchThunderstoreGames($call, await $request);
  }

  $async.Future<$0.ThunderstoreGamesReply> searchThunderstoreGames(
      $grpc.ServiceCall call, $0.SearchThunderstoreGamesRequest request);

  $async.Future<$0.DetectGameReply> detectGame_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DetectGameRequest> $request) async {
    return detectGame($call, await $request);
  }

  $async.Future<$0.DetectGameReply> detectGame(
      $grpc.ServiceCall call, $0.DetectGameRequest request);

  $async.Future<$0.CustomGameReply> readCustomGame_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadCustomGameRequest> $request) async {
    return readCustomGame($call, await $request);
  }

  $async.Future<$0.CustomGameReply> readCustomGame(
      $grpc.ServiceCall call, $0.ReadCustomGameRequest request);

  $async.Future<$0.CustomGameReply> saveCustomGame_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveCustomGameRequest> $request) async {
    return saveCustomGame($call, await $request);
  }

  $async.Future<$0.CustomGameReply> saveCustomGame(
      $grpc.ServiceCall call, $0.SaveCustomGameRequest request);
}
