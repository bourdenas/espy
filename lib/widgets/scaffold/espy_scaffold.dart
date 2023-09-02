import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/widgets/scaffold/espy_drawer.dart';
import 'package:espy/widgets/scaffold/espy_rail.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatelessWidget {
  const EspyScaffold({
    Key? key,
    required this.path,
    required this.body,
  }) : super(key: key);

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
                  onMatch: (storeEntry, gameEntry) {
                    context
                        .read<UserLibraryModel>()
                        .matchEntry(storeEntry, gameEntry);
                    context.pushNamed('details',
                        pathParameters: {'gid': '${gameEntry.id}'});
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
                  child: const Icon(Icons.search),
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
    final appConfig = context.read<AppConfigModel>();

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
            icon: Icon(
                _groupViews[appConfig.libraryGrouping.value.index].iconData),
            splashRadius: 20.0,
            onPressed: () => appConfig.libraryGrouping.nextValue(),
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
            isSelected: List.generate(_groupViews.length,
                (i) => i == appConfig.libraryGrouping.value.index),
            onPressed: (index) => appConfig.libraryGrouping.valueIndex = index,
            children: _groupViews.map((e) => Icon(e.iconData)).toList(),
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
    _CardsView(CardDecoration.empty, Icons.label_off),
    _CardsView(CardDecoration.info, Icons.info),
    _CardsView(CardDecoration.tags, Icons.collections_bookmark),
  ];

  final List<_GroupView> _groupViews = const [
    _GroupView(LibraryGrouping.none, Icons.block),
    _GroupView(LibraryGrouping.year, Icons.calendar_month),
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
  final LibraryGrouping grouping;
  final IconData iconData;

  const _GroupView(this.grouping, this.iconData);
}
