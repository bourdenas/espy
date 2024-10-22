import 'dart:convert';

import 'package:espy/modules/models/backend_api.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DebugDialog extends StatelessWidget {
  const DebugDialog({
    super.key,
    required this.gameEntry,
  });

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('    ');
    final gameEntryDebug = encoder.convert(gameEntry);

    return AlertDialog(
      insetPadding: const EdgeInsets.all(8),
      title: SizedBox(
        width: 500.0,
        height: 800.0,
        child: ListView(
          children: [
            SizedBox(
                height: 750,
                child: SingleChildScrollView(
                  child: JsonView.string(gameEntryDebug),
                )),
            const SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    BackendApi.retrieveGameEntry(gameEntry.id);
                  },
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.pop();
                    BackendApi.deleteGameEntry(gameEntry.id);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
