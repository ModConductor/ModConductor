// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_organization.proto.

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

import 'mod_organization.pb.dart' as $0;

export 'mod_organization.pb.dart';

@$pb.GrpcServiceName('modconductor.v1.ModOrganizationOperations')
class ModOrganizationOperationsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ModOrganizationOperationsClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.CategoriesReply> readCategories(
    $0.ReadCategoriesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readCategories, request, options: options);
  }

  $grpc.ResponseFuture<$0.OrganizationChangeReply> editCategory(
    $0.EditCategoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$editCategory, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModQueryReply> queryMods(
    $0.QueryModsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$queryMods, request, options: options);
  }

  // method descriptors

  static final _$readCategories =
      $grpc.ClientMethod<$0.ReadCategoriesRequest, $0.CategoriesReply>(
          '/modconductor.v1.ModOrganizationOperations/ReadCategories',
          ($0.ReadCategoriesRequest value) => value.writeToBuffer(),
          $0.CategoriesReply.fromBuffer);
  static final _$editCategory =
      $grpc.ClientMethod<$0.EditCategoryRequest, $0.OrganizationChangeReply>(
          '/modconductor.v1.ModOrganizationOperations/EditCategory',
          ($0.EditCategoryRequest value) => value.writeToBuffer(),
          $0.OrganizationChangeReply.fromBuffer);
  static final _$queryMods =
      $grpc.ClientMethod<$0.QueryModsRequest, $0.ModQueryReply>(
          '/modconductor.v1.ModOrganizationOperations/QueryMods',
          ($0.QueryModsRequest value) => value.writeToBuffer(),
          $0.ModQueryReply.fromBuffer);
}

@$pb.GrpcServiceName('modconductor.v1.ModOrganizationOperations')
abstract class ModOrganizationOperationsServiceBase extends $grpc.Service {
  $core.String get $name => 'modconductor.v1.ModOrganizationOperations';

  ModOrganizationOperationsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ReadCategoriesRequest, $0.CategoriesReply>(
            'ReadCategories',
            readCategories_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReadCategoriesRequest.fromBuffer(value),
            ($0.CategoriesReply value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.EditCategoryRequest, $0.OrganizationChangeReply>(
            'EditCategory',
            editCategory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.EditCategoryRequest.fromBuffer(value),
            ($0.OrganizationChangeReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryModsRequest, $0.ModQueryReply>(
        'QueryMods',
        queryMods_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryModsRequest.fromBuffer(value),
        ($0.ModQueryReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.CategoriesReply> readCategories_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadCategoriesRequest> $request) async {
    return readCategories($call, await $request);
  }

  $async.Future<$0.CategoriesReply> readCategories(
      $grpc.ServiceCall call, $0.ReadCategoriesRequest request);

  $async.Future<$0.OrganizationChangeReply> editCategory_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.EditCategoryRequest> $request) async {
    return editCategory($call, await $request);
  }

  $async.Future<$0.OrganizationChangeReply> editCategory(
      $grpc.ServiceCall call, $0.EditCategoryRequest request);

  $async.Future<$0.ModQueryReply> queryMods_Pre($grpc.ServiceCall $call,
      $async.Future<$0.QueryModsRequest> $request) async {
    return queryMods($call, await $request);
  }

  $async.Future<$0.ModQueryReply> queryMods(
      $grpc.ServiceCall call, $0.QueryModsRequest request);
}
