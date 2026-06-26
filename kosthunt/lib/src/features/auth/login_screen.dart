import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/kosthunt_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KostHuntTheme.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _LoginBrand(),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text('Masuk Akun', style: KostText.heading),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                          ),
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: KostText.label.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(_loading ? 'Memproses' : 'Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final AuthResult result = await AuthService.instance.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
    if (!result.success) {
      setState(() {
        _error = result.message ?? 'Login gagal.';
      });
      return;
    }
    _openRoleHome(result.user!);
  }

  void _openRoleHome(AppUser user) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      _routeFor(user.role),
      (Route<dynamic> route) => false,
    );
  }

  String _routeFor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return AppRoutes.customerHome;
      case UserRole.owner:
        return AppRoutes.ownerDashboard;
      case UserRole.admin:
        return AppRoutes.adminDashboard;
    }
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: KostHuntTheme.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: KostHuntTheme.surface,
          ),
        ),
        const SizedBox(height: 14),
        const Text('KostHunt', style: KostText.display),
        const SizedBox(height: 6),
        const Text(
          'Sign in memakai akun demo atau Supabase untuk membuka akses sesuai role.',
          style: KostText.body,
        ),
        const SizedBox(height: 10),
        const Text(
          'Demo: customer@kosthunt.test, owner@kosthunt.test, admin@kosthunt.test / KostHunt212',
          style: KostText.muted,
        ),
      ],
    );
  }
}
