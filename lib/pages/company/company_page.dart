import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/pages/library/library_page.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompanyPage extends StatelessWidget {
  const CompanyPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: BackendApi.companyFetch(name),
      builder:
          (BuildContext context, AsyncSnapshot<List<IgdbCompany>> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? CompanyContent(snapshot.data!)
            : Container();
      },
    );
  }
}

class CompanyContent extends StatelessWidget {
  const CompanyContent(this.companyDocs, {super.key});

  final List<IgdbCompany> companyDocs;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();

    companyDocs.sort((l, r) => -(l.developed.length + l.published.length)
        .compareTo(r.developed.length + r.published.length));

    final logoUrl = companyDocs.first.logo != null
        ? '${Urls.imageProvider}/t_logo_med/${companyDocs.first.logo!.imageId}.png'
        : null;

    final developed = {
      for (final digest
          in companyDocs.map((e) => e.developed).expand((e) => e).toList())
        digest.id: LibraryEntry.fromGameDigest(digest)
    };
    final published = {
      for (final digest
          in companyDocs.map((e) => e.published).expand((e) => e).toList())
        if (!developed.containsKey(digest.id))
          digest.id: LibraryEntry.fromGameDigest(digest)
    };

    final developedModel = LibraryViewModel.custom(appConfig, developed.values);
    final publishedModel = LibraryViewModel.custom(appConfig, published.values);

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 64),
                logoUrl != null
                    ? CachedNetworkImage(imageUrl: logoUrl)
                    : Text(
                        companyDocs.first.name,
                        style: const TextStyle(fontSize: 24),
                      ),
                const SizedBox(width: 64),
                Flexible(child: Text(companyDocs.first.description ?? '')),
              ],
            ),
          ),
        ),
        if (companyDocs.length > 1)
          Shelve(
            title: 'Subsidiaries',
            expansion: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final company in companyDocs) ...[
                        const SizedBox(width: 64),
                        Column(
                          children: [
                            SizedBox(
                              height: 64,
                              child: company.logo != null
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          '${Urls.imageProvider}/t_logo_med/${company.logo?.imageId}.png',
                                    )
                                  : const Icon(Icons.question_mark),
                            ),
                            const Expanded(child: SizedBox.shrink()),
                            Text(
                              company.name,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ]
                    ],
                  ),
                )),
            color: Colors.amber,
            expanded: true,
          ),
        Shelve(
          title: 'Drill-down',
          expansion: LibraryStats(developedModel.entries),
          color: Colors.amber,
          expanded: false,
        ),
        TileShelve(
          title: 'Developed (${developed.length})',
          color: Colors.grey,
          entries: developedModel.entries,
        ),
        TileShelve(
          title: 'Published (${published.length})',
          color: Colors.grey,
          entries: publishedModel.entries,
        ),
      ],
    );
  }
}
