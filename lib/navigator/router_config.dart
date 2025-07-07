
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/screen/details_screen.dart';
import 'package:find_a_surveyor/screen/edit_profile_screen.dart';
import 'package:find_a_surveyor/screen/list_screen.dart';
import 'package:find_a_surveyor/screen/login_screen.dart';
import 'package:find_a_surveyor/screen/map_screen.dart';
import 'package:find_a_surveyor/screen/verification_screen.dart';
import 'package:find_a_surveyor/service/startup_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// A simple notifier to bridge the auth stream with GoRouter's Listenable.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

class AppRoutes {
  // Paths
  static const String homePath = '/';
  static const String loginPath = '/login';
  static const String mapPath = '/map';
  static const String surveyorPath = 'surveyor/:id';
  static const String editProfilePath = 'edit';
  static const String verifyPath = 'verify';

  // Names
  static const String homeName = 'home';
  static const String loginName = 'login';
  static const String mapName = 'map';
  static const String detailName = 'detail';
  static const String editProfileName = 'edit';
  static const String verifyName = 'verify';
}

class AppRouter {
  final AuthNotifier authNotifier;
  final FirebaseAuth auth;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  AppRouter(this.auth, this.authNotifier);

  late final GoRouter router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: AppRoutes.homePath,
    observers: [
      FirebaseAnalyticsObserver(analytics: analytics),
    ],
    routes: [
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) {
          analytics.logScreenView(screenName: AppRoutes.homeName);
          return const ListScreen();
        },
        routes: [
          GoRoute(
            path: AppRoutes.surveyorPath,
            name: AppRoutes.detailName,
            builder: (context, state) {
              analytics.logScreenView(screenName: AppRoutes.detailName);
              final surveyor = state.extra as Surveyor;
              return DetailsScreen(surveyor: surveyor);
            },
            routes: [
              GoRoute(
                path: AppRoutes.editProfilePath,
                name: AppRoutes.editProfileName,
                builder: (context, state) {
                  analytics.logScreenView(screenName: AppRoutes.editProfileName);
                  final surveyor = state.extra as Surveyor;
                  return EditProfileScreen(surveyor: surveyor);
                },
              ),
              GoRoute(
                path: AppRoutes.verifyPath,
                name: AppRoutes.verifyName,
                builder: (context, state) {
                  analytics.logScreenView(screenName: AppRoutes.verifyName);
                  final surveyor = state.extra as Surveyor;
                  return VerificationScreen(surveyor: surveyor);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) {
          analytics.logScreenView(screenName: AppRoutes.loginName);
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.mapPath,
        name: AppRoutes.mapName,
        builder: (context, state) {
          analytics.logScreenView(screenName: AppRoutes.mapName);
          return const MapScreen();
        },
      ),
    ],
    redirect: (context, state) {
      final bool loggedIn = auth.currentUser != null;
      final bool loggingIn = state.matchedLocation == AppRoutes.loginPath;

      if (loggedIn && loggingIn) {
        final startupService = context.read<StartupService>();
        startupService.performInitialSync();
        return AppRoutes.homePath;
      }

      if (!loggedIn) return loggingIn ? null : AppRoutes.loginPath;
      return null;
    },
  );
}