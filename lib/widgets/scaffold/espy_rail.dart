import 'package:espy/widgets/scaffold/espy_menu_items.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EspyNavigationRail extends StatefulWidget {
  final bool extended;
  final String path;

  const EspyNavigationRail(this.extended, this.path, {super.key});

  @override
  State<StatefulWidget> createState() {
    return EspyNavigationRailState();
  }
}

class EspyNavigationRailState extends State<EspyNavigationRail> {
  int _selectedIndex = 0;
  final Map<String, int> _mapping = {
    '': 0,
    'games': 1,
    'browse': 2,
    'years': 3,
    'releases': 4,
    'unresolved': 5,
  };

  @override
  void initState() {
    super.initState();
    _selectedIndex = _mapping[widget.path.split('/')[1]] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return NavigationRail(
      extended: widget.extended,
      labelType: !widget.extended ? NavigationRailLabelType.selected : null,
      selectedIndex: _selectedIndex,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton(
            heroTag: 'userPic',
            backgroundColor: Colors.transparent,
            child: CircleAvatar(
              radius: 28,
              child: user != null
                  ? ClipOval(
                      child: Image.network(user.photoURL!),
                    )
                  : const Icon(Icons.account_circle),
            ),
            onPressed: () => context.pushNamed('profile')),
      ),
      groupAlignment: 0,
      destinations: espyMenuItems
          .where((e) => user != null || !e.requiresSignIn)
          .map((e) => NavigationRailDestination(
                label: Text(e.label),
                icon: e.showBadge(context)
                    ? Badge(
                        label: e.badgeLabel(context),
                        child: Icon(e.icon),
                      )
                    : Icon(e.icon),
                selectedIcon: Icon(e.selectedIcon),
              ))
          .toList(),
      onDestinationSelected: (index) {
        espyMenuItems
            .where((e) => user != null || !e.requiresSignIn)
            .elementAt(index)
            .onTap(context);
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}
