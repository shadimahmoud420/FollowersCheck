// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Follower Check';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get neverPassword => 'We never ask for your password';

  @override
  String get onboardingTitle1 => 'See who unfollowed you';

  @override
  String get onboardingBody1 =>
      'Follower Check compares two copies of your own Instagram data export and shows who unfollowed you, who doesn\'t follow you back and who your new followers are.';

  @override
  String get onboardingTitle2 => 'Export your data as JSON';

  @override
  String get onboardingBody2 =>
      'In the Instagram app, request a copy of your \"Followers and following\" in JSON format. Instagram will notify you when the file is ready to download.';

  @override
  String get onboardingTitle3 => 'Private by design';

  @override
  String get onboardingBody3 =>
      'We never ask for your password and never sign in to your account. Your files are processed only on this device and are never uploaded anywhere.';

  @override
  String get exportStepsTitle => 'How to export';

  @override
  String get exportStep1 => 'Open Settings › Accounts Center';

  @override
  String get exportStep2 => 'Your information and permissions › Export your information';

  @override
  String get exportStep3 => 'Create export › Export to device';

  @override
  String get exportStep4 => 'Customize information: select only \"Followers and following\"';

  @override
  String get exportStep5 => 'Date range: All time · Format: JSON';

  @override
  String get exportStep6 => 'Download the ZIP when it\'s ready, then import it here';

  @override
  String get navResults => 'Results';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get importTitle => 'Import export';

  @override
  String get importIntro =>
      'Choose the ZIP you downloaded, or the followers_1.json and following.json files from inside it.';

  @override
  String get importPick => 'Choose ZIP or JSON files';

  @override
  String get importProcessing => 'Reading your files on this device…';

  @override
  String get importSuccessTitle => 'Import complete';

  @override
  String importSuccessBody(int followers, int following) {
    return 'Followers: $followers · Following: $following';
  }

  @override
  String get importMissingFollowing =>
      'No following list was found, so \"Not following you back\" is unavailable for this snapshot.';

  @override
  String get viewResults => 'View results';

  @override
  String get errorHtml => 'This export is in HTML format. Please export again and choose JSON as the format.';

  @override
  String get errorCorrupt => 'The ZIP file couldn\'t be opened. Please download it again and retry.';

  @override
  String get errorNothing =>
      'We couldn\'t find followers data in these files. Make sure you selected \"Followers and following\" and JSON format.';

  @override
  String get errorMissingFollowers =>
      'Only a following list was found. Please include the followers file (followers_1.json) too.';

  @override
  String get errorGeneric => 'Something went wrong while reading the file. Please try again.';

  @override
  String freeLimitReached(String date) {
    return 'The free plan includes 1 comparison per week. Your next free comparison is available on $date.';
  }

  @override
  String get upgrade => 'Upgrade to Premium';

  @override
  String get resultsTitle => 'Results';

  @override
  String get tabUnfollowed => 'Unfollowed you';

  @override
  String get tabNotFollowingBack => 'Not following back';

  @override
  String get tabNewFollowers => 'New followers';

  @override
  String get searchHint => 'Search usernames';

  @override
  String get openProfile => 'Open profile';

  @override
  String get couldNotOpenLink => 'Couldn\'t open the link.';

  @override
  String get noDataTitle => 'No data yet';

  @override
  String get noDataBody => 'Import your first export to get started.';

  @override
  String get needsTwoSnapshots =>
      'This is your first snapshot. Import a newer export later to see who unfollowed you and who\'s new.';

  @override
  String get emptyList => 'Nobody here';

  @override
  String get noSearchResults => 'No usernames match your search';

  @override
  String get followingUnavailable =>
      'This snapshot has no following list. Import an export that includes following.json.';

  @override
  String comparing(String previous, String latest) {
    return '$previous → $latest';
  }

  @override
  String snapshotFrom(String date) {
    return 'Snapshot from $date';
  }

  @override
  String shownCount(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String totalCount(int count) {
    return 'Total: $count';
  }

  @override
  String get newImport => 'New import';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'Your snapshots will appear here.';

  @override
  String followersLabel(int count) {
    return 'Followers: $count';
  }

  @override
  String followingLabel(int count) {
    return 'Following: $count';
  }

  @override
  String get chartTitle => 'Followers over time';

  @override
  String get chartLocked => 'Charts are a Premium feature';

  @override
  String get chartNeedsTwo => 'Import at least two snapshots to see a chart.';

  @override
  String historyLocked(int count) {
    return '$count older snapshots are available with Premium';
  }

  @override
  String get deleteSnapshotTitle => 'Delete snapshot?';

  @override
  String get deleteSnapshotBody => 'This snapshot will be permanently removed from this device.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get reminders => 'Export reminder';

  @override
  String get remindersSubtitle => 'A local notification reminding you to request a fresh export';

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderWeekly => 'Weekly';

  @override
  String get reminderBiweekly => 'Every 2 weeks';

  @override
  String get reminderNotificationTitle => 'Time for a fresh export';

  @override
  String get reminderNotificationBody => 'Request a new \"Followers and following\" export to see who unfollowed you.';

  @override
  String get reminderPermissionDenied => 'Notifications are disabled for this app. Enable them in system settings.';

  @override
  String get dataSection => 'Data & privacy';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllTitle => 'Delete all data?';

  @override
  String get deleteAllBody => 'All snapshots will be permanently deleted from this device. This can\'t be undone.';

  @override
  String get dataDeleted => 'All data deleted';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get showGuide => 'Show export guide';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'Premium is active';

  @override
  String get premiumInactive => 'Unlimited comparisons, full history and charts';

  @override
  String get debugPremium => 'Simulate Premium (debug builds only)';

  @override
  String get about => 'About';

  @override
  String get disclaimer =>
      'Follower Check is an independent app. It is not affiliated with, endorsed or sponsored by Instagram or Meta.';

  @override
  String get paywallTitle => 'Follower Check Premium';

  @override
  String get paywallFeature1 => 'Unlimited comparisons';

  @override
  String get paywallFeature2 => 'Full snapshot history';

  @override
  String get paywallFeature3 => 'Follower charts';

  @override
  String paywallBuy(String price) {
    return 'Upgrade · $price';
  }

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallUnavailable => 'Purchases aren\'t available yet. Please check back soon.';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get privacyBody =>
      'Follower Check works entirely on your device.\n\n• We never ask for your Instagram password and never sign in to your account.\n• We don\'t use any unofficial API and don\'t contact any server.\n• The export files you choose are read on this device only. Only usernames and dates are stored, in a local database inside the app.\n• There are no analytics, ads, or trackers.\n• Reminders are local notifications scheduled on your device.\n• You can delete all data at any time from Settings › Delete all data, or by uninstalling the app.\n\nFollower Check is an independent app and is not affiliated with Instagram or Meta.';
}
