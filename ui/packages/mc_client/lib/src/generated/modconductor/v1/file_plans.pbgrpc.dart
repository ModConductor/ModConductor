// This is a generated file - do not edit.
//
// Generated from modconductor/v1/file_plans.proto.

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

import 'file_plans.pb.dart' as $0;

export 'file_plans.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.FilePlanOperations')
class FilePlanOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  FilePlanOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.FilePlanReply> openFilePlan(
    $0.OpenFilePlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openFilePlan, request, options: options);
  }

  $grpc.ResponseStream<$0.FilePlanLoadEvent> acquireFilePlan(
    $0.AcquireFilePlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$acquireFilePlan, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.FilePlanReply> readFilePlan(
    $0.FilePlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readFilePlan, request, options: options);
  }

  $grpc.ResponseFuture<$0.FilePlanPageReply> readFilePlanChildren(
    $0.FilePlanChildrenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readFilePlanChildren, request, options: options);
  }

  $grpc.ResponseFuture<$0.FilePlanProblemsReply> readFilePlanProblems(
    $0.FilePlanProblemsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readFilePlanProblems, request, options: options);
  }

  $grpc.ResponseFuture<$0.FilePlanInspectionReply> inspectFilePlanTarget(
    $0.InspectFilePlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectFilePlanTarget, request, options: options);
  }

  $grpc.ResponseFuture<$0.FilePlanInspectionReply> inspectSavedFile(
    $0.InspectSavedFileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$inspectSavedFile, request, options: options);
  }

  $grpc.ResponseFuture<$0.FileVisibilityReply> changeFileVisibility(
    $0.ChangeFileVisibilityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeFileVisibility, request, options: options);
  }

  $grpc.ResponseFuture<$0.FileVisibilityHistoryReply> readFileVisibilityHistory(
    $0.FileVisibilityHistoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readFileVisibilityHistory, request,
        options: options);
  }

  // method descriptors

  static final _$openFilePlan =
      $grpc.ClientMethod<$0.OpenFilePlanRequest, $0.FilePlanReply>(
          '/modconductor.v1.FilePlanOperations/OpenFilePlan',
          ($0.OpenFilePlanRequest value) => value.writeToBuffer(),
          $0.FilePlanReply.fromBuffer);
  static final _$acquireFilePlan =
      $grpc.ClientMethod<$0.AcquireFilePlanRequest, $0.FilePlanLoadEvent>(
          '/modconductor.v1.FilePlanOperations/AcquireFilePlan',
          ($0.AcquireFilePlanRequest value) => value.writeToBuffer(),
          $0.FilePlanLoadEvent.fromBuffer);
  static final _$readFilePlan =
      $grpc.ClientMethod<$0.FilePlanRequest, $0.FilePlanReply>(
          '/modconductor.v1.FilePlanOperations/ReadFilePlan',
          ($0.FilePlanRequest value) => value.writeToBuffer(),
          $0.FilePlanReply.fromBuffer);
  static final _$readFilePlanChildren =
      $grpc.ClientMethod<$0.FilePlanChildrenRequest, $0.FilePlanPageReply>(
          '/modconductor.v1.FilePlanOperations/ReadFilePlanChildren',
          ($0.FilePlanChildrenRequest value) => value.writeToBuffer(),
          $0.FilePlanPageReply.fromBuffer);
  static final _$readFilePlanProblems =
      $grpc.ClientMethod<$0.FilePlanProblemsRequest, $0.FilePlanProblemsReply>(
          '/modconductor.v1.FilePlanOperations/ReadFilePlanProblems',
          ($0.FilePlanProblemsRequest value) => value.writeToBuffer(),
          $0.FilePlanProblemsReply.fromBuffer);
  static final _$inspectFilePlanTarget =
      $grpc.ClientMethod<$0.InspectFilePlanRequest, $0.FilePlanInspectionReply>(
          '/modconductor.v1.FilePlanOperations/InspectFilePlanTarget',
          ($0.InspectFilePlanRequest value) => value.writeToBuffer(),
          $0.FilePlanInspectionReply.fromBuffer);
  static final _$inspectSavedFile = $grpc.ClientMethod<
          $0.InspectSavedFileRequest, $0.FilePlanInspectionReply>(
      '/modconductor.v1.FilePlanOperations/InspectSavedFile',
      ($0.InspectSavedFileRequest value) => value.writeToBuffer(),
      $0.FilePlanInspectionReply.fromBuffer);
  static final _$changeFileVisibility = $grpc.ClientMethod<
          $0.ChangeFileVisibilityRequest, $0.FileVisibilityReply>(
      '/modconductor.v1.FilePlanOperations/ChangeFileVisibility',
      ($0.ChangeFileVisibilityRequest value) => value.writeToBuffer(),
      $0.FileVisibilityReply.fromBuffer);
  static final _$readFileVisibilityHistory = $grpc.ClientMethod<
          $0.FileVisibilityHistoryRequest, $0.FileVisibilityHistoryReply>(
      '/modconductor.v1.FilePlanOperations/ReadFileVisibilityHistory',
      ($0.FileVisibilityHistoryRequest value) => value.writeToBuffer(),
      $0.FileVisibilityHistoryReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.FilePlanOperations')
abstract class FilePlanOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.FilePlanOperations';

  FilePlanOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.OpenFilePlanRequest, $0.FilePlanReply>(
        'OpenFilePlan',
        openFilePlan_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.OpenFilePlanRequest.fromBuffer(value),
        ($0.FilePlanReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.AcquireFilePlanRequest, $0.FilePlanLoadEvent>(
            'AcquireFilePlan',
            acquireFilePlan_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.AcquireFilePlanRequest.fromBuffer(value),
            ($0.FilePlanLoadEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FilePlanRequest, $0.FilePlanReply>(
        'ReadFilePlan',
        readFilePlan_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FilePlanRequest.fromBuffer(value),
        ($0.FilePlanReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.FilePlanChildrenRequest, $0.FilePlanPageReply>(
            'ReadFilePlanChildren',
            readFilePlanChildren_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.FilePlanChildrenRequest.fromBuffer(value),
            ($0.FilePlanPageReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FilePlanProblemsRequest,
            $0.FilePlanProblemsReply>(
        'ReadFilePlanProblems',
        readFilePlanProblems_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.FilePlanProblemsRequest.fromBuffer(value),
        ($0.FilePlanProblemsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InspectFilePlanRequest,
            $0.FilePlanInspectionReply>(
        'InspectFilePlanTarget',
        inspectFilePlanTarget_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InspectFilePlanRequest.fromBuffer(value),
        ($0.FilePlanInspectionReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InspectSavedFileRequest,
            $0.FilePlanInspectionReply>(
        'InspectSavedFile',
        inspectSavedFile_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InspectSavedFileRequest.fromBuffer(value),
        ($0.FilePlanInspectionReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangeFileVisibilityRequest,
            $0.FileVisibilityReply>(
        'ChangeFileVisibility',
        changeFileVisibility_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangeFileVisibilityRequest.fromBuffer(value),
        ($0.FileVisibilityReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FileVisibilityHistoryRequest,
            $0.FileVisibilityHistoryReply>(
        'ReadFileVisibilityHistory',
        readFileVisibilityHistory_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.FileVisibilityHistoryRequest.fromBuffer(value),
        ($0.FileVisibilityHistoryReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.FilePlanReply> openFilePlan_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OpenFilePlanRequest> $request) async {
    return openFilePlan($call, await $request);
  }

  $async.Future<$0.FilePlanReply> openFilePlan(
      $grpc.ServiceCall call, $0.OpenFilePlanRequest request);

  $async.Stream<$0.FilePlanLoadEvent> acquireFilePlan_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AcquireFilePlanRequest> $request) async* {
    yield* acquireFilePlan($call, await $request);
  }

  $async.Stream<$0.FilePlanLoadEvent> acquireFilePlan(
      $grpc.ServiceCall call, $0.AcquireFilePlanRequest request);

  $async.Future<$0.FilePlanReply> readFilePlan_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FilePlanRequest> $request) async {
    return readFilePlan($call, await $request);
  }

  $async.Future<$0.FilePlanReply> readFilePlan(
      $grpc.ServiceCall call, $0.FilePlanRequest request);

  $async.Future<$0.FilePlanPageReply> readFilePlanChildren_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FilePlanChildrenRequest> $request) async {
    return readFilePlanChildren($call, await $request);
  }

  $async.Future<$0.FilePlanPageReply> readFilePlanChildren(
      $grpc.ServiceCall call, $0.FilePlanChildrenRequest request);

  $async.Future<$0.FilePlanProblemsReply> readFilePlanProblems_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FilePlanProblemsRequest> $request) async {
    return readFilePlanProblems($call, await $request);
  }

  $async.Future<$0.FilePlanProblemsReply> readFilePlanProblems(
      $grpc.ServiceCall call, $0.FilePlanProblemsRequest request);

  $async.Future<$0.FilePlanInspectionReply> inspectFilePlanTarget_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InspectFilePlanRequest> $request) async {
    return inspectFilePlanTarget($call, await $request);
  }

  $async.Future<$0.FilePlanInspectionReply> inspectFilePlanTarget(
      $grpc.ServiceCall call, $0.InspectFilePlanRequest request);

  $async.Future<$0.FilePlanInspectionReply> inspectSavedFile_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InspectSavedFileRequest> $request) async {
    return inspectSavedFile($call, await $request);
  }

  $async.Future<$0.FilePlanInspectionReply> inspectSavedFile(
      $grpc.ServiceCall call, $0.InspectSavedFileRequest request);

  $async.Future<$0.FileVisibilityReply> changeFileVisibility_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangeFileVisibilityRequest> $request) async {
    return changeFileVisibility($call, await $request);
  }

  $async.Future<$0.FileVisibilityReply> changeFileVisibility(
      $grpc.ServiceCall call, $0.ChangeFileVisibilityRequest request);

  $async.Future<$0.FileVisibilityHistoryReply> readFileVisibilityHistory_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FileVisibilityHistoryRequest> $request) async {
    return readFileVisibilityHistory($call, await $request);
  }

  $async.Future<$0.FileVisibilityHistoryReply> readFileVisibilityHistory(
      $grpc.ServiceCall call, $0.FileVisibilityHistoryRequest request);
}
