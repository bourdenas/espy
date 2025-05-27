import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void setLibraryView(BuildContext context) {
  context.read<FilterModel>().clear();
  context.goNamed('games', pathParameters: {'title': 'Library'});
}

void updateLibraryView(
  BuildContext context, [
  LibraryFilter? filter,
]) {
  if (filter != null) {
    context.read<FilterModel>().filter = filter;
  }
  context.pushNamed('games', pathParameters: {'title': 'Library'});
}
