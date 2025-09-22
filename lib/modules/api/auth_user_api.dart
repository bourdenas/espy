import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/modules/api/auth_client.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart';

class AuthUserApi {
  static final _authClient = AuthClient();

  /// Initiates the library sync process to the espy backend for the user.
  static Future<String> syncLibrary(Keys keys) async {
    var response = await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/sync'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      return 'Done';
    } else {
      return 'Failed to post updated user information:\n${response.statusCode}';
    }
  }

  /// Unlinks a storefront from the account.
  static Future<void> unlink(String storefrontId) async {
    var response = await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/unlink'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'storefront_id': storefrontId}),
    );

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print('Failed to unlink storefront:\n${response.statusCode}');
      }
    }
  }

  static Future<bool> matchEntry(StoreEntry storeEntry, int gameId) async {
    final response = await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'game_id': gameId,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<bool> unmatchEntry(
    StoreEntry storeEntry,
    LibraryEntry libraryEntry, {
    bool delete = false,
  }) async {
    final response = await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'unmatch_entry': libraryEntry.toJson(),
        'delete_unmatched': delete,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<bool> rematchEntry(
    StoreEntry storeEntry,
    LibraryEntry libraryEntry,
    int gameId,
  ) async {
    final response = await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'game_id': gameId,
        'unmatch_entry': libraryEntry.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<bool> updateEntry(LibraryEntry libraryEntry) async {
    final response = await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/update'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'game_id': libraryEntry.id,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<void> addToWishlist(LibraryEntry libraryEntry) async {
    await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'add_game': libraryEntry.toJson(),
      }),
    );
  }

  static Future<void> removeFromWishlist(int gameId) async {
    await _authClient.post(
      Uri.parse('${Urls.espyBackend}/library/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'remove_game': gameId,
      }),
    );
  }

  static Future<bool> deleteGameEntry(int gameId) async {
    final response = await _authClient.post(
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

  static Future<void> updateGenre(int gameId, String? genre) async {
    await _authClient.post(
      Uri.parse('${Urls.espyBackend}/update_genre'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'game_id': gameId,
        if (genre != null) 'genre': genre,
      }),
    );
  }
}
