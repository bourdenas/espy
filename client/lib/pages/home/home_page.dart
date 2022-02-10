import 'package:espy/modules/dialogs/search/search_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/home/home_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomePage extends StatefulWidget {
  final Function _showMenu;

  HomePage(Function this._showMenu);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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
          appBar: _appBar(context),
          body: NotificationListener<ScrollNotification>(
            onNotification: _scrollListener,
            child: HomeContent(),
          ),
        );
      },
    );
  }

  AppBar _appBar(BuildContext context) {
    final isMobile = context.watch<AppConfigModel>().isMobile(context);

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
          onPressed: () => isMobile
              ? Navigator.pushNamed(context, '/search')
              : SearchDialog.show(context),
        )
      ],
      backgroundColor: _colorTween.value,
      elevation: 0.0,
    );
  }
}
