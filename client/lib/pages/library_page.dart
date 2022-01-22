import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/widgets/library_headline.dart';
import 'package:espy/widgets/library_slate.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class LibraryPage extends StatefulWidget {
  final Function _showMenu;

  LibraryPage(Function this._showMenu);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
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
    return AnimatedBuilder(
      animation: _colorAnimationController,
      builder: (context, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _appBar(),
          body: NotificationListener<ScrollNotification>(
            onNotification: _scrollListener,
            child: LibraryBody(),
          ),
        );
      },
    );
  }

  AppBar _appBar() {
    return AppBar(
      toolbarOpacity: 0.6,
      leading: IconButton(
        key: Key('drawerButton'),
        icon: Icon(Icons.menu),
        splashRadius: 20.0,
        onPressed: () {
          widget._showMenu();
        },
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
          key: Key('searchButton'),
          icon: Icon(Icons.search),
          splashRadius: 20.0,
          onPressed: () => Navigator.pushNamed(context, '/search'),
        )
      ],
      backgroundColor: _colorTween.value,
      elevation: 0.0,
    );
  }
}

class LibraryBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);

    return Scaffold(
      body: SingleChildScrollView(
        key: Key('libraryScrollView'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LibraryHeadline(),
            LibrarySlate(
              text: 'GOG',
              onExpand: () => Navigator.pushNamed(context, 'gog'),
            ),
            LibrarySlate(
              text: 'Steam',
              onExpand: () => Navigator.pushNamed(context, 'steam'),
            ),
            LibrarySlate(
              text: 'Epic',
              onExpand: () => Navigator.pushNamed(context, 'epic'),
            ),
            SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
