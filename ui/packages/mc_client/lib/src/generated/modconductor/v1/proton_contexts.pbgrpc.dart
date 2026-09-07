// This is a generated file - do not edit.
//
// Generated from modconductor/v1/proton_contexts.proto.

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

import 'proton_contexts.pb.dart' as $0;

export 'proton_contexts.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ProtonContextOperations')
class ProtonContextOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProtonContextOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ProtonSearchResult> searchProtonContexts(
    $0.SearchProtonContextsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchProtonContexts, request, options: options);
  }

  // method descriptors

  static final _$searchProtonContexts =
      $grpc.ClientMethod<$0.SearchProtonContextsRequest, $0.ProtonSearchResult>(
          '/modconductor.v1.ProtonContextOperations/SearchProtonContexts',
          ($0.SearchProtonContextsRequest value) => value.writeToBuffer(),
          $0.ProtonSearchResult.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ProtonContextOperations')
abstract class ProtonContextOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ProtonContextOperations';

  ProtonContextOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SearchProtonContextsRequest,
            $0.ProtonSearchResult>(
        'SearchProtonContexts',
        searchProtonContexts_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SearchProtonContextsRequest.fromBuffer(value),
        ($0.ProtonSearchResult value) => value.writeToBuffer()));
  }

  $async.Future<$0.ProtonSearchResult> searchProtonContexts_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SearchProtonContextsRequest> $request) async {
    return searchProtonContexts($call, await $request);
  }

  $async.Future<$0.ProtonSearchResult> searchProtonContexts(
      $grpc.ServiceCall call, $0.SearchProtonContextsRequest request);
}
