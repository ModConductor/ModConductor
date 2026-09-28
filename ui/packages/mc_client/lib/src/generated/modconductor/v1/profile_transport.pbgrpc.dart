// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_transport.proto.

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

import 'profile_transport.pb.dart' as $0;

export 'profile_transport.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ProfileTransportOperations')
class ProfileTransportOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProfileTransportOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ProfileTransportPreview> inspectProfileTransport(
    $0.InspectProfileTransportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectProfileTransport, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ProfileTransportPreview>
      previewExportProfileTransport(
    $0.PreviewExportProfileTransportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewExportProfileTransport, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ProfileTransportResult> exportProfileTransport(
    $0.ExportProfileTransportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exportProfileTransport, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ProfileTransportResult> importProfileTransport(
    $0.ImportProfileTransportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$importProfileTransport, request,
        options: options);
  }

  // method descriptors

  static final _$inspectProfileTransport = $grpc.ClientMethod<
          $0.InspectProfileTransportRequest, $0.ProfileTransportPreview>(
      '/modconductor.v1.ProfileTransportOperations/InspectProfileTransport',
      ($0.InspectProfileTransportRequest value) => value.writeToBuffer(),
      $0.ProfileTransportPreview.fromBuffer);
  static final _$previewExportProfileTransport = $grpc.ClientMethod<
          $0.PreviewExportProfileTransportRequest, $0.ProfileTransportPreview>(
      '/modconductor.v1.ProfileTransportOperations/PreviewExportProfileTransport',
      ($0.PreviewExportProfileTransportRequest value) => value.writeToBuffer(),
      $0.ProfileTransportPreview.fromBuffer);
  static final _$exportProfileTransport = $grpc.ClientMethod<
          $0.ExportProfileTransportRequest, $0.ProfileTransportResult>(
      '/modconductor.v1.ProfileTransportOperations/ExportProfileTransport',
      ($0.ExportProfileTransportRequest value) => value.writeToBuffer(),
      $0.ProfileTransportResult.fromBuffer);
  static final _$importProfileTransport = $grpc.ClientMethod<
          $0.ImportProfileTransportRequest, $0.ProfileTransportResult>(
      '/modconductor.v1.ProfileTransportOperations/ImportProfileTransport',
      ($0.ImportProfileTransportRequest value) => value.writeToBuffer(),
      $0.ProfileTransportResult.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ProfileTransportOperations')
abstract class ProfileTransportOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ProfileTransportOperations';

  ProfileTransportOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.InspectProfileTransportRequest,
            $0.ProfileTransportPreview>(
        'InspectProfileTransport',
        inspectProfileTransport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InspectProfileTransportRequest.fromBuffer(value),
        ($0.ProfileTransportPreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PreviewExportProfileTransportRequest,
            $0.ProfileTransportPreview>(
        'PreviewExportProfileTransport',
        previewExportProfileTransport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PreviewExportProfileTransportRequest.fromBuffer(value),
        ($0.ProfileTransportPreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportProfileTransportRequest,
            $0.ProfileTransportResult>(
        'ExportProfileTransport',
        exportProfileTransport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExportProfileTransportRequest.fromBuffer(value),
        ($0.ProfileTransportResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ImportProfileTransportRequest,
            $0.ProfileTransportResult>(
        'ImportProfileTransport',
        importProfileTransport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ImportProfileTransportRequest.fromBuffer(value),
        ($0.ProfileTransportResult value) => value.writeToBuffer()));
  }

  $async.Future<$0.ProfileTransportPreview> inspectProfileTransport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InspectProfileTransportRequest> $request) async {
    return inspectProfileTransport($call, await $request);
  }

  $async.Future<$0.ProfileTransportPreview> inspectProfileTransport(
      $grpc.ServiceCall call, $0.InspectProfileTransportRequest request);

  $async.Future<$0.ProfileTransportPreview> previewExportProfileTransport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PreviewExportProfileTransportRequest> $request) async {
    return previewExportProfileTransport($call, await $request);
  }

  $async.Future<$0.ProfileTransportPreview> previewExportProfileTransport(
      $grpc.ServiceCall call, $0.PreviewExportProfileTransportRequest request);

  $async.Future<$0.ProfileTransportResult> exportProfileTransport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExportProfileTransportRequest> $request) async {
    return exportProfileTransport($call, await $request);
  }

  $async.Future<$0.ProfileTransportResult> exportProfileTransport(
      $grpc.ServiceCall call, $0.ExportProfileTransportRequest request);

  $async.Future<$0.ProfileTransportResult> importProfileTransport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ImportProfileTransportRequest> $request) async {
    return importProfileTransport($call, await $request);
  }

  $async.Future<$0.ProfileTransportResult> importProfileTransport(
      $grpc.ServiceCall call, $0.ImportProfileTransportRequest request);
}
