import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.ecoPoints,
    required this.pickupCount,
    required this.reminderEnabled,
    required this.lastPickupSlot,
    required this.lastPickupNote,
    required this.onReminderChanged,
    required this.onLogout,
  });

  final int ecoPoints;
  final int pickupCount;
  final bool reminderEnabled;
  final String lastPickupSlot;
  final String lastPickupNote;
  final ValueChanged<bool> onReminderChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profil', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.lime,
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryDark,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Muhammad Anis Maksum W.',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'S1 Teknik Informatika',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const Text(
                              'Universitas Duta Bangsa',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMetric(
                          label: 'Eco Pts',
                          value: '$ecoPoints',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileMetric(
                          label: 'Pickup',
                          value: '$pickupCount',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: reminderEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.notifications_active_rounded),
                    title: const Text('Reminder pickup'),
                    subtitle: Text(reminderEnabled ? 'Aktif' : 'Nonaktif'),
                    onChanged: onReminderChanged,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Jadwal terakhir'),
                    subtitle: Text(lastPickupSlot),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notes_rounded),
                    title: const Text('Catatan pickup'),
                    subtitle: Text(lastPickupNote),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.verified_user_rounded),
                    title: Text('Member Hijau'),
                    subtitle: Text('Level operasional bank sampah aktif.'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Logout'),
                    subtitle: const Text('Kembali ke halaman masuk.'),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
