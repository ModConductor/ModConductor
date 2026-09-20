// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mod Conductor';

  @override
  String get changeAppearance => 'Change appearance';

  @override
  String get quit => 'Quit';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get preferences => 'Preferences';

  @override
  String openRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Open $count requests',
      one: 'Open 1 request',
      zero: 'Open requests',
    );
    return '$_temp0';
  }

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connection in progress';

  @override
  String get notConnected => 'Not connected';

  @override
  String get connectionError => 'Connection error';

  @override
  String get connection => 'Connection';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get cannotOpenFromOtherApps => 'Cannot open from other apps';

  @override
  String get openFromThisWindow =>
      'Open workspaces and archives from this window.';

  @override
  String get display => 'Display';

  @override
  String get scope => 'Scope';

  @override
  String get application => 'Application';

  @override
  String get currentWorkspace => 'Current workspace';

  @override
  String get appearance => 'Appearance';

  @override
  String get textSize => 'Text size';

  @override
  String get contrast => 'Contrast';

  @override
  String get useApplicationSettings => 'Use application settings';

  @override
  String get systemAppearance => 'Use system appearance';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get systemContrast => 'Use system contrast';

  @override
  String get standardContrast => 'Standard';

  @override
  String get highContrast => 'High contrast';

  @override
  String get apply => 'Apply';

  @override
  String get cancel => 'Cancel';

  @override
  String get activePreferences => 'Active preferences';

  @override
  String get close => 'Close';

  @override
  String preferencesSaved(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Preferences saved at $timeString';
  }

  @override
  String get settingsLoadFailed => 'The settings could not be loaded.';

  @override
  String get settingsSaveFailed => 'The settings could not be saved.';

  @override
  String get workspaceSettingsUnavailable =>
      'Open a workspace to change its settings.';

  @override
  String textScalePercent(int value) {
    return '$value%';
  }

  @override
  String get closeInspector => 'Close inspector';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Enter a name.';

  @override
  String get closeFilter => 'Close filter';

  @override
  String get noItems => 'No items.';

  @override
  String get noMatches => 'No matches in loaded items.';

  @override
  String get expanded => 'Expanded';

  @override
  String get collapsed => 'Collapsed';

  @override
  String get cancelLoad => 'Cancel load';

  @override
  String get loadMore => 'Load more';

  @override
  String get retry => 'Retry';

  @override
  String refreshCollection(String title) {
    return 'Refresh $title';
  }

  @override
  String collapseItem(String label) {
    return 'Collapse $label';
  }

  @override
  String expandItem(String label) {
    return 'Expand $label';
  }

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusUnavailable => 'Unavailable';

  @override
  String get statusUnsupported => 'Unsupported';

  @override
  String get statusInformation => 'Information';

  @override
  String get statusError => 'Error';
}
