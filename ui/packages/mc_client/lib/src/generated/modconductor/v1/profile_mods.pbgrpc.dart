// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_mods.proto.

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

import 'profile_mods.pb.dart' as $0;

export 'profile_mods.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ProfileModOperations')
class ProfileModOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProfileModOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ProfileModsChangeReply> changeProfileMods(
    $0.ChangeProfileModsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeProfileMods, request, options: options);
  }

  // method descriptors

  static final _$changeProfileMods = $grpc.ClientMethod<
          $0.ChangeProfileModsRequest, $0.ProfileModsChangeReply>(
      '/modconductor.v1.ProfileModOperations/ChangeProfileMods',
      ($0.ChangeProfileModsRequest value) => value.writeToBuffer(),
      $0.ProfileModsChangeReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ProfileModOperations')
abstract class ProfileModOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ProfileModOperations';

  ProfileModOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ChangeProfileModsRequest,
            $0.ProfileModsChangeReply>(
        'ChangeProfileMods',
        changeProfileMods_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangeProfileModsRequest.fromBuffer(value),
        ($0.ProfileModsChangeReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.ProfileModsChangeReply> changeProfileMods_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangeProfileModsRequest> $request) async {
    return changeProfileMods($call, await $request);
  }

  $async.Future<$0.ProfileModsChangeReply> changeProfileMods(
      $grpc.ServiceCall call, $0.ChangeProfileModsRequest request);
}
