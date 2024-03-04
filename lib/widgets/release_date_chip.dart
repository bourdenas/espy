import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';

class ReleaseDateChip extends StatelessWidget {
  const ReleaseDateChip(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 2.0,
          horizontal: 8.0,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          libraryEntry.digest.releaseDay,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
