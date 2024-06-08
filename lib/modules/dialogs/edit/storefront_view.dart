import 'package:espy/constants/stores.dart';
import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StorefrontView extends StatefulWidget {
  const StorefrontView(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  StorefrontViewState createState() => StorefrontViewState();
}

class StorefrontViewState extends State<StorefrontView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int tabIndex = 0;

  @override
  void initState() {
    _tabController = TabController(
      initialIndex: 0,
      length: widget.libraryEntry.storeEntries.length,
      vsync: this,
    );
    _tabController!.addListener(() {
      setState(() {
        tabIndex = _tabController!.index;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            for (final storeEntry in widget.libraryEntry.storeEntries)
              Tab(
                icon: SizedBox(
                  height: 32,
                  child: Stores.getIcon(storeEntry.storefront),
                ),
                iconMargin: const EdgeInsets.only(bottom: 10.0),
              ),
          ],
        ),
        SizedBox(
          height: 120,
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final storeEntry in widget.libraryEntry.storeEntries)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: TextEditingController()
                          ..text = storeEntry.title,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Store Title',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            child: const Text('Re-match'),
                            onPressed: () => onRematch(context, storeEntry),
                          ),
                          FilledButton(
                            child: const Text('Unmatch'),
                            onPressed: () => onUnmatch(context, storeEntry),
                          ),
                          FilledButton(
                            child: const Text('Delete'),
                            onPressed: () => onDelete(context, storeEntry),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void onRematch(BuildContext context, StoreEntry storeEntry) {
    MatchingDialog.show(
      context,
      storeEntry: storeEntry,
      onMatch: (storeEntry, gameEntry) {
        context
            .read<UserLibraryModel>()
            .rematchEntry(storeEntry, widget.libraryEntry, gameEntry);
        context
            .pushNamed('details', pathParameters: {'gid': '${gameEntry.id}'});
      },
    );
  }

  void onUnmatch(BuildContext context, StoreEntry storeEntry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('Are you sure you want to unmatch this entry?'),
          actions: [
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Unmatching '${storeEntry.title}'...")));
                Navigator.of(context).pop();

                if (widget.libraryEntry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context
                    .read<UserLibraryModel>()
                    .unmatchEntry(storeEntry, widget.libraryEntry);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void onDelete(BuildContext context, StoreEntry storeEntry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Deleting '${storeEntry.title}'...")));
                Navigator.of(context).pop();

                if (widget.libraryEntry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context.read<UserLibraryModel>().unmatchEntry(
                      storeEntry,
                      widget.libraryEntry,
                      delete: true,
                    );
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
