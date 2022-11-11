import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class HomeSlatesModel extends ChangeNotifier {
  List<_SlateInfo> _slates = [];

  List<_SlateInfo> get slates => _slates;

  void update(List<LibraryEntry> entries, List<String> tags) {
    _SlateInfo slate(String title, LibraryFilter filter) {
      final filteredEntries =
          entries.where((e) => filter.apply(e)).take(32).toList();
      return _SlateInfo(title: title, filter: filter, entries: filteredEntries);
    }

    _slates = [
      slate('GOG', LibraryFilter(stores: {'gog'})),
      slate('Steam', LibraryFilter(stores: {'steam'})),
      slate('EGS', LibraryFilter(stores: {'egs'})),
      slate('Battle.Net', LibraryFilter(stores: {'battle.net'})),
      for (final tag in tags) slate(tag, LibraryFilter(tags: {tag})),
    ];

    notifyListeners();
  }
}

class _SlateInfo {
  _SlateInfo({
    required this.title,
    required this.filter,
    required this.entries,
  });

  String title;
  LibraryFilter filter;
  List<LibraryEntry> entries = [];
}
