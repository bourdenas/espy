import 'package:espy/constants/stores.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
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
import 'package:espy/widgets/hover_animation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LibraryGridCard extends StatefulWidget {
  const LibraryGridCard(
    this.libraryEntry, {
    super.key,
    this.grayOutMissing = false,
    this.overlays = const [],
  });

  final LibraryEntry libraryEntry;
  final bool grayOutMissing;
  final List<Widget> overlays;

  @override
  State<LibraryGridCard> createState() => _LibraryGridCardState();
}

class _LibraryGridCardState extends State<LibraryGridCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final appConfig = context.watch<AppConfigModel>();
    final inLibrary = context.watch<UserModel>().isNotSignedIn ||
        widget.libraryEntry.storeEntries.isNotEmpty ||
        context.read<LibraryIndexModel>().contains(widget.libraryEntry.id);
    final grayedOut = widget.grayOutMissing && !inLibrary;
    final userModel = context.watch<UserModel>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => context.pushNamed('details',
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
        child: HoverAnimation(
          scale: 1.1,
          onHover: (val) => setState(() {
            hover = val;
          }),
          child: GridTile(
            footer: cardFooter(appConfig),
            child: coverImage(context, hover, grayedOut),
          ),
        ),
      ),
    );
  }

  Widget coverImage(BuildContext context, bool showAddButton, bool grayedOut) {
    Widget? storeFAB;
    if (showAddButton) {
      List<Widget> storeButtons = [
        if (widget.libraryEntry.storeEntries.isEmpty &&
            !context.watch<WishlistModel>().contains(widget.libraryEntry.id))
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
        ...Stores.ids.map((id) => storeButton(context, id)),
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
      grayedOut: grayedOut,
      overlays: [if (storeFAB != null) storeFAB, ...widget.overlays],
    );
  }

  Widget? storeButton(BuildContext context, String storeId) {
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
                      widget.libraryEntry.id,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
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
