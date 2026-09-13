// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus.proto.

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

import 'nexus.pb.dart' as $0;

export 'nexus.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.Nexus')
class NexusClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NexusClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.NexusAccountStatus> readNexusStatus(
    $0.NexusStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readNexusStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusAccountStatus> beginNexusSignIn(
    $0.NexusStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$beginNexusSignIn, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusAccountStatus> cancelNexusSignIn(
    $0.NexusStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelNexusSignIn, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusAccountStatus> connectNexus(
    $0.NexusStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$connectNexus, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusAccountStatus> checkNexusAccount(
    $0.NexusStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkNexusAccount, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusModReply> readNexusMod(
    $0.NexusModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readNexusMod, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusDownloadReply> downloadNexusFile(
    $0.NexusDownloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$downloadNexusFile, request, options: options);
  }

  $grpc.ResponseFuture<$0.NexusStatusRequest> openNexusModPage(
    $0.NexusModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openNexusModPage, request, options: options);
  }

  // method descriptors

  static final _$readNexusStatus =
      $grpc.ClientMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
          '/modconductor.v1.Nexus/ReadNexusStatus',
          ($0.NexusStatusRequest value) => value.writeToBuffer(),
          $0.NexusAccountStatus.fromBuffer);
  static final _$beginNexusSignIn =
      $grpc.ClientMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
          '/modconductor.v1.Nexus/BeginNexusSignIn',
          ($0.NexusStatusRequest value) => value.writeToBuffer(),
          $0.NexusAccountStatus.fromBuffer);
  static final _$cancelNexusSignIn =
      $grpc.ClientMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
          '/modconductor.v1.Nexus/CancelNexusSignIn',
          ($0.NexusStatusRequest value) => value.writeToBuffer(),
          $0.NexusAccountStatus.fromBuffer);
  static final _$connectNexus =
      $grpc.ClientMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
          '/modconductor.v1.Nexus/ConnectNexus',
          ($0.NexusStatusRequest value) => value.writeToBuffer(),
          $0.NexusAccountStatus.fromBuffer);
  static final _$checkNexusAccount =
      $grpc.ClientMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
          '/modconductor.v1.Nexus/CheckNexusAccount',
          ($0.NexusStatusRequest value) => value.writeToBuffer(),
          $0.NexusAccountStatus.fromBuffer);
  static final _$readNexusMod =
      $grpc.ClientMethod<$0.NexusModRequest, $0.NexusModReply>(
          '/modconductor.v1.Nexus/ReadNexusMod',
          ($0.NexusModRequest value) => value.writeToBuffer(),
          $0.NexusModReply.fromBuffer);
  static final _$downloadNexusFile =
      $grpc.ClientMethod<$0.NexusDownloadRequest, $0.NexusDownloadReply>(
          '/modconductor.v1.Nexus/DownloadNexusFile',
          ($0.NexusDownloadRequest value) => value.writeToBuffer(),
          $0.NexusDownloadReply.fromBuffer);
  static final _$openNexusModPage =
      $grpc.ClientMethod<$0.NexusModRequest, $0.NexusStatusRequest>(
          '/modconductor.v1.Nexus/OpenNexusModPage',
          ($0.NexusModRequest value) => value.writeToBuffer(),
          $0.NexusStatusRequest.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.Nexus')
abstract class NexusServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.Nexus';

  NexusServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
            'ReadNexusStatus',
            readNexusStatus_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusStatusRequest.fromBuffer(value),
            ($0.NexusAccountStatus value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
            'BeginNexusSignIn',
            beginNexusSignIn_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusStatusRequest.fromBuffer(value),
            ($0.NexusAccountStatus value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
            'CancelNexusSignIn',
            cancelNexusSignIn_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusStatusRequest.fromBuffer(value),
            ($0.NexusAccountStatus value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
            'ConnectNexus',
            connectNexus_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusStatusRequest.fromBuffer(value),
            ($0.NexusAccountStatus value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.NexusStatusRequest, $0.NexusAccountStatus>(
            'CheckNexusAccount',
            checkNexusAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusStatusRequest.fromBuffer(value),
            ($0.NexusAccountStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NexusModRequest, $0.NexusModReply>(
        'ReadNexusMod',
        readNexusMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NexusModRequest.fromBuffer(value),
        ($0.NexusModReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.NexusDownloadRequest, $0.NexusDownloadReply>(
            'DownloadNexusFile',
            downloadNexusFile_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.NexusDownloadRequest.fromBuffer(value),
            ($0.NexusDownloadReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NexusModRequest, $0.NexusStatusRequest>(
        'OpenNexusModPage',
        openNexusModPage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NexusModRequest.fromBuffer(value),
        ($0.NexusStatusRequest value) => value.writeToBuffer()));
  }

  $async.Future<$0.NexusAccountStatus> readNexusStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusStatusRequest> $request) async {
    return readNexusStatus($call, await $request);
  }

  $async.Future<$0.NexusAccountStatus> readNexusStatus(
      $grpc.ServiceCall call, $0.NexusStatusRequest request);

  $async.Future<$0.NexusAccountStatus> beginNexusSignIn_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusStatusRequest> $request) async {
    return beginNexusSignIn($call, await $request);
  }

  $async.Future<$0.NexusAccountStatus> beginNexusSignIn(
      $grpc.ServiceCall call, $0.NexusStatusRequest request);

  $async.Future<$0.NexusAccountStatus> cancelNexusSignIn_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusStatusRequest> $request) async {
    return cancelNexusSignIn($call, await $request);
  }

  $async.Future<$0.NexusAccountStatus> cancelNexusSignIn(
      $grpc.ServiceCall call, $0.NexusStatusRequest request);

  $async.Future<$0.NexusAccountStatus> connectNexus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.NexusStatusRequest> $request) async {
    return connectNexus($call, await $request);
  }

  $async.Future<$0.NexusAccountStatus> connectNexus(
      $grpc.ServiceCall call, $0.NexusStatusRequest request);

  $async.Future<$0.NexusAccountStatus> checkNexusAccount_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusStatusRequest> $request) async {
    return checkNexusAccount($call, await $request);
  }

  $async.Future<$0.NexusAccountStatus> checkNexusAccount(
      $grpc.ServiceCall call, $0.NexusStatusRequest request);

  $async.Future<$0.NexusModReply> readNexusMod_Pre($grpc.ServiceCall $call,
      $async.Future<$0.NexusModRequest> $request) async {
    return readNexusMod($call, await $request);
  }

  $async.Future<$0.NexusModReply> readNexusMod(
      $grpc.ServiceCall call, $0.NexusModRequest request);

  $async.Future<$0.NexusDownloadReply> downloadNexusFile_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusDownloadRequest> $request) async {
    return downloadNexusFile($call, await $request);
  }

  $async.Future<$0.NexusDownloadReply> downloadNexusFile(
      $grpc.ServiceCall call, $0.NexusDownloadRequest request);

  $async.Future<$0.NexusStatusRequest> openNexusModPage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.NexusModRequest> $request) async {
    return openNexusModPage($call, await $request);
  }

  $async.Future<$0.NexusStatusRequest> openNexusModPage(
      $grpc.ServiceCall call, $0.NexusModRequest request);
}
