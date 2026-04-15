import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'screens/app_theme.dart';
import 'auth_wrapper.dart';
import 'services/notification_service.dart';
import 'debug/debug_logger.dart';
import 'debug/debug_nav_observer.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

FlutterError.onError = (details) {
  DebugLogger.log(
    hypothesisId: 'ERR',
    location: 'main.dart',
    message: 'FlutterError',
    data: {
      'exception': details.exceptionAsString(),
      'library': details.library,
      'context': details.context?.toDescription(),
    },
  );
  FlutterError.presentError(details);
};

runZonedGuarded(() async {
// Firebase initialization
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);

// Initialize local notifications
await NotificationService().initialize();

// Lock orientation
SystemChrome.setPreferredOrientations([
DeviceOrientation.portraitUp,
]);

// Status bar styling
SystemChrome.setSystemUIOverlayStyle(
const SystemUiOverlayStyle(
statusBarColor: Colors.transparent,
statusBarIconBrightness: Brightness.dark,
),
);

runApp(const MediassureApp());
}, (error, stack) {
  DebugLogger.log(
    hypothesisId: 'ERR',
    location: 'main.dart',
    message: 'ZoneError',
    data: {
      'error': error.toString(),
      'stack': stack.toString(),
    },
  );
});
}

class MediassureApp extends StatelessWidget {
const MediassureApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Mediassure',
debugShowCheckedModeBanner: false,
theme: AppTheme.light,
home: const AuthWrapper(), // ← Single source of truth for routing
navigatorObservers: [DebugNavObserver()],
);
}
}
