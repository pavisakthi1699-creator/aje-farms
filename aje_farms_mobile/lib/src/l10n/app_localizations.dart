import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('sw')
  ];

  /// The title of the application
  ///
  /// In sw, this message translates to:
  /// **'Chuo Kikuu Cha Mtaani'**
  String get appTitle;

  /// No description provided for @translateToEnglish.
  ///
  /// In sw, this message translates to:
  /// **'Tafsiri kwa Kiingereza'**
  String get translateToEnglish;

  /// No description provided for @language.
  ///
  /// In sw, this message translates to:
  /// **'Lugha'**
  String get language;

  /// No description provided for @swahili.
  ///
  /// In sw, this message translates to:
  /// **'Kiswahili'**
  String get swahili;

  /// No description provided for @english.
  ///
  /// In sw, this message translates to:
  /// **'Kiingereza'**
  String get english;

  /// No description provided for @settings.
  ///
  /// In sw, this message translates to:
  /// **'Mipangilio'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In sw, this message translates to:
  /// **'Profaili'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In sw, this message translates to:
  /// **'Nyumbani'**
  String get home;

  /// No description provided for @courses.
  ///
  /// In sw, this message translates to:
  /// **'Kozi'**
  String get courses;

  /// No description provided for @community.
  ///
  /// In sw, this message translates to:
  /// **'Jamii'**
  String get community;

  /// No description provided for @notifications.
  ///
  /// In sw, this message translates to:
  /// **'Taarifa'**
  String get notifications;

  /// No description provided for @aiSupport.
  ///
  /// In sw, this message translates to:
  /// **'Msaidizi wa AI'**
  String get aiSupport;

  /// No description provided for @theme.
  ///
  /// In sw, this message translates to:
  /// **'Mandhari'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In sw, this message translates to:
  /// **'Mwanga'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In sw, this message translates to:
  /// **'Giza'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In sw, this message translates to:
  /// **'Mfumo'**
  String get systemTheme;

  /// No description provided for @signOut.
  ///
  /// In sw, this message translates to:
  /// **'Ondoka'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In sw, this message translates to:
  /// **'Ingia'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In sw, this message translates to:
  /// **'Jiandikishe'**
  String get signUp;

  /// No description provided for @searchHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta kozi, makala au mada...'**
  String get searchHint;

  /// No description provided for @save.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In sw, this message translates to:
  /// **'Ghairi'**
  String get cancel;

  /// No description provided for @editProfile.
  ///
  /// In sw, this message translates to:
  /// **'Hariri Profaili'**
  String get editProfile;

  /// No description provided for @adminDashboard.
  ///
  /// In sw, this message translates to:
  /// **'Dashibodi ya Admin'**
  String get adminDashboard;

  /// No description provided for @notificationsSettingTitle.
  ///
  /// In sw, this message translates to:
  /// **'Arifa za mafunzo na jamii'**
  String get notificationsSettingTitle;

  /// No description provided for @notificationsSettingSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Washa au zima vikumbusho kwenye app.'**
  String get notificationsSettingSubtitle;
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
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
