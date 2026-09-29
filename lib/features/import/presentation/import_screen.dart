import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/presentation/export_steps_card.dart';
import '../application/import_controller.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(importControllerProvider);
    final controller = ref.read(importControllerProvider.notifier);
    final processing = state is ImportProcessing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoPasswordBanner(),
          const SizedBox(height: 16),
          Text(l10n.importIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('import_pick'),
            onPressed: processing ? null : controller.pickAndImport,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(l10n.importPick),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 16),
          switch (state) {
            ImportIdle() => const SizedBox.shrink(),
            ImportProcessing() => Row(
              children: [
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 16),
                Expanded(child: Text(l10n.importProcessing)),
              ],
            ),
            ImportSuccess() => _SuccessCard(state: state),
            ImportError() => _ErrorCard(state: state),
          },
          const SizedBox(height: 24),
          const ExportStepsCard(),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.state});

  final ImportSuccess state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(l10n.importSuccessTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.importSuccessBody(state.followers, state.following)),
            if (!state.hasFollowing) ...[const SizedBox(height: 8), Text(l10n.importMissingFollowing)],
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go('/results'), child: Text(l10n.viewResults)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.state});

  final ImportError state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final limit = state.failure == ImportFailure.limitReached;
    final message = switch (state.failure) {
      ImportFailure.html => l10n.errorHtml,
      ImportFailure.corrupt => l10n.errorCorrupt,
      ImportFailure.nothingRecognized => l10n.errorNothing,
      ImportFailure.missingFollowers => l10n.errorMissingFollowers,
      ImportFailure.limitReached => l10n.freeLimitReached(formatDate(context, state.nextFreeAt!)),
      ImportFailure.generic => l10n.errorGeneric,
    };
    final bg = limit ? scheme.surfaceContainerHighest : scheme.errorContainer;
    final fg = limit ? scheme.onSurface : scheme.onErrorContainer;
    return Card.filled(
      key: const Key('import_error'),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(limit ? Icons.hourglass_bottom : Icons.error_outline, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: TextStyle(color: fg)),
                ),
              ],
            ),
            if (limit) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: () => context.push('/paywall'), child: Text(l10n.upgrade)),
            ],
          ],
        ),
      ),
    );
  }
}
