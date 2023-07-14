import 'package:espy/widgets/scaffold/espy_menu_items.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EspyDrawer extends StatefulWidget {
  const EspyDrawer(this.path, {super.key});

  final String path;

  @override
  State<EspyDrawer> createState() => _EspyDrawerState();
}

class _EspyDrawerState extends State<EspyDrawer> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FloatingActionButton(
                    heroTag: 'userPic',
                    backgroundColor: Colors.transparent,
                    child: CircleAvatar(
                      radius: 28,
                      child: user != null
                          ? ClipOval(
                              child: Image.network(user.photoURL!),
                            )
                          : const Icon(Icons.person),
                    ),
                    onPressed: () => context.pushNamed('profile'),
                  ),
                  const SizedBox(width: 16),
                  Text('${user?.displayName}'),
                ],
              ),
            ),
          ),
          for (final item in espyMenuItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                item.onTap(context);
              },
            ),
        ],
      ),
    );
  }
}
