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
  const TagChip(String tag, {VoidCallback? onPressed, VoidCallback? onDeleted})
      : super(
          label: tag,
          color: Colors.blueGrey,
          onPressed: onPressed,
          onDeleted: onDeleted,
        );
}

class EspyChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  const EspyChip({
    required this.label,
    required this.color,
    this.onPressed,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      backgroundColor: color,
      onPressed: onPressed,
      onDeleted: onDeleted,
    );
  }
}