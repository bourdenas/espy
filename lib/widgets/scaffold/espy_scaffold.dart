import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/widgets/scaffold/espy_drawer.dart';
import 'package:espy/widgets/scaffold/espy_rail.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatelessWidget {
  const EspyScaffold({
    super.key,
    required this.path,
    required this.body,
  });

  final String path;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) => context.pushNamed('search')),
        HomeIntent: CallbackAction<HomeIntent>(
            onInvoke: (intent) => context.goNamed('home')),
        AddGameIntent: CallbackAction<AddGameIntent>(
            onInvoke: (intent) => MatchingDialog.show(
                  context,
                  onMatch: (storeEntry, gameDigest) {
                    context
                        .read<UserLibraryModel>()
                        .matchEntry(storeEntry, gameDigest.id);
                    context.pushNamed('details',
                        pathParameters: {'gid': '${gameDigest.id}'});
                  },
                )),
      },
      child: Focus(
        autofocus: !path.startsWith('/details'),
        child: Row(
          children: [
            if (AppConfigModel.isDesktop(context))
              EspyNavigationRail(false, path),
            Expanded(
              child: Scaffold(
                appBar: appBar(context),
                drawer:
                    AppConfigModel.isMobile(context) ? EspyDrawer(path) : null,
                floatingActionButton: FloatingActionButton(
                  heroTag: 'searchButton',
                  child: Icon(Icons.search),
                  onPressed: () => context.pushNamed('search'),
                ),
                body: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();

    return AppBar(
      elevation: 4,
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
            icon: Icon(
                _libraryViews[appConfig.libraryLayout.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.libraryLayout.nextValue(),
          ),
          IconButton(
            icon:
                Icon(_cardViews[appConfig.cardDecoration.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.cardDecoration.nextValue(),
          ),
          IconButton(
            icon: Icon(
                _orderingViews[appConfig.libraryOrdering.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.libraryOrdering.nextValue(),
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
            isSelected: List.generate(_orderingViews.length,
                (i) => i == appConfig.libraryOrdering.value.index),
            onPressed: (index) => appConfig.libraryOrdering.valueIndex = index,
            children: _orderingViews.map((e) => Icon(e.iconData)).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  final List<_LibraryView> _libraryViews = const [
    _LibraryView(LibraryLayout.grid, Icons.grid_view),
    _LibraryView(LibraryLayout.list, Icons.view_list),
  ];

  final List<_CardsView> _cardViews = const [
    _CardsView(CardDecoration.empty, Icons.block),
    _CardsView(CardDecoration.info, Icons.info),
    _CardsView(CardDecoration.info, Icons.monitor_heart),
    _CardsView(CardDecoration.tags, Icons.collections_bookmark),
  ];

  final List<_OrderingView> _orderingViews = const [
    _OrderingView(LibraryOrdering.release, Icons.calendar_month),
    _OrderingView(LibraryOrdering.prominence, Icons.trending_up),
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

class _OrderingView {
  final LibraryOrdering ordering;
  final IconData iconData;

  const _OrderingView(this.ordering, this.iconData);
}
