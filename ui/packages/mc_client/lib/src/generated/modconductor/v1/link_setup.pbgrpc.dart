// This is a generated file - do not edit.
//
// Generated from modconductor/v1/link_setup.proto.

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

import 'link_setup.pb.dart' as $0;

export 'link_setup.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.NexusLinkSetup')
class NexusLinkSetupClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NexusLinkSetupClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.LinkSetupReply> readLinkSetup(
    $0.LinkSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readLinkSetup, request, options: options);
  }

  $grpc.ResponseFuture<$0.LinkSetupReply> addLinkSetup(
    $0.AddLinkSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addLinkSetup, request, options: options);
  }

  $grpc.ResponseFuture<$0.LinkSetupReply> removeLinkSetup(
    $0.LinkSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeLinkSetup, request, options: options);
  }

  $grpc.ResponseFuture<$0.LinkSetupReply> openLinkDefaults(
    $0.LinkSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openLinkDefaults, request, options: options);
  }

  // method descriptors

  static final _$readLinkSetup =
      $grpc.ClientMethod<$0.LinkSetupRequest, $0.LinkSetupReply>(
          '/modconductor.v1.NexusLinkSetup/ReadLinkSetup',
          ($0.LinkSetupRequest value) => value.writeToBuffer(),
          $0.LinkSetupReply.fromBuffer);
  static final _$addLinkSetup =
      $grpc.ClientMethod<$0.AddLinkSetupRequest, $0.LinkSetupReply>(
          '/modconductor.v1.NexusLinkSetup/AddLinkSetup',
          ($0.AddLinkSetupRequest value) => value.writeToBuffer(),
          $0.LinkSetupReply.fromBuffer);
  static final _$removeLinkSetup =
      $grpc.ClientMethod<$0.LinkSetupRequest, $0.LinkSetupReply>(
          '/modconductor.v1.NexusLinkSetup/RemoveLinkSetup',
          ($0.LinkSetupRequest value) => value.writeToBuffer(),
          $0.LinkSetupReply.fromBuffer);
  static final _$openLinkDefaults =
      $grpc.ClientMethod<$0.LinkSetupRequest, $0.LinkSetupReply>(
          '/modconductor.v1.NexusLinkSetup/OpenLinkDefaults',
          ($0.LinkSetupRequest value) => value.writeToBuffer(),
          $0.LinkSetupReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.NexusLinkSetup')
abstract class NexusLinkSetupServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.NexusLinkSetup';

  NexusLinkSetupServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LinkSetupRequest, $0.LinkSetupReply>(
        'ReadLinkSetup',
        readLinkSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LinkSetupRequest.fromBuffer(value),
        ($0.LinkSetupReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddLinkSetupRequest, $0.LinkSetupReply>(
        'AddLinkSetup',
        addLinkSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AddLinkSetupRequest.fromBuffer(value),
        ($0.LinkSetupReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LinkSetupRequest, $0.LinkSetupReply>(
        'RemoveLinkSetup',
        removeLinkSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LinkSetupRequest.fromBuffer(value),
        ($0.LinkSetupReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LinkSetupRequest, $0.LinkSetupReply>(
        'OpenLinkDefaults',
        openLinkDefaults_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LinkSetupRequest.fromBuffer(value),
        ($0.LinkSetupReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.LinkSetupReply> readLinkSetup_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LinkSetupRequest> $request) async {
    return readLinkSetup($call, await $request);
  }

  $async.Future<$0.LinkSetupReply> readLinkSetup(
      $grpc.ServiceCall call, $0.LinkSetupRequest request);

  $async.Future<$0.LinkSetupReply> addLinkSetup_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddLinkSetupRequest> $request) async {
    return addLinkSetup($call, await $request);
  }

  $async.Future<$0.LinkSetupReply> addLinkSetup(
      $grpc.ServiceCall call, $0.AddLinkSetupRequest request);

  $async.Future<$0.LinkSetupReply> removeLinkSetup_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LinkSetupRequest> $request) async {
    return removeLinkSetup($call, await $request);
  }

  $async.Future<$0.LinkSetupReply> removeLinkSetup(
      $grpc.ServiceCall call, $0.LinkSetupRequest request);

  $async.Future<$0.LinkSetupReply> openLinkDefaults_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LinkSetupRequest> $request) async {
    return openLinkDefaults($call, await $request);
  }

  $async.Future<$0.LinkSetupReply> openLinkDefaults(
      $grpc.ServiceCall call, $0.LinkSetupRequest request);
}
