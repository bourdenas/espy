import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/dialogs/store_entry_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnmatchedView extends StatefulWidget {
  @override
  _UnmatchedViewState createState() => _UnmatchedViewState();
}

class _UnmatchedViewState extends State<UnmatchedView> {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(context.watch<UserModel>().user.uid)
            .collection('unknown')
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Failed to reach remote server.');
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          return ListView(
            restorationId: 'list_view_unmatched_game_entries_offset',
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final item = document.data() as Map<String, dynamic>;
              return ListTile(
                title: Row(children: [
                  Text(item['title']),
                ]),
                subtitle: Text(item['storefront_name']),
                onTap: () async => await StoreEntryEditDialog.show(
                    context,
                    StoreEntry(
                      title: item['title'],
                    )),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
