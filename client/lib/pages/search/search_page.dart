import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/dialogs/search/search_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/pages/details/game_details_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    key: Key('searchTextField'),
                    // controller: _textEditingController,
                    onSubmitted: (text) {},
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    cursorColor: Colors.white,
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.filter_alt_outlined),
                    onPressed: () {},
                    splashRadius: 20.0,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Text(
                    'Search Result for ',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    'Games',
                    style: Theme.of(context).textTheme.headline6?.copyWith(
                          color: Colors.redAccent,
                        ),
                  )
                ],
              ),
            ),
            // _buildSearchResults(context, data.filter),
          ],
        ),
      ),
    );
  }
}
