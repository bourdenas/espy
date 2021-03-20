class EspyRoutePath {
  final String? entryId;

  EspyRoutePath.home() : entryId = null;
  EspyRoutePath.entry(this.entryId);

  bool get isHomePage => entryId == null;
  bool get isGameDetailsPage => entryId != null;
}
