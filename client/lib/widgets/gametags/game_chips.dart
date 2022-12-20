import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/material.dart';

class CompanyChip extends EspyChip {
  CompanyChip(String company,
      {VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          label: company,
          color: Colors.redAccent,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class CollectionChip extends EspyChip {
  CollectionChip(String collection,
      {VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          label: collection,
          color: Colors.indigoAccent,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class StoreChip extends EspyChip {
  StoreChip(String store, {VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          label: store,
          color: Colors.deepPurpleAccent,
          onPressed: onPressed ?? () {},
          onDeleted: onDeleted,
        );
}

class TagChip extends EspyChip {
  TagChip(
    UserTag tag, {
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
    VoidCallback? onRightClick,
  }) : super(
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
    required this.label,
    required this.color,
    this.onPressed,
    this.onDeleted,
    this.onRightClick,
  });

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
