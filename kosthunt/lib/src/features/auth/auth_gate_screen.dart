import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/kosthunt_theme.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await AuthService.instance.restoreSession();
    if (!mounted) {
      return;
    }

    final AppUser? user = AuthService.instance.currentUser;
    Navigator.pushNamedAndRemoveUntil(
      context,
      _routeFor(user?.role),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: KostHuntTheme.paper,
      body: Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  String _routeFor(UserRole? role) {
    switch (role) {
      case UserRole.customer:
        return AppRoutes.customerHome;
      case UserRole.owner:
        return AppRoutes.ownerDashboard;
      case UserRole.admin:
        return AppRoutes.adminDashboard;
      case null:
        return AppRoutes.login;
    }
  }
}
