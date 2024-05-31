import 'package:espy/modules/models/tags/user_tag_manager.dart';
import 'package:flutter/material.dart';

class DeveloperChip extends EspyChip {
  DeveloperChip(String company,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: company,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.redAccent;
}

class PublisherChip extends EspyChip {
  PublisherChip(String company,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: company,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.red[200]!;
}

class CollectionChip extends EspyChip {
  CollectionChip(String collection,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: collection,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.indigoAccent;
}

class FranchiseChip extends EspyChip {
  FranchiseChip(String collection,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: collection,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.indigo[200]!;
}

class GenreChip extends EspyChip {
  GenreChip(String keyword,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: keyword,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.deepPurple[200]!;
}

class GenreTagChip extends EspyChip {
  GenreTagChip(String keyword,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: keyword,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.orange;
}

class EspyGenreTagChip extends EspyChip {
  EspyGenreTagChip(String genre,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: genre,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.deepPurpleAccent;
}

class KeywordChip extends EspyChip {
  KeywordChip(String keyword,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: keyword,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.grey;
}

class StoreChip extends EspyChip {
  StoreChip(String store, {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: store,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.deepOrange;
}

class TagChip extends EspyChip {
  TagChip(
    CustomUserTag tag, {
    super.key,
    super.onPressed,
    super.onDeleted,
    super.onRightClick,
  }) : super(
          label: tag.name,
          color: tag.color,
        );
}

class EspyChip extends StatelessWidget {
  final String _label;
  final Color _color;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final VoidCallback? onRightClick;

  const EspyChip({
    Key? key,
    required String label,
    required Color color,
    this.onPressed,
    this.onDeleted,
    this.onRightClick,
  })  : _label = label,
        _color = color,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: onRightClick,
      child: InputChip(
        label: Text(_label),
        backgroundColor: _color,
        onPressed: onPressed,
        onDeleted: onDeleted,
      ),
    );
  }
}
