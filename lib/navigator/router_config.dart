
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/screen/details_screen.dart';
import 'package:find_a_surveyor/screen/edit_profile_screen.dart';
import 'package:find_a_surveyor/screen/list_screen.dart';
import 'package:find_a_surveyor/screen/login_screen.dart';
import 'package:find_a_surveyor/screen/map_screen.dart';
import 'package:find_a_surveyor/screen/verification_screen.dart';
import 'package:find_a_surveyor/service/startup_service.dart';
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
  static const home = '/';
  static const login = '/login';
  static const detail = 'detail';
  static const map = 'map';
  static const verify = 'verify';
  static const editProfile = 'edit';
}

class AppRouter {
  final AuthNotifier authNotifier;
  final FirebaseAuth auth;

  AppRouter(this.auth, this.authNotifier);

  late final GoRouter router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ListScreen(),
        routes: [
          GoRoute(
            path: 'surveyor/:id',
            name: AppRoutes.detail,
            builder: (context, state) {
              final surveyor = state.extra as Surveyor;
              return DetailsScreen(surveyor: surveyor);
            },
            routes: [
              GoRoute(
                name: AppRoutes.editProfile,
                path: 'edit',
                builder: (context, state) {
                  final surveyor = state.extra as Surveyor;
                  return EditProfileScreen(surveyor: surveyor);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/map',
        name: AppRoutes.map,
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/verify/:id',
        name: AppRoutes.verify,
        builder: (context, state) {
          final surveyor = state.extra as Surveyor;
          return VerificationScreen(surveyor: surveyor);
        },
      ),
    ],
    redirect: (context, state) {
      final bool loggedIn = auth.currentUser != null;
      final bool loggingIn = state.matchedLocation == AppRoutes.login;

      // --- NEW: Trigger sync after login ---
      if (loggedIn && state.matchedLocation == AppRoutes.login) {
        // This means the user has just successfully logged in.
        // We can safely trigger our one-time sync logic here.
        // We use `read` because we are outside the widget build method.
        final startupService = context.read<StartupService>();
        startupService.performInitialSync();
      }

      if (!loggedIn) return loggingIn ? null : AppRoutes.login;
      if (loggingIn) return AppRoutes.home;

      return null;
    },
  );
}