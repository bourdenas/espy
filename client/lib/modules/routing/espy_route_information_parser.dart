import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/models/filters_model.dart';
import 'package:espy/modules/routing/espy_route_path.dart';
import 'package:flutter/material.dart';

class EspyRouteInformationParser extends RouteInformationParser<EspyRoutePath> {
  @override
  Future<EspyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    if (routeInformation.location == null) {
      return EspyRoutePath.library();
    }

    final uri = Uri.parse(routeInformation.location!);
    print('parseRouteInformation=$uri');

    if (uri.pathSegments.length == 0) {
      return EspyRoutePath.library();
    } else if (uri.pathSegments.length == 1) {
      if (uri.pathSegments[0] == 'unmatched') {
        return EspyRoutePath.unmatched();
      } else if (uri.pathSegments[0] == 'tags') {
        return EspyRoutePath.tags();
      }
    } else if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] == 'game') {
        final gameId = uri.pathSegments[1];
        return EspyRoutePath.details(gameId);
      } else if (uri.pathSegments[0] == 'filter') {
        final encodedFilter = uri.pathSegments[1];
        return EspyRoutePath.filter(_parseFilter(encodedFilter));
      }
    }

    return EspyRoutePath.library();
  }

  @override
  RouteInformation? restoreRouteInformation(EspyRoutePath path) {
    if (path.isLibraryPage) {
      return RouteInformation(location: '/');
    } else if (path.isFilterPage) {
      final encodedFilter = _encodeFilter(path.filter!);
      return RouteInformation(location: '/filter/$encodedFilter');
    } else if (path.isDetailsPage) {
      return RouteInformation(location: '/game/${path.gameId}');
    } else if (path.isUnmatchedPage) {
      return RouteInformation(location: '/unmatched');
    } else if (path.isTagsPage) {
      return RouteInformation(location: '/tags');
    }
    return null;
  }
}

LibraryFilter _parseFilter(String encodedFilter) {
  var filter = LibraryFilter();

  final segments = encodedFilter.split('+');
  for (final segment in segments) {
    final term = segment.split('=');
    if (term.length != 2) {
      continue;
    }

    if (term[0] == 'cmp') {
      filter.companies
          .add(Annotation(id: int.tryParse(term[1]) ?? 0, name: ''));
    } else if (term[0] == 'col') {
      filter.collections
          .add(Annotation(id: int.tryParse(term[1]) ?? 0, name: ''));
    } else if (term[0] == 'tag') {
      filter.tags.add(term[1]);
    } else if (term[0] == 'str') {
      filter.stores.add(term[1]);
    }
  }

  return filter;
}

String _encodeFilter(LibraryFilter filter) {
  final companies = filter.companies.map((c) => 'cmp=${c.id}').join('+');
  final collections = filter.collections.map((c) => 'col=${c.id}').join('+');
  final tags = filter.tags.map((tag) => 'tag=$tag').join('+');
  final stores = filter.stores.map((store) => 'str=$store').join('+');

  return [companies, collections, tags, stores]
      .where((param) => param.isNotEmpty)
      .join('+');
}
