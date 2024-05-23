import 'package:espy/modules/models/unresolved_model.dart';
import 'package:espy/pages/unresolved/unknown_list_view.dart';
import 'package:espy/pages/unresolved/unresolved_list_view.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnresolvedPage extends StatelessWidget {
  const UnresolvedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final unresolved = context.watch<UnresolvedModel>();

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        if (unresolved.needApproval.isNotEmpty)
          Shelve(
            title: 'Pending Review',
            expansion: UnresolvedListView(unresolved.needApproval),
          ),
        if (unresolved.unknown.isNotEmpty)
          Shelve(
            title: 'Unknown Entries',
            expansion: UnknownListView(unresolved.unknown),
            expanded: unresolved.needApproval.isEmpty,
          ),
      ],
    );
  }
}
