import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/kosthunt_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KostHuntTheme.paper,
      appBar: AppBar(
        backgroundColor: KostHuntTheme.paper,
        elevation: 0,
        foregroundColor: KostHuntTheme.ink,
        title: const Text('Edit Profil', style: KostText.title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            Center(child: _AvatarEditor(name: _nameController.text)),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _FieldLabel('Nama Lengkap'),
                  _ProfileTextField(
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                    hint: 'Masukkan nama lengkap',
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('Nomor WhatsApp'),
                  _ProfileTextField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: 'Contoh: 0812xxxxxxx',
                    keyboardType: TextInputType.phone,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor WhatsApp tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('Email'),
                  _ProfileTextField(
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    hint: 'nama@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('Alamat Domisili'),
                  _ProfileTextField(
                    controller: _addressController,
                    icon: Icons.place_outlined,
                    hint: 'Alamat saat ini (opsional)',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KostHuntTheme.surface,
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
    });
    // TODO: hubungkan ke AuthService/Supabase untuk menyimpan perubahan profil.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil diperbarui.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: KostHuntTheme.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: KostHuntTheme.surface,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: Material(
            color: KostHuntTheme.teal,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: KostHuntTheme.surface,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: KostText.label),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: KostText.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: KostText.muted,
        prefixIcon: Icon(icon, color: KostHuntTheme.muted, size: 20),
        filled: true,
        fillColor: KostHuntTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KostHuntTheme.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KostHuntTheme.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KostHuntTheme.teal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KostHuntTheme.amber),
        ),
      ),
    );
  }
}