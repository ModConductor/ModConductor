// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fomod.proto.

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
import 'fomod.pb.dart' as $0;

export 'fomod.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.FomodInstallation')
class FomodInstallationClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  FomodInstallationClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.FomodChoices> openChoices(
    $0.OpenFomodChoices request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openChoices, request, options: options);
  }

  $grpc.ResponseFuture<$0.FomodChoices> readChoices(
    $1.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readChoices, request, options: options);
  }

  $grpc.ResponseFuture<$0.FomodChoices> changeChoice(
    $0.FomodChoiceChange request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeChoice, request, options: options);
  }

  $grpc.ResponseFuture<$0.FomodChoices> nextStep(
    $1.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$nextStep, request, options: options);
  }

  $grpc.ResponseFuture<$0.FomodChoices> previousStep(
    $1.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previousStep, request, options: options);
  }

  $grpc.ResponseFuture<$1.ArchiveInstallationDraft> useManualLayout(
    $1.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$useManualLayout, request, options: options);
  }

  $grpc.ResponseFuture<$0.FomodImage> readChoiceImage(
    $0.FomodImageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readChoiceImage, request, options: options);
  }

  // method descriptors

  static final _$openChoices =
      $grpc.ClientMethod<$0.OpenFomodChoices, $0.FomodChoices>(
          '/modconductor.v1.FomodInstallation/OpenChoices',
          ($0.OpenFomodChoices value) => value.writeToBuffer(),
          $0.FomodChoices.fromBuffer);
  static final _$readChoices =
      $grpc.ClientMethod<$1.InstallationDraftReference, $0.FomodChoices>(
          '/modconductor.v1.FomodInstallation/ReadChoices',
          ($1.InstallationDraftReference value) => value.writeToBuffer(),
          $0.FomodChoices.fromBuffer);
  static final _$changeChoice =
      $grpc.ClientMethod<$0.FomodChoiceChange, $0.FomodChoices>(
          '/modconductor.v1.FomodInstallation/ChangeChoice',
          ($0.FomodChoiceChange value) => value.writeToBuffer(),
          $0.FomodChoices.fromBuffer);
  static final _$nextStep =
      $grpc.ClientMethod<$1.InstallationDraftReference, $0.FomodChoices>(
          '/modconductor.v1.FomodInstallation/NextStep',
          ($1.InstallationDraftReference value) => value.writeToBuffer(),
          $0.FomodChoices.fromBuffer);
  static final _$previousStep =
      $grpc.ClientMethod<$1.InstallationDraftReference, $0.FomodChoices>(
          '/modconductor.v1.FomodInstallation/PreviousStep',
          ($1.InstallationDraftReference value) => value.writeToBuffer(),
          $0.FomodChoices.fromBuffer);
  static final _$useManualLayout = $grpc.ClientMethod<
          $1.InstallationDraftReference, $1.ArchiveInstallationDraft>(
      '/modconductor.v1.FomodInstallation/UseManualLayout',
      ($1.InstallationDraftReference value) => value.writeToBuffer(),
      $1.ArchiveInstallationDraft.fromBuffer);
  static final _$readChoiceImage =
      $grpc.ClientMethod<$0.FomodImageRequest, $0.FomodImage>(
          '/modconductor.v1.FomodInstallation/ReadChoiceImage',
          ($0.FomodImageRequest value) => value.writeToBuffer(),
          $0.FomodImage.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.FomodInstallation')
abstract class FomodInstallationServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.FomodInstallation';

  FomodInstallationServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.OpenFomodChoices, $0.FomodChoices>(
        'OpenChoices',
        openChoices_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.OpenFomodChoices.fromBuffer(value),
        ($0.FomodChoices value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.InstallationDraftReference, $0.FomodChoices>(
            'ReadChoices',
            readChoices_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.InstallationDraftReference.fromBuffer(value),
            ($0.FomodChoices value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FomodChoiceChange, $0.FomodChoices>(
        'ChangeChoice',
        changeChoice_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FomodChoiceChange.fromBuffer(value),
        ($0.FomodChoices value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.InstallationDraftReference, $0.FomodChoices>(
            'NextStep',
            nextStep_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.InstallationDraftReference.fromBuffer(value),
            ($0.FomodChoices value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.InstallationDraftReference, $0.FomodChoices>(
            'PreviousStep',
            previousStep_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.InstallationDraftReference.fromBuffer(value),
            ($0.FomodChoices value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.InstallationDraftReference,
            $1.ArchiveInstallationDraft>(
        'UseManualLayout',
        useManualLayout_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.InstallationDraftReference.fromBuffer(value),
        ($1.ArchiveInstallationDraft value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FomodImageRequest, $0.FomodImage>(
        'ReadChoiceImage',
        readChoiceImage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FomodImageRequest.fromBuffer(value),
        ($0.FomodImage value) => value.writeToBuffer()));
  }

  $async.Future<$0.FomodChoices> openChoices_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OpenFomodChoices> $request) async {
    return openChoices($call, await $request);
  }

  $async.Future<$0.FomodChoices> openChoices(
      $grpc.ServiceCall call, $0.OpenFomodChoices request);

  $async.Future<$0.FomodChoices> readChoices_Pre($grpc.ServiceCall $call,
      $async.Future<$1.InstallationDraftReference> $request) async {
    return readChoices($call, await $request);
  }

  $async.Future<$0.FomodChoices> readChoices(
      $grpc.ServiceCall call, $1.InstallationDraftReference request);

  $async.Future<$0.FomodChoices> changeChoice_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FomodChoiceChange> $request) async {
    return changeChoice($call, await $request);
  }

  $async.Future<$0.FomodChoices> changeChoice(
      $grpc.ServiceCall call, $0.FomodChoiceChange request);

  $async.Future<$0.FomodChoices> nextStep_Pre($grpc.ServiceCall $call,
      $async.Future<$1.InstallationDraftReference> $request) async {
    return nextStep($call, await $request);
  }

  $async.Future<$0.FomodChoices> nextStep(
      $grpc.ServiceCall call, $1.InstallationDraftReference request);

  $async.Future<$0.FomodChoices> previousStep_Pre($grpc.ServiceCall $call,
      $async.Future<$1.InstallationDraftReference> $request) async {
    return previousStep($call, await $request);
  }

  $async.Future<$0.FomodChoices> previousStep(
      $grpc.ServiceCall call, $1.InstallationDraftReference request);

  $async.Future<$1.ArchiveInstallationDraft> useManualLayout_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.InstallationDraftReference> $request) async {
    return useManualLayout($call, await $request);
  }

  $async.Future<$1.ArchiveInstallationDraft> useManualLayout(
      $grpc.ServiceCall call, $1.InstallationDraftReference request);

  $async.Future<$0.FomodImage> readChoiceImage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FomodImageRequest> $request) async {
    return readChoiceImage($call, await $request);
  }

  $async.Future<$0.FomodImage> readChoiceImage(
      $grpc.ServiceCall call, $0.FomodImageRequest request);
}
