import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/espy_rail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatefulWidget {
  final void Function()? onShowMenu;
  final Widget body;

  EspyScaffold({required this.body, this.onShowMenu});

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
        if (widget.onShowMenu == null) EspyNavigationRail(false),
        Expanded(
          child: AnimatedBuilder(
            animation: _colorAnimationController,
            builder: (context, _) {
              return Scaffold(
                extendBodyBehindAppBar: AppConfigModel.isMobile(context),
                appBar: appBar(context),
                body: NotificationListener<ScrollNotification>(
                  onNotification: _scrollListener,
                  child: widget.body,
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
      leading: widget.onShowMenu != null
          ? IconButton(
              key: Key('drawerButton'),
              icon: Icon(Icons.menu),
              splashRadius: 20.0,
              onPressed: widget.onShowMenu,
            )
          : Image.asset(
              'assets/images/espy-logo_800.png',
              fit: BoxFit.cover,
            ),
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
