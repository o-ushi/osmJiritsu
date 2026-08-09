import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'icloud_sync_error_code.dart';
import 'icloud_sync_messages.dart';
import 'icloud_sync_payload.dart';

/// iOS-only bridge to `NSUbiquitousKeyValueStore` (see
/// `ios/Runner/ICloudKVSyncManager.swift`).
class IcloudSyncService {
  IcloudSyncService._();

  static const _channel = MethodChannel(
    'com.osamushikubo.osmjiritsu/icloud_sync',
  );
  static const _events = EventChannel(
    'com.osamushikubo.osmjiritsu/icloud_sync_events',
  );

  static bool get isSupported => Platform.isIOS;

  static Stream<void>? _externalChanges;

  static Stream<void> get externalChanges {
    if (!isSupported) return const Stream.empty();
    _externalChanges ??= _events
        .receiveBroadcastStream()
        .map((_) {})
        .handleError((Object e) => debugPrint('iCloud event stream: $e'));
    return _externalChanges!;
  }

  static Future<String> accountStatus() async {
    if (!isSupported) return 'unsupported';
    try {
      final status = await _channel.invokeMethod<String>('accountStatus');
      return status ?? 'unknown';
    } on MissingPluginException catch (e) {
      debugPrint('iCloud accountStatus missing plugin: $e');
      return 'missingPlugin';
    } on PlatformException catch (e) {
      debugPrint('iCloud accountStatus failed: $e');
      return 'unknown';
    }
  }

  static double? _parseSyncedAtReference(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  /// Timestamp compare + upload/download, both done natively.
  static Future<IcloudManualSyncOutcome> manualSync({
    required String localJson,
    required double localSyncReferenceTS,
  }) async {
    if (!isSupported) {
      return const IcloudManualSyncOutcome.unavailable();
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('manualSync', {
        'localJson': localJson,
        'localSyncReferenceTS': localSyncReferenceTS,
      });
      if (raw is! Map) {
        return const IcloudManualSyncOutcome.failed(
          IcloudSyncErrorCode.invalidResponse,
        );
      }

      final map = Map<String, dynamic>.from(raw);
      final action = map['action'] as String? ?? '';
      final syncedAt = _parseSyncedAtReference(map['syncedAt']);
      if (syncedAt == null) {
        return const IcloudManualSyncOutcome.failed(
          IcloudSyncErrorCode.invalidResponse,
        );
      }

      return IcloudManualSyncOutcome.success(
        IcloudManualSyncResult(
          downloaded: action == 'download',
          remoteJson: map['json'] as String?,
          syncedAtReference: syncedAt,
        ),
      );
    } on MissingPluginException catch (e) {
      debugPrint('iCloud manualSync missing plugin: $e');
      return const IcloudManualSyncOutcome.failed(
        IcloudSyncErrorCode.missingPlugin,
      );
    } on PlatformException catch (e) {
      debugPrint('iCloud manualSync failed: $e');
      final parsed = parseIcloudSyncErrorMessage(
        e.message?.isNotEmpty == true ? e.message : e.code,
      );
      return IcloudManualSyncOutcome.failed(
        parsed.code,
        detail: parsed.detail,
      );
    }
  }

  static Future<bool> upload(String json) async {
    if (!isSupported) return false;
    try {
      await _channel.invokeMethod<void>('upload', json);
      return true;
    } on PlatformException catch (e) {
      debugPrint('iCloud upload failed: $e');
      return false;
    }
  }

  /// Deletes osmJiritsu's payload and timestamp from iCloud KVS.
  static Future<bool> deleteCloudCopy() async {
    if (!isSupported) return false;
    try {
      await _channel.invokeMethod<void>('deleteCloudCopy');
      return true;
    } on MissingPluginException catch (e) {
      debugPrint('iCloud deleteCloudCopy missing plugin: $e');
      return false;
    } on PlatformException catch (e) {
      debugPrint('iCloud deleteCloudCopy failed: $e');
      return false;
    }
  }
}

class IcloudManualSyncOutcome {
  const IcloudManualSyncOutcome._({
    this.result,
    this.errorCode,
    this.errorDetail,
  });

  const IcloudManualSyncOutcome.unavailable()
    : this._(errorCode: IcloudSyncErrorCode.unsupported);

  const IcloudManualSyncOutcome.failed(String code, {String? detail})
    : this._(errorCode: code, errorDetail: detail);

  const IcloudManualSyncOutcome.success(IcloudManualSyncResult result)
    : this._(result: result);

  final IcloudManualSyncResult? result;
  final String? errorCode;
  final String? errorDetail;

  bool get isSuccess => result != null;
}

class IcloudManualSyncResult {
  const IcloudManualSyncResult({
    required this.downloaded,
    required this.syncedAtReference,
    this.remoteJson,
  });

  final bool downloaded;
  final String? remoteJson;
  final double syncedAtReference;

  DateTime get syncedAt => appleReferenceToDate(syncedAtReference);
}
