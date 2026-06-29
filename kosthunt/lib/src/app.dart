import 'package:flutter/material.dart';

import 'features/auth/auth_gate_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/roles/role_screens.dart';
import 'models/app_user.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'theme/kosthunt_theme.dart';

class KostHuntApp extends StatelessWidget {
  const KostHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KostHunt',
      debugShowCheckedModeBanner: false,
      theme: KostHuntTheme.light,
      initialRoute: AppRoutes.authGate,
      routes: <String, WidgetBuilder>{
        AppRoutes.authGate: (context) => const AuthGateScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),

        AppRoutes.customerHome: (context) => const _RoleGuard(
              role: UserRole.customer,
              child: KostHuntHomeScreen(),
            ),

        AppRoutes.ownerDashboard: (context) => const _RoleGuard(
              role: UserRole.owner,
              child: OwnerDashboardScreen(),
            ),

        AppRoutes.ownerListings: (context) => const _RoleGuard(
              role: UserRole.owner,
              child: OwnerListingsScreen(),
            ),

        AppRoutes.ownerListingForm: (context) => const _RoleGuard(
              role: UserRole.owner,
              child: OwnerListingFormScreen(),
            ),

        AppRoutes.ownerBookings: (context) => const _RoleGuard(
              role: UserRole.owner,
              child: OwnerBookingsScreen(),
            ),

        AppRoutes.ownerProfile: (context) => const _RoleGuard(
              role: UserRole.owner,
              child: OwnerProfileScreen(),
            ),

        AppRoutes.adminDashboard: (context) => const _RoleGuard(
              role: UserRole.admin,
              child: AdminDashboardScreen(),
            ),

        AppRoutes.adminListings: (context) => const _RoleGuard(
              role: UserRole.admin,
              child: AdminListingsScreen(),
            ),

        AppRoutes.adminOwners: (context) => const _RoleGuard(
              role: UserRole.admin,
              child: AdminOwnersScreen(),
            ),

        AppRoutes.adminUsers: (context) => const _RoleGuard(
              role: UserRole.admin,
              child: AdminUsersScreen(),
            ),

        AppRoutes.adminReports: (context) => const _RoleGuard(
              role: UserRole.admin,
              child: AdminReportsScreen(),
            ),

        AppRoutes.adminSettings: (context) => const _RoleGuard(
              role: UserRole.admin,
              child: AdminSettingsScreen(),
            ),
      },
    );
  }
}

class _RoleGuard extends StatelessWidget {
  const _RoleGuard({
    required this.role,
    required this.child,
  });

  final UserRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.canAccess(role)) {
          return child;
        }
        return const LoginScreen();
      },
    );
  }
}