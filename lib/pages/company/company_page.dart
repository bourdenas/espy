import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/pages/library/library_page.dart';
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

class CompanyContent extends StatelessWidget {
  const CompanyContent(this.companyDocs, {super.key});

  final List<IgdbCompany> companyDocs;

  @override
  Widget build(BuildContext context) {
    return LibraryPage(
      entries: companyDocs
          .map((e) => e.developed)
          .expand((e) => e)
          .map((digest) => LibraryEntry.fromGameDigest(digest)),
    );
  }
}
