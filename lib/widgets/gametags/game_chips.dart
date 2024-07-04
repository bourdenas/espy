import 'package:flutter/material.dart';

class StoreChip extends EspyChip {
  StoreChip(
    String store, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: store,
          color: color,
        );

  static Color get color => Colors.deepOrange;
}

class DeveloperChip extends EspyChip {
  DeveloperChip(
    String company, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: company,
          color: color,
        );

  static Color get color => Colors.redAccent;
}

class PublisherChip extends EspyChip {
  PublisherChip(
    String company, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: company,
          color: color,
        );

  static Color get color => Colors.red[200]!;
}

class CollectionChip extends EspyChip {
  CollectionChip(
    String name, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: name,
          color: color,
        );

  static Color get color => Colors.indigoAccent;
}

class FranchiseChip extends EspyChip {
  FranchiseChip(
    String name, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: name,
          color: color,
        );

  static Color get color => Colors.indigo[200]!;
}

class GenreGroupChip extends EspyChip {
  GenreGroupChip(
    String genre, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: genre,
          color: color,
        );

  static Color get color => Colors.deepPurple[200]!;
}

class EspyGenreChip extends EspyChip {
  EspyGenreChip(
    String genre, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: genre,
          color: color,
        );

  static Color get color => Colors.deepPurpleAccent;
}

class KeywordChip extends EspyChip {
  KeywordChip(
    String keyword, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: keyword,
          color: color,
        );

  static Color get color => Colors.grey;
}

class ManualGenreChip extends EspyChip {
  ManualGenreChip(
    String genre, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: genre,
          color: color,
        );

  static Color get color => Colors.orange;
}

class TagChip extends EspyChip {
  TagChip(
    String tag, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
    super.filled,
  }) : super(
          label: tag,
          color: color,
        );

  static MaterialColor get color => Colors.blueGrey;
}

class EspyChip extends StatelessWidget {
  final String _label;
  final Color _color;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final VoidCallback? onRightClick;
  final bool filled;

  const EspyChip({
    super.key,
    required String label,
    required Color color,
    this.onPressed,
    this.onDeleted,
    this.onRightClick,
    this.filled = true,
  })  : _label = label,
        _color = color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: onRightClick,
      child: InputChip(
        label: Text(
          _label,
          style: TextStyle(color: filled ? Colors.white : _color),
        ),
        backgroundColor: filled ? _color : null,
        onPressed: onPressed,
        onDeleted: onDeleted,
      ),
    );
  }
}
