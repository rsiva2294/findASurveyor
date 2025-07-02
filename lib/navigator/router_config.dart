
import 'package:find_a_surveyor/screen/details_screen.dart';
import 'package:find_a_surveyor/screen/list_screen.dart';
import 'package:find_a_surveyor/screen/login_screen.dart';
import 'package:find_a_surveyor/screen/map_screen.dart';
import 'package:go_router/go_router.dart';

class AppRoutes{
  static const home = 'home';
  static const detail = 'detail';
  static const map = 'map';
}

final gRouterConfig = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: AppRoutes.home,
      builder: (context, state) => const CustomLoginScreen(),
      routes: [
        GoRoute(
          path: 'surveyor/:id',
          name: AppRoutes.detail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DetailsScreen(surveyorID: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/map',
      name: AppRoutes.map,
      builder: (context, state) => const MapScreen(),
    ),
  ],
);