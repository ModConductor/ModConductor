// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus_interactions.proto.

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

import 'nexus_interactions.pb.dart' as $1;
import 'nexus_metadata.pb.dart' as $0;

export 'nexus_interactions.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.NexusInteractions')
class NexusInteractionsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NexusInteractionsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.ModNexusInteractionsReply> readModNexusInteractions(
    $0.ModNexusReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readModNexusInteractions, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.ModNexusInteractionsReply> changeModNexusInteraction(
    $1.ChangeModNexusInteractionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeModNexusInteraction, request,
        options: options);
  }

  // method descriptors

  static final _$readModNexusInteractions =
      $grpc.ClientMethod<$0.ModNexusReference, $1.ModNexusInteractionsReply>(
          '/modconductor.v1.NexusInteractions/ReadModNexusInteractions',
          ($0.ModNexusReference value) => value.writeToBuffer(),
          $1.ModNexusInteractionsReply.fromBuffer);
  static final _$changeModNexusInteraction = $grpc.ClientMethod<
          $1.ChangeModNexusInteractionRequest, $1.ModNexusInteractionsReply>(
      '/modconductor.v1.NexusInteractions/ChangeModNexusInteraction',
      ($1.ChangeModNexusInteractionRequest value) => value.writeToBuffer(),
      $1.ModNexusInteractionsReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.NexusInteractions')
abstract class NexusInteractionsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.NexusInteractions';

  NexusInteractionsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ModNexusReference, $1.ModNexusInteractionsReply>(
            'ReadModNexusInteractions',
            readModNexusInteractions_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ModNexusReference.fromBuffer(value),
            ($1.ModNexusInteractionsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ChangeModNexusInteractionRequest,
            $1.ModNexusInteractionsReply>(
        'ChangeModNexusInteraction',
        changeModNexusInteraction_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ChangeModNexusInteractionRequest.fromBuffer(value),
        ($1.ModNexusInteractionsReply value) => value.writeToBuffer()));
  }

  $async.Future<$1.ModNexusInteractionsReply> readModNexusInteractions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ModNexusReference> $request) async {
    return readModNexusInteractions($call, await $request);
  }

  $async.Future<$1.ModNexusInteractionsReply> readModNexusInteractions(
      $grpc.ServiceCall call, $0.ModNexusReference request);

  $async.Future<$1.ModNexusInteractionsReply> changeModNexusInteraction_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ChangeModNexusInteractionRequest> $request) async {
    return changeModNexusInteraction($call, await $request);
  }

  $async.Future<$1.ModNexusInteractionsReply> changeModNexusInteraction(
      $grpc.ServiceCall call, $1.ChangeModNexusInteractionRequest request);
}
