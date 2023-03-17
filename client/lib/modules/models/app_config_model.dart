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

  ModalOption<LibraryLayout> libraryLayout = ModalOption<LibraryLayout>(
    (index) => LibraryLayout.values[index],
    LibraryLayout.values.length,
  );
  ModalOption<CardDecoration> cardDecoration = ModalOption<CardDecoration>(
    (index) => CardDecoration.values[index],
    CardDecoration.values.length,
  );
  ModalOption<GroupBy> groupBy = ModalOption<GroupBy>(
    (index) => GroupBy.values[index],
    GroupBy.values.length,
  );
  ModalOption<Stacks> stacks = ModalOption<Stacks>(
    (index) => Stacks.values[index],
    Stacks.values.length,
  );

  AppConfigModel() {
    libraryLayout.onUpdate = _updateOptions;
    cardDecoration.onUpdate = _updateOptions;
    groupBy.onUpdate = _updateOptions;
    stacks.onUpdate = _updateOptions;
  }

  void _updateOptions() {
    _saveLocalPref();
    notifyListeners();
  }

  Future<void> loadLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    libraryLayout.valueIndex = prefs.getInt('libraryLayout') ?? 0;
    cardDecoration.valueIndex = prefs.getInt('cardDecoration') ?? 1;
    groupBy.valueIndex = prefs.getInt('groupBy') ?? 0;

    notifyListeners();
  }

  Future<void> _saveLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('libraryLayout', libraryLayout.value.index);
    prefs.setInt('cardDecoration', cardDecoration.value.index);
    prefs.setInt('groupBy', groupBy.value.index);
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

enum Stacks {
  COLLECTIONS,
  GENRES,
  STYLES,
  THEMES,
}

class ModalOption<OptionEnum> {
  OptionEnum Function(int) _valueGetter;
  OptionEnum _value;
  int _valueIndex;
  int _valuesLen;
  void Function()? onUpdate;

  ModalOption(this._valueGetter, this._valuesLen)
      : _value = _valueGetter(0),
        _valueIndex = 0;

  OptionEnum get value => _value;

  set valueIndex(int index) {
    _valueIndex = index % _valuesLen;
    _value = _valueGetter(_valueIndex);
    onUpdate?.call();
  }

  void nextValue() => valueIndex = _valueIndex + 1;
}
