// This is a generated file - do not edit.
//
// Generated from modconductor/v1/enb.proto.

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

import 'enb.pb.dart' as $0;

export 'enb.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.EnbOperations')
class EnbOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EnbOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.EnbState> readEnb(
    $0.EnbRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readEnb, request, options: options);
  }

  $grpc.ResponseFuture<$0.EnbState> openEnbAuthorPage(
    $0.EnbRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openEnbAuthorPage, request, options: options);
  }

  $grpc.ResponseFuture<$0.EnbState> selectEnbArchive(
    $0.EnbArchiveRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$selectEnbArchive, request, options: options);
  }

  $grpc.ResponseFuture<$0.EnbState> cancelEnbWait(
    $0.EnbRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelEnbWait, request, options: options);
  }

  // method descriptors

  static final _$readEnb = $grpc.ClientMethod<$0.EnbRequest, $0.EnbState>(
      '/modconductor.v1.EnbOperations/ReadEnb',
      ($0.EnbRequest value) => value.writeToBuffer(),
      $0.EnbState.fromBuffer);
  static final _$openEnbAuthorPage =
      $grpc.ClientMethod<$0.EnbRequest, $0.EnbState>(
          '/modconductor.v1.EnbOperations/OpenEnbAuthorPage',
          ($0.EnbRequest value) => value.writeToBuffer(),
          $0.EnbState.fromBuffer);
  static final _$selectEnbArchive =
      $grpc.ClientMethod<$0.EnbArchiveRequest, $0.EnbState>(
          '/modconductor.v1.EnbOperations/SelectEnbArchive',
          ($0.EnbArchiveRequest value) => value.writeToBuffer(),
          $0.EnbState.fromBuffer);
  static final _$cancelEnbWait = $grpc.ClientMethod<$0.EnbRequest, $0.EnbState>(
      '/modconductor.v1.EnbOperations/CancelEnbWait',
      ($0.EnbRequest value) => value.writeToBuffer(),
      $0.EnbState.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.EnbOperations')
abstract class EnbOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.EnbOperations';

  EnbOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.EnbRequest, $0.EnbState>(
        'ReadEnb',
        readEnb_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EnbRequest.fromBuffer(value),
        ($0.EnbState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnbRequest, $0.EnbState>(
        'OpenEnbAuthorPage',
        openEnbAuthorPage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EnbRequest.fromBuffer(value),
        ($0.EnbState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnbArchiveRequest, $0.EnbState>(
        'SelectEnbArchive',
        selectEnbArchive_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EnbArchiveRequest.fromBuffer(value),
        ($0.EnbState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnbRequest, $0.EnbState>(
        'CancelEnbWait',
        cancelEnbWait_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EnbRequest.fromBuffer(value),
        ($0.EnbState value) => value.writeToBuffer()));
  }

  $async.Future<$0.EnbState> readEnb_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EnbRequest> $request) async {
    return readEnb($call, await $request);
  }

  $async.Future<$0.EnbState> readEnb(
      $grpc.ServiceCall call, $0.EnbRequest request);

  $async.Future<$0.EnbState> openEnbAuthorPage_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EnbRequest> $request) async {
    return openEnbAuthorPage($call, await $request);
  }

  $async.Future<$0.EnbState> openEnbAuthorPage(
      $grpc.ServiceCall call, $0.EnbRequest request);

  $async.Future<$0.EnbState> selectEnbArchive_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EnbArchiveRequest> $request) async {
    return selectEnbArchive($call, await $request);
  }

  $async.Future<$0.EnbState> selectEnbArchive(
      $grpc.ServiceCall call, $0.EnbArchiveRequest request);

  $async.Future<$0.EnbState> cancelEnbWait_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EnbRequest> $request) async {
    return cancelEnbWait($call, await $request);
  }

  $async.Future<$0.EnbState> cancelEnbWait(
      $grpc.ServiceCall call, $0.EnbRequest request);
}
