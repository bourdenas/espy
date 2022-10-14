class SteamData {
  final String name;
  final int steamAppid;
  final String detailedDescription;
  final String shortDescription;
  final String aboutTheGame;

  final String? headerImage;
  final String? backgroundImage;

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
          screenshots: json.containsKey('screenshots')
              ? [
                  for (final screenshot in json['screenshots'])
                    Screenshot.fromJson(screenshot),
                ]
              : [],
          movies: json.containsKey('movies')
              ? [
                  for (final movie in json['movies']) Movie.fromJson(movie),
                ]
              : [],
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
