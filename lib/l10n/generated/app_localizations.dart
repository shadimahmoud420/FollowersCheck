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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Follower Check'**
  String get appTitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @neverPassword.
  ///
  /// In en, this message translates to:
  /// **'We never ask for your password'**
  String get neverPassword;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'See who unfollowed you'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Follower Check compares two copies of your own Instagram data export and shows who unfollowed you, who doesn\'t follow you back and who your new followers are.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Export your data as JSON'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'In the Instagram app, request a copy of your \"Followers and following\" in JSON format. Instagram will notify you when the file is ready to download.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'We never ask for your password and never sign in to your account. Your files are processed only on this device and are never uploaded anywhere.'**
  String get onboardingBody3;

  /// No description provided for @exportStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to export'**
  String get exportStepsTitle;

  /// No description provided for @exportStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Settings › Accounts Center'**
  String get exportStep1;

  /// No description provided for @exportStep2.
  ///
  /// In en, this message translates to:
  /// **'Your information and permissions › Export your information'**
  String get exportStep2;

  /// No description provided for @exportStep3.
  ///
  /// In en, this message translates to:
  /// **'Create export › Export to device'**
  String get exportStep3;

  /// No description provided for @exportStep4.
  ///
  /// In en, this message translates to:
  /// **'Customize information: select only \"Followers and following\"'**
  String get exportStep4;

  /// No description provided for @exportStep5.
  ///
  /// In en, this message translates to:
  /// **'Date range: All time · Format: JSON'**
  String get exportStep5;

  /// No description provided for @exportStep6.
  ///
  /// In en, this message translates to:
  /// **'Download the ZIP when it\'s ready, then import it here'**
  String get exportStep6;

  /// No description provided for @navResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get navResults;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import export'**
  String get importTitle;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the ZIP you downloaded, or the followers_1.json and following.json files from inside it.'**
  String get importIntro;

  /// No description provided for @importPick.
  ///
  /// In en, this message translates to:
  /// **'Choose ZIP or JSON files'**
  String get importPick;

  /// No description provided for @importProcessing.
  ///
  /// In en, this message translates to:
  /// **'Reading your files on this device…'**
  String get importProcessing;

  /// No description provided for @importSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get importSuccessTitle;

  /// No description provided for @importSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Followers: {followers} · Following: {following}'**
  String importSuccessBody(int followers, int following);

  /// No description provided for @importMissingFollowing.
  ///
  /// In en, this message translates to:
  /// **'No following list was found, so \"Not following you back\" is unavailable for this snapshot.'**
  String get importMissingFollowing;

  /// No description provided for @viewResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get viewResults;

  /// No description provided for @errorHtml.
  ///
  /// In en, this message translates to:
  /// **'This export is in HTML format. Please export again and choose JSON as the format.'**
  String get errorHtml;

  /// No description provided for @errorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The ZIP file couldn\'t be opened. Please download it again and retry.'**
  String get errorCorrupt;

  /// No description provided for @errorNothing.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find followers data in these files. Make sure you selected \"Followers and following\" and JSON format.'**
  String get errorNothing;

  /// No description provided for @errorMissingFollowers.
  ///
  /// In en, this message translates to:
  /// **'Only a following list was found. Please include the followers file (followers_1.json) too.'**
  String get errorMissingFollowers;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading the file. Please try again.'**
  String get errorGeneric;

  /// No description provided for @freeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'The free plan includes 1 comparison per week. Your next free comparison is available on {date}.'**
  String freeLimitReached(String date);

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgrade;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @tabUnfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed you'**
  String get tabUnfollowed;

  /// No description provided for @tabNotFollowingBack.
  ///
  /// In en, this message translates to:
  /// **'Not following back'**
  String get tabNotFollowingBack;

  /// No description provided for @tabNewFollowers.
  ///
  /// In en, this message translates to:
  /// **'New followers'**
  String get tabNewFollowers;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search usernames'**
  String get searchHint;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get couldNotOpenLink;

  /// No description provided for @noDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataTitle;

  /// No description provided for @noDataBody.
  ///
  /// In en, this message translates to:
  /// **'Import your first export to get started.'**
  String get noDataBody;

  /// No description provided for @needsTwoSnapshots.
  ///
  /// In en, this message translates to:
  /// **'This is your first snapshot. Import a newer export later to see who unfollowed you and who\'s new.'**
  String get needsTwoSnapshots;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'Nobody here'**
  String get emptyList;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No usernames match your search'**
  String get noSearchResults;

  /// No description provided for @followingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This snapshot has no following list. Import an export that includes following.json.'**
  String get followingUnavailable;

  /// No description provided for @comparing.
  ///
  /// In en, this message translates to:
  /// **'{previous} → {latest}'**
  String comparing(String previous, String latest);

  /// No description provided for @snapshotFrom.
  ///
  /// In en, this message translates to:
  /// **'Snapshot from {date}'**
  String snapshotFrom(String date);

  /// No description provided for @shownCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String shownCount(int shown, int total);

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalCount(int count);

  /// No description provided for @newImport.
  ///
  /// In en, this message translates to:
  /// **'New import'**
  String get newImport;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your snapshots will appear here.'**
  String get historyEmpty;

  /// No description provided for @followersLabel.
  ///
  /// In en, this message translates to:
  /// **'Followers: {count}'**
  String followersLabel(int count);

  /// No description provided for @followingLabel.
  ///
  /// In en, this message translates to:
  /// **'Following: {count}'**
  String followingLabel(int count);

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Followers over time'**
  String get chartTitle;

  /// No description provided for @chartLocked.
  ///
  /// In en, this message translates to:
  /// **'Charts are a Premium feature'**
  String get chartLocked;

  /// No description provided for @chartNeedsTwo.
  ///
  /// In en, this message translates to:
  /// **'Import at least two snapshots to see a chart.'**
  String get chartNeedsTwo;

  /// No description provided for @historyLocked.
  ///
  /// In en, this message translates to:
  /// **'{count} older snapshots are available with Premium'**
  String historyLocked(int count);

  /// No description provided for @deleteSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot?'**
  String get deleteSnapshotTitle;

  /// No description provided for @deleteSnapshotBody.
  ///
  /// In en, this message translates to:
  /// **'This snapshot will be permanently removed from this device.'**
  String get deleteSnapshotBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Export reminder'**
  String get reminders;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A local notification reminding you to request a fresh export'**
  String get remindersSubtitle;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @reminderWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reminderWeekly;

  /// No description provided for @reminderBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get reminderBiweekly;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for a fresh export'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Request a new \"Followers and following\" export to see who unfollowed you.'**
  String get reminderNotificationBody;

  /// No description provided for @reminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled for this app. Enable them in system settings.'**
  String get reminderPermissionDenied;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get dataSection;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'All snapshots will be permanently deleted from this device. This can\'t be undone.'**
  String get deleteAllBody;

  /// No description provided for @dataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get dataDeleted;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @showGuide.
  ///
  /// In en, this message translates to:
  /// **'Show export guide'**
  String get showGuide;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active'**
  String get premiumActive;

  /// No description provided for @premiumInactive.
  ///
  /// In en, this message translates to:
  /// **'Unlimited comparisons, full history and charts'**
  String get premiumInactive;

  /// No description provided for @debugPremium.
  ///
  /// In en, this message translates to:
  /// **'Simulate Premium (debug builds only)'**
  String get debugPremium;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Follower Check is an independent app. It is not affiliated with, endorsed or sponsored by Instagram or Meta.'**
  String get disclaimer;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Follower Check Premium'**
  String get paywallTitle;

  /// No description provided for @paywallFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited comparisons'**
  String get paywallFeature1;

  /// No description provided for @paywallFeature2.
  ///
  /// In en, this message translates to:
  /// **'Full snapshot history'**
  String get paywallFeature2;

  /// No description provided for @paywallFeature3.
  ///
  /// In en, this message translates to:
  /// **'Follower charts'**
  String get paywallFeature3;

  /// No description provided for @paywallBuy.
  ///
  /// In en, this message translates to:
  /// **'Upgrade · {price}'**
  String paywallBuy(String price);

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases aren\'t available yet. Please check back soon.'**
  String get paywallUnavailable;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Follower Check works entirely on your device.\n\n• We never ask for your Instagram password and never sign in to your account.\n• We don\'t use any unofficial API and don\'t contact any server.\n• The export files you choose are read on this device only. Only usernames and dates are stored, in a local database inside the app.\n• There are no analytics, ads, or trackers.\n• Reminders are local notifications scheduled on your device.\n• You can delete all data at any time from Settings › Delete all data, or by uninstalling the app.\n\nFollower Check is an independent app and is not affiliated with Instagram or Meta.'**
  String get privacyBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

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
