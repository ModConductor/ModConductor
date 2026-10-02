// This is a generated file - do not edit.
//
// Generated from modconductor/v1/unreal.proto.

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
import 'unreal.pb.dart' as $1;

export 'unreal.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.Unreal')
class UnrealClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  UnrealClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.UnrealLoaderReply> readUnrealLoader(
    $0.LoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readUnrealLoader, request, options: options);
  }

  $grpc.ResponseFuture<$1.UnrealLoaderReply> changeUnrealLoader(
    $0.ChangeLoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeUnrealLoader, request, options: options);
  }

  $grpc.ResponseStream<$1.UnrealAcquisitionProgress> acquireUnrealLoader(
    $1.AcquireUnrealLoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$acquireUnrealLoader, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.LoaderTextReply> readUnrealText(
    $1.UnrealTextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readUnrealText, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoaderTextReply> saveUnrealText(
    $1.SaveUnrealTextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveUnrealText, request, options: options);
  }

  $grpc.ResponseFuture<$1.UnrealPageReply> openUnrealLoaderPage(
    $0.LoaderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openUnrealLoaderPage, request, options: options);
  }

  // method descriptors

  static final _$readUnrealLoader =
      $grpc.ClientMethod<$0.LoaderRequest, $1.UnrealLoaderReply>(
          '/modconductor.v1.Unreal/ReadUnrealLoader',
          ($0.LoaderRequest value) => value.writeToBuffer(),
          $1.UnrealLoaderReply.fromBuffer);
  static final _$changeUnrealLoader =
      $grpc.ClientMethod<$0.ChangeLoaderRequest, $1.UnrealLoaderReply>(
          '/modconductor.v1.Unreal/ChangeUnrealLoader',
          ($0.ChangeLoaderRequest value) => value.writeToBuffer(),
          $1.UnrealLoaderReply.fromBuffer);
  static final _$acquireUnrealLoader = $grpc.ClientMethod<
          $1.AcquireUnrealLoaderRequest, $1.UnrealAcquisitionProgress>(
      '/modconductor.v1.Unreal/AcquireUnrealLoader',
      ($1.AcquireUnrealLoaderRequest value) => value.writeToBuffer(),
      $1.UnrealAcquisitionProgress.fromBuffer);
  static final _$readUnrealText =
      $grpc.ClientMethod<$1.UnrealTextRequest, $0.LoaderTextReply>(
          '/modconductor.v1.Unreal/ReadUnrealText',
          ($1.UnrealTextRequest value) => value.writeToBuffer(),
          $0.LoaderTextReply.fromBuffer);
  static final _$saveUnrealText =
      $grpc.ClientMethod<$1.SaveUnrealTextRequest, $0.LoaderTextReply>(
          '/modconductor.v1.Unreal/SaveUnrealText',
          ($1.SaveUnrealTextRequest value) => value.writeToBuffer(),
          $0.LoaderTextReply.fromBuffer);
  static final _$openUnrealLoaderPage =
      $grpc.ClientMethod<$0.LoaderRequest, $1.UnrealPageReply>(
          '/modconductor.v1.Unreal/OpenUnrealLoaderPage',
          ($0.LoaderRequest value) => value.writeToBuffer(),
          $1.UnrealPageReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.Unreal')
abstract class UnrealServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.Unreal';

  UnrealServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LoaderRequest, $1.UnrealLoaderReply>(
        'ReadUnrealLoader',
        readUnrealLoader_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoaderRequest.fromBuffer(value),
        ($1.UnrealLoaderReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ChangeLoaderRequest, $1.UnrealLoaderReply>(
            'ChangeUnrealLoader',
            changeUnrealLoader_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ChangeLoaderRequest.fromBuffer(value),
            ($1.UnrealLoaderReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.AcquireUnrealLoaderRequest,
            $1.UnrealAcquisitionProgress>(
        'AcquireUnrealLoader',
        acquireUnrealLoader_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $1.AcquireUnrealLoaderRequest.fromBuffer(value),
        ($1.UnrealAcquisitionProgress value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.UnrealTextRequest, $0.LoaderTextReply>(
        'ReadUnrealText',
        readUnrealText_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.UnrealTextRequest.fromBuffer(value),
        ($0.LoaderTextReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.SaveUnrealTextRequest, $0.LoaderTextReply>(
            'SaveUnrealText',
            saveUnrealText_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.SaveUnrealTextRequest.fromBuffer(value),
            ($0.LoaderTextReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoaderRequest, $1.UnrealPageReply>(
        'OpenUnrealLoaderPage',
        openUnrealLoaderPage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoaderRequest.fromBuffer(value),
        ($1.UnrealPageReply value) => value.writeToBuffer()));
  }

  $async.Future<$1.UnrealLoaderReply> readUnrealLoader_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoaderRequest> $request) async {
    return readUnrealLoader($call, await $request);
  }

  $async.Future<$1.UnrealLoaderReply> readUnrealLoader(
      $grpc.ServiceCall call, $0.LoaderRequest request);

  $async.Future<$1.UnrealLoaderReply> changeUnrealLoader_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangeLoaderRequest> $request) async {
    return changeUnrealLoader($call, await $request);
  }

  $async.Future<$1.UnrealLoaderReply> changeUnrealLoader(
      $grpc.ServiceCall call, $0.ChangeLoaderRequest request);

  $async.Stream<$1.UnrealAcquisitionProgress> acquireUnrealLoader_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.AcquireUnrealLoaderRequest> $request) async* {
    yield* acquireUnrealLoader($call, await $request);
  }

  $async.Stream<$1.UnrealAcquisitionProgress> acquireUnrealLoader(
      $grpc.ServiceCall call, $1.AcquireUnrealLoaderRequest request);

  $async.Future<$0.LoaderTextReply> readUnrealText_Pre($grpc.ServiceCall $call,
      $async.Future<$1.UnrealTextRequest> $request) async {
    return readUnrealText($call, await $request);
  }

  $async.Future<$0.LoaderTextReply> readUnrealText(
      $grpc.ServiceCall call, $1.UnrealTextRequest request);

  $async.Future<$0.LoaderTextReply> saveUnrealText_Pre($grpc.ServiceCall $call,
      $async.Future<$1.SaveUnrealTextRequest> $request) async {
    return saveUnrealText($call, await $request);
  }

  $async.Future<$0.LoaderTextReply> saveUnrealText(
      $grpc.ServiceCall call, $1.SaveUnrealTextRequest request);

  $async.Future<$1.UnrealPageReply> openUnrealLoaderPage_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoaderRequest> $request) async {
    return openUnrealLoaderPage($call, await $request);
  }

  $async.Future<$1.UnrealPageReply> openUnrealLoaderPage(
      $grpc.ServiceCall call, $0.LoaderRequest request);
}
