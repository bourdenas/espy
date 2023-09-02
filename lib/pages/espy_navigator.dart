import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void pushLibraryView(BuildContext context, LibraryFilter filter) {
  context.read<LibraryFilterModel>().filter = filter;
  context.pushNamed('games', queryParameters: filter.params());
}
