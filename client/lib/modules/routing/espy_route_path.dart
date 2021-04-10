class EspyRoutePath {
  final String? gameId;

  EspyRoutePath.library() : gameId = null;
  EspyRoutePath.details(this.gameId);

  bool get isLibraryPage => gameId == null;
  bool get isGameDetailsPage => gameId != null;
}
