// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_installation.proto.

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
import 'artifacts.pb.dart' as $0;

export 'archive_installation.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ArchiveInstallation')
class ArchiveInstallationClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ArchiveInstallationClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.ArchiveInstallationDraft> prepareInstallation(
    $0.ArtifactReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$prepareInstallation, request, options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationDraft> changeInstallationLayout(
    $1.InstallationLayoutChange request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeInstallationLayout, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.InstallationDraftClosed> closeInstallationDraft(
    $1.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeInstallationDraft, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationStatus> startInstallation(
    $1.StartArchiveInstallation request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startInstallation, request, options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationList> recentInstallations(
    $1.InstallationWorkspace request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$recentInstallations, request, options: options);
  }

  $grpc.ResponseStream<$1.ArchiveInstallationStatus> watchInstallation(
    $1.InstallationReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchInstallation, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationStatus> cancelInstallation(
    $1.InstallationReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelInstallation, request, options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationStatus> deleteInstallationFiles(
    $1.InstallationReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteInstallationFiles, request,
        options: options);
  }

  // method descriptors

  static final _$prepareInstallation =
      $grpc.ClientMethod<$0.ArtifactReference, $1.ArchiveInstallationDraft>(
          '/modconductor.v1.ArchiveInstallation/PrepareInstallation',
          ($0.ArtifactReference value) => value.writeToBuffer(),
          $1.ArchiveInstallationDraft.fromBuffer);
  static final _$changeInstallationLayout = $grpc.ClientMethod<
          $1.InstallationLayoutChange, $1.ArchiveInstallationDraft>(
      '/modconductor.v1.ArchiveInstallation/ChangeInstallationLayout',
      ($1.InstallationLayoutChange value) => value.writeToBuffer(),
      $1.ArchiveInstallationDraft.fromBuffer);
  static final _$closeInstallationDraft = $grpc.ClientMethod<
          $1.InstallationDraftReference, $1.InstallationDraftClosed>(
      '/modconductor.v1.ArchiveInstallation/CloseInstallationDraft',
      ($1.InstallationDraftReference value) => value.writeToBuffer(),
      $1.InstallationDraftClosed.fromBuffer);
  static final _$startInstallation = $grpc.ClientMethod<
          $1.StartArchiveInstallation, $1.ArchiveInstallationStatus>(
      '/modconductor.v1.ArchiveInstallation/StartInstallation',
      ($1.StartArchiveInstallation value) => value.writeToBuffer(),
      $1.ArchiveInstallationStatus.fromBuffer);
  static final _$recentInstallations =
      $grpc.ClientMethod<$1.InstallationWorkspace, $1.ArchiveInstallationList>(
          '/modconductor.v1.ArchiveInstallation/RecentInstallations',
          ($1.InstallationWorkspace value) => value.writeToBuffer(),
          $1.ArchiveInstallationList.fromBuffer);
  static final _$watchInstallation = $grpc.ClientMethod<
          $1.InstallationReference, $1.ArchiveInstallationStatus>(
      '/modconductor.v1.ArchiveInstallation/WatchInstallation',
      ($1.InstallationReference value) => value.writeToBuffer(),
      $1.ArchiveInstallationStatus.fromBuffer);
  static final _$cancelInstallation = $grpc.ClientMethod<
          $1.InstallationReference, $1.ArchiveInstallationStatus>(
      '/modconductor.v1.ArchiveInstallation/CancelInstallation',
      ($1.InstallationReference value) => value.writeToBuffer(),
      $1.ArchiveInstallationStatus.fromBuffer);
  static final _$deleteInstallationFiles = $grpc.ClientMethod<
          $1.InstallationReference, $1.ArchiveInstallationStatus>(
      '/modconductor.v1.ArchiveInstallation/DeleteInstallationFiles',
      ($1.InstallationReference value) => value.writeToBuffer(),
      $1.ArchiveInstallationStatus.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ArchiveInstallation')
abstract class ArchiveInstallationServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ArchiveInstallation';

  ArchiveInstallationServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ArtifactReference, $1.ArchiveInstallationDraft>(
            'PrepareInstallation',
            prepareInstallation_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ArtifactReference.fromBuffer(value),
            ($1.ArchiveInstallationDraft value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationLayoutChange,
            $1.ArchiveInstallationDraft>(
        'ChangeInstallationLayout',
        changeInstallationLayout_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.InstallationLayoutChange.fromBuffer(value),
        ($1.ArchiveInstallationDraft value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationDraftReference,
            $1.InstallationDraftClosed>(
        'CloseInstallationDraft',
        closeInstallationDraft_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.InstallationDraftReference.fromBuffer(value),
        ($1.InstallationDraftClosed value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StartArchiveInstallation,
            $1.ArchiveInstallationStatus>(
        'StartInstallation',
        startInstallation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.StartArchiveInstallation.fromBuffer(value),
        ($1.ArchiveInstallationStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationWorkspace,
            $1.ArchiveInstallationList>(
        'RecentInstallations',
        recentInstallations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.InstallationWorkspace.fromBuffer(value),
        ($1.ArchiveInstallationList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationReference,
            $1.ArchiveInstallationStatus>(
        'WatchInstallation',
        watchInstallation_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $1.InstallationReference.fromBuffer(value),
        ($1.ArchiveInstallationStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationReference,
            $1.ArchiveInstallationStatus>(
        'CancelInstallation',
        cancelInstallation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.InstallationReference.fromBuffer(value),
        ($1.ArchiveInstallationStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationReference,
            $1.ArchiveInstallationStatus>(
        'DeleteInstallationFiles',
        deleteInstallationFiles_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.InstallationReference.fromBuffer(value),
        ($1.ArchiveInstallationStatus value) => value.writeToBuffer()));
  }

  $async.Future<$1.ArchiveInstallationDraft> prepareInstallation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReference> $request) async {
    return prepareInstallation($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationDraft> prepareInstallation(
      $grpc.ServiceCall call, $0.ArtifactReference request);

  $async.Future<$1.ArchiveInstallationDraft> changeInstallationLayout_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationLayoutChange> $request) async {
    return changeInstallationLayout($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationDraft> changeInstallationLayout(
      $grpc.ServiceCall call, $1.InstallationLayoutChange request);

  $async.Future<$1.InstallationDraftClosed> closeInstallationDraft_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationDraftReference> $request) async {
    return closeInstallationDraft($call, await $request);
  }

  $async.Future<$1.InstallationDraftClosed> closeInstallationDraft(
      $grpc.ServiceCall call, $1.InstallationDraftReference request);

  $async.Future<$1.ArchiveInstallationStatus> startInstallation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.StartArchiveInstallation> $request) async {
    return startInstallation($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationStatus> startInstallation(
      $grpc.ServiceCall call, $1.StartArchiveInstallation request);

  $async.Future<$1.ArchiveInstallationList> recentInstallations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationWorkspace> $request) async {
    return recentInstallations($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationList> recentInstallations(
      $grpc.ServiceCall call, $1.InstallationWorkspace request);

  $async.Stream<$1.ArchiveInstallationStatus> watchInstallation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationReference> $request) async* {
    yield* watchInstallation($call, await $request);
  }

  $async.Stream<$1.ArchiveInstallationStatus> watchInstallation(
      $grpc.ServiceCall call, $1.InstallationReference request);

  $async.Future<$1.ArchiveInstallationStatus> cancelInstallation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationReference> $request) async {
    return cancelInstallation($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationStatus> cancelInstallation(
      $grpc.ServiceCall call, $1.InstallationReference request);

  $async.Future<$1.ArchiveInstallationStatus> deleteInstallationFiles_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationReference> $request) async {
    return deleteInstallationFiles($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationStatus> deleteInstallationFiles(
      $grpc.ServiceCall call, $1.InstallationReference request);
}
