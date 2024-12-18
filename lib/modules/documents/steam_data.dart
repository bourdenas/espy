class SteamData {
  final String name;
  final int steamAppid;
  final String detailedDescription;
  final String shortDescription;
  final String aboutTheGame;

  final String? headerImage;
  final String? backgroundImage;

  final List<String> developers;
  final List<String> publishers;

  final SteamScore? score;
  final List<NewsItem> news;
  final Metacritic? metacritic;

  final List<Genre> genres;
  final List<String> userTags;
  final List<Screenshot> screenshots;
  final List<Movie> movies;

  const SteamData({
    required this.name,
    required this.steamAppid,
    required this.detailedDescription,
    required this.shortDescription,
    required this.aboutTheGame,
    this.headerImage = '',
    this.backgroundImage = '',
    this.developers = const [],
    this.publishers = const [],
    this.score,
    this.news = const [],
    this.metacritic,
    this.genres = const [],
    this.userTags = const [],
    this.screenshots = const [],
    this.movies = const [],
  });

  SteamData.fromJson(Map<String, dynamic> json)
      : this(
          name: json['name']!,
          steamAppid: json['steam_appid']!,
          detailedDescription: json['detailed_description']!,
          shortDescription: json['short_description']!,
          aboutTheGame: json['about_the_game']!,
          headerImage: json['header_image'],
          backgroundImage: json['background_raw'],
          developers: [
            for (final developer in json['developers'] ?? []) developer,
          ],
          publishers: [
            for (final publisher in json['publishers'] ?? []) publisher,
          ],
          score:
              json['score'] != null ? SteamScore.fromJson(json['score']) : null,
          news: [
            for (final item in json['news'] ?? []) NewsItem.fromJson(item),
          ],
          metacritic: json['metacritic'] != null
              ? Metacritic.fromJson(json['metacritic'])
              : null,
          genres: [
            for (final genre in json['genres'] ?? []) Genre.fromJson(genre),
          ],
          userTags: [
            for (final tag in json['user_tags'] ?? []) tag,
          ],
          screenshots: [
            for (final screenshot in json['screenshots'] ?? [])
              Screenshot.fromJson(screenshot),
          ],
          movies: [
            for (final movie in json['movies'] ?? []) Movie.fromJson(movie),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'steam_appid': steamAppid,
      'detailed_description': detailedDescription,
      'short_description': shortDescription,
      'about_the_game': aboutTheGame,
      if (headerImage != null) 'header_image': headerImage,
      if (backgroundImage != null) 'background_raw': backgroundImage,
      if (developers.isNotEmpty) 'developers': developers,
      if (publishers.isNotEmpty) 'publishers': publishers,
      if (score != null) 'score': score!.toJson(),
      if (metacritic != null) 'metacritic': metacritic!.toJson(),
      if (genres.isNotEmpty)
        'genres': [
          for (final genre in genres) genre.toJson(),
        ],
      if (userTags.isNotEmpty) 'user_tags': userTags,
      if (screenshots.isNotEmpty)
        'screenshots': [
          for (final screenshot in screenshots) screenshot.toJson(),
        ],
      if (movies.isNotEmpty)
        'movies': [
          for (final movie in movies) movie.toJson(),
        ],
    };
  }
}

class Genre {
  final String id;
  final String description;

  const Genre({
    required this.id,
    required this.description,
  });

  Genre.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'] ?? '',
          description: json['description'] ?? '',
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
    };
  }
}

class SteamScore {
  final int reviewScore;
  final int totalReviews;
  final String reviewScoreDescription;

  const SteamScore({
    required this.reviewScore,
    required this.totalReviews,
    required this.reviewScoreDescription,
  });

  SteamScore.fromJson(Map<String, dynamic> json)
      : this(
          reviewScore: json['review_score'] ?? 0,
          totalReviews: json['total_reviews'] ?? 0,
          reviewScoreDescription: json['review_score_desc'] ?? '',
        );

  Map<String, dynamic> toJson() {
    return {
      'review_score': reviewScore,
      'total_reviews': totalReviews,
      'review_score_desc': reviewScoreDescription,
    };
  }
}

class NewsItem {
  final int date;
  final String url;
  final String title;
  final String contents;

  const NewsItem({
    required this.date,
    required this.url,
    required this.title,
    required this.contents,
  });

  NewsItem.fromJson(Map<String, dynamic> json)
      : this(
          date: json['date'] ?? '',
          url: json['url'] ?? '',
          title: json['title'] ?? '',
          contents: json['contents'] ?? '',
        );

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'url': url,
      'title': title,
      'contents': contents,
    };
  }
}

class Metacritic {
  final int score;
  final String url;

  const Metacritic({
    required this.score,
    required this.url,
  });

  Metacritic.fromJson(Map<String, dynamic> json)
      : this(
          score: json['score'] ?? '',
          url: json['url'] ?? '',
        );

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'url': url,
    };
  }
}

class Screenshot {
  final int id;
  final String pathThumbnail;
  final String pathFull;

  const Screenshot({
    required this.id,
    required this.pathThumbnail,
    required this.pathFull,
  });

  Screenshot.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          pathThumbnail: json['path_thumbnail'],
          pathFull: json['path_full'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path_thumbnail': pathThumbnail,
      'path_full': pathFull,
    };
  }
}

class Movie {
  final int id;
  final String name;
  final String thumbnail;
  final WebM webm;

  const Movie({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.webm,
  });

  Movie.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
          thumbnail: json['thumbnail'],
          webm: WebM.fromJson(json['webm']),
        );

  Map<String, dynamic> toJson() {
    return {
      'image_id': id,
      'height': name,
      'width': thumbnail,
    };
  }
}

class WebM {
  final String max;

  const WebM({
    required this.max,
  });

  WebM.fromJson(Map<String, dynamic> json)
      : this(
          max: json['max'],
        );

  Map<String, dynamic> toJson() {
    return {
      'max': max,
    };
  }
}
