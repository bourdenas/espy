import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filter =
        context.select((EspyRouterDelegate delegate) => delegate.filter);

    if (filter == null) {
      return Row(children: []);
    }

    return Row(children: [
      for (final store in filter.stores) ...[
        InputChip(
          label: Text(store),
          backgroundColor: Colors.purple[800],
          onDeleted: () {
            context.read<EspyRouterDelegate>().showLibrary();
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
      for (final company in filter.companies) ...[
        InputChip(
          label: Text('${company.name}'),
          backgroundColor: Colors.red[800],
          onDeleted: () {
            context.read<EspyRouterDelegate>().showLibrary();
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
      for (final collection in filter.collections) ...[
        InputChip(
          label: Text('${collection.name}'),
          backgroundColor: Colors.indigo[800],
          onDeleted: () {
            context.read<EspyRouterDelegate>().showLibrary();
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
      for (final tag in filter.tags) ...[
        InputChip(
          label: Text(tag),
          onDeleted: () {
            context.read<EspyRouterDelegate>().showLibrary();
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
    ]);
  }
}
