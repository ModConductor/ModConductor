// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_updates.proto.

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

import 'archive_installation.pb.dart' as $1;
import 'mod_updates.pb.dart' as $0;

export 'mod_updates.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ModUpdates')
class ModUpdatesClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ModUpdatesClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ModUpdatePreview> prepareModUpdate(
    $0.PrepareModUpdateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$prepareModUpdate, request, options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationStatus> startModUpdate(
    $0.StartModUpdateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startModUpdate, request, options: options);
  }

  // method descriptors

  static final _$prepareModUpdate =
      $grpc.ClientMethod<$0.PrepareModUpdateRequest, $0.ModUpdatePreview>(
          '/modconductor.v1.ModUpdates/PrepareModUpdate',
          ($0.PrepareModUpdateRequest value) => value.writeToBuffer(),
          $0.ModUpdatePreview.fromBuffer);
  static final _$startModUpdate = $grpc.ClientMethod<$0.StartModUpdateRequest,
          $1.ArchiveInstallationStatus>(
      '/modconductor.v1.ModUpdates/StartModUpdate',
      ($0.StartModUpdateRequest value) => value.writeToBuffer(),
      $1.ArchiveInstallationStatus.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ModUpdates')
abstract class ModUpdatesServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ModUpdates';

  ModUpdatesServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.PrepareModUpdateRequest, $0.ModUpdatePreview>(
            'PrepareModUpdate',
            prepareModUpdate_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PrepareModUpdateRequest.fromBuffer(value),
            ($0.ModUpdatePreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartModUpdateRequest,
            $1.ArchiveInstallationStatus>(
        'StartModUpdate',
        startModUpdate_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartModUpdateRequest.fromBuffer(value),
        ($1.ArchiveInstallationStatus value) => value.writeToBuffer()));
  }

  $async.Future<$0.ModUpdatePreview> prepareModUpdate_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PrepareModUpdateRequest> $request) async {
    return prepareModUpdate($call, await $request);
  }

  $async.Future<$0.ModUpdatePreview> prepareModUpdate(
      $grpc.ServiceCall call, $0.PrepareModUpdateRequest request);

  $async.Future<$1.ArchiveInstallationStatus> startModUpdate_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartModUpdateRequest> $request) async {
    return startModUpdate($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationStatus> startModUpdate(
      $grpc.ServiceCall call, $0.StartModUpdateRequest request);
}
