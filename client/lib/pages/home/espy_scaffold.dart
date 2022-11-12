import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/espy_rail.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatefulWidget {
  final void Function()? onShowMenu;
  final Widget body;
  final String path;

  EspyScaffold({required this.body, required this.path, this.onShowMenu});

  @override
  State<EspyScaffold> createState() => _EspyScaffoldState();
}

class _EspyScaffoldState extends State<EspyScaffold>
    with TickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  late Animation _colorTween;

  @override
  void initState() {
    super.initState();

    _colorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 0),
    );
    _colorTween = ColorTween(
      begin: Colors.transparent,
      end: Colors.black.withOpacity(1),
    ).animate(_colorAnimationController);
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  bool _scrollListener(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.axis == Axis.vertical) {
      _colorAnimationController.animateTo(scrollInfo.metrics.pixels / 600);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.onShowMenu == null) EspyNavigationRail(false, widget.path),
        Expanded(
          child: AnimatedBuilder(
            animation: _colorAnimationController,
            builder: (context, _) {
              return Scaffold(
                extendBodyBehindAppBar: AppConfigModel.isMobile(context),
                appBar: appBar(context),
                floatingActionButton: FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () => MatchingDialog.show(
                    context,
                    onMatch: (storeEntry, gameEntry) {
                      context
                          .read<GameLibraryModel>()
                          .matchEntry(storeEntry, gameEntry);
                    },
                  ),
                ),
                body: NotificationListener<ScrollNotification>(
                  onNotification: _scrollListener,
                  child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      }),
                      child: widget.body),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  AppBar appBar(BuildContext context) {
    final appConfig = context.read<AppConfigModel>();

    return AppBar(
      toolbarOpacity: 0.6,
      title: Text(
        'espy',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ),
      ),
      actions: [
        IconButton(
          key: Key('layoutButton'),
          icon: Icon(_libraryViews[appConfig.libraryLayout.index].iconData),
          splashRadius: 20.0,
          onPressed: () {
            setState(() {
              appConfig.nextLibraryLayout();
            });
          },
        ),
        IconButton(
          key: Key('cardInfoButton'),
          icon: Icon(_cardViews[appConfig.cardDecoration.index].iconData),
          splashRadius: 20.0,
          onPressed: () {
            setState(() {
              appConfig.nextCardDecoration();
            });
          },
        ),
        IconButton(
          key: Key('searchButton'),
          icon: Icon(Icons.search),
          splashRadius: 20.0,
          onPressed: () => context.pushNamed('search'),
        ),
      ],
      backgroundColor: _colorTween.value,
      elevation: 0.0,
    );
  }

  List<_LibraryView> _libraryViews = const [
    _LibraryView(LibraryLayout.GRID, Icons.grid_view),
    _LibraryView(LibraryLayout.LIST, Icons.view_list),
  ];

  List<_CardsView> _cardViews = const [
    _CardsView(CardDecoration.EMPTY, Icons.label_off),
    _CardsView(CardDecoration.INFO, Icons.info),
    _CardsView(CardDecoration.TAGS, Icons.collections_bookmark),
  ];
}

class _LibraryView {
  final LibraryLayout layout;
  final IconData iconData;

  const _LibraryView(this.layout, this.iconData);
}

class _CardsView {
  final CardDecoration decoration;
  final IconData iconData;

  const _CardsView(this.decoration, this.iconData);
}
