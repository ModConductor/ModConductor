// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bain.proto.

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

import 'archive_installation.pb.dart' as $0;
import 'bain.pb.dart' as $1;

export 'bain.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.BainInstallation')
class BainInstallationClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  BainInstallationClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.BainChoices> openPackageChoices(
    $0.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openPackageChoices, request, options: options);
  }

  $grpc.ResponseFuture<$1.BainChoices> selectPackageFolder(
    $1.BainFolderSelection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$selectPackageFolder, request, options: options);
  }

  $grpc.ResponseFuture<$1.BainChoices> selectAllPackageFolders(
    $1.BainAllFoldersSelection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$selectAllPackageFolders, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.BainChoices> includePackageFile(
    $1.BainFileSelection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$includePackageFile, request, options: options);
  }

  $grpc.ResponseFuture<$1.BainChoices> reviewPackageFiles(
    $0.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reviewPackageFiles, request, options: options);
  }

  $grpc.ResponseFuture<$1.BainChoices> backToPackageFolders(
    $0.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$backToPackageFolders, request, options: options);
  }

  $grpc.ResponseFuture<$1.BainFolderFiles> readPackageFolder(
    $1.BainFolderReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readPackageFolder, request, options: options);
  }

  $grpc.ResponseFuture<$1.BainPackageNotes> readPackageNotes(
    $0.InstallationDraftReference request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readPackageNotes, request, options: options);
  }

  $grpc.ResponseFuture<$0.ArchiveInstallationDraft> selectArchiveInstaller(
    $1.ArchiveInstallerChange request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$selectArchiveInstaller, request,
        options: options);
  }

  // method descriptors

  static final _$openPackageChoices =
      $grpc.ClientMethod<$0.InstallationDraftReference, $1.BainChoices>(
          '/modconductor.v1.BainInstallation/OpenPackageChoices',
          ($0.InstallationDraftReference value) => value.writeToBuffer(),
          $1.BainChoices.fromBuffer);
  static final _$selectPackageFolder =
      $grpc.ClientMethod<$1.BainFolderSelection, $1.BainChoices>(
          '/modconductor.v1.BainInstallation/SelectPackageFolder',
          ($1.BainFolderSelection value) => value.writeToBuffer(),
          $1.BainChoices.fromBuffer);
  static final _$selectAllPackageFolders =
      $grpc.ClientMethod<$1.BainAllFoldersSelection, $1.BainChoices>(
          '/modconductor.v1.BainInstallation/SelectAllPackageFolders',
          ($1.BainAllFoldersSelection value) => value.writeToBuffer(),
          $1.BainChoices.fromBuffer);
  static final _$includePackageFile =
      $grpc.ClientMethod<$1.BainFileSelection, $1.BainChoices>(
          '/modconductor.v1.BainInstallation/IncludePackageFile',
          ($1.BainFileSelection value) => value.writeToBuffer(),
          $1.BainChoices.fromBuffer);
  static final _$reviewPackageFiles =
      $grpc.ClientMethod<$0.InstallationDraftReference, $1.BainChoices>(
          '/modconductor.v1.BainInstallation/ReviewPackageFiles',
          ($0.InstallationDraftReference value) => value.writeToBuffer(),
          $1.BainChoices.fromBuffer);
  static final _$backToPackageFolders =
      $grpc.ClientMethod<$0.InstallationDraftReference, $1.BainChoices>(
          '/modconductor.v1.BainInstallation/BackToPackageFolders',
          ($0.InstallationDraftReference value) => value.writeToBuffer(),
          $1.BainChoices.fromBuffer);
  static final _$readPackageFolder =
      $grpc.ClientMethod<$1.BainFolderReference, $1.BainFolderFiles>(
          '/modconductor.v1.BainInstallation/ReadPackageFolder',
          ($1.BainFolderReference value) => value.writeToBuffer(),
          $1.BainFolderFiles.fromBuffer);
  static final _$readPackageNotes =
      $grpc.ClientMethod<$0.InstallationDraftReference, $1.BainPackageNotes>(
          '/modconductor.v1.BainInstallation/ReadPackageNotes',
          ($0.InstallationDraftReference value) => value.writeToBuffer(),
          $1.BainPackageNotes.fromBuffer);
  static final _$selectArchiveInstaller = $grpc.ClientMethod<
          $1.ArchiveInstallerChange, $0.ArchiveInstallationDraft>(
      '/modconductor.v1.BainInstallation/SelectArchiveInstaller',
      ($1.ArchiveInstallerChange value) => value.writeToBuffer(),
      $0.ArchiveInstallationDraft.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.BainInstallation')
abstract class BainInstallationServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.BainInstallation';

  BainInstallationServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.InstallationDraftReference, $1.BainChoices>(
            'OpenPackageChoices',
            openPackageChoices_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.InstallationDraftReference.fromBuffer(value),
            ($1.BainChoices value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BainFolderSelection, $1.BainChoices>(
        'SelectPackageFolder',
        selectPackageFolder_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.BainFolderSelection.fromBuffer(value),
        ($1.BainChoices value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BainAllFoldersSelection, $1.BainChoices>(
        'SelectAllPackageFolders',
        selectAllPackageFolders_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.BainAllFoldersSelection.fromBuffer(value),
        ($1.BainChoices value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BainFileSelection, $1.BainChoices>(
        'IncludePackageFile',
        includePackageFile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BainFileSelection.fromBuffer(value),
        ($1.BainChoices value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.InstallationDraftReference, $1.BainChoices>(
            'ReviewPackageFiles',
            reviewPackageFiles_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.InstallationDraftReference.fromBuffer(value),
            ($1.BainChoices value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.InstallationDraftReference, $1.BainChoices>(
            'BackToPackageFolders',
            backToPackageFolders_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.InstallationDraftReference.fromBuffer(value),
            ($1.BainChoices value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BainFolderReference, $1.BainFolderFiles>(
        'ReadPackageFolder',
        readPackageFolder_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.BainFolderReference.fromBuffer(value),
        ($1.BainFolderFiles value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.InstallationDraftReference, $1.BainPackageNotes>(
            'ReadPackageNotes',
            readPackageNotes_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.InstallationDraftReference.fromBuffer(value),
            ($1.BainPackageNotes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ArchiveInstallerChange,
            $0.ArchiveInstallationDraft>(
        'SelectArchiveInstaller',
        selectArchiveInstaller_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ArchiveInstallerChange.fromBuffer(value),
        ($0.ArchiveInstallationDraft value) => value.writeToBuffer()));
  }

  $async.Future<$1.BainChoices> openPackageChoices_Pre($grpc.ServiceCall $call,
      $async.Future<$0.InstallationDraftReference> $request) async {
    return openPackageChoices($call, await $request);
  }

  $async.Future<$1.BainChoices> openPackageChoices(
      $grpc.ServiceCall call, $0.InstallationDraftReference request);

  $async.Future<$1.BainChoices> selectPackageFolder_Pre($grpc.ServiceCall $call,
      $async.Future<$1.BainFolderSelection> $request) async {
    return selectPackageFolder($call, await $request);
  }

  $async.Future<$1.BainChoices> selectPackageFolder(
      $grpc.ServiceCall call, $1.BainFolderSelection request);

  $async.Future<$1.BainChoices> selectAllPackageFolders_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BainAllFoldersSelection> $request) async {
    return selectAllPackageFolders($call, await $request);
  }

  $async.Future<$1.BainChoices> selectAllPackageFolders(
      $grpc.ServiceCall call, $1.BainAllFoldersSelection request);

  $async.Future<$1.BainChoices> includePackageFile_Pre($grpc.ServiceCall $call,
      $async.Future<$1.BainFileSelection> $request) async {
    return includePackageFile($call, await $request);
  }

  $async.Future<$1.BainChoices> includePackageFile(
      $grpc.ServiceCall call, $1.BainFileSelection request);

  $async.Future<$1.BainChoices> reviewPackageFiles_Pre($grpc.ServiceCall $call,
      $async.Future<$0.InstallationDraftReference> $request) async {
    return reviewPackageFiles($call, await $request);
  }

  $async.Future<$1.BainChoices> reviewPackageFiles(
      $grpc.ServiceCall call, $0.InstallationDraftReference request);

  $async.Future<$1.BainChoices> backToPackageFolders_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InstallationDraftReference> $request) async {
    return backToPackageFolders($call, await $request);
  }

  $async.Future<$1.BainChoices> backToPackageFolders(
      $grpc.ServiceCall call, $0.InstallationDraftReference request);

  $async.Future<$1.BainFolderFiles> readPackageFolder_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BainFolderReference> $request) async {
    return readPackageFolder($call, await $request);
  }

  $async.Future<$1.BainFolderFiles> readPackageFolder(
      $grpc.ServiceCall call, $1.BainFolderReference request);

  $async.Future<$1.BainPackageNotes> readPackageNotes_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InstallationDraftReference> $request) async {
    return readPackageNotes($call, await $request);
  }

  $async.Future<$1.BainPackageNotes> readPackageNotes(
      $grpc.ServiceCall call, $0.InstallationDraftReference request);

  $async.Future<$0.ArchiveInstallationDraft> selectArchiveInstaller_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ArchiveInstallerChange> $request) async {
    return selectArchiveInstaller($call, await $request);
  }

  $async.Future<$0.ArchiveInstallationDraft> selectArchiveInstaller(
      $grpc.ServiceCall call, $1.ArchiveInstallerChange request);
}
