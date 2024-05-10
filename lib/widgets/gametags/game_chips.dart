import 'package:espy/modules/models/tags/user_tag_manager.dart';
import 'package:flutter/material.dart';

class DeveloperChip extends EspyChip {
  DeveloperChip(String company,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: company,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.redAccent;
}

class PublisherChip extends EspyChip {
  PublisherChip(String company,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: company,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.red[200]!;
}

class CollectionChip extends EspyChip {
  CollectionChip(String collection,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: collection,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.indigoAccent;
}

class FranchiseChip extends EspyChip {
  FranchiseChip(String collection,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: collection,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.indigo[200]!;
}

class GenreChip extends EspyChip {
  GenreChip(String keyword,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: keyword,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.deepPurple[200]!;
}

class GenreTagChip extends EspyChip {
  GenreTagChip(String keyword,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: keyword,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.deepPurpleAccent;
}

class EspyGenreTagChip extends EspyChip {
  EspyGenreTagChip(String genre,
      {super.key, VoidCallback? onPressed, super.onDeleted})
      : super(
          label: genre,
          color: color,
          onPressed: onPressed ?? () {},
        );

  static Color get color => Colors.orange;
}

class KeywordChip extends EspyChip {
  KeywordChip(String keyword,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: keyword,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.grey;
}

class StoreChip extends EspyChip {
  StoreChip(String store,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: store,
          color: color,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );

  static Color get color => Colors.orange;
}

class TagChip extends EspyChip {
  TagChip(
    CustomUserTag tag, {
    Key? key,
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
    VoidCallback? onRightClick,
  }) : super(
          key: key,
          label: tag.name,
          color: tag.color,
          onPressed: onPressed,
          onDeleted: onDeleted,
          onRightClick: onRightClick,
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
