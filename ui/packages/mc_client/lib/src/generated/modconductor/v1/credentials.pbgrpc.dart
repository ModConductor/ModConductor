// This is a generated file - do not edit.
//
// Generated from modconductor/v1/credentials.proto.

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

import 'credentials.pb.dart' as $0;

export 'credentials.pb.dart';

/// Secret bytes never cross this boundary. Saved presence is not authentication.
@$pb.GrpcServiceName('modconductor.v1.CredentialStorage')
class CredentialStorageClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CredentialStorageClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.CredentialStorageStatus> readCredentialStatus(
    $0.CredentialStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readCredentialStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.CredentialStorageStatus> setCredentialStorageMode(
    $0.CredentialModeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setCredentialStorageMode, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.CredentialStorageStatus> removeSavedCredentials(
    $0.CredentialStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeSavedCredentials, request,
        options: options);
  }

  // method descriptors

  static final _$readCredentialStatus = $grpc.ClientMethod<
          $0.CredentialStatusRequest, $0.CredentialStorageStatus>(
      '/modconductor.v1.CredentialStorage/ReadCredentialStatus',
      ($0.CredentialStatusRequest value) => value.writeToBuffer(),
      $0.CredentialStorageStatus.fromBuffer);
  static final _$setCredentialStorageMode =
      $grpc.ClientMethod<$0.CredentialModeRequest, $0.CredentialStorageStatus>(
          '/modconductor.v1.CredentialStorage/SetCredentialStorageMode',
          ($0.CredentialModeRequest value) => value.writeToBuffer(),
          $0.CredentialStorageStatus.fromBuffer);
  static final _$removeSavedCredentials = $grpc.ClientMethod<
          $0.CredentialStatusRequest, $0.CredentialStorageStatus>(
      '/modconductor.v1.CredentialStorage/RemoveSavedCredentials',
      ($0.CredentialStatusRequest value) => value.writeToBuffer(),
      $0.CredentialStorageStatus.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.CredentialStorage')
abstract class CredentialStorageServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.CredentialStorage';

  CredentialStorageServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CredentialStatusRequest,
            $0.CredentialStorageStatus>(
        'ReadCredentialStatus',
        readCredentialStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CredentialStatusRequest.fromBuffer(value),
        ($0.CredentialStorageStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CredentialModeRequest,
            $0.CredentialStorageStatus>(
        'SetCredentialStorageMode',
        setCredentialStorageMode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CredentialModeRequest.fromBuffer(value),
        ($0.CredentialStorageStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CredentialStatusRequest,
            $0.CredentialStorageStatus>(
        'RemoveSavedCredentials',
        removeSavedCredentials_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CredentialStatusRequest.fromBuffer(value),
        ($0.CredentialStorageStatus value) => value.writeToBuffer()));
  }

  $async.Future<$0.CredentialStorageStatus> readCredentialStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CredentialStatusRequest> $request) async {
    return readCredentialStatus($call, await $request);
  }

  $async.Future<$0.CredentialStorageStatus> readCredentialStatus(
      $grpc.ServiceCall call, $0.CredentialStatusRequest request);

  $async.Future<$0.CredentialStorageStatus> setCredentialStorageMode_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CredentialModeRequest> $request) async {
    return setCredentialStorageMode($call, await $request);
  }

  $async.Future<$0.CredentialStorageStatus> setCredentialStorageMode(
      $grpc.ServiceCall call, $0.CredentialModeRequest request);

  $async.Future<$0.CredentialStorageStatus> removeSavedCredentials_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CredentialStatusRequest> $request) async {
    return removeSavedCredentials($call, await $request);
  }

  $async.Future<$0.CredentialStorageStatus> removeSavedCredentials(
      $grpc.ServiceCall call, $0.CredentialStatusRequest request);
}
