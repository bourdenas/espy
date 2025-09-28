class UserData {
  final String uid;
  final Keys? keys;

  UserData({
    required this.uid,
    required this.keys,
  });

  UserData.fromJson(Map<String, dynamic> json)
      : this(
          uid: json['uid']!,
          keys: json.containsKey('keys') ? Keys.fromJson(json['keys']) : null,
        );

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      if (keys != null) 'keys': keys!.toJson(),
    };
  }
}

class ReconReport {
  final List<String> lines;

  ReconReport({
    required this.lines,
  });

  ReconReport.fromJson(Map<String, dynamic> json)
      : this(
          lines: json.containsKey('lines')
              ? [for (final line in json['lines']) line]
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      'lines': lines,
    };
  }
}

class Keys {
  final String? gogAuthCode;
  final String? steamUserId;

  Keys({
    required this.gogAuthCode,
    required this.steamUserId,
  });

  Keys.fromJson(Map<String, dynamic> json)
      : this(
          gogAuthCode:
              json.containsKey('gog_auth_code') ? json['gog_auth_code'] : null,
          steamUserId:
              json.containsKey('steam_user_id') ? json['steam_user_id'] : null,
        );

  Map<String, dynamic> toJson() {
    return {
      if (gogAuthCode != null) 'gog_auth_code': gogAuthCode,
      if (steamUserId != null) 'steam_user_id': steamUserId,
    };
  }
}
