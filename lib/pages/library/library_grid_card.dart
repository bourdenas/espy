import 'package:espy/constants/stores.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/igdb_game.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/cards/cover.dart';
import 'package:espy/widgets/cards/footers.dart';
import 'package:espy/widgets/expandable_fab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LibraryGridCard extends StatefulWidget {
  const LibraryGridCard(
    this.libraryEntry, {
    super.key,
    required this.pushNavigation,
  });

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
    final inLibrary = context.watch<UserModel>().isNotSignedIn ||
        widget.libraryEntry.storeEntries.isNotEmpty ||
        context.read<LibraryIndexModel>().contains(widget.libraryEntry.id);
    final userModel = context.watch<UserModel>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => widget.pushNavigation
            ? context.pushNamed('details',
                pathParameters: {'gid': '${widget.libraryEntry.id}'})
            : context.replaceNamed('details',
                pathParameters: {'gid': '${widget.libraryEntry.id}'}),
        onSecondaryTap: () => userModel.isSignedIn
            ? EditEntryDialog.show(
                context,
                widget.libraryEntry,
                gameId: widget.libraryEntry.id,
              )
            : null,
        onLongPress: () => userModel.isSignedIn
            ? isMobile
                ? context.pushNamed('edit',
                    pathParameters: {'gid': '${widget.libraryEntry.id}'})
                : EditEntryDialog.show(
                    context,
                    widget.libraryEntry,
                    gameId: widget.libraryEntry.id,
                  )
            : null,
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
            child: coverImage(context, hover || !inLibrary, inLibrary),
          ),
        ),
      ),
    );
  }

  Widget coverImage(BuildContext context, bool showAddButton, bool inLibrary) {
    Widget? storeFAB;
    if (showAddButton) {
      List<Widget> storeButtons = [
        if (widget.libraryEntry.storeEntries.isEmpty &&
            !context.read<WishlistModel>().contains(widget.libraryEntry.id))
          FloatingActionButton(
            mini: true,
            backgroundColor: const Color(0x00FFFFFF),
            onPressed: () => context
                .read<WishlistModel>()
                .addToWishlist(widget.libraryEntry),
            tooltip: 'wishlist',
            child: const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 32,
            ),
          ),
        ...Stores.ids.map((id) => storeButton(id)),
      ].where((e) => e != null).map((e) => e!).toList();

      storeFAB = Positioned(
        right: 0,
        child: SizedBox(
          width: 200,
          height: 200,
          child: ExpandableFab(
            distance: 54,
            children: storeButtons,
          ),
        ),
      );
    }
    return CardCover(
      cover: widget.libraryEntry.cover,
      grayedOut: !inLibrary,
      overlays: storeFAB != null ? [storeFAB] : [],
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
      child: switch (appConfig.cardDecoration.value) {
        CardDecoration.info => InfoTileBar(
            widget.libraryEntry.name,
            year: widget.libraryEntry.digest.release.year,
            stores: widget.libraryEntry.storeEntries
                .map((e) => e.storefront)
                .toSet()
                .toList(),
          ),
        CardDecoration.pulse => PulseTileBar(widget.libraryEntry),
        CardDecoration.tags => TagsTileBar(widget.libraryEntry),
        _ => null,
      },
    );
  }
}
