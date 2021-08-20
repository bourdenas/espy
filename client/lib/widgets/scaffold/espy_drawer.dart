import 'package:espy/widgets/scaffold/menu_items.dart' show menuItems;
import 'package:espy/modules/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyDrawer extends StatelessWidget {
  const EspyDrawer();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: CircleAvatar(
              child: user.signedIn
                  ? ClipOval(
                      child: Image.network(user.user.photoURL),
                    )
                  : Icon(Icons.person),
            ),
          ),
          for (final item in menuItems)
            ListTile(
              title: Text(item.label),
              leading: Icon(item.icon),
              onTap: () {
                item.onTap(context);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
