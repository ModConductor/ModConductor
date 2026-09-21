import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mod Conductor'**
  String get appTitle;

  /// No description provided for @changeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Change appearance'**
  String get changeAppearance;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @workspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @openRequests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Open requests} =1{Open 1 request} other{Open {count} requests}}'**
  String openRequests(int count);

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connection in progress'**
  String get connecting;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @cannotOpenFromOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Cannot open from other apps'**
  String get cannotOpenFromOtherApps;

  /// No description provided for @openFromThisWindow.
  ///
  /// In en, this message translates to:
  /// **'Open workspaces and archives from this window.'**
  String get openFromThisWindow;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scope;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// No description provided for @currentWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Current workspace'**
  String get currentWorkspace;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @useApplicationSettings.
  ///
  /// In en, this message translates to:
  /// **'Use application settings'**
  String get useApplicationSettings;

  /// No description provided for @systemAppearance.
  ///
  /// In en, this message translates to:
  /// **'Use system appearance'**
  String get systemAppearance;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @systemContrast.
  ///
  /// In en, this message translates to:
  /// **'Use system contrast'**
  String get systemContrast;

  /// No description provided for @standardContrast.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standardContrast;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @activePreferences.
  ///
  /// In en, this message translates to:
  /// **'Active preferences'**
  String get activePreferences;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved at {time}'**
  String preferencesSaved(DateTime time);

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The settings could not be loaded.'**
  String get settingsLoadFailed;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The settings could not be saved.'**
  String get settingsSaveFailed;

  /// No description provided for @workspaceSettingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Open a workspace to change its settings.'**
  String get workspaceSettingsUnavailable;

  /// No description provided for @textScalePercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String textScalePercent(int value);

  /// No description provided for @closeInspector.
  ///
  /// In en, this message translates to:
  /// **'Close inspector'**
  String get closeInspector;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get enterName;

  /// No description provided for @closeFilter.
  ///
  /// In en, this message translates to:
  /// **'Close filter'**
  String get closeFilter;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items.'**
  String get noItems;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches in loaded items.'**
  String get noMatches;

  /// No description provided for @expanded.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get expanded;

  /// No description provided for @collapsed.
  ///
  /// In en, this message translates to:
  /// **'Collapsed'**
  String get collapsed;

  /// No description provided for @cancelLoad.
  ///
  /// In en, this message translates to:
  /// **'Cancel load'**
  String get cancelLoad;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refreshCollection.
  ///
  /// In en, this message translates to:
  /// **'Refresh {title}'**
  String refreshCollection(String title);

  /// No description provided for @collapseItem.
  ///
  /// In en, this message translates to:
  /// **'Collapse {label}'**
  String collapseItem(String label);

  /// No description provided for @expandItem.
  ///
  /// In en, this message translates to:
  /// **'Expand {label}'**
  String expandItem(String label);

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @statusUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get statusUnsupported;

  /// No description provided for @statusInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get statusInformation;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @credentialNexusMods.
  ///
  /// In en, this message translates to:
  /// **'Nexus Mods'**
  String get credentialNexusMods;

  /// No description provided for @credentialDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from Nexus Mods?'**
  String get credentialDisconnectTitle;

  /// No description provided for @credentialDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get credentialDisconnect;

  /// No description provided for @credentialDisconnectPause.
  ///
  /// In en, this message translates to:
  /// **'Nexus downloads will pause. Local files will not be deleted.'**
  String get credentialDisconnectPause;

  /// No description provided for @credentialDisconnectRemovesSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved sign-in details will be removed.'**
  String get credentialDisconnectRemovesSaved;

  /// No description provided for @credentialSessionOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Use this session only?'**
  String get credentialSessionOnlyTitle;

  /// No description provided for @credentialSessionOnly.
  ///
  /// In en, this message translates to:
  /// **'This session only'**
  String get credentialSessionOnly;

  /// No description provided for @credentialSessionOnlyLost.
  ///
  /// In en, this message translates to:
  /// **'New sign-in details will be lost when MC closes.'**
  String get credentialSessionOnlyLost;

  /// No description provided for @credentialSessionOnlyKeepsSaved.
  ///
  /// In en, this message translates to:
  /// **'Existing saved sign-in details will not be deleted.'**
  String get credentialSessionOnlyKeepsSaved;

  /// No description provided for @credentialClearSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear session sign-in?'**
  String get credentialClearSessionTitle;

  /// No description provided for @credentialRemoveSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove saved sign-in?'**
  String get credentialRemoveSavedTitle;

  /// No description provided for @credentialClearSignIn.
  ///
  /// In en, this message translates to:
  /// **'Clear sign-in'**
  String get credentialClearSignIn;

  /// No description provided for @credentialRemoveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Remove sign-in'**
  String get credentialRemoveSignIn;

  /// No description provided for @credentialClearsSessionToo.
  ///
  /// In en, this message translates to:
  /// **'MC will also clear sign-in details held for this session.'**
  String get credentialClearsSessionToo;

  /// No description provided for @credentialStorageDetails.
  ///
  /// In en, this message translates to:
  /// **'Sign-in storage details'**
  String get credentialStorageDetails;

  /// No description provided for @credentialStorageLocked.
  ///
  /// In en, this message translates to:
  /// **'System keyring is locked'**
  String get credentialStorageLocked;

  /// No description provided for @credentialStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Secure storage is not available'**
  String get credentialStorageUnavailable;

  /// No description provided for @credentialStorageDenied.
  ///
  /// In en, this message translates to:
  /// **'Access to secure storage was denied'**
  String get credentialStorageDenied;

  /// No description provided for @credentialStorageTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Secure storage did not respond in time'**
  String get credentialStorageTimedOut;

  /// No description provided for @credentialStorageCancelled.
  ///
  /// In en, this message translates to:
  /// **'The storage operation was cancelled'**
  String get credentialStorageCancelled;

  /// No description provided for @credentialStorageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Sign-in details exceed the storage limit'**
  String get credentialStorageTooLarge;

  /// No description provided for @credentialStorageFailed.
  ///
  /// In en, this message translates to:
  /// **'The storage operation failed'**
  String get credentialStorageFailed;

  /// No description provided for @credentialWaitingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sign-in'**
  String get credentialWaitingSignIn;

  /// No description provided for @credentialConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {name}'**
  String credentialConnectedAs(String name);

  /// No description provided for @credentialPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get credentialPremium;

  /// No description provided for @credentialNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get credentialNotConnected;

  /// No description provided for @credentialNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get credentialNotSignedIn;

  /// No description provided for @credentialNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Sign-in details were not saved'**
  String get credentialNotSaved;

  /// No description provided for @credentialCancelSignIn.
  ///
  /// In en, this message translates to:
  /// **'Cancel sign-in'**
  String get credentialCancelSignIn;

  /// No description provided for @credentialCheckAccount.
  ///
  /// In en, this message translates to:
  /// **'Check account'**
  String get credentialCheckAccount;

  /// No description provided for @credentialSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get credentialSignInAgain;

  /// No description provided for @credentialConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get credentialConnect;

  /// No description provided for @credentialSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get credentialSignIn;

  /// No description provided for @credentialPersonalApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter personal API key'**
  String get credentialPersonalApiKey;

  /// No description provided for @credentialShowPersonalApiKey.
  ///
  /// In en, this message translates to:
  /// **'Show personal API key'**
  String get credentialShowPersonalApiKey;

  /// No description provided for @credentialHidePersonalApiKey.
  ///
  /// In en, this message translates to:
  /// **'Hide personal API key'**
  String get credentialHidePersonalApiKey;

  /// No description provided for @credentialSubmitPersonalApiKey.
  ///
  /// In en, this message translates to:
  /// **'Connect with API key'**
  String get credentialSubmitPersonalApiKey;

  /// No description provided for @credentialStorageCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in storage could not be checked'**
  String get credentialStorageCheckFailed;

  /// No description provided for @credentialCheckEngine.
  ///
  /// In en, this message translates to:
  /// **'Check the engine connection and try again.'**
  String get credentialCheckEngine;

  /// No description provided for @credentialSavedNotRemoved.
  ///
  /// In en, this message translates to:
  /// **'Saved sign-in not removed'**
  String get credentialSavedNotRemoved;

  /// No description provided for @credentialUnlockKeyring.
  ///
  /// In en, this message translates to:
  /// **'Unlock the system keyring and try again.'**
  String get credentialUnlockKeyring;

  /// No description provided for @credentialSaved.
  ///
  /// In en, this message translates to:
  /// **'Sign-in details are saved on this computer.'**
  String get credentialSaved;

  /// No description provided for @credentialNoneSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved sign-in details.'**
  String get credentialNoneSaved;

  /// No description provided for @credentialCannotCheckSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved sign-in details cannot be checked.'**
  String get credentialCannotCheckSaved;

  /// No description provided for @credentialNewSignIns.
  ///
  /// In en, this message translates to:
  /// **'New sign-ins'**
  String get credentialNewSignIns;

  /// No description provided for @credentialSaveOnComputer.
  ///
  /// In en, this message translates to:
  /// **'Save on this computer'**
  String get credentialSaveOnComputer;

  /// No description provided for @credentialCheckStorage.
  ///
  /// In en, this message translates to:
  /// **'Check storage'**
  String get credentialCheckStorage;

  /// No description provided for @credentialRetryRemoval.
  ///
  /// In en, this message translates to:
  /// **'Retry removal'**
  String get credentialRetryRemoval;

  /// No description provided for @nexusLinks.
  ///
  /// In en, this message translates to:
  /// **'Nexus download links'**
  String get nexusLinks;

  /// No description provided for @nexusOpenLinks.
  ///
  /// In en, this message translates to:
  /// **'Open Mod Manager Download links with Mod Conductor.'**
  String get nexusOpenLinks;

  /// No description provided for @nexusRemoveWindowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove MC from Windows Settings?'**
  String get nexusRemoveWindowsTitle;

  /// No description provided for @nexusRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Nexus link setup?'**
  String get nexusRemoveTitle;

  /// No description provided for @nexusRemoveWindows.
  ///
  /// In en, this message translates to:
  /// **'Remove from Windows Settings'**
  String get nexusRemoveWindows;

  /// No description provided for @nexusRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link setup'**
  String get nexusRemove;

  /// No description provided for @nexusChooseOtherDefault.
  ///
  /// In en, this message translates to:
  /// **'Choose another default app in Windows Settings.'**
  String get nexusChooseOtherDefault;

  /// No description provided for @nexusRestoreDefault.
  ///
  /// In en, this message translates to:
  /// **'The previous default app will be restored only if Mod Conductor is still the default.'**
  String get nexusRestoreDefault;

  /// No description provided for @nexusAvailableWindows.
  ///
  /// In en, this message translates to:
  /// **'Available in Windows Settings'**
  String get nexusAvailableWindows;

  /// No description provided for @nexusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Link setup is available'**
  String get nexusAvailable;

  /// No description provided for @nexusNotAddedWindows.
  ///
  /// In en, this message translates to:
  /// **'Not added to Windows Settings'**
  String get nexusNotAddedWindows;

  /// No description provided for @nexusOff.
  ///
  /// In en, this message translates to:
  /// **'Link setup is off'**
  String get nexusOff;

  /// No description provided for @nexusCannotCheck.
  ///
  /// In en, this message translates to:
  /// **'Link setup cannot be checked'**
  String get nexusCannotCheck;

  /// No description provided for @nexusDefaultApp.
  ///
  /// In en, this message translates to:
  /// **'Default app: {app}'**
  String nexusDefaultApp(String app);

  /// No description provided for @nexusModConductor.
  ///
  /// In en, this message translates to:
  /// **'Mod Conductor'**
  String get nexusModConductor;

  /// No description provided for @nexusAnotherApp.
  ///
  /// In en, this message translates to:
  /// **'Another app'**
  String get nexusAnotherApp;

  /// No description provided for @nexusNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get nexusNotSet;

  /// No description provided for @nexusCannotCheckDefault.
  ///
  /// In en, this message translates to:
  /// **'Cannot check'**
  String get nexusCannotCheckDefault;

  /// No description provided for @nexusChooseDefaultWindows.
  ///
  /// In en, this message translates to:
  /// **'Choose the default app in Windows Settings.'**
  String get nexusChooseDefaultWindows;

  /// No description provided for @nexusDefaultChanged.
  ///
  /// In en, this message translates to:
  /// **'The default app has changed. Removing MC will keep your current choice.'**
  String get nexusDefaultChanged;

  /// No description provided for @nexusCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The Nexus link setup could not be checked. Check the engine connection.'**
  String get nexusCheckFailed;

  /// No description provided for @nexusAddWindows.
  ///
  /// In en, this message translates to:
  /// **'Add to Windows Settings'**
  String get nexusAddWindows;

  /// No description provided for @nexusUseModConductor.
  ///
  /// In en, this message translates to:
  /// **'Use Mod Conductor'**
  String get nexusUseModConductor;

  /// No description provided for @nexusOpenWindows.
  ///
  /// In en, this message translates to:
  /// **'Open Windows Settings'**
  String get nexusOpenWindows;

  /// No description provided for @nexusCheckDefault.
  ///
  /// In en, this message translates to:
  /// **'Check default app'**
  String get nexusCheckDefault;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
