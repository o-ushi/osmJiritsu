import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import 'icloud_sync_error_code.dart';

String localizedIcloudSyncError(
  AppLanguage lang,
  String? code, {
  String? detail,
}) {
  switch (code) {
    case IcloudSyncErrorCode.missingPlugin:
      return 'iCloud同期_エラー_未検出'.tr(lang);
    case IcloudSyncErrorCode.unavailable:
      return 'iCloud同期_利用不可'.tr(lang);
    case IcloudSyncErrorCode.projectsNotLoaded:
      return 'iCloud同期_エラー_案件未読込'.tr(lang);
    case IcloudSyncErrorCode.dataTooLarge:
      return 'iCloud同期_エラー_容量超過'.trFmt(lang, [detail ?? '?']);
    case IcloudSyncErrorCode.mergeFailed:
      return 'iCloud同期_エラー_マージ失敗'.tr(lang);
    case IcloudSyncErrorCode.invalidResponse:
      return 'iCloud同期_エラー_不正な応答'.tr(lang);
    case IcloudSyncErrorCode.unsupported:
    case IcloudSyncErrorCode.syncFailed:
    case null:
    case '':
      return 'iCloud同期_エラー'.tr(lang);
    default:
      return 'iCloud同期_エラー'.tr(lang);
  }
}

/// Maps native / legacy English error messages to [IcloudSyncErrorCode].
({String code, String? detail}) parseIcloudSyncErrorMessage(String? message) {
  if (message == null || message.isEmpty) {
    return (code: IcloudSyncErrorCode.syncFailed, detail: null);
  }

  final lower = message.toLowerCase();
  if (lower.contains('bridge not registered') ||
      lower.contains('missing plugin')) {
    return (code: IcloudSyncErrorCode.missingPlugin, detail: null);
  }
  if (lower.contains('not available') || lower.contains('noaccount')) {
    return (code: IcloudSyncErrorCode.unavailable, detail: null);
  }
  if (lower.contains('exceeds') && lower.contains('limit')) {
    final match = RegExp(
      r'([\d.]+)\s*mb',
      caseSensitive: false,
    ).firstMatch(message);
    return (code: IcloudSyncErrorCode.dataTooLarge, detail: match?.group(1));
  }

  return (code: IcloudSyncErrorCode.syncFailed, detail: null);
}
