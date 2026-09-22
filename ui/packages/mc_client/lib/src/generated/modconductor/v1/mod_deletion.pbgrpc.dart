// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_deletion.proto.

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

import 'mod_deletion.pb.dart' as $0;

export 'mod_deletion.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ModDeletion')
class ModDeletionClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ModDeletionClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ModDeletionPreview> prepareModDeletion(
    $0.PrepareModDeletionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$prepareModDeletion, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModDeleted> deleteMod(
    $0.DeleteModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteMod, request, options: options);
  }

  // method descriptors

  static final _$prepareModDeletion =
      $grpc.ClientMethod<$0.PrepareModDeletionRequest, $0.ModDeletionPreview>(
          '/modconductor.v1.ModDeletion/PrepareModDeletion',
          ($0.PrepareModDeletionRequest value) => value.writeToBuffer(),
          $0.ModDeletionPreview.fromBuffer);
  static final _$deleteMod =
      $grpc.ClientMethod<$0.DeleteModRequest, $0.ModDeleted>(
          '/modconductor.v1.ModDeletion/DeleteMod',
          ($0.DeleteModRequest value) => value.writeToBuffer(),
          $0.ModDeleted.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ModDeletion')
abstract class ModDeletionServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ModDeletion';

  ModDeletionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PrepareModDeletionRequest,
            $0.ModDeletionPreview>(
        'PrepareModDeletion',
        prepareModDeletion_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PrepareModDeletionRequest.fromBuffer(value),
        ($0.ModDeletionPreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteModRequest, $0.ModDeleted>(
        'DeleteMod',
        deleteMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteModRequest.fromBuffer(value),
        ($0.ModDeleted value) => value.writeToBuffer()));
  }

  $async.Future<$0.ModDeletionPreview> prepareModDeletion_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PrepareModDeletionRequest> $request) async {
    return prepareModDeletion($call, await $request);
  }

  $async.Future<$0.ModDeletionPreview> prepareModDeletion(
      $grpc.ServiceCall call, $0.PrepareModDeletionRequest request);

  $async.Future<$0.ModDeleted> deleteMod_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteModRequest> $request) async {
    return deleteMod($call, await $request);
  }

  $async.Future<$0.ModDeleted> deleteMod(
      $grpc.ServiceCall call, $0.DeleteModRequest request);
}
