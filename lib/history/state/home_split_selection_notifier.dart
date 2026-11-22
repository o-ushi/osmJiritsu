import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The 案件 id shown in the right pane while home is split (iPad
/// landscape). In-memory only, never written into project JSON. An id that
/// is no longer in the project list reads as "nothing selected".
final homeSplitSelectedProjectIdProvider =
    NotifierProvider<HomeSplitSelectedProjectIdNotifier, String?>(
      HomeSplitSelectedProjectIdNotifier.new,
    );

class HomeSplitSelectedProjectIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}
