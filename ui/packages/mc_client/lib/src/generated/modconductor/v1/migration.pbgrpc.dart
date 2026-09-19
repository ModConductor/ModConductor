// This is a generated file - do not edit.
//
// Generated from modconductor/v1/migration.proto.

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

import 'migration.pb.dart' as $0;

export 'migration.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.MigrationOperations')
class MigrationOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MigrationOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ProfileList> profiles(
    $0.ProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$profiles, request, options: options);
  }

  $grpc.ResponseStream<$0.MigrationEvent> migrate(
    $0.MigrationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$migrate, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$profiles =
      $grpc.ClientMethod<$0.ProfileRequest, $0.ProfileList>(
          '/modconductor.v1.MigrationOperations/Profiles',
          ($0.ProfileRequest value) => value.writeToBuffer(),
          $0.ProfileList.fromBuffer);
  static final _$migrate =
      $grpc.ClientMethod<$0.MigrationRequest, $0.MigrationEvent>(
          '/modconductor.v1.MigrationOperations/Migrate',
          ($0.MigrationRequest value) => value.writeToBuffer(),
          $0.MigrationEvent.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.MigrationOperations')
abstract class MigrationOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.MigrationOperations';

  MigrationOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ProfileRequest, $0.ProfileList>(
        'Profiles',
        profiles_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ProfileRequest.fromBuffer(value),
        ($0.ProfileList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MigrationRequest, $0.MigrationEvent>(
        'Migrate',
        migrate_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.MigrationRequest.fromBuffer(value),
        ($0.MigrationEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.ProfileList> profiles_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProfileRequest> $request) async {
    return profiles($call, await $request);
  }

  $async.Future<$0.ProfileList> profiles(
      $grpc.ServiceCall call, $0.ProfileRequest request);

  $async.Stream<$0.MigrationEvent> migrate_Pre($grpc.ServiceCall $call,
      $async.Future<$0.MigrationRequest> $request) async* {
    yield* migrate($call, await $request);
  }

  $async.Stream<$0.MigrationEvent> migrate(
      $grpc.ServiceCall call, $0.MigrationRequest request);
}
