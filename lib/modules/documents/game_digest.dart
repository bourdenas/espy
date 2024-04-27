import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/scores.dart';
import 'package:intl/intl.dart' show DateFormat;

class GameDigest {
  final int id;
  final String name;

  final String? category;
  final String? status;
  final String? cover;

  final int releaseDate;
  final Scores scores;

  final List<String> collections;
  final List<String> franchises;
  final List<String> developers;
  final List<String> publishers;

  final List<String> espyGenres;
  final List<String> igdbGenres;
  final List<String> keywords;

  String get releaseDay => DateFormat('yMMMd').format(release);
  String get releaseMonth => DateFormat('yMMM').format(release);
  DateTime get release =>
      DateTime.fromMillisecondsSinceEpoch(releaseDate * 1000);

  GameDigest({
    required this.id,
    required this.name,
    this.category,
    this.status,
    this.cover,
    this.releaseDate = 0,
    this.scores = const Scores(),
    this.collections = const [],
    this.franchises = const [],
    this.developers = const [],
    this.publishers = const [],
    this.espyGenres = const [],
    this.igdbGenres = const [],
    this.keywords = const [],
  });

  GameDigest.fromGameEntry(GameEntry gameEntry)
      : this(
          id: gameEntry.id,
          name: gameEntry.name,
          category: gameEntry.category,
          status: gameEntry.status,
          cover: gameEntry.cover?.imageId,
          releaseDate: gameEntry.releaseDate ?? 0,
          scores: gameEntry.scores,
          collections: [
            for (final collection in gameEntry.collections) collection.name
          ],
          franchises: [
            for (final franchise in gameEntry.franchises) franchise.name
          ],
          developers: [
            for (final company in gameEntry.developers) company.name
          ],
          publishers: [
            for (final company in gameEntry.publishers) company.name
          ],
          espyGenres: gameEntry.espyGenres,
          igdbGenres: gameEntry.igdbGenres,
          keywords: [],
        );

  GameDigest.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          category: json['category'] ?? '',
          status: json['status'] ?? '',
          cover: json['cover'],
          releaseDate: json['release_date'] ?? 0,
          scores: json.containsKey('scores')
              ? Scores.fromJson(json['scores'])
              : const Scores(),
          collections: [
            for (final collection in json['collections'] ?? []) collection,
          ],
          franchises: [
            for (final franchise in json['franchises'] ?? []) franchise,
          ],
          developers: [
            for (final company in json['developers'] ?? []) company,
          ],
          publishers: [
            for (final company in json['publishers'] ?? []) company,
          ],
          espyGenres: [
            for (final genre in json['espy_genres'] ?? []) genre,
          ],
          igdbGenres: [
            for (final genre in json['igdb_genres'] ?? []) genre,
          ],
          keywords: [
            for (final kw in json['keywords'] ?? []) kw,
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      if (cover != null) 'cover': cover,
      'release_date': releaseDate,
      'scores': scores.toJson(),
      if (collections.isNotEmpty) 'collections': collections,
      if (franchises.isNotEmpty) 'franchises': franchises,
      if (developers.isNotEmpty) 'developers': developers,
      if (publishers.isNotEmpty) 'publishers': publishers,
      if (espyGenres.isNotEmpty) 'espy_genres': espyGenres,
      if (igdbGenres.isNotEmpty) 'igdb_genres': igdbGenres,
      if (keywords.isNotEmpty) 'keywords': keywords,
    };
  }

  bool hasDiff(GameDigest other) {
    return id == other.id &&
        (name != other.name ||
            category != other.category ||
            status != other.status ||
            cover != other.cover ||
            releaseDate != other.releaseDate ||
            scores.hasDiff(other.scores) ||
            !_match(collections, other.collections) ||
            !_match(franchises, other.franchises) ||
            !_match(developers, other.developers) ||
            !_match(publishers, other.publishers));
  }

  bool get isReleased =>
      releaseDate > 0 &&
      DateTime.now()
          .isAfter(DateTime.fromMillisecondsSinceEpoch(releaseDate * 1000));
}

bool _match(Iterable<String> left, Iterable<String> right) {
  Set<String> a = Set.from(left);
  Set<String> b = Set.from(right);

  return a.intersection(b).length == a.length;
}
