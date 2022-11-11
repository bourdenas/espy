import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration structure.
class AppConfigModel extends ChangeNotifier {
  double windowWidth = 0;
  CardDecoration _cardDecoration = CardDecoration.TAGS;
  LibraryLayout _libraryLayout = LibraryLayout.GRID;

  get cardDecoration => _cardDecoration;
  get libraryLayout => _libraryLayout;

  get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: backgrounColour,
        backgroundColor: backgrounColour,
      );

  get foregroundColour => Color(0xFF66A3BB);
  get backgrounColour => Color(0xFF253A47);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 800;

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

enum LibraryLayout {
  GRID,
  LIST,
}

enum CardDecoration {
  EMPTY,
  INFO,
  TAGS,
}