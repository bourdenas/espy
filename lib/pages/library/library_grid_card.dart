import 'package:espy/constants/stores.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/igdb_game.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/expandable_fab.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LibraryGridCard extends StatefulWidget {
  const LibraryGridCard(
    this.libraryEntry, {
    Key? key,
    required this.pushNavigation,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final bool pushNavigation;

  @override
  State<LibraryGridCard> createState() => _LibraryGridCardState();
}

class _LibraryGridCardState extends State<LibraryGridCard>
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
    final inLibrary = widget.libraryEntry.storeEntries.isNotEmpty ||
        context.read<LibraryEntriesModel>().inLibrary(widget.libraryEntry.id);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => widget.pushNavigation
            ? context.pushNamed('details',
                pathParameters: {'gid': '${widget.libraryEntry.id}'})
            : context.replaceNamed('details',
                pathParameters: {'gid': '${widget.libraryEntry.id}'}),
        onSecondaryTap: () => EditEntryDialog.show(context, widget.libraryEntry,
            gameId: widget.libraryEntry.id),
        onLongPress: () => isMobile
            ? context.pushNamed('edit',
                pathParameters: {'gid': '${widget.libraryEntry.id}'})
            : EditEntryDialog.show(
                context,
                widget.libraryEntry,
                gameId: widget.libraryEntry.id,
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
      if (widget.libraryEntry.storeEntries.isEmpty &&
          !context.read<WishlistModel>().contains(widget.libraryEntry.id))
        FloatingActionButton(
          mini: true,
          backgroundColor: const Color(0x00FFFFFF),
          onPressed: () =>
              context.read<WishlistModel>().addToWishlist(widget.libraryEntry),
          tooltip: 'wishlist',
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 32,
          ),
        ),
      ...Stores.ids.map((id) => storeButton(id)),
    ].where((e) => e != null).map((e) => e!).toList();

    return Material(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.libraryEntry.cover != null &&
                  widget.libraryEntry.cover!.isNotEmpty
              ? Image.network(
                  '${Urls.imageProvider}/t_cover_big/${widget.libraryEntry.cover}.jpg')
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

  Widget? storeButton(String storeId) {
    return !widget.libraryEntry.storeEntries.any((e) => e.storefront == storeId)
        ? SizedBox(
            width: 32,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.transparent,
              onPressed: () {
                context.read<UserLibraryModel>().matchEntry(
                      StoreEntry(
                        id: '',
                        title: widget.libraryEntry.name,
                        storefront: storeId,
                      ),
                      GameEntry(
                        id: widget.libraryEntry.id,
                        name: widget.libraryEntry.name,
                        category: widget.libraryEntry.digest.category ?? '',
                        igdbGame: const IgdbGame(id: 0, name: ''),
                      ),
                    );
              },
              child: Stores.getIcon(storeId),
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
          ? TagsTileBar(widget.libraryEntry)
          : appConfig.cardDecoration.value == CardDecoration.info
              ? InfoTileBar(widget.libraryEntry)
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
