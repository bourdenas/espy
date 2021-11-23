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
        return EspyRoutePath.filter(LibraryFilter.decode(encodedFilter));
      }
    }

    return EspyRoutePath.library();
  }

  @override
  RouteInformation? restoreRouteInformation(EspyRoutePath path) {
    if (path.isLibraryPage) {
      return RouteInformation(location: '/');
    } else if (path.isFilterPage) {
      final encodedFilter = path.filter!.encode();
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
