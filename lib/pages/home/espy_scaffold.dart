import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/espy_rail.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatefulWidget {
  final void Function()? onShowMenu;
  final Widget body;
  final String path;

  const EspyScaffold(
      {Key? key, required this.body, required this.path, this.onShowMenu})
      : super(key: key);

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
      duration: const Duration(milliseconds: 0),
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
                  heroTag: 'searchButton',
                  child: const Icon(Icons.search),
                  onPressed: () => context.pushNamed('search'),
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
      title: const Text(
        'espy',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ),
      ),
      actions: [
        if (AppConfigModel.isMobile(context)) ...[
          IconButton(
            key: const Key('layoutButton'),
            icon: Icon(
                _libraryViews[appConfig.libraryLayout.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.libraryLayout.nextValue(),
          ),
          IconButton(
            key: const Key('cardInfoButton'),
            icon:
                Icon(_cardViews[appConfig.cardDecoration.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.cardDecoration.nextValue(),
          ),
          IconButton(
            key: const Key('groupByButton'),
            icon: Icon(_groupViews[appConfig.groupBy.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.groupBy.nextValue(),
          ),
          IconButton(
            key: const Key('searchButton'),
            icon: const Icon(Icons.search),
            splashRadius: 20.0,
            onPressed: () => context.pushNamed('search'),
          ),
        ] else ...[
          ToggleButtons(
            renderBorder: false,
            isSelected: List.generate(_libraryViews.length,
                (i) => i == appConfig.libraryLayout.value.index),
            onPressed: (index) => appConfig.libraryLayout.valueIndex = index,
            children: _libraryViews.map((e) => Icon(e.iconData)).toList(),
          ),
          const SizedBox(width: 24),
          ToggleButtons(
            renderBorder: false,
            isSelected: List.generate(_cardViews.length,
                (i) => i == appConfig.cardDecoration.value.index),
            onPressed: (index) => appConfig.cardDecoration.valueIndex = index,
            children: _cardViews.map((e) => Icon(e.iconData)).toList(),
          ),
          const SizedBox(width: 24),
          ToggleButtons(
            renderBorder: false,
            isSelected: List.generate(
                _groupViews.length, (i) => i == appConfig.groupBy.value.index),
            onPressed: (index) => appConfig.groupBy.valueIndex = index,
            children: _groupViews.map((e) => Icon(e.iconData)).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ],
      backgroundColor: _colorTween.value,
      elevation: 0.0,
    );
  }

  final List<_LibraryView> _libraryViews = const [
    _LibraryView(LibraryLayout.grid, Icons.grid_view),
    _LibraryView(LibraryLayout.list, Icons.view_list),
  ];

  final List<_CardsView> _cardViews = const [
    _CardsView(CardDecoration.empty, Icons.label_off),
    _CardsView(CardDecoration.info, Icons.info),
    _CardsView(CardDecoration.tags, Icons.collections_bookmark),
  ];

  final List<_GroupView> _groupViews = const [
    _GroupView(GroupBy.none, Icons.block),
    _GroupView(GroupBy.year, Icons.calendar_month),
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
