import 'package:flutter/material.dart';

class AppBarSearchModel extends ChangeNotifier {
  String _searchPhrase = '';
  TextEditingController? _controller;

  String get text => _searchPhrase;

  set text(String text) {
    final str = text.toLowerCase();
    if (_searchPhrase == str) {
      return;
    }

    _searchPhrase = str;
    notifyListeners();
  }

  set controller(TextEditingController controller) {
    _controller = controller;
  }

  void clear() {
    if (_searchPhrase.isEmpty) {
      return;
    }

    _searchPhrase = '';
    if (_controller != null) {
      _controller!.text = '';
    }
    notifyListeners();
  }
}
