import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/kosthunt_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  UserRole _role = UserRole.customer;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _RegisterBrand(),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text('Buat Akun Baru', style: KostText.heading),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <UserRole>[
                              UserRole.customer,
                              UserRole.owner,
                            ].map((UserRole role) {
                              return ChoiceChip(
                                label: Text(_roleLabel(role)),
                                selected: _role == role,
                                onSelected: (_) {
                                  setState(() {
                                    _role = role;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi password',
                              prefixIcon: Icon(Icons.lock_reset_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _role == UserRole.owner
                                ? 'Akun owner bisa langsung masuk dashboard owner setelah registrasi berhasil.'
                                : 'Akun customer akan langsung diarahkan ke halaman pencarian kost.',
                            style: KostText.muted,
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
                                : const Icon(Icons.person_add_alt_1_rounded),
                            label:
                                Text(_loading ? 'Memproses' : 'Daftar Sekarang'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.login,
                                    ),
                            child: const Text('Sudah punya akun? Masuk'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Akun admin dibuat terpisah melalui Supabase Dashboard.',
                            textAlign: TextAlign.center,
                            style: KostText.muted,
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
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _error = 'Konfirmasi password belum sama.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _error = 'Password minimal 6 karakter.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final AuthResult result = await AuthService.instance.signUp(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: password,
      role: _role,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    if (!result.success) {
      setState(() {
        _error = result.message ?? 'Registrasi gagal.';
      });
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      _homeRouteFor(result.user!.role),
      (Route<dynamic> route) => false,
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _homeRouteFor(UserRole role) {
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

class _RegisterBrand extends StatelessWidget {
  const _RegisterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: KostHuntTheme.teal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.app_registration_rounded,
            color: KostHuntTheme.surface,
          ),
        ),
        const SizedBox(height: 14),
        const Text('KostHunt', style: KostText.display),
        const SizedBox(height: 6),
        const Text(
          'Buat akun customer atau owner, lalu masuk ke area sesuai peranmu.',
          style: KostText.body,
        ),
      ],
    );
  }
}
