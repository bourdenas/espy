import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void setLibraryView(BuildContext context) {
  context.read<RefinementModel>().clear();
  context.goNamed('games');
}

void updateLibraryView(
  BuildContext context, [
  LibraryFilter? filter,
]) {
  if (filter != null) {
    context.read<RefinementModel>().refinement = filter;
  }
  context.pushNamed('games');
}
