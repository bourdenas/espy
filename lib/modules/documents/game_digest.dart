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
  });

  GameDigest.fromGameEntry(GameEntry gameEntry)
      : this(
          id: gameEntry.id,
          name: gameEntry.name,
          category: gameEntry.category,
          cover: gameEntry.cover?.imageId,
          releaseDate: gameEntry.releaseDate,
          rating: gameEntry.igdbRating,
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
    };
  }
}
