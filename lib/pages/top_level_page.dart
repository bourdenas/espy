import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/pages/home/espy_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TopLevelPage extends StatefulWidget {
  final Widget body;
  final String path;

  const TopLevelPage({Key? key, required this.body, required this.path})
      : super(key: key);

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
      duration: const Duration(milliseconds: 300),
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
    return AppConfigModel.isMobile(context)
        ? _mobilePage(context)
        : _desktopPage(context);
  }

  Widget _desktopPage(BuildContext context) {
    return Actions(
      actions: {
        SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) => context.pushNamed('search')),
        HomeIntent: CallbackAction<HomeIntent>(
            onInvoke: (intent) => context.goNamed('home')),
        AddGameIntent: CallbackAction<AddGameIntent>(
            onInvoke: (intent) => MatchingDialog.show(
                  context,
                  onMatch: (storeEntry, gameEntry) {
                    context
                        .read<GameLibraryModel>()
                        .matchEntry(storeEntry, gameEntry);
                    context.pushNamed('details',
                        params: {'gid': '${gameEntry.id}'});
                  },
                )),
      },
      child: Focus(
        autofocus: !widget.path.startsWith('/details'),
        child: EspyScaffold(
          body: widget.body,
          path: widget.path,
        ),
      ),
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
              SizedBox(
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
                    path: widget.path,
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

    return Material(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32.0),
          GestureDetector(
            key: const Key('closeDrawerButton'),
            onTap: () {
              _drawerAnimationController.reverse();
            },
            child: Row(
              children: const [
                SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 64.0),
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
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName!,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontSize: 16.0,
                            ),
                      ),
                      Text(
                        user.email!,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          const SizedBox(height: 32.0),
          ListTile(
            key: const Key('libraryListTile'),
            onTap: () => context.pushNamed('games'),
            leading: const Icon(Icons.my_library_books),
            title: const Text('Library'),
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
            key: const Key('unmatchedListTile'),
            onTap: () => context.pushNamed('unmatched'),
            leading: const Icon(Icons.device_unknown),
            title: const Text('Unmatched Titles'),
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
            key: const Key('settingsListTile'),
            onTap: () => context.pushNamed('profile'),
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            iconColor: Colors.white70,
            textColor: Colors.white70,
          ),
        ],
      ),
    );
  }
}
