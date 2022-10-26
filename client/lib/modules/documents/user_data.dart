import 'package:espy/modules/documents/store_entry.dart';

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

class Upload {
  final List<StoreEntry> entries;

  Upload({
    required this.entries,
  });

  Upload.fromJson(Map<StoreEntry, dynamic> json)
      : this(
          entries: json.containsKey('entries')
              ? [
                  for (final entry in json['entries'])
                    StoreEntry.fromJson(entry)
                ]
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      if (entries.isNotEmpty)
        'entries': [
          for (final entry in entries) entry.toJson(),
        ],
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
  final GogToken? gogToken;
  final String? steamUserId;
  final String? egsAuthCode;

  Keys({
    required this.gogToken,
    required this.steamUserId,
    required this.egsAuthCode,
  });

  Keys.fromJson(Map<String, dynamic> json)
      : this(
          gogToken: json.containsKey('gog_token')
              ? GogToken.fromJson(json['gog_token'])
              : null,
          steamUserId:
              json.containsKey('steam_user_id') ? json['steam_user_id'] : null,
          egsAuthCode:
              json.containsKey('egs_auth_code') ? json['egs_auth_code'] : null,
        );

  Map<String, dynamic> toJson() {
    return {
      if (gogToken != null) 'gog_token': gogToken!.toJson(),
      if (steamUserId != null) 'steam_user_id': steamUserId,
      if (egsAuthCode != null) 'egs_auth_code': egsAuthCode,
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
