import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.privacyBody, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
      ),
    );
  }
}
