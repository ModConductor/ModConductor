// This is a generated file - do not edit.
//
// Generated from modconductor/v1/artifacts.proto.

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

import 'artifacts.pb.dart' as $0;

export 'artifacts.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ArtifactLibrary')
class ArtifactLibraryClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ArtifactLibraryClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ArtifactPage> listArtifacts(
    $0.ArtifactListRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listArtifacts, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArtifactLinkPage> listArtifactLinkOptions(
    $0.ArtifactListRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listArtifactLinkOptions, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveArtifact> readArtifact(
    $0.ArtifactReadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readArtifact, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveArtifact> addArtifact(
    $0.ArtifactAddRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addArtifact, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveArtifact> retryArtifact(
    $0.ArtifactReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$retryArtifact, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveArtifact> locateArtifact(
    $0.ArtifactLocateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$locateArtifact, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveArtifact> linkArtifact(
    $0.ArtifactLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$linkArtifact, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveArtifact> deleteArtifactCopy(
    $0.ArtifactReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteArtifactCopy, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArtifactRemoved> removeArtifact(
    $0.ArtifactReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeArtifact, request, options: options);
  }

  // method descriptors

  static final _$listArtifacts =
      $grpc.ClientMethod<$0.ArtifactListRequest, $0.ArtifactPage>(
          '/modconductor.v1.ArtifactLibrary/ListArtifacts',
          ($0.ArtifactListRequest value) => value.writeToBuffer(),
          $0.ArtifactPage.fromBuffer);
  static final _$listArtifactLinkOptions =
      $grpc.ClientMethod<$0.ArtifactListRequest, $0.ArtifactLinkPage>(
          '/modconductor.v1.ArtifactLibrary/ListArtifactLinkOptions',
          ($0.ArtifactListRequest value) => value.writeToBuffer(),
          $0.ArtifactLinkPage.fromBuffer);
  static final _$readArtifact =
      $grpc.ClientMethod<$0.ArtifactReadRequest, $0.ArchiveArtifact>(
          '/modconductor.v1.ArtifactLibrary/ReadArtifact',
          ($0.ArtifactReadRequest value) => value.writeToBuffer(),
          $0.ArchiveArtifact.fromBuffer);
  static final _$addArtifact =
      $grpc.ClientMethod<$0.ArtifactAddRequest, $0.ArchiveArtifact>(
          '/modconductor.v1.ArtifactLibrary/AddArtifact',
          ($0.ArtifactAddRequest value) => value.writeToBuffer(),
          $0.ArchiveArtifact.fromBuffer);
  static final _$retryArtifact =
      $grpc.ClientMethod<$0.ArtifactReference, $0.ArchiveArtifact>(
          '/modconductor.v1.ArtifactLibrary/RetryArtifact',
          ($0.ArtifactReference value) => value.writeToBuffer(),
          $0.ArchiveArtifact.fromBuffer);
  static final _$locateArtifact =
      $grpc.ClientMethod<$0.ArtifactLocateRequest, $0.ArchiveArtifact>(
          '/modconductor.v1.ArtifactLibrary/LocateArtifact',
          ($0.ArtifactLocateRequest value) => value.writeToBuffer(),
          $0.ArchiveArtifact.fromBuffer);
  static final _$linkArtifact =
      $grpc.ClientMethod<$0.ArtifactLinkRequest, $0.ArchiveArtifact>(
          '/modconductor.v1.ArtifactLibrary/LinkArtifact',
          ($0.ArtifactLinkRequest value) => value.writeToBuffer(),
          $0.ArchiveArtifact.fromBuffer);
  static final _$deleteArtifactCopy =
      $grpc.ClientMethod<$0.ArtifactReference, $0.ArchiveArtifact>(
          '/modconductor.v1.ArtifactLibrary/DeleteArtifactCopy',
          ($0.ArtifactReference value) => value.writeToBuffer(),
          $0.ArchiveArtifact.fromBuffer);
  static final _$removeArtifact =
      $grpc.ClientMethod<$0.ArtifactReference, $0.ArtifactRemoved>(
          '/modconductor.v1.ArtifactLibrary/RemoveArtifact',
          ($0.ArtifactReference value) => value.writeToBuffer(),
          $0.ArtifactRemoved.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ArtifactLibrary')
abstract class ArtifactLibraryServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ArtifactLibrary';

  ArtifactLibraryServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ArtifactListRequest, $0.ArtifactPage>(
        'ListArtifacts',
        listArtifacts_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ArtifactListRequest.fromBuffer(value),
        ($0.ArtifactPage value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactListRequest, $0.ArtifactLinkPage>(
        'ListArtifactLinkOptions',
        listArtifactLinkOptions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ArtifactListRequest.fromBuffer(value),
        ($0.ArtifactLinkPage value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactReadRequest, $0.ArchiveArtifact>(
        'ReadArtifact',
        readArtifact_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ArtifactReadRequest.fromBuffer(value),
        ($0.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactAddRequest, $0.ArchiveArtifact>(
        'AddArtifact',
        addArtifact_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ArtifactAddRequest.fromBuffer(value),
        ($0.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactReference, $0.ArchiveArtifact>(
        'RetryArtifact',
        retryArtifact_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ArtifactReference.fromBuffer(value),
        ($0.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ArtifactLocateRequest, $0.ArchiveArtifact>(
            'LocateArtifact',
            locateArtifact_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ArtifactLocateRequest.fromBuffer(value),
            ($0.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactLinkRequest, $0.ArchiveArtifact>(
        'LinkArtifact',
        linkArtifact_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ArtifactLinkRequest.fromBuffer(value),
        ($0.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactReference, $0.ArchiveArtifact>(
        'DeleteArtifactCopy',
        deleteArtifactCopy_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ArtifactReference.fromBuffer(value),
        ($0.ArchiveArtifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactReference, $0.ArtifactRemoved>(
        'RemoveArtifact',
        removeArtifact_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ArtifactReference.fromBuffer(value),
        ($0.ArtifactRemoved value) => value.writeToBuffer()));
  }

  $async.Future<$0.ArtifactPage> listArtifacts_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactListRequest> $request) async {
    return listArtifacts($call, await $request);
  }

  $async.Future<$0.ArtifactPage> listArtifacts(
      $grpc.ServiceCall call, $0.ArtifactListRequest request);

  $async.Future<$0.ArtifactLinkPage> listArtifactLinkOptions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ArtifactListRequest> $request) async {
    return listArtifactLinkOptions($call, await $request);
  }

  $async.Future<$0.ArtifactLinkPage> listArtifactLinkOptions(
      $grpc.ServiceCall call, $0.ArtifactListRequest request);

  $async.Future<$0.ArchiveArtifact> readArtifact_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReadRequest> $request) async {
    return readArtifact($call, await $request);
  }

  $async.Future<$0.ArchiveArtifact> readArtifact(
      $grpc.ServiceCall call, $0.ArtifactReadRequest request);

  $async.Future<$0.ArchiveArtifact> addArtifact_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactAddRequest> $request) async {
    return addArtifact($call, await $request);
  }

  $async.Future<$0.ArchiveArtifact> addArtifact(
      $grpc.ServiceCall call, $0.ArtifactAddRequest request);

  $async.Future<$0.ArchiveArtifact> retryArtifact_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReference> $request) async {
    return retryArtifact($call, await $request);
  }

  $async.Future<$0.ArchiveArtifact> retryArtifact(
      $grpc.ServiceCall call, $0.ArtifactReference request);

  $async.Future<$0.ArchiveArtifact> locateArtifact_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactLocateRequest> $request) async {
    return locateArtifact($call, await $request);
  }

  $async.Future<$0.ArchiveArtifact> locateArtifact(
      $grpc.ServiceCall call, $0.ArtifactLocateRequest request);

  $async.Future<$0.ArchiveArtifact> linkArtifact_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactLinkRequest> $request) async {
    return linkArtifact($call, await $request);
  }

  $async.Future<$0.ArchiveArtifact> linkArtifact(
      $grpc.ServiceCall call, $0.ArtifactLinkRequest request);

  $async.Future<$0.ArchiveArtifact> deleteArtifactCopy_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReference> $request) async {
    return deleteArtifactCopy($call, await $request);
  }

  $async.Future<$0.ArchiveArtifact> deleteArtifactCopy(
      $grpc.ServiceCall call, $0.ArtifactReference request);

  $async.Future<$0.ArtifactRemoved> removeArtifact_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReference> $request) async {
    return removeArtifact($call, await $request);
  }

  $async.Future<$0.ArtifactRemoved> removeArtifact(
      $grpc.ServiceCall call, $0.ArtifactReference request);
}
