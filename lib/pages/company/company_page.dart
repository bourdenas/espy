import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/material.dart';

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

class CompanyContent extends StatefulWidget {
  const CompanyContent(this.companyDocs, {super.key});

  final List<IgdbCompany> companyDocs;

  @override
  State<CompanyContent> createState() => _CompanyContentState();
}

class _CompanyContentState extends State<CompanyContent> {
  IgdbCompany? selectedCompany;

  @override
  Widget build(BuildContext context) {
    widget.companyDocs.sort((l, r) => -(l.developed.length + l.published.length)
        .compareTo(r.developed.length + r.published.length));

    final logoUrl = widget.companyDocs.first.logo != null
        ? '${Urls.imageProvider}/t_logo_med/${widget.companyDocs.first.logo!.imageId}.png'
        : null;

    final developed = <GameDigest>[];
    for (final digest in selectedCompany?.developed ??
        widget.companyDocs.map((e) => e.developed).expand((e) => e).toList()) {
      developed.add(digest);
    }
    final minDateDeveloped = developed.isEmpty
        ? DateTime(1970)
        : DateTime.fromMillisecondsSinceEpoch(developed
                .map((digest) => digest.releaseDate)
                .where((date) => date > 0)
                .reduce(min) *
            1000);
    final maxDateDeveloped = developed.isEmpty
        ? DateTime(1970)
        : DateTime.fromMillisecondsSinceEpoch(developed
                .map((digest) => digest.releaseDate)
                .where((date) => date > 0)
                .reduce(max) *
            1000);

    final published = <GameDigest>[];
    for (final digest in selectedCompany?.published ??
        widget.companyDocs.map((e) => e.published).expand((e) => e).toList()) {
      published.add(digest);
    }
    final minDatePublished = published.isEmpty
        ? DateTime(1970)
        : DateTime.fromMillisecondsSinceEpoch(published
                .map((digest) => digest.releaseDate)
                .where((date) => date > 0)
                .reduce(min) *
            1000);
    final maxDatePublished = published.isEmpty
        ? DateTime(1970)
        : DateTime.fromMillisecondsSinceEpoch(published
                .map((digest) => digest.releaseDate)
                .where((date) => date > 0)
                .reduce(max) *
            1000);

    final developedGames = groupDigestsBy(
      developed,
      byKey: (digest) => '${digest.releaseYear}',
      sortBy: (l, r) => l.releaseDate.compareTo(r.releaseDate),
    );
    final publishedGames = groupDigestsBy(
      published,
      byKey: (digest) => '${digest.releaseYear}',
      sortBy: (l, r) => l.releaseDate.compareTo(r.releaseDate),
    );

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
                        widget.companyDocs.first.name,
                        style: const TextStyle(fontSize: 24),
                      ),
                const SizedBox(width: 64),
                Flexible(
                    child: Text(selectedCompany?.description ??
                        widget.companyDocs.first.description ??
                        '')),
              ],
            ),
          ),
        ),
        if (widget.companyDocs.length > 1)
          Shelve(
            title: 'Subsidiaries',
            expansion: subsidiaries(),
            color: Colors.amber,
            expanded: true,
          ),
        Shelve(
          title: 'Drill-down',
          expansion: LibraryStats(
              developed.map((digest) => LibraryEntry.fromGameDigest(digest))),
          color: Colors.amber,
          expanded: false,
        ),
        if (developedGames.isNotEmpty)
          Shelve(
            title: 'Developed (${developed.length})',
            expansion: CalendarViewYear(
              startYear: maxDateDeveloped.year,
              endYear: minDateDeveloped.year,
              gamesByYear: developedGames,
            ),
            color: Colors.grey,
          ),
        if (publishedGames.isNotEmpty)
          Shelve(
            title: 'Published (${published.length})',
            expansion: CalendarViewYear(
              startYear: maxDatePublished.year,
              endYear: minDatePublished.year,
              gamesByYear: publishedGames,
            ),
            color: Colors.grey,
          ),
      ],
    );
  }

  Padding subsidiaries() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final company in widget.companyDocs) ...[
              const SizedBox(width: 64),
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedCompany =
                            selectedCompany != company ? company : null;
                      });
                    },
                    child: SizedBox(
                      height: 64,
                      child: company.logo != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  '${Urls.imageProvider}/t_logo_med/${company.logo?.imageId}.png',
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.question_mark),
                            ),
                    ),
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
      ),
    );
  }
}
