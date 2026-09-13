// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nxm.proto.

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

import 'nexus.pb.dart' as $1;
import 'nxm.pb.dart' as $0;

export 'nxm.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.NexusLinks')
class NexusLinksClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NexusLinksClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.NexusIngressReply> configureNexusIngress(
    $0.NexusIngressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$configureNexusIngress, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusLinkReply> readNexusLink(
    $0.NexusLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readNexusLink, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusLinkReply> downloadNexusLink(
    $0.NexusLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$downloadNexusLink, request, options: options);
  }

  $grpc.ResponseFuture<$1.NexusStatusRequest> dismissNexusLink(
    $0.NexusLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$dismissNexusLink, request, options: options);
  }

  // method descriptors

  static final _$configureNexusIngress =
      $grpc.ClientMethod<$0.NexusIngressRequest, $0.NexusIngressReply>(
          '/modconductor.v1.NexusLinks/ConfigureNexusIngress',
          ($0.NexusIngressRequest value) => value.writeToBuffer(),
          $0.NexusIngressReply.fromBuffer);
  static final _$readNexusLink =
      $grpc.ClientMethod<$0.NexusLinkRequest, $0.NexusLinkReply>(
          '/modconductor.v1.NexusLinks/ReadNexusLink',
          ($0.NexusLinkRequest value) => value.writeToBuffer(),
          $0.NexusLinkReply.fromBuffer);
  static final _$downloadNexusLink =
      $grpc.ClientMethod<$0.NexusLinkRequest, $0.NexusLinkReply>(
          '/modconductor.v1.NexusLinks/DownloadNexusLink',
          ($0.NexusLinkRequest value) => value.writeToBuffer(),
          $0.NexusLinkReply.fromBuffer);
  static final _$dismissNexusLink =
      $grpc.ClientMethod<$0.NexusLinkRequest, $1.NexusStatusRequest>(
          '/modconductor.v1.NexusLinks/DismissNexusLink',
          ($0.NexusLinkRequest value) => value.writeToBuffer(),
          $1.NexusStatusRequest.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.NexusLinks')
abstract class NexusLinksServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.NexusLinks';

  NexusLinksServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.NexusIngressRequest, $0.NexusIngressReply>(
            'ConfigureNexusIngress',
            configureNexusIngress_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusIngressRequest.fromBuffer(value),
            ($0.NexusIngressReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NexusLinkRequest, $0.NexusLinkReply>(
        'ReadNexusLink',
        readNexusLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NexusLinkRequest.fromBuffer(value),
        ($0.NexusLinkReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NexusLinkRequest, $0.NexusLinkReply>(
        'DownloadNexusLink',
        downloadNexusLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NexusLinkRequest.fromBuffer(value),
        ($0.NexusLinkReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NexusLinkRequest, $1.NexusStatusRequest>(
        'DismissNexusLink',
        dismissNexusLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NexusLinkRequest.fromBuffer(value),
        ($1.NexusStatusRequest value) => value.writeToBuffer()));
  }

  $async.Future<$0.NexusIngressReply> configureNexusIngress_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusIngressRequest> $request) async {
    return configureNexusIngress($call, await $request);
  }

  $async.Future<$0.NexusIngressReply> configureNexusIngress(
      $grpc.ServiceCall call, $0.NexusIngressRequest request);

  $async.Future<$0.NexusLinkReply> readNexusLink_Pre($grpc.ServiceCall $call,
      $async.Future<$0.NexusLinkRequest> $request) async {
    return readNexusLink($call, await $request);
  }

  $async.Future<$0.NexusLinkReply> readNexusLink(
      $grpc.ServiceCall call, $0.NexusLinkRequest request);

  $async.Future<$0.NexusLinkReply> downloadNexusLink_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusLinkRequest> $request) async {
    return downloadNexusLink($call, await $request);
  }

  $async.Future<$0.NexusLinkReply> downloadNexusLink(
      $grpc.ServiceCall call, $0.NexusLinkRequest request);

  $async.Future<$1.NexusStatusRequest> dismissNexusLink_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusLinkRequest> $request) async {
    return dismissNexusLink($call, await $request);
  }

  $async.Future<$1.NexusStatusRequest> dismissNexusLink(
      $grpc.ServiceCall call, $0.NexusLinkRequest request);
}
