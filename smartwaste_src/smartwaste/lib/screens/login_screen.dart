import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _rememberDevice = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoAccount() {
    setState(() {
      _usernameController.text = 'admin';
      _passwordController.text = '12345';
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username == 'admin' && password == '12345') {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username atau password belum sesuai. Coba akun demo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FBF3), Color(0xFFEAF3EA), Color(0xFFFFF6E5)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: constraints.maxHeight < 680 ? 12 : 32),
                        const _BrandLockup(),
                        const SizedBox(height: 28),
                        _LoginPanel(
                          formKey: _formKey,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          passwordVisible: _passwordVisible,
                          rememberDevice: _rememberDevice,
                          isLoading: _isLoading,
                          onTogglePassword: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                          onRememberChanged: (value) {
                            setState(() => _rememberDevice = value ?? false);
                          },
                          onDemoPressed: _fillDemoAccount,
                          onLoginPressed: _handleLogin,
                        ),
                        const SizedBox(height: 20),
                        const _ImpactStrip(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.recycling_rounded,
            color: AppColors.lime,
            size: 46,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'SMARTWASTE',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Setor, hitung poin, dan jemput sampah bernilai.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.passwordVisible,
    required this.rememberDevice,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onDemoPressed,
    required this.onLoginPressed,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool passwordVisible;
  final bool rememberDevice;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onDemoPressed;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Masuk akun', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Dashboard operasional bank sampah pintar.'),
            const SizedBox(height: 18),
            TextFormField(
              controller: usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Username wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: !passwordVisible,
              onFieldSubmitted: (_) => onLoginPressed(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: passwordVisible
                      ? 'Sembunyikan password'
                      : 'Tampilkan password',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Password wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: rememberDevice,
                  activeColor: AppColors.primary,
                  onChanged: onRememberChanged,
                ),
                const Expanded(child: Text('Ingat perangkat ini')),
                TextButton(
                  onPressed: onDemoPressed,
                  child: const Text('Isi Demo'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onLoginPressed,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(isLoading ? 'Memeriksa...' : 'Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactStrip extends StatelessWidget {
  const _ImpactStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ImpactItem(
            icon: Icons.emoji_events_rounded,
            label: 'Reward',
            value: 'Eco Pts',
            color: AppColors.amber,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ImpactItem(
            icon: Icons.local_shipping_rounded,
            label: 'Pickup',
            value: 'Terjadwal',
            color: AppColors.teal,
          ),
        ),
      ],
    );
  }
}

class _ImpactItem extends StatelessWidget {
  const _ImpactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
