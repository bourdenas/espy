import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:http/http.dart' as http;

class BackendApi {
  static Future<List<GameDigest>> searchByTitle(
    String title, {
    baseGameOnly = false,
  }) async {
    if (title.isEmpty) return [];

    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/search'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'title': title,
        'base_game_only': baseGameOnly,
      }),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final jsonObj = jsonDecode(response.body) as List<dynamic>;
    return jsonObj.map((obj) => GameDigest.fromJson(obj)).toList();
  }

  static Future<bool> retrieveGameEntry(int gameId) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/resolve'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'game_id': gameId,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<bool> deleteGameEntry(int gameId) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/delete'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'game_id': gameId,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<List<IgdbCompany>> companyFetch(String name) async {
    if (name.isEmpty) {
      return [];
    }

    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/company_fetch'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final jsonObj = jsonDecode(response.body) as List<dynamic>;
    return jsonObj.map((obj) => IgdbCompany.fromJson(obj)).toList();
  }
}
