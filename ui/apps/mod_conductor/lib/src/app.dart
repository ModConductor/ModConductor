import 'dart:async';
import 'dart:io';

import 'dart:ui' show AppExitType, AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

part 'shell.dart';
part 'welcome.dart';
part 'preferences.dart';
part 'status.dart';
part 'desktop_host.dart';

void _quitDesktop() {
  ServicesBinding.instance.exitApplication(AppExitType.cancelable);
}

void startDesktop() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopHost());
}

enum _Destination { welcome, preferences }

typedef _Preferences = ({ThemeMode theme, double scale});

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Use system appearance',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

class ModConductorApp extends StatefulWidget {
  const ModConductorApp({
    super.key,
    this.onQuit,
    this.onRetry,
    this.status = const DesktopDisconnected(),
  });
  final DesktopStatus status;
  final VoidCallback? onQuit;
  final VoidCallback? onRetry;
  @override
  State<ModConductorApp> createState() => _ModConductorAppState();
}

class _ModConductorAppState extends State<ModConductorApp> {
  _Destination _destination = _Destination.welcome;
  _Preferences _applied = (theme: ThemeMode.system, scale: 1);
  _Preferences _draft = (theme: ThemeMode.system, scale: 1);
  final _welcomeFocus = FocusNode(debugLabel: 'Welcome navigation');
  final _preferencesFocus = FocusNode(debugLabel: 'Preferences navigation');
  final _detailsFocus = FocusNode(debugLabel: 'Active preferences');
  final _quitFocus = FocusNode(debugLabel: 'Quit');

  @override
  void dispose() {
    for (final node in [
      _welcomeFocus,
      _preferencesFocus,
      _detailsFocus,
      _quitFocus,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  void _navigate(_Destination value) {
    setState(() => _destination = value);
    (value == _Destination.welcome ? _welcomeFocus : _preferencesFocus)
        .requestFocus();
  }

  void _quickTheme(ThemeMode value) => setState(() {
    _applied = (theme: value, scale: _applied.scale);
    _draft = (theme: value, scale: _draft.scale);
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mod Conductor',
    debugShowCheckedModeBanner: false,
    theme: mcTheme(Brightness.light),
    darkTheme: mcTheme(Brightness.dark),
    themeMode: _applied.theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(_applied.scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              _navigate(_Destination.preferences),
          const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
              _navigate(_Destination.welcome),
          const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
              _navigate(_Destination.preferences),
          const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
              widget.onQuit ?? _quitDesktop,
        },
        child: _DesktopShell(
          connectionStatus: widget.status,
          destination: _destination,
          onNavigate: _navigate,
          onQuit: widget.onQuit ?? _quitDesktop,
          welcomeFocus: _welcomeFocus,
          preferencesFocus: _preferencesFocus,
          quitFocus: _quitFocus,
          child: IndexedStack(
            index: _destination.index,
            children: [
              ExcludeFocus(
                excluding: _destination != _Destination.welcome,
                child: switch (widget.status) {
                  DesktopFailure(:final reason) => _FailurePage(
                    reason: reason,
                    onRetry: widget.onRetry,
                    onPreferences: () => _navigate(_Destination.preferences),
                  ),
                  DesktopDisconnected() ||
                  DesktopConnecting() ||
                  DesktopConnected() => _WelcomePage(
                    theme: _applied.theme,
                    onTheme: _quickTheme,
                    onPreferences: () => _navigate(_Destination.preferences),
                  ),
                },
              ),
              ExcludeFocus(
                excluding: _destination != _Destination.preferences,
                child: _PreferencesPage(
                  applied: _applied,
                  draft: _draft,
                  detailsFocus: _detailsFocus,
                  onDraft: (value) => setState(() => _draft = value),
                  onSave: () => setState(() => _applied = _draft),
                  onCancel: () => setState(() => _draft = _applied),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
