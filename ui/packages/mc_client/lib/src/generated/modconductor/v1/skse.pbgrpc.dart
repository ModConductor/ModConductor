// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skse.proto.

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

import 'skse.pb.dart' as $0;

export 'skse.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.SkseOperations')
class SkseOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SkseOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SkseState> readSkse(
    $0.SkseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readSkse, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkseState> startSkse(
    $0.SkseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startSkse, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkseState> checkSkseUpdate(
    $0.SkseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkSkseUpdate, request, options: options);
  }

  // method descriptors

  static final _$readSkse = $grpc.ClientMethod<$0.SkseRequest, $0.SkseState>(
      '/modconductor.v1.SkseOperations/ReadSkse',
      ($0.SkseRequest value) => value.writeToBuffer(),
      $0.SkseState.fromBuffer);
  static final _$startSkse = $grpc.ClientMethod<$0.SkseRequest, $0.SkseState>(
      '/modconductor.v1.SkseOperations/StartSkse',
      ($0.SkseRequest value) => value.writeToBuffer(),
      $0.SkseState.fromBuffer);
  static final _$checkSkseUpdate =
      $grpc.ClientMethod<$0.SkseRequest, $0.SkseState>(
          '/modconductor.v1.SkseOperations/CheckSkseUpdate',
          ($0.SkseRequest value) => value.writeToBuffer(),
          $0.SkseState.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.SkseOperations')
abstract class SkseOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.SkseOperations';

  SkseOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SkseRequest, $0.SkseState>(
        'ReadSkse',
        readSkse_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SkseRequest.fromBuffer(value),
        ($0.SkseState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SkseRequest, $0.SkseState>(
        'StartSkse',
        startSkse_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SkseRequest.fromBuffer(value),
        ($0.SkseState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SkseRequest, $0.SkseState>(
        'CheckSkseUpdate',
        checkSkseUpdate_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SkseRequest.fromBuffer(value),
        ($0.SkseState value) => value.writeToBuffer()));
  }

  $async.Future<$0.SkseState> readSkse_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SkseRequest> $request) async {
    return readSkse($call, await $request);
  }

  $async.Future<$0.SkseState> readSkse(
      $grpc.ServiceCall call, $0.SkseRequest request);

  $async.Future<$0.SkseState> startSkse_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SkseRequest> $request) async {
    return startSkse($call, await $request);
  }

  $async.Future<$0.SkseState> startSkse(
      $grpc.ServiceCall call, $0.SkseRequest request);

  $async.Future<$0.SkseState> checkSkseUpdate_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SkseRequest> $request) async {
    return checkSkseUpdate($call, await $request);
  }

  $async.Future<$0.SkseState> checkSkseUpdate(
      $grpc.ServiceCall call, $0.SkseRequest request);
}
