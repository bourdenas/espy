import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void setLibraryView(BuildContext context, LibraryFilter filter) {
  context.read<LibraryFilterModel>().filter = filter;
  context.goNamed('games');
}

void updateLibraryView(BuildContext context, LibraryFilter filter) {
  final filterModel = context.read<LibraryFilterModel>();
  filterModel.filter = filter;
}
