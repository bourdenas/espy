import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration structure.
class AppConfigModel extends ChangeNotifier {
  get theme => darkTheme;

  get themeMode => ThemeMode.dark;
  get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.light,
      );
  get darkTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
      );

  set seedColor(Color color) {
    _seedColor = color;
    _saveLocalPref();
    notifyListeners();
  }

  Color _seedColor = Colors.blueGrey;

  static get gameDetailsBackgroundColor => const Color(0xFF1B2838);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 800;
  static bool isDesktop(BuildContext context) => !isMobile(context);

  static const gridCardContraints =
      LibraryCardContraints(maxCardWidth: 250, cardAspectRatio: .75);
  static const listCardContraints =
      LibraryCardContraints(maxCardWidth: 600, cardAspectRatio: 2.5);

  double windowWidth = 0;

  EnumOption<LibraryLayout> libraryLayout = EnumOption<LibraryLayout>(
    (index) => LibraryLayout.values[index],
    LibraryLayout.values.length,
  );
  EnumOption<CardDecoration> cardDecoration = EnumOption<CardDecoration>(
    (index) => CardDecoration.values[index],
    CardDecoration.values.length,
  );
  EnumOption<LibraryGrouping> libraryGrouping = EnumOption<LibraryGrouping>(
    (index) => LibraryGrouping.values[index],
    LibraryGrouping.values.length,
  );
  EnumOption<Stacks> stacks = EnumOption<Stacks>(
    (index) => Stacks.values[index],
    Stacks.values.length,
  );

  BoolOption showExpansions = BoolOption();
  BoolOption fetchRemote = BoolOption();

  AppConfigModel() {
    libraryLayout.onUpdate = _updateOptions;
    cardDecoration.onUpdate = _updateOptions;
    libraryGrouping.onUpdate = _updateOptions;
    stacks.onUpdate = _updateOptions;
    showExpansions.onUpdate = _updateOptions;
    fetchRemote.onUpdate = _updateOptions;
  }

  void _updateOptions() {
    _saveLocalPref();
    notifyListeners();
  }

  Future<void> loadLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    libraryLayout.valueIndex = prefs.getInt('libraryLayout') ?? 0;
    cardDecoration.valueIndex = prefs.getInt('cardDecoration') ?? 1;
    libraryGrouping.valueIndex = prefs.getInt('groupBy') ?? 0;
    stacks.valueIndex = prefs.getInt('stacks') ?? 0;
    showExpansions.value = prefs.getBool('showExpansions') ?? false;
    fetchRemote.value = prefs.getBool('fetchRemote') ?? false;
    _seedColor = Color(prefs.getInt('seedColor') ?? 0);

    notifyListeners();
  }

  Future<void> _saveLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('libraryLayout', libraryLayout.value.index);
    prefs.setInt('cardDecoration', cardDecoration.value.index);
    prefs.setInt('groupBy', libraryGrouping.value.index);
    prefs.setInt('stacks', stacks.value.index);
    prefs.setBool('showExpansions', showExpansions.value);
    prefs.setBool('fetchRemote', fetchRemote.value);
    prefs.setInt('seedColor', _seedColor.value);
  }
}

enum LibraryLayout {
  grid,
  list,
}

enum CardDecoration {
  empty,
  info,
  tags,
}

enum Stacks {
  collections,
  developers,
  genres,
}

class EnumOption<EnumType> {
  final EnumType Function(int) _valueGetter;
  EnumType _value;
  int _valueIndex;
  final int _valuesLen;
  void Function()? onUpdate;

  EnumOption(this._valueGetter, this._valuesLen)
      : _value = _valueGetter(0),
        _valueIndex = 0;

  EnumType get value => _value;

  set valueIndex(int index) {
    _valueIndex = index % _valuesLen;
    _value = _valueGetter(_valueIndex);
    onUpdate?.call();
  }

  void nextValue() => valueIndex = _valueIndex + 1;
}

class BoolOption {
  bool _value = false;
  void Function()? onUpdate;

  bool get value => _value;

  set value(bool value) {
    _value = value;
    onUpdate?.call();
  }

  void nextValue() => value = !_value;
}

class LibraryCardContraints {
  const LibraryCardContraints(
      {required this.maxCardWidth, required this.cardAspectRatio});

  final double maxCardWidth;
  final double cardAspectRatio;
}
