import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/presentation/export_steps_card.dart';

/// The export instructions, reachable from Settings after onboarding.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.showGuide)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.onboardingBody2, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          const ExportStepsCard(),
          const SizedBox(height: 16),
          const NoPasswordBanner(),
        ],
      ),
    );
  }
}
