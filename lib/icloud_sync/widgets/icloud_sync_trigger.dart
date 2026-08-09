import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/state/analysis_history_notifier.dart';
import '../state/icloud_sync_notifier.dart';

/// iCloud KVS sync (osmPod/osmSolver-style): pull-merge on launch/resume,
/// upload on background, and react to KVS changes pushed from other
/// devices. No-op when [IcloudSyncService.isSupported] is false (Android).
class IcloudSyncTrigger extends ConsumerStatefulWidget {
  const IcloudSyncTrigger({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IcloudSyncTrigger> createState() => _IcloudSyncTriggerState();
}

class _IcloudSyncTriggerState extends ConsumerState<IcloudSyncTrigger>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    } else if (state == AppLifecycleState.paused) {
      ref.read(icloudSyncProvider.notifier).uploadToCloud();
    }
  }

  Future<void> _sync() async {
    await ref.read(analysisHistoryProvider.future);
    if (!mounted) return;
    await ref.read(icloudSyncProvider.notifier).syncNow();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
