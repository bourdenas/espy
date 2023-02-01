import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration structure.
class AppConfigModel extends ChangeNotifier {
  double windowWidth = 0;
  LibraryLayout _libraryLayout = LibraryLayout.GRID;
  CardDecoration _cardDecoration = CardDecoration.TAGS;

  LibraryLayout get libraryLayout => _libraryLayout;
  CardDecoration get cardDecoration => _cardDecoration;

  get theme => ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(backgroundColor: backgrounColor),
        scaffoldBackgroundColor: backgrounColor,
      );

  static get foregroundColor => Color(0xFF0F1720);
  static get backgrounColor => Color(0xFF1B2838);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 800;

  set libraryLayoutIndex(int index) {
    _libraryLayout = LibraryLayout.values[index % LibraryLayout.values.length];
    saveLocalPref();
    notifyListeners();
  }

  void nextLibraryLayout() {
    _libraryLayout = LibraryLayout
        .values[(_libraryLayout.index + 1) % LibraryLayout.values.length];
    saveLocalPref();
    notifyListeners();
  }

  set cardDecorationIndex(int index) {
    _cardDecoration =
        CardDecoration.values[index % CardDecoration.values.length];
    saveLocalPref();
    notifyListeners();
  }

  void nextCardDecoration() {
    _cardDecoration = CardDecoration
        .values[(_cardDecoration.index + 1) % CardDecoration.values.length];
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

enum LibraryLayout {
  GRID,
  LIST,
}

enum CardDecoration {
  EMPTY,
  INFO,
  TAGS,
}
