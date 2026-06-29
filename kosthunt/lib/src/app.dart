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
        AppRoutes.authGate: (BuildContext context) => const AuthGateScreen(),
        AppRoutes.login: (BuildContext context) => const LoginScreen(),
        AppRoutes.register: (BuildContext context) => const RegisterScreen(),
        AppRoutes.customerHome: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.customer,
              child: KostHuntHomeScreen(),
            ),
        AppRoutes.ownerDashboard: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.owner,
              child: OwnerDashboardScreen(),
            ),
        AppRoutes.ownerListings: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.owner,
              child: OwnerListingsScreen(),
            ),
        AppRoutes.ownerListingForm: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.owner,
              child: OwnerListingFormScreen(),
            ),
        AppRoutes.ownerBookings: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.owner,
              child: OwnerBookingsScreen(),
            ),
        AppRoutes.ownerProfile: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.owner,
              child: OwnerProfileScreen(),
            ),
        AppRoutes.adminDashboard: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.admin,
              child: AdminDashboardScreen(),
            ),
        AppRoutes.adminListings: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.admin,
              child: AdminListingsScreen(),
            ),
        AppRoutes.adminOwners: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.admin,
              child: AdminOwnersScreen(),
            ),
        AppRoutes.adminUsers: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.admin,
              child: AdminUsersScreen(),
            ),
        AppRoutes.adminReports: (BuildContext context) =>
            const _RoleGuard(
              role: UserRole.admin,
              child: AdminReportsScreen(),
            ),
        AppRoutes.adminSettings: (BuildContext context) =>
            const _RoleGuard(
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
      builder: (BuildContext context, Widget? _) {
        if (AuthService.instance.canAccess(role)) {
          return child;
        }
        return const LoginScreen();
      },
    );
  }
}
