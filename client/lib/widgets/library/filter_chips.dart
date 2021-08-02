import 'package:espy/modules/models/library_filters_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFiltersModel>().filter;

    return Row(children: [
      for (final company in filter.companies) ...[
        InputChip(
          label: Text('${company.name}'),
          backgroundColor: Colors.red[900],
          onDeleted: () {
            context.read<LibraryFiltersModel>().removeCompanyFilter(company);
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
      for (final collection in filter.collections) ...[
        InputChip(
          label: Text('${collection.name}'),
          backgroundColor: Colors.indigo[800],
          onDeleted: () {
            context
                .read<LibraryFiltersModel>()
                .removeCollectionFilter(collection);
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
      for (final tag in filter.tags) ...[
        InputChip(
          label: Text(tag),
          onDeleted: () {
            context.read<LibraryFiltersModel>().removeTagFilter(tag);
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
    ]);
  }
}
