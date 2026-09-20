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
