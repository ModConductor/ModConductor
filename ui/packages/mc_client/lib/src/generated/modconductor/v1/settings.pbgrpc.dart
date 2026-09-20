// This is a generated file - do not edit.
//
// Generated from modconductor/v1/settings.proto.

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

import 'settings.pb.dart' as $0;

export 'settings.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.SettingsOperations')
class SettingsOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SettingsOperationsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SettingsReply> readSettings(
    $0.ReadSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.SettingsReply> saveSettings(
    $0.SaveSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveSettings, request, options: options);
  }

  // method descriptors

  static final _$readSettings =
      $grpc.ClientMethod<$0.ReadSettingsRequest, $0.SettingsReply>(
          '/modconductor.v1.SettingsOperations/ReadSettings',
          ($0.ReadSettingsRequest value) => value.writeToBuffer(),
          $0.SettingsReply.fromBuffer);
  static final _$saveSettings =
      $grpc.ClientMethod<$0.SaveSettingsRequest, $0.SettingsReply>(
          '/modconductor.v1.SettingsOperations/SaveSettings',
          ($0.SaveSettingsRequest value) => value.writeToBuffer(),
          $0.SettingsReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.SettingsOperations')
abstract class SettingsOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.SettingsOperations';

  SettingsOperationsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ReadSettingsRequest, $0.SettingsReply>(
        'ReadSettings',
        readSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReadSettingsRequest.fromBuffer(value),
        ($0.SettingsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveSettingsRequest, $0.SettingsReply>(
        'SaveSettings',
        saveSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SaveSettingsRequest.fromBuffer(value),
        ($0.SettingsReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.SettingsReply> readSettings_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadSettingsRequest> $request) async {
    return readSettings($call, await $request);
  }

  $async.Future<$0.SettingsReply> readSettings(
      $grpc.ServiceCall call, $0.ReadSettingsRequest request);

  $async.Future<$0.SettingsReply> saveSettings_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveSettingsRequest> $request) async {
    return saveSettings($call, await $request);
  }

  $async.Future<$0.SettingsReply> saveSettings(
      $grpc.ServiceCall call, $0.SaveSettingsRequest request);
}
