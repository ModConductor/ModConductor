// This is a generated file - do not edit.
//
// Generated from modconductor/v1/inventory_export.proto.

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

import 'inventory_export.pb.dart' as $0;

export 'inventory_export.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.InventoryExportOperations')
class InventoryExportOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  InventoryExportOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.PrepareInventoryExportReply> prepareInventoryExport(
    $0.PrepareInventoryExportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$prepareInventoryExport, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.InspectInventoryExportDestinationReply>
      inspectInventoryExportDestination(
    $0.InspectInventoryExportDestinationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectInventoryExportDestination, request,
        options: options);
  }

  $grpc.ResponseStream<$0.InventoryExportEvent> writeInventoryExport(
    $0.WriteInventoryExportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$writeInventoryExport, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.CancelInventoryExportReply> cancelInventoryExport(
    $0.CancelInventoryExportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelInventoryExport, request, options: options);
  }

  $grpc.ResponseFuture<$0.DiscardInventoryExportReply> discardInventoryExport(
    $0.DiscardInventoryExportRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$discardInventoryExport, request,
        options: options);
  }

  // method descriptors

  static final _$prepareInventoryExport = $grpc.ClientMethod<
          $0.PrepareInventoryExportRequest, $0.PrepareInventoryExportReply>(
      '/modconductor.v1.InventoryExportOperations/PrepareInventoryExport',
      ($0.PrepareInventoryExportRequest value) => value.writeToBuffer(),
      $0.PrepareInventoryExportReply.fromBuffer);
  static final _$inspectInventoryExportDestination = $grpc.ClientMethod<
          $0.InspectInventoryExportDestinationRequest,
          $0.InspectInventoryExportDestinationReply>(
      '/modconductor.v1.InventoryExportOperations/InspectInventoryExportDestination',
      ($0.InspectInventoryExportDestinationRequest value) =>
          value.writeToBuffer(),
      $0.InspectInventoryExportDestinationReply.fromBuffer);
  static final _$writeInventoryExport = $grpc.ClientMethod<
          $0.WriteInventoryExportRequest, $0.InventoryExportEvent>(
      '/modconductor.v1.InventoryExportOperations/WriteInventoryExport',
      ($0.WriteInventoryExportRequest value) => value.writeToBuffer(),
      $0.InventoryExportEvent.fromBuffer);
  static final _$cancelInventoryExport = $grpc.ClientMethod<
          $0.CancelInventoryExportRequest, $0.CancelInventoryExportReply>(
      '/modconductor.v1.InventoryExportOperations/CancelInventoryExport',
      ($0.CancelInventoryExportRequest value) => value.writeToBuffer(),
      $0.CancelInventoryExportReply.fromBuffer);
  static final _$discardInventoryExport = $grpc.ClientMethod<
          $0.DiscardInventoryExportRequest, $0.DiscardInventoryExportReply>(
      '/modconductor.v1.InventoryExportOperations/DiscardInventoryExport',
      ($0.DiscardInventoryExportRequest value) => value.writeToBuffer(),
      $0.DiscardInventoryExportReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.InventoryExportOperations')
abstract class InventoryExportOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.InventoryExportOperations';

  InventoryExportOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PrepareInventoryExportRequest,
            $0.PrepareInventoryExportReply>(
        'PrepareInventoryExport',
        prepareInventoryExport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PrepareInventoryExportRequest.fromBuffer(value),
        ($0.PrepareInventoryExportReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InspectInventoryExportDestinationRequest,
            $0.InspectInventoryExportDestinationReply>(
        'InspectInventoryExportDestination',
        inspectInventoryExportDestination_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InspectInventoryExportDestinationRequest.fromBuffer(value),
        ($0.InspectInventoryExportDestinationReply value) =>
            value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WriteInventoryExportRequest,
            $0.InventoryExportEvent>(
        'WriteInventoryExport',
        writeInventoryExport_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WriteInventoryExportRequest.fromBuffer(value),
        ($0.InventoryExportEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelInventoryExportRequest,
            $0.CancelInventoryExportReply>(
        'CancelInventoryExport',
        cancelInventoryExport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CancelInventoryExportRequest.fromBuffer(value),
        ($0.CancelInventoryExportReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DiscardInventoryExportRequest,
            $0.DiscardInventoryExportReply>(
        'DiscardInventoryExport',
        discardInventoryExport_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DiscardInventoryExportRequest.fromBuffer(value),
        ($0.DiscardInventoryExportReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.PrepareInventoryExportReply> prepareInventoryExport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PrepareInventoryExportRequest> $request) async {
    return prepareInventoryExport($call, await $request);
  }

  $async.Future<$0.PrepareInventoryExportReply> prepareInventoryExport(
      $grpc.ServiceCall call, $0.PrepareInventoryExportRequest request);

  $async.Future<$0.InspectInventoryExportDestinationReply>
      inspectInventoryExportDestination_Pre(
          $grpc.ServiceCall $call,
          $async.Future<$0.InspectInventoryExportDestinationRequest>
              $request) async {
    return inspectInventoryExportDestination($call, await $request);
  }

  $async.Future<$0.InspectInventoryExportDestinationReply>
      inspectInventoryExportDestination($grpc.ServiceCall call,
          $0.InspectInventoryExportDestinationRequest request);

  $async.Stream<$0.InventoryExportEvent> writeInventoryExport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WriteInventoryExportRequest> $request) async* {
    yield* writeInventoryExport($call, await $request);
  }

  $async.Stream<$0.InventoryExportEvent> writeInventoryExport(
      $grpc.ServiceCall call, $0.WriteInventoryExportRequest request);

  $async.Future<$0.CancelInventoryExportReply> cancelInventoryExport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CancelInventoryExportRequest> $request) async {
    return cancelInventoryExport($call, await $request);
  }

  $async.Future<$0.CancelInventoryExportReply> cancelInventoryExport(
      $grpc.ServiceCall call, $0.CancelInventoryExportRequest request);

  $async.Future<$0.DiscardInventoryExportReply> discardInventoryExport_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiscardInventoryExportRequest> $request) async {
    return discardInventoryExport($call, await $request);
  }

  $async.Future<$0.DiscardInventoryExportReply> discardInventoryExport(
      $grpc.ServiceCall call, $0.DiscardInventoryExportRequest request);
}
