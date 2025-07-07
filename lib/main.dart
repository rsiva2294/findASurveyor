import 'dart:async';

import 'package:find_a_surveyor/firebase_options.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/service/review_service.dart';
import 'package:find_a_surveyor/service/startup_service.dart';
import 'package:find_a_surveyor/service/storage_service.dart';
import 'package:find_a_surveyor/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

void main() {

  // catches async errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Flutter framework errors
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Platform-level errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthNotifier>(
            create: (context) => AuthNotifier(),
          ),
          Provider<FirestoreService>(
            create: (context) => FirestoreService(),
          ),
          Provider<DatabaseService>(
            create: (context) => DatabaseService(),
          ),
          Provider<AuthenticationService>(
            create: (context) => AuthenticationService(FirebaseAuth.instance),
          ),
          Provider<StorageService>(
            create: (context) => StorageService(),
          ),
          ProxyProvider3<AuthenticationService, FirestoreService, DatabaseService, StartupService>(
            update: (context, auth, firestore, db, _) => StartupService(
              authService: auth,
              firestoreService: firestore,
              databaseService: db,
            ),
          ),
          Provider<ReviewService>(
            create: (context) => ReviewService(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    _appRouter = AppRouter(FirebaseAuth.instance, authNotifier);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Find A Surveyor",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.router,
      builder: (BuildContext context, Widget? routerWidget) {
        return UpgradeAlert(
          showIgnore: false,
          upgrader: Upgrader(
            durationUntilAlertAgain: const Duration(days: 1),
          ),
          navigatorKey: _appRouter.router.routerDelegate.navigatorKey,
          child: routerWidget,
        );
      },
    );
  }
}
