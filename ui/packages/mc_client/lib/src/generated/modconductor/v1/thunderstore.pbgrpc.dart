// This is a generated file - do not edit.
//
// Generated from modconductor/v1/thunderstore.proto.

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

import 'thunderstore.pb.dart' as $0;

export 'thunderstore.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.Thunderstore')
class ThunderstoreClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ThunderstoreClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ThunderstoreSearchReply> searchThunderstore(
    $0.ThunderstoreSearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchThunderstore, request, options: options);
  }

  $grpc.ResponseFuture<$0.ThunderstorePackageReply> readThunderstorePackage(
    $0.ThunderstorePackageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readThunderstorePackage, request,
        options: options);
  }

  $grpc.ResponseStream<$0.ThunderstoreAcquisition> acquireThunderstorePackage(
    $0.ThunderstoreAcquireRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$acquireThunderstorePackage, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ThunderstoreOpened> openThunderstorePage(
    $0.ThunderstorePackageReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openThunderstorePage, request, options: options);
  }

  // method descriptors

  static final _$searchThunderstore = $grpc.ClientMethod<
          $0.ThunderstoreSearchRequest, $0.ThunderstoreSearchReply>(
      '/modconductor.v1.Thunderstore/SearchThunderstore',
      ($0.ThunderstoreSearchRequest value) => value.writeToBuffer(),
      $0.ThunderstoreSearchReply.fromBuffer);
  static final _$readThunderstorePackage = $grpc.ClientMethod<
          $0.ThunderstorePackageRequest, $0.ThunderstorePackageReply>(
      '/modconductor.v1.Thunderstore/ReadThunderstorePackage',
      ($0.ThunderstorePackageRequest value) => value.writeToBuffer(),
      $0.ThunderstorePackageReply.fromBuffer);
  static final _$acquireThunderstorePackage = $grpc.ClientMethod<
          $0.ThunderstoreAcquireRequest, $0.ThunderstoreAcquisition>(
      '/modconductor.v1.Thunderstore/AcquireThunderstorePackage',
      ($0.ThunderstoreAcquireRequest value) => value.writeToBuffer(),
      $0.ThunderstoreAcquisition.fromBuffer);
  static final _$openThunderstorePage = $grpc.ClientMethod<
          $0.ThunderstorePackageReference, $0.ThunderstoreOpened>(
      '/modconductor.v1.Thunderstore/OpenThunderstorePage',
      ($0.ThunderstorePackageReference value) => value.writeToBuffer(),
      $0.ThunderstoreOpened.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.Thunderstore')
abstract class ThunderstoreServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.Thunderstore';

  ThunderstoreServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ThunderstoreSearchRequest,
            $0.ThunderstoreSearchReply>(
        'SearchThunderstore',
        searchThunderstore_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ThunderstoreSearchRequest.fromBuffer(value),
        ($0.ThunderstoreSearchReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ThunderstorePackageRequest,
            $0.ThunderstorePackageReply>(
        'ReadThunderstorePackage',
        readThunderstorePackage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ThunderstorePackageRequest.fromBuffer(value),
        ($0.ThunderstorePackageReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ThunderstoreAcquireRequest,
            $0.ThunderstoreAcquisition>(
        'AcquireThunderstorePackage',
        acquireThunderstorePackage_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.ThunderstoreAcquireRequest.fromBuffer(value),
        ($0.ThunderstoreAcquisition value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ThunderstorePackageReference,
            $0.ThunderstoreOpened>(
        'OpenThunderstorePage',
        openThunderstorePage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ThunderstorePackageReference.fromBuffer(value),
        ($0.ThunderstoreOpened value) => value.writeToBuffer()));
  }

  $async.Future<$0.ThunderstoreSearchReply> searchThunderstore_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ThunderstoreSearchRequest> $request) async {
    return searchThunderstore($call, await $request);
  }

  $async.Future<$0.ThunderstoreSearchReply> searchThunderstore(
      $grpc.ServiceCall call, $0.ThunderstoreSearchRequest request);

  $async.Future<$0.ThunderstorePackageReply> readThunderstorePackage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ThunderstorePackageRequest> $request) async {
    return readThunderstorePackage($call, await $request);
  }

  $async.Future<$0.ThunderstorePackageReply> readThunderstorePackage(
      $grpc.ServiceCall call, $0.ThunderstorePackageRequest request);

  $async.Stream<$0.ThunderstoreAcquisition> acquireThunderstorePackage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ThunderstoreAcquireRequest> $request) async* {
    yield* acquireThunderstorePackage($call, await $request);
  }

  $async.Stream<$0.ThunderstoreAcquisition> acquireThunderstorePackage(
      $grpc.ServiceCall call, $0.ThunderstoreAcquireRequest request);

  $async.Future<$0.ThunderstoreOpened> openThunderstorePage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ThunderstorePackageReference> $request) async {
    return openThunderstorePage($call, await $request);
  }

  $async.Future<$0.ThunderstoreOpened> openThunderstorePage(
      $grpc.ServiceCall call, $0.ThunderstorePackageReference request);
}
