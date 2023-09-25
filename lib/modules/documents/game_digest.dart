import 'package:espy/modules/documents/game_entry.dart';

class GameDigest {
  final int id;
  final String name;

  final String? category;
  final String? cover;

  final int releaseDate;
  final double rating;

  final List<String> collections;
  final List<String> franchises;
  final List<String> developers;
  final List<String> publishers;
  final List<String> genres;

  GameDigest({
    required this.id,
    required this.name,
    this.category,
    this.cover,
    this.releaseDate = 0,
    this.rating = 0,
    this.collections = const [],
    this.franchises = const [],
    this.developers = const [],
    this.publishers = const [],
    this.genres = const [],
  });

  GameDigest.fromGameEntry(GameEntry gameEntry)
      : this(
          id: gameEntry.id,
          name: gameEntry.name,
          category: gameEntry.category,
          cover: gameEntry.cover?.imageId,
          releaseDate: gameEntry.igdbGame.releaseDate,
          rating: gameEntry.igdbGame.rating,
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
          genres: gameEntry.genres,
        );

  GameDigest.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          category: json['category'] ?? '',
          cover: json['cover'],
          releaseDate: json['release_date'] ?? 0,
          rating: json['rating'] ?? 0,
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
          genres: [
            for (final genre in json['genres'] ?? []) genre,
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      if (cover != null) 'cover': cover,
      'release_date': releaseDate,
      if (rating != 0) 'rating': rating,
      if (collections.isNotEmpty) 'collections': collections,
      if (franchises.isNotEmpty) 'franchises': franchises,
      if (developers.isNotEmpty) 'developers': developers,
      if (publishers.isNotEmpty) 'publishers': publishers,
      if (genres.isNotEmpty) 'genres': genres,
    };
  }

  bool hasDiff(GameDigest other) {
    return id == other.id &&
        (name != other.name ||
            category != other.category ||
            cover != other.cover ||
            releaseDate != other.releaseDate ||
            rating != other.rating ||
            !_match(collections, other.collections) ||
            !_match(franchises, other.franchises) ||
            !_match(developers, other.developers) ||
            !_match(publishers, other.publishers));
  }
}

bool _match(Iterable<String> left, Iterable<String> right) {
  Set<String> a = Set.from(left);
  Set<String> b = Set.from(right);

  return a.intersection(b).length == a.length;
}
