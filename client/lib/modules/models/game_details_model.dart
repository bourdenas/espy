import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameDetailsModel extends ChangeNotifier {
  String _userId = '';

  void update(String userId) async {
    _userId = userId;
  }

  void postDetails(LibraryEntry entry) async {
    entry.userData.tags.sort();

    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/details/${entry.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tags': entry.userData.tags,
      }),
    );

    if (response.statusCode != 200) {
      print('postDetails (error): $response');
    } else {
      // TODO: Need to update local tags index.
      // _tags.addAll(entry.details.tag);
      notifyListeners();
    }
  }
}
