import 'package:espy/modules/routing/library_filter.dart';

class EspyRoutePath {
  final _EspyAppView view;
  final String? gameId;
  final LibraryFilter? filter;

  const EspyRoutePath.library()
      : view = _EspyAppView.library,
        gameId = null,
        filter = null;
  const EspyRoutePath.filter(this.filter)
      : view = _EspyAppView.filter,
        gameId = null;
  const EspyRoutePath.details(this.gameId)
      : view = _EspyAppView.entry_details,
        filter = null;
  const EspyRoutePath.unmatched()
      : view = _EspyAppView.unmatched,
        gameId = null,
        filter = null;
  const EspyRoutePath.tags()
      : view = _EspyAppView.tags,
        gameId = null,
        filter = null;

  bool get isLibraryPage => view == _EspyAppView.library;
  bool get isFilterPage => view == _EspyAppView.filter;
  bool get isDetailsPage => view == _EspyAppView.entry_details;
  bool get isUnmatchedPage => view == _EspyAppView.unmatched;
  bool get isTagsPage => view == _EspyAppView.tags;
}

enum _EspyAppView {
  library,
  filter,
  entry_details,
  unmatched,
  tags,
}
