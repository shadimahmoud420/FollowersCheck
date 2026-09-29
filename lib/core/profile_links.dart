import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';

/// Opens a public profile page in the browser / installed app.
Future<void> openProfile(BuildContext context, String username) async {
  final uri = Uri.https('instagram.com', '/$username');
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).couldNotOpenLink;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(message)));
}
