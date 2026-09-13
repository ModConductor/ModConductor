// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus_metadata.proto.

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

import 'nexus.pb.dart' as $1;
import 'nexus_metadata.pb.dart' as $0;

export 'nexus_metadata.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.NexusMetadata')
class NexusMetadataClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NexusMetadataClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ModNexusReply> readModNexus(
    $0.ModNexusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readModNexus, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModNexusReply> refreshModNexus(
    $0.ModNexusReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshModNexus, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModNexusReply> linkModNexus(
    $0.LinkModNexusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$linkModNexus, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModNexusReply> mapModNexusCategory(
    $0.MapModNexusCategoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$mapModNexusCategory, request, options: options);
  }

  $grpc.ResponseFuture<$1.NexusDownloadReply> downloadModNexusFile(
    $0.DownloadModNexusFileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$downloadModNexusFile, request, options: options);
  }

  // method descriptors

  static final _$readModNexus =
      $grpc.ClientMethod<$0.ModNexusRequest, $0.ModNexusReply>(
          '/modconductor.v1.NexusMetadata/ReadModNexus',
          ($0.ModNexusRequest value) => value.writeToBuffer(),
          $0.ModNexusReply.fromBuffer);
  static final _$refreshModNexus =
      $grpc.ClientMethod<$0.ModNexusReference, $0.ModNexusReply>(
          '/modconductor.v1.NexusMetadata/RefreshModNexus',
          ($0.ModNexusReference value) => value.writeToBuffer(),
          $0.ModNexusReply.fromBuffer);
  static final _$linkModNexus =
      $grpc.ClientMethod<$0.LinkModNexusRequest, $0.ModNexusReply>(
          '/modconductor.v1.NexusMetadata/LinkModNexus',
          ($0.LinkModNexusRequest value) => value.writeToBuffer(),
          $0.ModNexusReply.fromBuffer);
  static final _$mapModNexusCategory =
      $grpc.ClientMethod<$0.MapModNexusCategoryRequest, $0.ModNexusReply>(
          '/modconductor.v1.NexusMetadata/MapModNexusCategory',
          ($0.MapModNexusCategoryRequest value) => value.writeToBuffer(),
          $0.ModNexusReply.fromBuffer);
  static final _$downloadModNexusFile =
      $grpc.ClientMethod<$0.DownloadModNexusFileRequest, $1.NexusDownloadReply>(
          '/modconductor.v1.NexusMetadata/DownloadModNexusFile',
          ($0.DownloadModNexusFileRequest value) => value.writeToBuffer(),
          $1.NexusDownloadReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.NexusMetadata')
abstract class NexusMetadataServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.NexusMetadata';

  NexusMetadataServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ModNexusRequest, $0.ModNexusReply>(
        'ReadModNexus',
        readModNexus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ModNexusRequest.fromBuffer(value),
        ($0.ModNexusReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ModNexusReference, $0.ModNexusReply>(
        'RefreshModNexus',
        refreshModNexus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ModNexusReference.fromBuffer(value),
        ($0.ModNexusReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LinkModNexusRequest, $0.ModNexusReply>(
        'LinkModNexus',
        linkModNexus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.LinkModNexusRequest.fromBuffer(value),
        ($0.ModNexusReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.MapModNexusCategoryRequest, $0.ModNexusReply>(
            'MapModNexusCategory',
            mapModNexusCategory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.MapModNexusCategoryRequest.fromBuffer(value),
            ($0.ModNexusReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadModNexusFileRequest,
            $1.NexusDownloadReply>(
        'DownloadModNexusFile',
        downloadModNexusFile_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DownloadModNexusFileRequest.fromBuffer(value),
        ($1.NexusDownloadReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.ModNexusReply> readModNexus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ModNexusRequest> $request) async {
    return readModNexus($call, await $request);
  }

  $async.Future<$0.ModNexusReply> readModNexus(
      $grpc.ServiceCall call, $0.ModNexusRequest request);

  $async.Future<$0.ModNexusReply> refreshModNexus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ModNexusReference> $request) async {
    return refreshModNexus($call, await $request);
  }

  $async.Future<$0.ModNexusReply> refreshModNexus(
      $grpc.ServiceCall call, $0.ModNexusReference request);

  $async.Future<$0.ModNexusReply> linkModNexus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LinkModNexusRequest> $request) async {
    return linkModNexus($call, await $request);
  }

  $async.Future<$0.ModNexusReply> linkModNexus(
      $grpc.ServiceCall call, $0.LinkModNexusRequest request);

  $async.Future<$0.ModNexusReply> mapModNexusCategory_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.MapModNexusCategoryRequest> $request) async {
    return mapModNexusCategory($call, await $request);
  }

  $async.Future<$0.ModNexusReply> mapModNexusCategory(
      $grpc.ServiceCall call, $0.MapModNexusCategoryRequest request);

  $async.Future<$1.NexusDownloadReply> downloadModNexusFile_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DownloadModNexusFileRequest> $request) async {
    return downloadModNexusFile($call, await $request);
  }

  $async.Future<$1.NexusDownloadReply> downloadModNexusFile(
      $grpc.ServiceCall call, $0.DownloadModNexusFileRequest request);
}
