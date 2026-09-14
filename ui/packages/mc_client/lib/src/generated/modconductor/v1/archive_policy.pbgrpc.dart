// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_policy.proto.

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

import 'archive_policy.pb.dart' as $0;
import 'profile_data.pb.dart' as $1;

export 'archive_policy.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ArchivePolicies')
class ArchivePoliciesClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ArchivePoliciesClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ArchivePolicyReply> scanArchivePolicy(
    $0.ScanArchivePolicyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$scanArchivePolicy, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchivePolicyReply> readArchivePolicy(
    $0.ReadArchivePolicyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readArchivePolicy, request, options: options);
  }

  $grpc.ResponseStream<$1.ProfileDataEvent> applyArchivePolicy(
    $0.ApplyArchivePolicyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$applyArchivePolicy, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$1.ProfileDataEvent> restoreArchivePolicy(
    $0.RestoreArchivePolicyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$restoreArchivePolicy, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$scanArchivePolicy =
      $grpc.ClientMethod<$0.ScanArchivePolicyRequest, $0.ArchivePolicyReply>(
          '/modconductor.v1.ArchivePolicies/ScanArchivePolicy',
          ($0.ScanArchivePolicyRequest value) => value.writeToBuffer(),
          $0.ArchivePolicyReply.fromBuffer);
  static final _$readArchivePolicy =
      $grpc.ClientMethod<$0.ReadArchivePolicyRequest, $0.ArchivePolicyReply>(
          '/modconductor.v1.ArchivePolicies/ReadArchivePolicy',
          ($0.ReadArchivePolicyRequest value) => value.writeToBuffer(),
          $0.ArchivePolicyReply.fromBuffer);
  static final _$applyArchivePolicy =
      $grpc.ClientMethod<$0.ApplyArchivePolicyRequest, $1.ProfileDataEvent>(
          '/modconductor.v1.ArchivePolicies/ApplyArchivePolicy',
          ($0.ApplyArchivePolicyRequest value) => value.writeToBuffer(),
          $1.ProfileDataEvent.fromBuffer);
  static final _$restoreArchivePolicy =
      $grpc.ClientMethod<$0.RestoreArchivePolicyRequest, $1.ProfileDataEvent>(
          '/modconductor.v1.ArchivePolicies/RestoreArchivePolicy',
          ($0.RestoreArchivePolicyRequest value) => value.writeToBuffer(),
          $1.ProfileDataEvent.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ArchivePolicies')
abstract class ArchivePoliciesServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ArchivePolicies';

  ArchivePoliciesServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ScanArchivePolicyRequest, $0.ArchivePolicyReply>(
            'ScanArchivePolicy',
            scanArchivePolicy_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ScanArchivePolicyRequest.fromBuffer(value),
            ($0.ArchivePolicyReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReadArchivePolicyRequest, $0.ArchivePolicyReply>(
            'ReadArchivePolicy',
            readArchivePolicy_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadArchivePolicyRequest.fromBuffer(value),
            ($0.ArchivePolicyReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ApplyArchivePolicyRequest, $1.ProfileDataEvent>(
            'ApplyArchivePolicy',
            applyArchivePolicy_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ApplyArchivePolicyRequest.fromBuffer(value),
            ($1.ProfileDataEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RestoreArchivePolicyRequest,
            $1.ProfileDataEvent>(
        'RestoreArchivePolicy',
        restoreArchivePolicy_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.RestoreArchivePolicyRequest.fromBuffer(value),
        ($1.ProfileDataEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.ArchivePolicyReply> scanArchivePolicy_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ScanArchivePolicyRequest> $request) async {
    return scanArchivePolicy($call, await $request);
  }

  $async.Future<$0.ArchivePolicyReply> scanArchivePolicy(
      $grpc.ServiceCall call, $0.ScanArchivePolicyRequest request);

  $async.Future<$0.ArchivePolicyReply> readArchivePolicy_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReadArchivePolicyRequest> $request) async {
    return readArchivePolicy($call, await $request);
  }

  $async.Future<$0.ArchivePolicyReply> readArchivePolicy(
      $grpc.ServiceCall call, $0.ReadArchivePolicyRequest request);

  $async.Stream<$1.ProfileDataEvent> applyArchivePolicy_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ApplyArchivePolicyRequest> $request) async* {
    yield* applyArchivePolicy($call, await $request);
  }

  $async.Stream<$1.ProfileDataEvent> applyArchivePolicy(
      $grpc.ServiceCall call, $0.ApplyArchivePolicyRequest request);

  $async.Stream<$1.ProfileDataEvent> restoreArchivePolicy_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RestoreArchivePolicyRequest> $request) async* {
    yield* restoreArchivePolicy($call, await $request);
  }

  $async.Stream<$1.ProfileDataEvent> restoreArchivePolicy(
      $grpc.ServiceCall call, $0.RestoreArchivePolicyRequest request);
}
