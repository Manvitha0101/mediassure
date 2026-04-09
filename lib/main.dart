import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

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
}

class MediassureApp extends StatelessWidget {
const MediassureApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Mediassure',
debugShowCheckedModeBanner: false,
theme: AppTheme.light,
home: const SplashScreen(),
);
}
}
