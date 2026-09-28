// This is a generated file - do not edit.
//
// Generated from modconductor/v1/desktop.proto.

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

import 'desktop.pb.dart' as $0;

export 'desktop.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.DesktopOperations')
class DesktopOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DesktopOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.DesktopRequestReply> resolveDesktopRequest(
    $0.ResolveDesktopRequestMessage request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resolveDesktopRequest, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateHandoffReply> checkUpdateHandoff(
    $0.UpdateHandoffRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkUpdateHandoff, request, options: options);
  }

  // method descriptors

  static final _$resolveDesktopRequest = $grpc.ClientMethod<
          $0.ResolveDesktopRequestMessage, $0.DesktopRequestReply>(
      '/modconductor.v1.DesktopOperations/ResolveDesktopRequest',
      ($0.ResolveDesktopRequestMessage value) => value.writeToBuffer(),
      $0.DesktopRequestReply.fromBuffer);
  static final _$checkUpdateHandoff =
      $grpc.ClientMethod<$0.UpdateHandoffRequest, $0.UpdateHandoffReply>(
          '/modconductor.v1.DesktopOperations/CheckUpdateHandoff',
          ($0.UpdateHandoffRequest value) => value.writeToBuffer(),
          $0.UpdateHandoffReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.DesktopOperations')
abstract class DesktopOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.DesktopOperations';

  DesktopOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ResolveDesktopRequestMessage,
            $0.DesktopRequestReply>(
        'ResolveDesktopRequest',
        resolveDesktopRequest_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ResolveDesktopRequestMessage.fromBuffer(value),
        ($0.DesktopRequestReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateHandoffRequest, $0.UpdateHandoffReply>(
            'CheckUpdateHandoff',
            checkUpdateHandoff_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateHandoffRequest.fromBuffer(value),
            ($0.UpdateHandoffReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.DesktopRequestReply> resolveDesktopRequest_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ResolveDesktopRequestMessage> $request) async {
    return resolveDesktopRequest($call, await $request);
  }

  $async.Future<$0.DesktopRequestReply> resolveDesktopRequest(
      $grpc.ServiceCall call, $0.ResolveDesktopRequestMessage request);

  $async.Future<$0.UpdateHandoffReply> checkUpdateHandoff_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateHandoffRequest> $request) async {
    return checkUpdateHandoff($call, await $request);
  }

  $async.Future<$0.UpdateHandoffReply> checkUpdateHandoff(
      $grpc.ServiceCall call, $0.UpdateHandoffRequest request);
}
