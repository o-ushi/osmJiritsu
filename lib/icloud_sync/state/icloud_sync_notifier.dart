import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/state/analysis_history_notifier.dart';
import '../data/icloud_sync_settings_repository.dart';
import '../services/icloud_merge.dart';
import '../services/icloud_sync_error_code.dart';
import '../services/icloud_sync_payload.dart';
import '../services/icloud_sync_service.dart';

enum IcloudSyncStatus { idle, syncing, error, unavailable }

/// Mirrors osmSolver/osmPod's iCloud sync status surface for the settings UI.
class IcloudSyncState {
  const IcloudSyncState({
    this.isEnabled = true,
    this.isICloudAvailable = false,
    this.lastSyncDate,
    this.status = IcloudSyncStatus.idle,
    this.errorCode,
    this.errorDetail,
    this.lastSyncAction,
  });

  final bool isEnabled;
  final bool isICloudAvailable;
  final DateTime? lastSyncDate;
  final IcloudSyncStatus status;
  final String? errorCode;
  final String? errorDetail;

  /// Short result from the latest manual sync attempt: 'uploaded',
  /// 'downloaded', 'failed', 'mergeFailed', or null before any attempt.
  final String? lastSyncAction;

  bool get isWorking => status == IcloudSyncStatus.syncing;

  IcloudSyncState copyWith({
    bool? isEnabled,
    bool? isICloudAvailable,
    Object? lastSyncDate = _unset,
    IcloudSyncStatus? status,
    Object? errorCode = _unset,
    Object? errorDetail = _unset,
    Object? lastSyncAction = _unset,
  }) {
    return IcloudSyncState(
      isEnabled: isEnabled ?? this.isEnabled,
      isICloudAvailable: isICloudAvailable ?? this.isICloudAvailable,
      lastSyncDate: identical(lastSyncDate, _unset)
          ? this.lastSyncDate
          : lastSyncDate as DateTime?,
      status: status ?? this.status,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      errorDetail: identical(errorDetail, _unset)
          ? this.errorDetail
          : errorDetail as String?,
      lastSyncAction: identical(lastSyncAction, _unset)
          ? this.lastSyncAction
          : lastSyncAction as String?,
    );
  }
}

const _unset = Object();

class IcloudSyncNotifier extends Notifier<IcloudSyncState> {
  Future<void>? _syncChain;
  StreamSubscription<void>? _externalChanges;

  @override
  IcloudSyncState build() {
    final settings = ref.read(icloudSyncSettingsRepositoryProvider);
    if (IcloudSyncService.isSupported) {
      unawaited(refreshAvailability());
      _externalChanges ??= IcloudSyncService.externalChanges.listen((_) {
        unawaited(syncNow());
      });
      ref.onDispose(() {
        _externalChanges?.cancel();
        _externalChanges = null;
      });
    }
    return IcloudSyncState(
      isEnabled: settings.isEnabled(),
      lastSyncDate: settings.lastSyncDate(),
    );
  }

  Future<void> refreshAvailability() async {
    final accountStatus = await IcloudSyncService.accountStatus();
    state = state.copyWith(
      isICloudAvailable: accountStatus == 'available',
      errorCode: accountStatus == 'missingPlugin'
          ? IcloudSyncErrorCode.missingPlugin
          : state.errorCode,
      status: accountStatus == 'missingPlugin'
          ? IcloudSyncStatus.error
          : state.status,
    );
  }

  void setEnabled(bool value) {
    ref.read(icloudSyncSettingsRepositoryProvider).setEnabled(value);
    state = state.copyWith(isEnabled: value);
  }

  void clearError() {
    if (state.status == IcloudSyncStatus.error) {
      state = state.copyWith(
        status: IcloudSyncStatus.idle,
        errorCode: null,
        errorDetail: null,
        lastSyncAction: null,
      );
    }
  }

  Future<void> syncNow() async {
    if (!state.isEnabled) return;
    final queued = (_syncChain ?? Future<void>.value()).then(
      (_) => _manualSync(),
    );
    _syncChain = queued;
    await queued;
  }

  /// Upload-only sync — used on backgrounding, where a full round trip
  /// (including a possible remote download + merge) would be wasted work.
  Future<void> uploadToCloud() async {
    if (!state.isEnabled || !state.isICloudAvailable) return;
    final projects = await ref.read(analysisHistoryProvider.future);
    final json = encodeIcloudSyncPayload(projects);
    if (!await IcloudSyncService.upload(json)) return;

    final settings = ref.read(icloudSyncSettingsRepositoryProvider);
    final syncedAt = await settings.recordSuccessfulSync();
    state = state.copyWith(lastSyncDate: syncedAt);
  }

  /// Timestamp compare + upload/download, done natively — remote newer
  /// downloads and merges; otherwise the local library is uploaded as-is.
  Future<void> _manualSync() async {
    await refreshAvailability();
    if (state.errorCode == IcloudSyncErrorCode.missingPlugin) {
      return;
    }
    if (!state.isICloudAvailable) {
      state = state.copyWith(
        status: IcloudSyncStatus.error,
        errorCode: IcloudSyncErrorCode.unavailable,
        errorDetail: null,
        lastSyncAction: 'failed',
      );
      return;
    }

    state = state.copyWith(
      status: IcloudSyncStatus.syncing,
      errorCode: null,
      errorDetail: null,
      lastSyncAction: null,
    );

    try {
      final projects = await ref.read(analysisHistoryProvider.future);
      final settings = ref.read(icloudSyncSettingsRepositoryProvider);

      final outcome = await IcloudSyncService.manualSync(
        localJson: encodeIcloudSyncPayload(projects),
        localSyncReferenceTS: settings.lastSyncReference(),
      );

      if (!outcome.isSuccess) {
        state = state.copyWith(
          status: IcloudSyncStatus.error,
          errorCode: outcome.errorCode ?? IcloudSyncErrorCode.syncFailed,
          errorDetail: outcome.errorDetail,
          lastSyncAction: 'failed',
        );
        return;
      }

      final result = outcome.result!;

      final syncedAt = await settings.recordSuccessfulSync(
        when: result.syncedAt,
      );
      state = state.copyWith(
        status: IcloudSyncStatus.idle,
        lastSyncDate: syncedAt,
        errorCode: null,
        errorDetail: null,
        lastSyncAction: result.downloaded ? 'downloaded' : 'uploaded',
      );

      if (result.downloaded && result.remoteJson != null) {
        try {
          final remoteProjects = decodeIcloudSyncPayload(result.remoteJson!);
          await ref
              .read(analysisHistoryProvider.notifier)
              .applyIcloudMergePlan(
                planFullRemoteSnapshot(local: projects, remote: remoteProjects),
              );
        } catch (e, st) {
          debugPrint('iCloud merge after download failed: $e\n$st');
          state = state.copyWith(
            status: IcloudSyncStatus.error,
            errorCode: IcloudSyncErrorCode.mergeFailed,
            errorDetail: null,
            lastSyncAction: 'mergeFailed',
          );
        }
      }
    } catch (e, st) {
      debugPrint('iCloud manualSync failed: $e\n$st');
      state = state.copyWith(
        status: IcloudSyncStatus.error,
        errorCode: IcloudSyncErrorCode.syncFailed,
        errorDetail: null,
        lastSyncAction: 'failed',
      );
    }
  }
}

final icloudSyncProvider =
    NotifierProvider<IcloudSyncNotifier, IcloudSyncState>(
      IcloudSyncNotifier.new,
    );
