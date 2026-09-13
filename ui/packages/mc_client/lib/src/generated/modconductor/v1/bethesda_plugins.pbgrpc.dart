// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bethesda_plugins.proto.

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

import 'bethesda_plugins.pb.dart' as $0;

export 'bethesda_plugins.pb.dart';

/// Header observations are read-only and are not deployment content pins.
@$pb.GrpcServiceName('modconductor.v1.BethesdaPlugins')
class BethesdaPluginsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  BethesdaPluginsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.BethesdaPluginsReply> scanPlugins(
    $0.ScanPluginsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$scanPlugins, request, options: options);
  }

  $grpc.ResponseFuture<$0.BethesdaPluginsReply> readPlugins(
    $0.ReadPluginsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readPlugins, request, options: options);
  }

  // method descriptors

  static final _$scanPlugins =
      $grpc.ClientMethod<$0.ScanPluginsRequest, $0.BethesdaPluginsReply>(
          '/modconductor.v1.BethesdaPlugins/ScanPlugins',
          ($0.ScanPluginsRequest value) => value.writeToBuffer(),
          $0.BethesdaPluginsReply.fromBuffer);
  static final _$readPlugins =
      $grpc.ClientMethod<$0.ReadPluginsRequest, $0.BethesdaPluginsReply>(
          '/modconductor.v1.BethesdaPlugins/ReadPlugins',
          ($0.ReadPluginsRequest value) => value.writeToBuffer(),
          $0.BethesdaPluginsReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.BethesdaPlugins')
abstract class BethesdaPluginsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.BethesdaPlugins';

  BethesdaPluginsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ScanPluginsRequest, $0.BethesdaPluginsReply>(
            'ScanPlugins',
            scanPlugins_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ScanPluginsRequest.fromBuffer(value),
            ($0.BethesdaPluginsReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadPluginsRequest, $0.BethesdaPluginsReply>(
            'ReadPlugins',
            readPlugins_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadPluginsRequest.fromBuffer(value),
            ($0.BethesdaPluginsReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.BethesdaPluginsReply> scanPlugins_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ScanPluginsRequest> $request) async {
    return scanPlugins($call, await $request);
  }

  $async.Future<$0.BethesdaPluginsReply> scanPlugins(
      $grpc.ServiceCall call, $0.ScanPluginsRequest request);

  $async.Future<$0.BethesdaPluginsReply> readPlugins_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadPluginsRequest> $request) async {
    return readPlugins($call, await $request);
  }

  $async.Future<$0.BethesdaPluginsReply> readPlugins(
      $grpc.ServiceCall call, $0.ReadPluginsRequest request);
}
