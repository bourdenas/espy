import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class FilterModel extends ChangeNotifier {
  LibraryFilter _filter = LibraryFilter();
  late AppConfigModel _config;

  FilterModel();
  FilterModel.create(this._filter, this._config);

  void update(AppConfigModel config) {
    _config = config;
    notifyListeners();
  }

  Iterable<GameDigest> process(Iterable<GameDigest> games) {
    return games.where((e) => passCategory(e) && _filter.pass(e));
  }

  Iterable<LibraryEntry> processLibraryEntries(Iterable<LibraryEntry> entries) {
    return entries
        .where((e) => passCategory(e.digest) && _filter.passLibraryEntry(e));
  }

  bool passCategory(GameDigest digest) =>
      (_config.showMains.value &&
          digest.isMain &&
          !digest.isEarlyAccess &&
          !digest.isCasual) ||
      (_config.showExpansions.value && digest.isExpansion) ||
      (_config.showRemakes.value && (digest.isRemake || digest.isRemaster)) ||
      (_config.showEarlyAccess.value && digest.isEarlyAccess) ||
      (_config.showDlcs.value && digest.isDlc) ||
      (_config.showVersions.value && digest.isVersion) ||
      (_config.showBundles.value && digest.isBundle) ||
      (_config.showCasual.value && digest.isCasual);

  LibraryFilter get filter => _filter;
  set filter(LibraryFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void add(LibraryFilter filter) {
    _filter = _filter.add(filter);
    notifyListeners();
  }

  void subtract(LibraryFilter filter) {
    _filter = _filter.subtract(filter);
    notifyListeners();
  }

  void clear() {
    _filter = LibraryFilter();
    notifyListeners();
  }
}
