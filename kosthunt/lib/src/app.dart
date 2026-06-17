import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/roles/role_screens.dart';
import 'routes/app_routes.dart';
import 'theme/kosthunt_theme.dart';

class KostHuntApp extends StatelessWidget {
  const KostHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KostHunt',
      debugShowCheckedModeBanner: false,
      theme: KostHuntTheme.light,
      initialRoute: AppRoutes.customerHome,
      routes: <String, WidgetBuilder>{
        AppRoutes.customerHome: (BuildContext context) =>
            const KostHuntHomeScreen(),
        AppRoutes.ownerDashboard: (BuildContext context) =>
            const OwnerDashboardScreen(),
        AppRoutes.ownerListings: (BuildContext context) =>
            const OwnerListingsScreen(),
        AppRoutes.ownerListingForm: (BuildContext context) =>
            const OwnerListingFormScreen(),
        AppRoutes.ownerBookings: (BuildContext context) =>
            const OwnerBookingsScreen(),
        AppRoutes.ownerProfile: (BuildContext context) =>
            const OwnerProfileScreen(),
        AppRoutes.adminDashboard: (BuildContext context) =>
            const AdminDashboardScreen(),
        AppRoutes.adminListings: (BuildContext context) =>
            const AdminListingsScreen(),
        AppRoutes.adminOwners: (BuildContext context) =>
            const AdminOwnersScreen(),
        AppRoutes.adminUsers: (BuildContext context) =>
            const AdminUsersScreen(),
        AppRoutes.adminReports: (BuildContext context) =>
            const AdminReportsScreen(),
        AppRoutes.adminSettings: (BuildContext context) =>
            const AdminSettingsScreen(),
      },
    );
  }
}
