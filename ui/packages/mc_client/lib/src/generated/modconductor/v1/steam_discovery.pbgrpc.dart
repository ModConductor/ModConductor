// This is a generated file - do not edit.
//
// Generated from modconductor/v1/steam_discovery.proto.

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

import 'steam_discovery.pb.dart' as $0;

export 'steam_discovery.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.SteamDiscoveryOperations')
class SteamDiscoveryOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SteamDiscoveryOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SteamSearchResult> searchInstallations(
    $0.SteamSearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchInstallations, request, options: options);
  }

  // method descriptors

  static final _$searchInstallations =
      $grpc.ClientMethod<$0.SteamSearchRequest, $0.SteamSearchResult>(
          '/modconductor.v1.SteamDiscoveryOperations/SearchInstallations',
          ($0.SteamSearchRequest value) => value.writeToBuffer(),
          $0.SteamSearchResult.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.SteamDiscoveryOperations')
abstract class SteamDiscoveryOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.SteamDiscoveryOperations';

  SteamDiscoveryOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SteamSearchRequest, $0.SteamSearchResult>(
        'SearchInstallations',
        searchInstallations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SteamSearchRequest.fromBuffer(value),
        ($0.SteamSearchResult value) => value.writeToBuffer()));
  }

  $async.Future<$0.SteamSearchResult> searchInstallations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SteamSearchRequest> $request) async {
    return searchInstallations($call, await $request);
  }

  $async.Future<$0.SteamSearchResult> searchInstallations(
      $grpc.ServiceCall call, $0.SteamSearchRequest request);
}
