class EspyRoutePath {
  final _EspyAppView view;
  final String? gameId;

  const EspyRoutePath.library()
      : view = _EspyAppView.library,
        gameId = null;
  const EspyRoutePath.details(this.gameId) : view = _EspyAppView.entry_details;
  const EspyRoutePath.unmatched()
      : view = _EspyAppView.unmatched,
        gameId = null;
  const EspyRoutePath.tags()
      : view = _EspyAppView.tags,
        gameId = null;

  const EspyRoutePath(this.view, {String? gameId}) : gameId = gameId;

  bool get isLibraryPage => view == _EspyAppView.library;
  bool get isDetailsPage => view == _EspyAppView.entry_details;
  bool get isUnmatchedPage => view == _EspyAppView.unmatched;
  bool get isTagsPage => view == _EspyAppView.tags;
}

enum _EspyAppView {
  library,
  entry_details,
  unmatched,
  tags,
}
