import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/pages/timeline/timeline_view.dart';
import 'package:espy/widgets/loading_spinner.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key, required this.name});

  final String name;

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late Future<List<IgdbCompany>> _companies;

  @override
  void initState() {
    super.initState();
    _companies = BackendApi.companyFetch(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _companies,
      builder:
          (BuildContext context, AsyncSnapshot<List<IgdbCompany>> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? CompanyContent(snapshot.data!)
            : LoadingSpinner(message: 'Retrieving company...');
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
  CompanyRole selectedRole = CompanyRole.developed;

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

    final published = <GameDigest>[];
    for (final digest in selectedCompany?.published ??
        widget.companyDocs.map((e) => e.published).expand((e) => e).toList()) {
      published.add(digest);
    }

    final shownGames =
        context.watch<FilterModel>().process(switch (selectedRole) {
              CompanyRole.developed => developed,
              CompanyRole.published => published,
            });

    final (startYear, endYear) = (
      [developed, published]
          .expand((e) => e)
          .map((digest) => digest.releaseYear)
          .reduce(max),
      [developed, published]
          .expand((e) => e)
          .map((digest) => digest.releaseYear)
          .where((year) => year > 1970)
          .reduce(min),
    );

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: appbar(context),
                body: content(context, logoUrl, shownGames, startYear, endYear),
              ),
            ),
            // Add some space for the side pane.
            SizedBox(
              width: context.watch<AppConfigModel>().showBottomSheet ? 500 : 40,
            ),
          ],
        ),
        FilterSidePane(
          switch (selectedRole) {
            CompanyRole.developed => developed,
            CompanyRole.published => published,
          }
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
        ),
      ],
    );
  }

  AppBar appbar(BuildContext context) {
    return AppBar(
      leading: Container(),
      title: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<CompanyRole>(
                segments: const <ButtonSegment<CompanyRole>>[
                  ButtonSegment<CompanyRole>(
                    value: CompanyRole.developed,
                    label: Text('Developed'),
                  ),
                  ButtonSegment<CompanyRole>(
                    value: CompanyRole.published,
                    label: Text('Published'),
                  ),
                ],
                selected: <CompanyRole>{selectedRole},
                onSelectionChanged: (Set<CompanyRole> newSelection) {
                  setState(() {
                    selectedRole = newSelection.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget content(
    BuildContext context,
    String? logoUrl,
    Iterable<GameDigest> shownGames,
    int startYear,
    int endYear,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 256),
                child: Container(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  padding: EdgeInsets.all(8),
                  child: logoUrl != null
                      ? CachedNetworkImage(imageUrl: logoUrl)
                      : Container(),
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                  child: Text(selectedCompany?.description ??
                      widget.companyDocs.first.description ??
                      '')),
            ],
          ),
        ),
        SizedBox(height: 16),
        if (widget.companyDocs.length > 1)
          Shelve(
            title: 'Subsidiaries',
            expansion: subsidiaries(),
            color: Colors.amber,
            expanded: false,
          ),
        Expanded(
          child: switch (context.watch<AppConfigModel>().libraryLayout.value) {
            LibraryLayout.grid => CalendarViewYear(
                shownGames,
                startYear: startYear,
                endYear: endYear,
              ),
            LibraryLayout.list => TimelineView(
                shownGames.map((digest) => LibraryEntry.fromGameDigest(digest)))
          },
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
                      child: Container(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        padding: EdgeInsets.all(4),
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

enum CompanyRole {
  developed,
  published,
}
