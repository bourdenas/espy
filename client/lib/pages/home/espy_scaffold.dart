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
                  heroTag: 'quickAdd',
                  child: Icon(Icons.add),
                  onPressed: () => MatchingDialog.show(
                    context,
                    onMatch: (storeEntry, gameEntry) {
                      context
                          .read<GameLibraryModel>()
                          .matchEntry(storeEntry, gameEntry);
                      context.pushNamed('details',
                          params: {'gid': '${gameEntry.id}'});
                    },
                  ),
                ),
                body: NotificationListener<ScrollNotification>(
                  onNotification: _scrollListener,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: widget.body,
                  ),
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
      leading: AppConfigModel.isMobile(context) && !context.canPop()
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onShowMenu,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            )
          : null,
      title: Text(
        'espy',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ),
      ),
      actions: [
        if (AppConfigModel.isMobile(context)) ...[
          IconButton(
            key: Key('layoutButton'),
            icon: Icon(_libraryViews[appConfig.libraryLayout.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.nextLibraryLayout(),
          ),
          IconButton(
            key: Key('cardInfoButton'),
            icon: Icon(_cardViews[appConfig.cardDecoration.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.nextCardDecoration(),
          ),
          IconButton(
            key: Key('groupByButton'),
            icon: Icon(_groupViews[appConfig.groupBy.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.nextGroupBy(),
          ),
          IconButton(
            key: Key('searchButton'),
            icon: Icon(Icons.search),
            splashRadius: 20.0,
            onPressed: () => context.pushNamed('search'),
          ),
        ] else ...[
          ToggleButtons(
            renderBorder: false,
            children: _libraryViews.map((e) => Icon(e.iconData)).toList(),
            isSelected: List.generate(_libraryViews.length,
                (i) => i == appConfig.libraryLayout.index),
            onPressed: (index) => appConfig.libraryLayoutIndex = index,
          ),
          SizedBox(width: 24),
          ToggleButtons(
            renderBorder: false,
            children: _cardViews.map((e) => Icon(e.iconData)).toList(),
            isSelected: List.generate(
                _cardViews.length, (i) => i == appConfig.cardDecoration.index),
            onPressed: (index) => appConfig.cardDecorationIndex = index,
          ),
          SizedBox(width: 24),
          ToggleButtons(
            renderBorder: false,
            children: _groupViews.map((e) => Icon(e.iconData)).toList(),
            isSelected: List.generate(
                _groupViews.length, (i) => i == appConfig.groupBy.index),
            onPressed: (index) => appConfig.groupByIndex = index,
          ),
          SizedBox(width: 8),
        ],
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

  List<_GroupView> _groupViews = const [
    _GroupView(GroupBy.NONE, Icons.block),
    _GroupView(GroupBy.YEAR, Icons.calendar_month),
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

class _GroupView {
  final GroupBy group;
  final IconData iconData;

  const _GroupView(this.group, this.iconData);
}
