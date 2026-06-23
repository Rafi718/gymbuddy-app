import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/booking/find_trainers_screen.dart';
import '../screens/booking/my_bookings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_trainers_screen.dart';
import '../screens/admin/admin_articles_screen.dart';
import '../screens/admin/admin_bookings_screen.dart';
import '../screens/admin/admin_promo_screen.dart';
import '../screens/admin/admin_faq_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/trainer/trainer_dashboard_screen.dart';
import '../screens/trainer/trainer_sessions_screen.dart';
import '../screens/trainer/trainer_clients_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/session/session_detail_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/pricing/pricing_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(WidgetRef ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isInitialized = auth.isInitialized;
      final isLoggedIn = auth.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isTrainerRoute = state.matchedLocation.startsWith('/trainer');

      // TUNGGU sampai _checkToken() selesai sebelum redirect
      if (!isInitialized) return null;

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      if (isAdminRoute && !auth.isAdmin) return '/';
      if (isTrainerRoute && !auth.isTrainer && !auth.isAdmin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/find-trainers', builder: (_, _) => const FindTrainersScreen()),
      GoRoute(path: '/my-bookings', builder: (_, _) => const MyBookingsScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/edit-profile', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/pricing', builder: (_, _) => const PricingScreen()),
      GoRoute(
        path: '/session/:id',
        builder: (_, state) => SessionDetailScreen(
          sessionId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/payment/:bookingId',
        builder: (_, state) {
          final bp = state.pathParameters;
          return PaymentScreen(
            bookingId: int.parse(bp['bookingId']!),
            sessionTitle: state.uri.queryParameters['title'] ?? 'Sesi',
            amount: double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0,
          );
        },
      ),

      // Admin routes
      GoRoute(path: '/admin', builder: (_, _) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users', builder: (_, _) => const AdminUsersScreen()),
      GoRoute(path: '/admin/trainers', builder: (_, _) => const AdminTrainersScreen()),
      GoRoute(path: '/admin/articles', builder: (_, _) => const AdminArticlesScreen()),
      GoRoute(path: '/admin/bookings', builder: (_, _) => const AdminBookingsScreen()),
      GoRoute(path: '/admin/promo', builder: (_, _) => const AdminPromoScreen()),
      GoRoute(path: '/admin/faq', builder: (_, _) => const AdminFaqScreen()),

      // Trainer routes
      GoRoute(path: '/trainer', builder: (_, _) => const TrainerDashboardScreen()),
      GoRoute(path: '/trainer/sessions', builder: (_, _) => const TrainerSessionsScreen()),
      GoRoute(path: '/trainer/clients', builder: (_, _) => const TrainerClientsScreen()),
    ],
  );
}
