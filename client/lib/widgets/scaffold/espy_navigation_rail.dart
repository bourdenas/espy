import 'package:espy/widgets/scaffold/menu_items.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyNavigationRail extends StatefulWidget {
  final bool extended;

  const EspyNavigationRail(this.extended);

  @override
  State<StatefulWidget> createState() {
    return EspyNavigationRailState(extended);
  }
}

class EspyNavigationRailState extends State<EspyNavigationRail> {
  final bool extended;
  int _selectedIndex = 0;

  EspyNavigationRailState(this.extended);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    return NavigationRail(
      extended: extended,
      labelType: NavigationRailLabelType.selected,
      selectedIndex: _selectedIndex,
      leading: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            child: user.signedIn
                ? ClipOval(
                    child: Image.network(user.user.photoURL),
                  )
                : Icon(Icons.person),
          ),
        ),
      ]),
      groupAlignment: 0,
      destinations: menuItems
          .map((e) => NavigationRailDestination(
                label: Text(e.label),
                icon: Icon(e.icon),
                selectedIcon: Icon(e.selectedIcon),
              ))
          .toList(),
      onDestinationSelected: (index) {
        _selectedIndex = index;
        menuItems[_selectedIndex].onTap(context);
      },
    );
  }
}
