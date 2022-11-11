import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/home/espy_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopLevelPage extends StatefulWidget {
  final Widget body;

  TopLevelPage({required this.body});

  @override
  State<TopLevelPage> createState() => _TopLevelPageState();
}

class _TopLevelPageState extends State<TopLevelPage>
    with TickerProviderStateMixin {
  late AnimationController _drawerAnimationController;
  late Animation _drawerTween;

  @override
  void initState() {
    super.initState();

    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _drawerTween = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawerAnimationController,
        curve: Curves.easeInOutCirc,
      ),
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFF26262F),
      child: Actions(
        actions: {
          SearchIntent: CallbackAction<SearchIntent>(
              onInvoke: (intent) => context.pushNamed('search')),
        },
        child: Focus(
          autofocus: true,
          child: AppConfigModel.isMobile(context)
              ? _mobilePage(context)
              : _desktopPage(context),
        ),
      ),
    );
  }

  Widget _desktopPage(BuildContext context) {
    return EspyScaffold(
      body: widget.body,
    );
  }

  Widget _mobilePage(BuildContext context) {
    return AnimatedBuilder(
        animation: _drawerTween,
        builder: (context, _) {
          double slide = 300.0 * _drawerTween.value;
          double scale = 1.0 - (_drawerTween.value * 0.25);
          double radius = _drawerTween.value * 30.0;
          double rotate = _drawerTween.value * -0.139626;

          return Stack(
            children: [
              Container(
                width: 220.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _sideMenu(context),
                ),
              ),
              Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale)
                  ..rotateZ(rotate),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: EspyScaffold(
                    body: widget.body,
                    onShowMenu: () {
                      _drawerAnimationController.forward();
                    },
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget _sideMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32.0),
        GestureDetector(
          key: Key('closeDrawerButton'),
          onTap: () {
            _drawerAnimationController.reverse();
          },
          child: Row(
            children: [
              SizedBox(width: 8.0),
              CircleAvatar(
                child: Icon(
                  Icons.close,
                ),
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ),
        SizedBox(height: 64.0),
        if (user != null)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image(
                    image: NetworkImage(user.photoURL!),
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName!,
                      style: Theme.of(context).textTheme.headline6!.copyWith(
                            fontSize: 16.0,
                          ),
                    ),
                    Text(
                      user.email!,
                      style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              )
            ],
          ),
        SizedBox(height: 32.0),
        ListTile(
          key: Key('libraryListTile'),
          onTap: () => context.goNamed('games'),
          leading: Icon(Icons.my_library_books),
          title: Text('Library'),
          // selected: data.state == figure out,
          style: ListTileStyle.drawer,
          iconColor: Colors.white70,
          textColor: Colors.white70,
          selectedColor: Colors.white,
          selectedTileColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        ListTile(
          key: Key('unmatchedListTile'),
          onTap: () => context.goNamed('unmatched'),
          leading: Icon(Icons.device_unknown),
          title: Text('Unmatched Titles'),
          // selected: data.state == figure out,
          style: ListTileStyle.drawer,
          iconColor: Colors.white70,
          textColor: Colors.white70,
          selectedColor: Colors.white,
          selectedTileColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        ListTile(
          key: Key('settingsListTile'),
          onTap: () => context.goNamed('profile'),
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          iconColor: Colors.white70,
          textColor: Colors.white70,
        ),
      ],
    );
  }
}