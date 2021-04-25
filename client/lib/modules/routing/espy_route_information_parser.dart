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

    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'game') {
      var gameId = uri.pathSegments[1];
      return EspyRoutePath.details(gameId);
    } else {
      return EspyRoutePath.library();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(EspyRoutePath path) {
    if (path.isLibraryPage) {
      return RouteInformation(location: '/');
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
