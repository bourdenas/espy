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
  final String? gogAuthCode;
  final String? steamUserId;
  final String? egsAuthCode;

  Keys({
    required this.gogAuthCode,
    required this.steamUserId,
    required this.egsAuthCode,
  });

  Keys.fromJson(Map<String, dynamic> json)
      : this(
          gogAuthCode:
              json.containsKey('gog_auth_code') ? json['gog_auth_code'] : null,
          steamUserId:
              json.containsKey('steam_user_id') ? json['steam_user_id'] : null,
          egsAuthCode:
              json.containsKey('egs_auth_code') ? json['egs_auth_code'] : null,
        );

  Map<String, dynamic> toJson() {
    return {
      if (gogAuthCode != null) 'gog_auth_code': gogAuthCode,
      if (steamUserId != null) 'steam_user_id': steamUserId,
      if (egsAuthCode != null) 'egs_auth_code': egsAuthCode,
    };
  }
}
