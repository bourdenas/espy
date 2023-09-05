import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void setLibraryView(BuildContext context, LibraryFilter filter) {
  context.read<LibraryFilterModel>().filter = filter;
  context.goNamed('games', queryParameters: filter.params());
}

void updateLibraryView(BuildContext context, LibraryFilter filter) {
  context.read<LibraryFilterModel>().updateFilter(filter);
  context.pushNamed('games', queryParameters: filter.params());
}
