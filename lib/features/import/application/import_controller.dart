import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../premium/application/premium_providers.dart';
import '../../snapshots/application/snapshot_providers.dart';
import '../../settings/application/reminder_controller.dart';
import '../data/export_file_source.dart';
import '../domain/export_parser.dart';
import '../domain/parsed_export.dart';

final exportFileSourceProvider = Provider<ExportFileSource>((ref) => const FilePickerExportFileSource());

final importControllerProvider = NotifierProvider.autoDispose<ImportController, ImportState>(ImportController.new);

sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportProcessing extends ImportState {
  const ImportProcessing();
}

class ImportSuccess extends ImportState {
  const ImportSuccess({
    required this.snapshotId,
    required this.followers,
    required this.following,
    required this.hasFollowing,
  });

  final int snapshotId;
  final int followers;
  final int following;
  final bool hasFollowing;
}

enum ImportFailure { html, corrupt, nothingRecognized, missingFollowers, limitReached, generic }

class ImportError extends ImportState {
  const ImportError(this.failure, {this.nextFreeAt});

  final ImportFailure failure;
  final DateTime? nextFreeAt;
}

/// Picks files, parses them off the UI thread and stores a new snapshot.
class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportIdle();

  /// When free users hit the weekly limit, returns the date the next free
  /// import becomes available; null otherwise.
  Future<DateTime?> nextFreeImportAt() async {
    final snapshots = await ref.read(snapshotsProvider.future);
    return ref
        .read(usagePolicyProvider)
        .nextFreeImportAt(
          // Query the service directly too: unlistened providers may be paused.
          isPremium: ref.read(entitlementServiceProvider).isPremium || ref.read(isPremiumProvider),
          lastImportAt: snapshots.isEmpty ? null : snapshots.first.createdAt,
          now: ref.read(clockProvider)(),
        );
  }

  Future<void> pickAndImport() async {
    if (state is ImportProcessing) return;

    final blockedUntil = await nextFreeImportAt();
    if (blockedUntil != null) {
      state = ImportError(ImportFailure.limitReached, nextFreeAt: blockedUntil);
      return;
    }

    final List<ExportInputFile> files;
    try {
      files = await ref.read(exportFileSourceProvider).pick();
    } catch (_) {
      state = const ImportError(ImportFailure.generic);
      return;
    }
    if (files.isEmpty) return; // cancelled
    if (!ref.mounted) return;

    state = const ImportProcessing();
    try {
      final parsed = await compute(_parseInBackground, files);
      if (!parsed.foundFollowersFile) {
        state = const ImportError(ImportFailure.missingFollowers);
        return;
      }
      final now = ref.read(clockProvider)();
      final id = await ref
          .read(snapshotRepositoryProvider)
          .saveSnapshot(
            createdAt: now,
            followers: parsed.followers,
            following: parsed.following,
            hasFollowingData: parsed.foundFollowingFile,
          );
      ref.invalidate(snapshotsProvider);
      ref.invalidate(comparisonProvider);
      await ref.read(reminderControllerProvider).reschedule(lastImportAt: now);
      if (!ref.mounted) return;
      state = ImportSuccess(
        snapshotId: id,
        followers: parsed.followers.length,
        following: parsed.following.length,
        hasFollowing: parsed.foundFollowingFile,
      );
    } on ExportParseException catch (e) {
      if (!ref.mounted) return;
      state = ImportError(switch (e.error) {
        ExportParseError.htmlFormat => ImportFailure.html,
        ExportParseError.corruptArchive => ImportFailure.corrupt,
        ExportParseError.nothingRecognized => ImportFailure.nothingRecognized,
      });
    } catch (_) {
      if (!ref.mounted) return;
      state = const ImportError(ImportFailure.generic);
    }
  }

  void reset() => state = const ImportIdle();
}

/// Top-level so it can run in a background isolate without capturing state.
ParsedExport _parseInBackground(List<ExportInputFile> files) => const ExportParser().parseFiles(files);
