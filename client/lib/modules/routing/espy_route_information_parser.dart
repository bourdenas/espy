import 'package:espy/modules/routing/espy_route_path.dart';
import 'package:flutter/material.dart';

class EspyRouteInformationParser extends RouteInformationParser<EspyRoutePath> {
  @override
  Future<EspyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    if (routeInformation.location == null) {
      return EspyRoutePath.home();
    }

    final uri = Uri.parse(routeInformation.location!);
    print('parseRouteInformation=$uri');

    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'game') {
      var gameId = uri.pathSegments[1];
      return EspyRoutePath.entry(gameId);
    } else {
      return EspyRoutePath.home();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(EspyRoutePath path) {
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isGameDetailsPage) {
      return RouteInformation(location: '/game/${path.entryId}');
    }
    return null;
  }
}
