import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/material.dart';

class DeveloperChip extends EspyChip {
  DeveloperChip(String company,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: company,
          color: Colors.redAccent,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class PublisherChip extends EspyChip {
  PublisherChip(String company,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: company,
          color: Colors.red[200]!,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class CollectionChip extends EspyChip {
  CollectionChip(String collection,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: collection,
          color: Colors.indigoAccent,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class FranchiseChip extends EspyChip {
  FranchiseChip(String collection,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: collection,
          color: Colors.indigo[200]!,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class KeywordChip extends EspyChip {
  KeywordChip(String keyword,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: keyword,
          color: Colors.grey,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class StoreChip extends EspyChip {
  StoreChip(String store,
      {Key? key, VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          key: key,
          label: store,
          color: Colors.deepPurpleAccent,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class TagChip extends EspyChip {
  TagChip(
    UserTag tag, {
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
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final VoidCallback? onRightClick;

  const EspyChip({
    Key? key,
    required this.label,
    required this.color,
    this.onPressed,
    this.onDeleted,
    this.onRightClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: onRightClick,
      child: InputChip(
        label: Text(label),
        backgroundColor: color,
        onPressed: onPressed,
        onDeleted: onDeleted,
      ),
    );
  }
}
