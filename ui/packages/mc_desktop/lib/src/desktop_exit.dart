import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:flutter/services.dart';

// Flutter Linux retains cancelled native exit requests, so approve shutdown first.
Future<AppExitResponse> _exitApplication() =>
    ServicesBinding.instance.exitApplication(AppExitType.required);

class DesktopExit {
  DesktopExit({required this.close, this.exitApplication = _exitApplication});

  final Future<bool> Function() close;
  final Future<AppExitResponse> Function() exitApplication;
  Future<AppExitResponse>? _pending;
  bool _requestedByPlatform = false;

  Future<AppExitResponse> request() => _pending ??= _request();

  Future<AppExitResponse> requestedByPlatform() {
    _requestedByPlatform = true;
    return request();
  }

  Future<AppExitResponse> _request() async {
    var response = AppExitResponse.cancel;
    try {
      if (!await close()) return response;
      response = _requestedByPlatform
          ? AppExitResponse.exit
          : await exitApplication();
      return response;
    } finally {
      if (response == AppExitResponse.cancel) {
        _pending = null;
        _requestedByPlatform = false;
      }
    }
  }
}
