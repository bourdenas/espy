import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig extends ChangeNotifier {
  double windowWidth = 0;
  CardDecoration _cardDecoration = CardDecoration.TAGS;
  LibraryLayout _libraryLayout = LibraryLayout.GRID;

  get cardDecoration => _cardDecoration;
  get libraryLayout => _libraryLayout;

  get isMobile => windowWidth <= 800;
  get isNotMobile => windowWidth > 800;

  get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: backgrounColour,
        backgroundColor: backgrounColour,
      );

  get foregroundColour => Color(0xFF66A3BB);
  get backgrounColour => Color(0xFF253A47);

  void nextCardDecoration() {
    _cardDecoration = CardDecoration
        .values[(_cardDecoration.index + 1) % CardDecoration.values.length];
    saveLocalPref();
    notifyListeners();
  }

  void nextLibraryLayout() {
    _libraryLayout = LibraryLayout
        .values[(_libraryLayout.index + 1) % LibraryLayout.values.length];
    saveLocalPref();
    notifyListeners();
  }

  Future<void> loadLocalPref() async {
    final prefs = await SharedPreferences.getInstance();

    _cardDecoration =
        CardDecoration.values[prefs.getInt('cardDecoration') ?? 1];
    _libraryLayout = LibraryLayout.values[prefs.getInt('libraryLayout') ?? 0];

    notifyListeners();
  }

  Future<void> saveLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('cardDecoration', _cardDecoration.index);
    prefs.setInt('libraryLayout', _libraryLayout.index);
  }
}

enum CardDecoration {
  EMPTY,
  INFO,
  TAGS,
}

enum LibraryLayout {
  GRID,
  EXPANDED_LIST,
  LIST,
}
