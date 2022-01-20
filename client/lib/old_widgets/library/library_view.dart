import 'package:flutter/material.dart';

abstract class LibraryView extends StatelessWidget {
  const LibraryView({Key? key}) : super(key: key);

  int visibleEntries(BuildContext context);

  double get scrollThreshold;
}
