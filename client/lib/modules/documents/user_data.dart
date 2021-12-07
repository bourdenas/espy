class UserData {
  final String uid;
  final Keys? keys;
  final int? version;

  UserData({
    required this.uid,
    required this.keys,
    required this.version,
  });

  UserData.fromJson(Map<String, dynamic> json)
      : this(
          uid: json['uid']!,
          keys: json.containsKey('keys') ? Keys.fromJson(json['keys']) : null,
          version: json.containsKey('keys') ? json['version'] : null,
        );

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      if (keys != null) 'keys': keys!.toJson(),
      if (version != null) 'version': version,
    };
  }
}

class Keys {
  final String? steamUserId;
  final GogToken? gogToken;

  Keys({
    required this.steamUserId,
    required this.gogToken,
  });

  Keys.fromJson(Map<String, dynamic> json)
      : this(
          steamUserId:
              json.containsKey('steam_user_id') ? json['steam_user_id'] : null,
          gogToken: json.containsKey('gog_token')
              ? GogToken.fromJson(json['gog_token'])
              : null,
        );

  Map<String, dynamic> toJson() {
    return {
      if (steamUserId != null) 'steam_user_id': steamUserId,
      if (gogToken != null) 'gog_token': gogToken!.toJson(),
    };
  }
}

class GogToken {
  final String oauthCode;

  GogToken({
    required this.oauthCode,
  });

  GogToken.fromJson(Map<String, dynamic> json)
      : this(
          oauthCode: json['oauth_code'],
        );

  Map<String, dynamic> toJson() {
    return {
      'oauth_code': oauthCode,
    };
  }
}
