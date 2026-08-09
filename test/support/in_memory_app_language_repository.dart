import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';

/// In-memory [AppLanguageRepository] for tests — no Hive box needed.
class InMemoryAppLanguageRepository implements AppLanguageRepository {
  AppLanguage? _stored;

  InMemoryAppLanguageRepository([this._stored]);

  @override
  AppLanguage? load() => _stored;

  @override
  void save(AppLanguage language) => _stored = language;

  @override
  Future<void> clear() async {
    _stored = null;
  }
}
