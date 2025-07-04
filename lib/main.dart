import 'package:find_a_surveyor/firebase_options.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/service/review_service.dart';
import 'package:find_a_surveyor/service/startup_service.dart';
import 'package:find_a_surveyor/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(
      MultiProvider(
        providers: [
          Provider<FirestoreService>(
            create: (context) => FirestoreService(),
          ),
          Provider<DatabaseService>(
            create: (context) => DatabaseService(),
          ),
          Provider<AuthenticationService>(
            create: (context) => AuthenticationService(FirebaseAuth.instance),
          ),
          ChangeNotifierProvider<AuthNotifier>(
            create: (context) => AuthNotifier(),
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(
      FirebaseAuth.instance,
      Provider.of<AuthNotifier>(context),
    );
    return MaterialApp.router(
      title: "Find A Surveyor",
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter.router,
    );
  }
}
