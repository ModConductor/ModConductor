// This is a generated file - do not edit.
//
// Generated from modconductor/v1/diagnostics.proto.

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

import 'diagnostics.pb.dart' as $0;

export 'diagnostics.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.DiagnosticOperations')
class DiagnosticOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DiagnosticOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.DiagnosticSnapshotReply> checkDiagnostics(
    $0.DiagnosticRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkDiagnostics, request, options: options);
  }

  $grpc.ResponseFuture<$0.DiagnosticPreviewReply> previewDiagnosticChange(
    $0.DiagnosticPreviewRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewDiagnosticChange, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.DiagnosticApplyReply> applyDiagnosticChange(
    $0.DiagnosticApplyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyDiagnosticChange, request, options: options);
  }

  $grpc.ResponseFuture<$0.DiagnosticSupportReply> exportDiagnosticSupport(
    $0.DiagnosticSnapshotReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exportDiagnosticSupport, request,
        options: options);
  }

  // method descriptors

  static final _$checkDiagnostics =
      $grpc.ClientMethod<$0.DiagnosticRequest, $0.DiagnosticSnapshotReply>(
          '/modconductor.v1.DiagnosticOperations/CheckDiagnostics',
          ($0.DiagnosticRequest value) => value.writeToBuffer(),
          $0.DiagnosticSnapshotReply.fromBuffer);
  static final _$previewDiagnosticChange = $grpc.ClientMethod<
          $0.DiagnosticPreviewRequest, $0.DiagnosticPreviewReply>(
      '/modconductor.v1.DiagnosticOperations/PreviewDiagnosticChange',
      ($0.DiagnosticPreviewRequest value) => value.writeToBuffer(),
      $0.DiagnosticPreviewReply.fromBuffer);
  static final _$applyDiagnosticChange =
      $grpc.ClientMethod<$0.DiagnosticApplyRequest, $0.DiagnosticApplyReply>(
          '/modconductor.v1.DiagnosticOperations/ApplyDiagnosticChange',
          ($0.DiagnosticApplyRequest value) => value.writeToBuffer(),
          $0.DiagnosticApplyReply.fromBuffer);
  static final _$exportDiagnosticSupport = $grpc.ClientMethod<
          $0.DiagnosticSnapshotReference, $0.DiagnosticSupportReply>(
      '/modconductor.v1.DiagnosticOperations/ExportDiagnosticSupport',
      ($0.DiagnosticSnapshotReference value) => value.writeToBuffer(),
      $0.DiagnosticSupportReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.DiagnosticOperations')
abstract class DiagnosticOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.DiagnosticOperations';

  DiagnosticOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.DiagnosticRequest, $0.DiagnosticSnapshotReply>(
            'CheckDiagnostics',
            checkDiagnostics_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DiagnosticRequest.fromBuffer(value),
            ($0.DiagnosticSnapshotReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DiagnosticPreviewRequest,
            $0.DiagnosticPreviewReply>(
        'PreviewDiagnosticChange',
        previewDiagnosticChange_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DiagnosticPreviewRequest.fromBuffer(value),
        ($0.DiagnosticPreviewReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DiagnosticApplyRequest, $0.DiagnosticApplyReply>(
            'ApplyDiagnosticChange',
            applyDiagnosticChange_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DiagnosticApplyRequest.fromBuffer(value),
            ($0.DiagnosticApplyReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DiagnosticSnapshotReference,
            $0.DiagnosticSupportReply>(
        'ExportDiagnosticSupport',
        exportDiagnosticSupport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DiagnosticSnapshotReference.fromBuffer(value),
        ($0.DiagnosticSupportReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.DiagnosticSnapshotReply> checkDiagnostics_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiagnosticRequest> $request) async {
    return checkDiagnostics($call, await $request);
  }

  $async.Future<$0.DiagnosticSnapshotReply> checkDiagnostics(
      $grpc.ServiceCall call, $0.DiagnosticRequest request);

  $async.Future<$0.DiagnosticPreviewReply> previewDiagnosticChange_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiagnosticPreviewRequest> $request) async {
    return previewDiagnosticChange($call, await $request);
  }

  $async.Future<$0.DiagnosticPreviewReply> previewDiagnosticChange(
      $grpc.ServiceCall call, $0.DiagnosticPreviewRequest request);

  $async.Future<$0.DiagnosticApplyReply> applyDiagnosticChange_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiagnosticApplyRequest> $request) async {
    return applyDiagnosticChange($call, await $request);
  }

  $async.Future<$0.DiagnosticApplyReply> applyDiagnosticChange(
      $grpc.ServiceCall call, $0.DiagnosticApplyRequest request);

  $async.Future<$0.DiagnosticSupportReply> exportDiagnosticSupport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiagnosticSnapshotReference> $request) async {
    return exportDiagnosticSupport($call, await $request);
  }

  $async.Future<$0.DiagnosticSupportReply> exportDiagnosticSupport(
      $grpc.ServiceCall call, $0.DiagnosticSnapshotReference request);
}
