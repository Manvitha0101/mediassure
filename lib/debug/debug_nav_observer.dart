import 'package:flutter/material.dart';

import 'debug_logger.dart';

class DebugNavObserver extends NavigatorObserver {
  void _log(String event, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    DebugLogger.log(
      hypothesisId: 'NAV',
      location: 'debug_nav_observer.dart',
      message: event,
      data: {
        'routeType': route?.runtimeType.toString(),
        'routeName': route?.settings.name,
        'prevRouteType': previousRoute?.runtimeType.toString(),
        'prevRouteName': previousRoute?.settings.name,
      },
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log('didPush', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _log('didPop', route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _log('didRemove', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _log('didReplace', newRoute, oldRoute);
  }
}

