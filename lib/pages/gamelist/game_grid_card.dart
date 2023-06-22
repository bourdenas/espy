import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/expandable_fab.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameGridCard extends StatefulWidget {
  const GameGridCard({
    Key? key,
    required this.entry,
    required this.pushNavigation,
  }) : super(key: key);

  final LibraryEntry entry;
  final bool pushNavigation;

  @override
  State<GameGridCard> createState() => _GameGridCardState();
}

class _GameGridCardState extends State<GameGridCard>
    with SingleTickerProviderStateMixin {
  bool hover = false;
  late AnimationController _controller;
  late Animation _animation;
  late Animation padding;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(
        parent: _controller, curve: Curves.ease, reverseCurve: Curves.easeIn));
    padding = Tween(begin: 0.0, end: -12.5).animate(CurvedAnimation(
        parent: _controller, curve: Curves.ease, reverseCurve: Curves.easeIn));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final appConfig = context.watch<AppConfigModel>();
    final inLibrary = widget.entry.storeEntries.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => widget.pushNavigation
            ? context.pushNamed('details',
                pathParameters: {'gid': '${widget.entry.id}'})
            : context.replaceNamed('details',
                pathParameters: {'gid': '${widget.entry.id}'}),
        onSecondaryTap: () => EditEntryDialog.show(context, widget.entry,
            gameId: widget.entry.id),
        onLongPress: () => isMobile
            ? context.pushNamed('edit',
                pathParameters: {'gid': '${widget.entry.id}'})
            : EditEntryDialog.show(
                context,
                widget.entry,
                gameId: widget.entry.id,
              ),
        onHover: (val) => setState(() {
          hover = val;
          if (hover) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        }),
        child: Container(
          transform: Matrix4(_animation.value, 0, 0, 0, 0, _animation.value, 0,
              0, 0, 0, 1, 0, padding.value, padding.value, 0, 1),
          child: GridTile(
            footer: cardFooter(appConfig),
            child: coverImage(context, hover || !inLibrary),
          ),
        ),
      ),
    );
  }

  Widget coverImage(BuildContext context, bool showAddButton) {
    List<Widget> storeButtons = [
      if (!context.read<WishlistModel>().contains(widget.entry.id))
        FloatingActionButton(
          mini: true,
          backgroundColor: const Color(0x00FFFFFF),
          onPressed: () =>
              context.read<WishlistModel>().addToWishlist(widget.entry),
          tooltip: 'wishlist',
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 32,
          ),
        ),
      storeButton('gog'),
      storeButton('steam'),
      storeButton('egs'),
      storeButton('battlenet'),
      storeButton('ea'),
      storeButton('uplay'),
      storeButton('disc'),
    ].where((e) => e != null).map((e) => e!).toList();

    return Material(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.entry.cover != null && widget.entry.cover!.isNotEmpty
              ? Image.network(
                  '${Urls.imageProvider}/t_cover_big/${widget.entry.cover}.jpg')
              : Image.asset('assets/images/placeholder.png'),
          if (showAddButton)
            Positioned(
              right: 0,
              child: SizedBox(
                width: 200,
                height: 200,
                child: ExpandableFab(
                  distance: 54,
                  children: storeButtons,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? storeButton(String store) {
    return !widget.entry.storeEntries.any((e) => e.storefront == store)
        ? SizedBox(
            width: 32,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => print(store),
              child: Image.asset('assets/images/$store-128.png'),
            ),
          )
        : null;
  }

  Widget cardFooter(AppConfigModel appConfig) {
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: appConfig.cardDecoration.value == CardDecoration.tags
          ? TagsTileBar(widget.entry)
          : appConfig.cardDecoration.value == CardDecoration.info
              ? InfoTileBar(widget.entry)
              : null,
    );
  }
}

class InfoTileBar extends StatelessWidget {
  const InfoTileBar(this.entry, {Key? key}) : super(key: key);

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: GameTitleText(entry.name),
      subtitle: Row(children: [
        if (entry.releaseDate > 0)
          GameTitleText(
              '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000).year}'),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
        if (entry.storeEntries.isNotEmpty)
          GameTitleText(
              entry.storeEntries.map((e) => e.storefront).toSet().join(', ')),
      ]),
    );
  }
}

class TagsTileBar extends StatelessWidget {
  const TagsTileBar(this.libraryEntry, {Key? key}) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: GameCardChips(
        libraryEntry: libraryEntry,
      ),
    );
  }
}

class GameTitleText extends StatelessWidget {
  const GameTitleText(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(text),
    );
  }
}
