// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bepinex.proto.

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

import 'bepinex.pb.dart' as $0;

export 'bepinex.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.BepInEx')
class BepInExClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  BepInExClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.LoaderReply> readLoader(
    $0.LoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readLoader, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoaderReply> changeLoader(
    $0.ChangeLoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeLoader, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoaderTextReply> readLoaderSettings(
    $0.LoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readLoaderSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoaderTextReply> saveLoaderSettings(
    $0.SaveLoaderSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveLoaderSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoaderTextReply> readLoaderLog(
    $0.LoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readLoaderLog, request, options: options);
  }

  // method descriptors

  static final _$readLoader =
      $grpc.ClientMethod<$0.LoaderRequest, $0.LoaderReply>(
          '/modconductor.v1.BepInEx/ReadLoader',
          ($0.LoaderRequest value) => value.writeToBuffer(),
          $0.LoaderReply.fromBuffer);
  static final _$changeLoader =
      $grpc.ClientMethod<$0.ChangeLoaderRequest, $0.LoaderReply>(
          '/modconductor.v1.BepInEx/ChangeLoader',
          ($0.ChangeLoaderRequest value) => value.writeToBuffer(),
          $0.LoaderReply.fromBuffer);
  static final _$readLoaderSettings =
      $grpc.ClientMethod<$0.LoaderRequest, $0.LoaderTextReply>(
          '/modconductor.v1.BepInEx/ReadLoaderSettings',
          ($0.LoaderRequest value) => value.writeToBuffer(),
          $0.LoaderTextReply.fromBuffer);
  static final _$saveLoaderSettings =
      $grpc.ClientMethod<$0.SaveLoaderSettingsRequest, $0.LoaderTextReply>(
          '/modconductor.v1.BepInEx/SaveLoaderSettings',
          ($0.SaveLoaderSettingsRequest value) => value.writeToBuffer(),
          $0.LoaderTextReply.fromBuffer);
  static final _$readLoaderLog =
      $grpc.ClientMethod<$0.LoaderRequest, $0.LoaderTextReply>(
          '/modconductor.v1.BepInEx/ReadLoaderLog',
          ($0.LoaderRequest value) => value.writeToBuffer(),
          $0.LoaderTextReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.BepInEx')
abstract class BepInExServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.BepInEx';

  BepInExServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LoaderRequest, $0.LoaderReply>(
        'ReadLoader',
        readLoader_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoaderRequest.fromBuffer(value),
        ($0.LoaderReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangeLoaderRequest, $0.LoaderReply>(
        'ChangeLoader',
        changeLoader_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangeLoaderRequest.fromBuffer(value),
        ($0.LoaderReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoaderRequest, $0.LoaderTextReply>(
        'ReadLoaderSettings',
        readLoaderSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoaderRequest.fromBuffer(value),
        ($0.LoaderTextReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveLoaderSettingsRequest, $0.LoaderTextReply>(
            'SaveLoaderSettings',
            saveLoaderSettings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveLoaderSettingsRequest.fromBuffer(value),
            ($0.LoaderTextReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoaderRequest, $0.LoaderTextReply>(
        'ReadLoaderLog',
        readLoaderLog_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoaderRequest.fromBuffer(value),
        ($0.LoaderTextReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.LoaderReply> readLoader_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoaderRequest> $request) async {
    return readLoader($call, await $request);
  }

  $async.Future<$0.LoaderReply> readLoader(
      $grpc.ServiceCall call, $0.LoaderRequest request);

  $async.Future<$0.LoaderReply> changeLoader_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ChangeLoaderRequest> $request) async {
    return changeLoader($call, await $request);
  }

  $async.Future<$0.LoaderReply> changeLoader(
      $grpc.ServiceCall call, $0.ChangeLoaderRequest request);

  $async.Future<$0.LoaderTextReply> readLoaderSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoaderRequest> $request) async {
    return readLoaderSettings($call, await $request);
  }

  $async.Future<$0.LoaderTextReply> readLoaderSettings(
      $grpc.ServiceCall call, $0.LoaderRequest request);

  $async.Future<$0.LoaderTextReply> saveLoaderSettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SaveLoaderSettingsRequest> $request) async {
    return saveLoaderSettings($call, await $request);
  }

  $async.Future<$0.LoaderTextReply> saveLoaderSettings(
      $grpc.ServiceCall call, $0.SaveLoaderSettingsRequest request);

  $async.Future<$0.LoaderTextReply> readLoaderLog_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoaderRequest> $request) async {
    return readLoaderLog($call, await $request);
  }

  $async.Future<$0.LoaderTextReply> readLoaderLog(
      $grpc.ServiceCall call, $0.LoaderRequest request);
}
