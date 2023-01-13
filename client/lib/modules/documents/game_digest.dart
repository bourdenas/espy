import 'package:espy/modules/documents/game_entry.dart';

class GameDigest {
  final String name;
  final String? cover;

  final int releaseDate;
  final double rating;

  final List<String> collections;
  final List<String> companies;

  GameDigest({
    required this.name,
    this.cover,
    this.releaseDate = 0,
    this.rating = 0,
    this.collections = const [],
    this.companies = const [],
  });

  GameDigest.fromGameEntry(GameEntry gameEntry)
      : this(
          name: gameEntry.name,
          cover: gameEntry.cover?.imageId,
          releaseDate: gameEntry.releaseDate,
          rating: gameEntry.igdbRating,
          collections: [
            for (final collection in gameEntry.collections) collection.name
          ],
          companies: [for (final company in gameEntry.companies) company.name],
        );

  GameDigest.fromJson(Map<String, dynamic> json)
      : this(
          name: json['name']!,
          cover: json['cover'],
          releaseDate: json['release_date'] ?? 0,
          rating: json['rating'] ?? 0,
          collections: [
            for (final collection in json['collections'] ?? []) collection,
          ],
          companies: [
            for (final company in json['companies'] ?? []) company,
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (cover != null) 'cover': cover,
      'release_date': releaseDate,
      if (rating != 0) 'rating': rating,
      if (collections.isNotEmpty) 'collections': collections,
      if (companies.isNotEmpty) 'companies': companies,
    };
  }
}
