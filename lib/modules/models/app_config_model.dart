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

  bool get showBottomSheet => _showBottomSheet;
  set showBottomSheet(bool show) {
    _showBottomSheet = show;
    notifyListeners();
  }

  bool _showBottomSheet = false;

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
  EnumOption<LibraryOrdering> libraryOrdering = EnumOption<LibraryOrdering>(
    (index) => LibraryOrdering.values[index],
    LibraryOrdering.values.length,
  );
  EnumOption<LibraryGrouping> libraryGrouping = EnumOption<LibraryGrouping>(
    (index) => LibraryGrouping.values[index],
    LibraryGrouping.values.length,
  );
  EnumOption<Stacks> stacks = EnumOption<Stacks>(
    (index) => Stacks.values[index],
    Stacks.values.length,
  );

  BoolOption showMains = BoolOption();
  BoolOption showExpansions = BoolOption();
  BoolOption showRemakes = BoolOption();
  BoolOption showEarlyAccess = BoolOption();
  BoolOption showDlcs = BoolOption();
  BoolOption showVersions = BoolOption();
  BoolOption showBundles = BoolOption();
  BoolOption showCasual = BoolOption();

  AppConfigModel() {
    libraryLayout.onUpdate = _updateOptions;
    cardDecoration.onUpdate = _updateOptions;
    libraryOrdering.onUpdate = _updateOptions;
    libraryGrouping.onUpdate = _updateOptions;
    stacks.onUpdate = _updateOptions;
    showMains.onUpdate = _updateOptions;
    showExpansions.onUpdate = _updateOptions;
    showRemakes.onUpdate = _updateOptions;
    showEarlyAccess.onUpdate = _updateOptions;
    showDlcs.onUpdate = _updateOptions;
    showVersions.onUpdate = _updateOptions;
    showBundles.onUpdate = _updateOptions;
    showCasual.onUpdate = _updateOptions;
  }

  void _updateOptions() {
    _saveLocalPref();
    notifyListeners();
  }

  Future<void> loadLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    libraryLayout.valueIndex = prefs.getInt('libraryLayout') ?? 0;
    cardDecoration.valueIndex = prefs.getInt('cardDecoration') ?? 1;
    libraryOrdering.valueIndex = prefs.getInt('orderBy') ?? 0;
    libraryGrouping.valueIndex = prefs.getInt('groupBy') ?? 0;
    stacks.valueIndex = prefs.getInt('stacks') ?? 0;
    showMains.value = prefs.getBool('showMains') ?? true;
    showExpansions.value = prefs.getBool('showExpansions') ?? false;
    showRemakes.value = prefs.getBool('showRemakes') ?? false;
    showEarlyAccess.value = prefs.getBool('showEarlyAccess') ?? false;
    showDlcs.value = prefs.getBool('showDlcs') ?? false;
    showVersions.value = prefs.getBool('showVersions') ?? false;
    showBundles.value = prefs.getBool('showBundles') ?? false;
    showCasual.value = prefs.getBool('showCasual') ?? false;
    _seedColor = Color(prefs.getInt('seedColor') ?? 0);

    notifyListeners();
  }

  Future<void> _saveLocalPref() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('libraryLayout', libraryLayout.value.index);
    prefs.setInt('cardDecoration', cardDecoration.value.index);
    prefs.setInt('orderBy', libraryOrdering.value.index);
    prefs.setInt('groupBy', libraryGrouping.value.index);
    prefs.setInt('stacks', stacks.value.index);
    prefs.setBool('showMains', showMains.value);
    prefs.setBool('showExpansions', showExpansions.value);
    prefs.setBool('showRemakes', showRemakes.value);
    prefs.setBool('showEarlyAccess', showEarlyAccess.value);
    prefs.setBool('showDlcs', showDlcs.value);
    prefs.setBool('showVersions', showVersions.value);
    prefs.setBool('showBundles', showBundles.value);
    prefs.setBool('showCasual', showCasual.value);
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
  pulse,
  tags,
}

enum Stacks {
  genres,
  collections,
  developers,
}

enum LibraryClass {
  all,
  inLibrary,
  wishlist,
  untagged,
}

enum LibraryOrdering {
  release,
  rating,
  popularity,
}

enum LibraryGrouping {
  none,
  year,
  genre,
  keywords,
  rating,
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
