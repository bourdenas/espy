import 'dart:collection';
import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameDetailsModel extends ChangeNotifier {
  Set<String> _tags = {};

  UnmodifiableListView<String> get tags => UnmodifiableListView(_tags);

  void update(Library library) {
    _tags.clear();
    for (final entry in library.entry) {
      _tags.addAll(entry.details.tag);
    }
    notifyListeners();
  }

  void postDetails(GameEntry entry) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/testing/details/${entry.game.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tags': entry.details.tag,
      }),
    );

    if (response.statusCode != 200) {
      print('postDetails (error): $response');
    } else {
      _tags.addAll(entry.details.tag);
      notifyListeners();
    }
  }
}
