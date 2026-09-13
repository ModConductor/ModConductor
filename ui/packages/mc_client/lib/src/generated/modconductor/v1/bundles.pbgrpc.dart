// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bundles.proto.

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

import 'archive_installation.pb.dart' as $2;
import 'artifacts.pb.dart' as $0;
import 'bundles.pb.dart' as $1;

export 'bundles.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.BundleInstallation')
class BundleInstallationClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  BundleInstallationClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.BundleFound> findBundle(
    $0.ArtifactReadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$findBundle, request, options: options);
  }

  $grpc.ResponseFuture<$1.BundleDiscovery> discoverBundle(
    $0.ArtifactReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$discoverBundle, request, options: options);
  }

  $grpc.ResponseFuture<$1.ModBundle> createBundle(
    $1.BundleSelection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createBundle, request, options: options);
  }

  $grpc.ResponseFuture<$1.ModBundle> readBundle(
    $1.BundleReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readBundle, request, options: options);
  }

  $grpc.ResponseFuture<$1.BundleConfiguration> configureBundleMod(
    $1.BundleModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$configureBundleMod, request, options: options);
  }

  $grpc.ResponseFuture<$1.ModBundle> chooseNestedArchives(
    $1.NestedBundleSelection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$chooseNestedArchives, request, options: options);
  }

  $grpc.ResponseFuture<$1.ModBundle> renameBundleMod(
    $1.BundleModRename request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameBundleMod, request, options: options);
  }

  $grpc.ResponseFuture<$1.ModBundle> moveBundleMod(
    $1.BundleModMove request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$moveBundleMod, request, options: options);
  }

  $grpc.ResponseFuture<$2.ArchiveInstallationStatus> readBundleModStatus(
    $1.BundleModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readBundleModStatus, request, options: options);
  }

  $grpc.ResponseFuture<$1.ModBundle> retryBundleMod(
    $1.BundleModRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$retryBundleMod, request, options: options);
  }

  $grpc.ResponseFuture<$1.BundleClosed> deleteBundleTemporaryFiles(
    $1.BundleReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteBundleTemporaryFiles, request,
        options: options);
  }

  // method descriptors

  static final _$findBundle =
      $grpc.ClientMethod<$0.ArtifactReadRequest, $1.BundleFound>(
          '/modconductor.v1.BundleInstallation/FindBundle',
          ($0.ArtifactReadRequest value) => value.writeToBuffer(),
          $1.BundleFound.fromBuffer);
  static final _$discoverBundle =
      $grpc.ClientMethod<$0.ArtifactReference, $1.BundleDiscovery>(
          '/modconductor.v1.BundleInstallation/DiscoverBundle',
          ($0.ArtifactReference value) => value.writeToBuffer(),
          $1.BundleDiscovery.fromBuffer);
  static final _$createBundle =
      $grpc.ClientMethod<$1.BundleSelection, $1.ModBundle>(
          '/modconductor.v1.BundleInstallation/CreateBundle',
          ($1.BundleSelection value) => value.writeToBuffer(),
          $1.ModBundle.fromBuffer);
  static final _$readBundle =
      $grpc.ClientMethod<$1.BundleReference, $1.ModBundle>(
          '/modconductor.v1.BundleInstallation/ReadBundle',
          ($1.BundleReference value) => value.writeToBuffer(),
          $1.ModBundle.fromBuffer);
  static final _$configureBundleMod =
      $grpc.ClientMethod<$1.BundleModRequest, $1.BundleConfiguration>(
          '/modconductor.v1.BundleInstallation/ConfigureBundleMod',
          ($1.BundleModRequest value) => value.writeToBuffer(),
          $1.BundleConfiguration.fromBuffer);
  static final _$chooseNestedArchives =
      $grpc.ClientMethod<$1.NestedBundleSelection, $1.ModBundle>(
          '/modconductor.v1.BundleInstallation/ChooseNestedArchives',
          ($1.NestedBundleSelection value) => value.writeToBuffer(),
          $1.ModBundle.fromBuffer);
  static final _$renameBundleMod =
      $grpc.ClientMethod<$1.BundleModRename, $1.ModBundle>(
          '/modconductor.v1.BundleInstallation/RenameBundleMod',
          ($1.BundleModRename value) => value.writeToBuffer(),
          $1.ModBundle.fromBuffer);
  static final _$moveBundleMod =
      $grpc.ClientMethod<$1.BundleModMove, $1.ModBundle>(
          '/modconductor.v1.BundleInstallation/MoveBundleMod',
          ($1.BundleModMove value) => value.writeToBuffer(),
          $1.ModBundle.fromBuffer);
  static final _$readBundleModStatus =
      $grpc.ClientMethod<$1.BundleModRequest, $2.ArchiveInstallationStatus>(
          '/modconductor.v1.BundleInstallation/ReadBundleModStatus',
          ($1.BundleModRequest value) => value.writeToBuffer(),
          $2.ArchiveInstallationStatus.fromBuffer);
  static final _$retryBundleMod =
      $grpc.ClientMethod<$1.BundleModRequest, $1.ModBundle>(
          '/modconductor.v1.BundleInstallation/RetryBundleMod',
          ($1.BundleModRequest value) => value.writeToBuffer(),
          $1.ModBundle.fromBuffer);
  static final _$deleteBundleTemporaryFiles =
      $grpc.ClientMethod<$1.BundleReference, $1.BundleClosed>(
          '/modconductor.v1.BundleInstallation/DeleteBundleTemporaryFiles',
          ($1.BundleReference value) => value.writeToBuffer(),
          $1.BundleClosed.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.BundleInstallation')
abstract class BundleInstallationServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.BundleInstallation';

  BundleInstallationServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ArtifactReadRequest, $1.BundleFound>(
        'FindBundle',
        findBundle_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ArtifactReadRequest.fromBuffer(value),
        ($1.BundleFound value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ArtifactReference, $1.BundleDiscovery>(
        'DiscoverBundle',
        discoverBundle_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ArtifactReference.fromBuffer(value),
        ($1.BundleDiscovery value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleSelection, $1.ModBundle>(
        'CreateBundle',
        createBundle_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleSelection.fromBuffer(value),
        ($1.ModBundle value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleReference, $1.ModBundle>(
        'ReadBundle',
        readBundle_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleReference.fromBuffer(value),
        ($1.ModBundle value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleModRequest, $1.BundleConfiguration>(
        'ConfigureBundleMod',
        configureBundleMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleModRequest.fromBuffer(value),
        ($1.BundleConfiguration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.NestedBundleSelection, $1.ModBundle>(
        'ChooseNestedArchives',
        chooseNestedArchives_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.NestedBundleSelection.fromBuffer(value),
        ($1.ModBundle value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleModRename, $1.ModBundle>(
        'RenameBundleMod',
        renameBundleMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleModRename.fromBuffer(value),
        ($1.ModBundle value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleModMove, $1.ModBundle>(
        'MoveBundleMod',
        moveBundleMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleModMove.fromBuffer(value),
        ($1.ModBundle value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.BundleModRequest, $2.ArchiveInstallationStatus>(
            'ReadBundleModStatus',
            readBundleModStatus_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.BundleModRequest.fromBuffer(value),
            ($2.ArchiveInstallationStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleModRequest, $1.ModBundle>(
        'RetryBundleMod',
        retryBundleMod_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleModRequest.fromBuffer(value),
        ($1.ModBundle value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BundleReference, $1.BundleClosed>(
        'DeleteBundleTemporaryFiles',
        deleteBundleTemporaryFiles_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BundleReference.fromBuffer(value),
        ($1.BundleClosed value) => value.writeToBuffer()));
  }

  $async.Future<$1.BundleFound> findBundle_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReadRequest> $request) async {
    return findBundle($call, await $request);
  }

  $async.Future<$1.BundleFound> findBundle(
      $grpc.ServiceCall call, $0.ArtifactReadRequest request);

  $async.Future<$1.BundleDiscovery> discoverBundle_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ArtifactReference> $request) async {
    return discoverBundle($call, await $request);
  }

  $async.Future<$1.BundleDiscovery> discoverBundle(
      $grpc.ServiceCall call, $0.ArtifactReference request);

  $async.Future<$1.ModBundle> createBundle_Pre($grpc.ServiceCall $call,
      $async.Future<$1.BundleSelection> $request) async {
    return createBundle($call, await $request);
  }

  $async.Future<$1.ModBundle> createBundle(
      $grpc.ServiceCall call, $1.BundleSelection request);

  $async.Future<$1.ModBundle> readBundle_Pre($grpc.ServiceCall $call,
      $async.Future<$1.BundleReference> $request) async {
    return readBundle($call, await $request);
  }

  $async.Future<$1.ModBundle> readBundle(
      $grpc.ServiceCall call, $1.BundleReference request);

  $async.Future<$1.BundleConfiguration> configureBundleMod_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BundleModRequest> $request) async {
    return configureBundleMod($call, await $request);
  }

  $async.Future<$1.BundleConfiguration> configureBundleMod(
      $grpc.ServiceCall call, $1.BundleModRequest request);

  $async.Future<$1.ModBundle> chooseNestedArchives_Pre($grpc.ServiceCall $call,
      $async.Future<$1.NestedBundleSelection> $request) async {
    return chooseNestedArchives($call, await $request);
  }

  $async.Future<$1.ModBundle> chooseNestedArchives(
      $grpc.ServiceCall call, $1.NestedBundleSelection request);

  $async.Future<$1.ModBundle> renameBundleMod_Pre($grpc.ServiceCall $call,
      $async.Future<$1.BundleModRename> $request) async {
    return renameBundleMod($call, await $request);
  }

  $async.Future<$1.ModBundle> renameBundleMod(
      $grpc.ServiceCall call, $1.BundleModRename request);

  $async.Future<$1.ModBundle> moveBundleMod_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.BundleModMove> $request) async {
    return moveBundleMod($call, await $request);
  }

  $async.Future<$1.ModBundle> moveBundleMod(
      $grpc.ServiceCall call, $1.BundleModMove request);

  $async.Future<$2.ArchiveInstallationStatus> readBundleModStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BundleModRequest> $request) async {
    return readBundleModStatus($call, await $request);
  }

  $async.Future<$2.ArchiveInstallationStatus> readBundleModStatus(
      $grpc.ServiceCall call, $1.BundleModRequest request);

  $async.Future<$1.ModBundle> retryBundleMod_Pre($grpc.ServiceCall $call,
      $async.Future<$1.BundleModRequest> $request) async {
    return retryBundleMod($call, await $request);
  }

  $async.Future<$1.ModBundle> retryBundleMod(
      $grpc.ServiceCall call, $1.BundleModRequest request);

  $async.Future<$1.BundleClosed> deleteBundleTemporaryFiles_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BundleReference> $request) async {
    return deleteBundleTemporaryFiles($call, await $request);
  }

  $async.Future<$1.BundleClosed> deleteBundleTemporaryFiles(
      $grpc.ServiceCall call, $1.BundleReference request);
}
