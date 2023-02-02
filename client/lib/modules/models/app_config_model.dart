import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration structure.
class AppConfigModel extends ChangeNotifier {
  get theme => ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(backgroundColor: backgrounColor),
        scaffoldBackgroundColor: backgrounColor,
      );

  static Color get foregroundColor => Color(0xFF0F1720);
  static Color get backgrounColor => Color(0xFF1B2838);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 800;

  double windowWidth = 0;

  LibraryLayout get libraryLayout => _libraryLayout;

  set libraryLayoutIndex(int index) {
    _libraryLayout = LibraryLayout.values[index % LibraryLayout.values.length];
    _saveLocalPref();
    notifyListeners();
  }

  void nextLibraryLayout() => libraryLayoutIndex = _libraryLayout.index + 1;

  CardDecoration get cardDecoration => _cardDecoration;

  set cardDecorationIndex(int index) {
    _cardDecoration =
        CardDecoration.values[index % CardDecoration.values.length];
    _saveLocalPref();
    notifyListeners();
  }

  void nextCardDecoration() => cardDecorationIndex = _cardDecoration.index + 1;

  GroupBy get groupBy => _groupBy;

  set groupByIndex(int index) {
    _groupBy = GroupBy.values[index % GroupBy.values.length];
    _saveLocalPref();
    notifyListeners();
  }

  void nextGroupBy() => groupByIndex = _groupBy.index + 1;

  LibraryLayout _libraryLayout = LibraryLayout.GRID;
  CardDecoration _cardDecoration = CardDecoration.TAGS;
  GroupBy _groupBy = GroupBy.NONE;

  Future<void> loadLocalPref() async {
    final prefs = await SharedPreferences.getInstance();

    _cardDecoration =
        CardDecoration.values[prefs.getInt('cardDecoration') ?? 1];
    _libraryLayout = LibraryLayout.values[prefs.getInt('libraryLayout') ?? 0];
    _groupBy = GroupBy.values[prefs.getInt('groupBy') ?? 0];

    notifyListeners();
  }

  Future<void> _saveLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('cardDecoration', _cardDecoration.index);
    prefs.setInt('libraryLayout', _libraryLayout.index);
    prefs.setInt('groupBy', _groupBy.index);
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

enum GroupBy {
  NONE,
  YEAR,
}
