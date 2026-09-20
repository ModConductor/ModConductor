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

  @override
  String get credentialNexusMods => 'Nexus Mods';

  @override
  String get credentialDisconnectTitle => 'Disconnect from Nexus Mods?';

  @override
  String get credentialDisconnect => 'Disconnect';

  @override
  String get credentialDisconnectPause =>
      'Nexus downloads will pause. Local files will not be deleted.';

  @override
  String get credentialDisconnectRemovesSaved =>
      'Saved sign-in details will be removed.';

  @override
  String get credentialSessionOnlyTitle => 'Use this session only?';

  @override
  String get credentialSessionOnly => 'This session only';

  @override
  String get credentialSessionOnlyLost =>
      'New sign-in details will be lost when MC closes.';

  @override
  String get credentialSessionOnlyKeepsSaved =>
      'Existing saved sign-in details will not be deleted.';

  @override
  String get credentialClearSessionTitle => 'Clear session sign-in?';

  @override
  String get credentialRemoveSavedTitle => 'Remove saved sign-in?';

  @override
  String get credentialClearSignIn => 'Clear sign-in';

  @override
  String get credentialRemoveSignIn => 'Remove sign-in';

  @override
  String get credentialClearsSessionToo =>
      'MC will also clear sign-in details held for this session.';

  @override
  String get credentialStorageDetails => 'Sign-in storage details';

  @override
  String get credentialStorageLocked => 'System keyring is locked';

  @override
  String get credentialStorageUnavailable => 'Secure storage is not available';

  @override
  String get credentialStorageDenied => 'Access to secure storage was denied';

  @override
  String get credentialStorageTimedOut =>
      'Secure storage did not respond in time';

  @override
  String get credentialStorageCancelled =>
      'The storage operation was cancelled';

  @override
  String get credentialStorageTooLarge =>
      'Sign-in details exceed the storage limit';

  @override
  String get credentialStorageFailed => 'The storage operation failed';

  @override
  String get credentialNotConfigured =>
      'Sign-in is not configured in this build.';

  @override
  String get credentialWaitingSignIn => 'Waiting for sign-in';

  @override
  String credentialConnectedAs(String name) {
    return 'Connected as $name';
  }

  @override
  String get credentialPremium => 'Premium';

  @override
  String get credentialNotConnected => 'Not connected';

  @override
  String get credentialNotSignedIn => 'Not signed in';

  @override
  String get credentialNotSaved => 'Sign-in details were not saved';

  @override
  String get credentialCancelSignIn => 'Cancel sign-in';

  @override
  String get credentialCheckAccount => 'Check account';

  @override
  String get credentialSignInAgain => 'Sign in again';

  @override
  String get credentialConnect => 'Connect';

  @override
  String get credentialSignIn => 'Sign in';

  @override
  String get credentialStorageCheckFailed =>
      'Sign-in storage could not be checked';

  @override
  String get credentialCheckEngine =>
      'Check the engine connection and try again.';

  @override
  String get credentialSavedNotRemoved => 'Saved sign-in not removed';

  @override
  String get credentialUnlockKeyring =>
      'Unlock the system keyring and try again.';

  @override
  String get credentialSaved => 'Sign-in details are saved on this computer.';

  @override
  String get credentialNoneSaved => 'No saved sign-in details.';

  @override
  String get credentialCannotCheckSaved =>
      'Saved sign-in details cannot be checked.';

  @override
  String get credentialNewSignIns => 'New sign-ins';

  @override
  String get credentialSaveOnComputer => 'Save on this computer';

  @override
  String get credentialCheckStorage => 'Check storage';

  @override
  String get credentialRetryRemoval => 'Retry removal';

  @override
  String get nexusLinks => 'Nexus download links';

  @override
  String get nexusOpenLinks =>
      'Open Mod Manager Download links with Mod Conductor.';

  @override
  String get nexusRemoveWindowsTitle => 'Remove MC from Windows Settings?';

  @override
  String get nexusRemoveTitle => 'Remove Nexus link setup?';

  @override
  String get nexusRemoveWindows => 'Remove from Windows Settings';

  @override
  String get nexusRemove => 'Remove link setup';

  @override
  String get nexusChooseOtherDefault =>
      'Choose another default app in Windows Settings.';

  @override
  String get nexusRestoreDefault =>
      'The previous default app will be restored only if Mod Conductor is still the default.';

  @override
  String get nexusAvailableWindows => 'Available in Windows Settings';

  @override
  String get nexusAvailable => 'Link setup is available';

  @override
  String get nexusNotAddedWindows => 'Not added to Windows Settings';

  @override
  String get nexusOff => 'Link setup is off';

  @override
  String get nexusCannotCheck => 'Link setup cannot be checked';

  @override
  String nexusDefaultApp(String app) {
    return 'Default app: $app';
  }

  @override
  String get nexusModConductor => 'Mod Conductor';

  @override
  String get nexusAnotherApp => 'Another app';

  @override
  String get nexusNotSet => 'Not set';

  @override
  String get nexusCannotCheckDefault => 'Cannot check';

  @override
  String get nexusChooseDefaultWindows =>
      'Choose the default app in Windows Settings.';

  @override
  String get nexusDefaultChanged =>
      'The default app has changed. Removing MC will keep your current choice.';

  @override
  String get nexusCheckFailed =>
      'The Nexus link setup could not be checked. Check the engine connection.';

  @override
  String get nexusAddWindows => 'Add to Windows Settings';

  @override
  String get nexusUseModConductor => 'Use Mod Conductor';

  @override
  String get nexusOpenWindows => 'Open Windows Settings';

  @override
  String get nexusCheckDefault => 'Check default app';
}
