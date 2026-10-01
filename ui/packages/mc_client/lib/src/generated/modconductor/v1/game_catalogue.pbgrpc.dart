// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_catalogue.proto.

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

import 'game_catalogue.pb.dart' as $0;

export 'game_catalogue.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.GameCatalogue')
class GameCatalogueClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GameCatalogueClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GameCatalogueReply> readGameCatalogue(
    $0.ReadGameCatalogueRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readGameCatalogue, request, options: options);
  }

  $grpc.ResponseFuture<$0.OpenScriptExtenderPageReply> openScriptExtenderPage(
    $0.OpenScriptExtenderPageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openScriptExtenderPage, request,
        options: options);
  }

  // method descriptors

  static final _$readGameCatalogue =
      $grpc.ClientMethod<$0.ReadGameCatalogueRequest, $0.GameCatalogueReply>(
          '/modconductor.v1.GameCatalogue/ReadGameCatalogue',
          ($0.ReadGameCatalogueRequest value) => value.writeToBuffer(),
          $0.GameCatalogueReply.fromBuffer);
  static final _$openScriptExtenderPage = $grpc.ClientMethod<
          $0.OpenScriptExtenderPageRequest, $0.OpenScriptExtenderPageReply>(
      '/modconductor.v1.GameCatalogue/OpenScriptExtenderPage',
      ($0.OpenScriptExtenderPageRequest value) => value.writeToBuffer(),
      $0.OpenScriptExtenderPageReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.GameCatalogue')
abstract class GameCatalogueServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.GameCatalogue';

  GameCatalogueServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ReadGameCatalogueRequest, $0.GameCatalogueReply>(
            'ReadGameCatalogue',
            readGameCatalogue_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadGameCatalogueRequest.fromBuffer(value),
            ($0.GameCatalogueReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.OpenScriptExtenderPageRequest,
            $0.OpenScriptExtenderPageReply>(
        'OpenScriptExtenderPage',
        openScriptExtenderPage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.OpenScriptExtenderPageRequest.fromBuffer(value),
        ($0.OpenScriptExtenderPageReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.GameCatalogueReply> readGameCatalogue_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadGameCatalogueRequest> $request) async {
    return readGameCatalogue($call, await $request);
  }

  $async.Future<$0.GameCatalogueReply> readGameCatalogue(
      $grpc.ServiceCall call, $0.ReadGameCatalogueRequest request);

  $async.Future<$0.OpenScriptExtenderPageReply> openScriptExtenderPage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.OpenScriptExtenderPageRequest> $request) async {
    return openScriptExtenderPage($call, await $request);
  }

  $async.Future<$0.OpenScriptExtenderPageReply> openScriptExtenderPage(
      $grpc.ServiceCall call, $0.OpenScriptExtenderPageRequest request);
}
