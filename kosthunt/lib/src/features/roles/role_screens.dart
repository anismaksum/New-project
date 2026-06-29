import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/booking_request.dart';
import '../../models/kost.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/kosthunt_store.dart';
import '../../theme/kosthunt_theme.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KostHuntStore store = KostHuntStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        final List<Kost> ownerKosts = store.ownerKosts;
        final List<BookingRequest> ownerBookings = store.ownerBookings;
        final int available = ownerKosts.where(store.isAvailable).length;
        final int pending = ownerBookings
            .where((BookingRequest booking) => booking.status == 'Pending')
            .length;
        return _RoleScaffold(
          title: 'Owner Dashboard',
          subtitle: 'Kelola listing, status kamar, dan booking masuk.',
          role: _Role.owner,
          children: <Widget>[
            _MetricGrid(
              metrics: <_MetricData>[
                _MetricData(
                  ownerKosts.length.toString().padLeft(2, '0'),
                  'Total Listing',
                ),
                _MetricData(available.toString().padLeft(2, '0'), 'Tayang'),
                _MetricData(pending.toString().padLeft(2, '0'), 'Pending'),
              ],
            ),
            _ActionPanel(
              title: 'Pekerjaan Hari Ini',
              subtitle:
                  'Konfirmasi booking, update ketersediaan kamar, dan rapikan listing premium.',
              primaryLabel: 'Lihat Booking',
              primaryIcon: Icons.event_available_rounded,
              onPrimary: () => Navigator.pushNamed(
                context,
                AppRoutes.ownerBookings,
              ),
              secondaryLabel: 'Tambah Kost',
              secondaryIcon: Icons.add_home_work_rounded,
              onSecondary: () => Navigator.pushNamed(
                context,
                AppRoutes.ownerListingForm,
              ),
            ),
            const _SectionTitle(title: 'Listing Milikmu'),
            if (ownerKosts.isEmpty)
              const _EmptyRoleCard(
                icon: Icons.home_work_outlined,
                title: 'Belum ada listing',
                subtitle:
                    'Publish kost pertamamu dari menu Tambah Kost supaya langsung muncul di dashboard owner.',
              )
            else
              ...ownerKosts.take(3).map((Kost kost) {
                return _ListingWorkCard(
                  kost: kost,
                  status: store.isAvailable(kost) ? 'Tayang' : 'Disembunyikan',
                  badge: store.isVerified(kost) ? 'Terverifikasi' : 'Review',
                  primaryActionLabel: store.isAvailable(kost)
                      ? 'Pause Listing'
                      : 'Tampilkan Lagi',
                  primaryActionIcon: store.isAvailable(kost)
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  onPrimaryAction: () async {
                    final bool wasVisible = store.isAvailable(kost);
                    await store.toggleAvailability(kost);
                    _showSnack(
                      context,
                      wasVisible
                          ? '${kost.name} disembunyikan dari marketplace.'
                          : '${kost.name} tayang lagi di marketplace.',
                    );
                  },
                  secondaryActionLabel: 'Edit',
                  secondaryActionIcon: Icons.edit_outlined,
                  onSecondaryAction: () {
                    _openOwnerListingForm(context, listing: kost);
                  },
                );
              }),
          ],
        );
      },
    );
  }
}

class OwnerListingsScreen extends StatelessWidget {
  const OwnerListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KostHuntStore store = KostHuntStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        final List<Kost> ownerKosts = store.ownerKosts;
        return _RoleScaffold(
          title: 'Listing Owner',
          subtitle: 'Atur harga, status, dan visibilitas kost.',
          role: _Role.owner,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openOwnerListingForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Listing Baru'),
              ),
            ),
            const SizedBox(height: 14),
            if (ownerKosts.isEmpty)
              const _EmptyRoleCard(
                icon: Icons.add_home_work_outlined,
                title: 'Belum ada listing owner',
                subtitle:
                    'Isi form kost baru lalu publish. Listing akan langsung tersimpan ke Supabase dan tampil di aplikasi.',
              )
            else
              ...ownerKosts.map((Kost kost) {
                return _ListingWorkCard(
                  kost: kost,
                  status: store.isAvailable(kost) ? 'Tayang' : 'Disembunyikan',
                  badge: store.isVerified(kost) ? 'Terverifikasi' : 'Review',
                  primaryActionLabel: store.isAvailable(kost)
                      ? 'Pause Listing'
                      : 'Tampilkan Lagi',
                  primaryActionIcon: store.isAvailable(kost)
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  onPrimaryAction: () async {
                    final bool wasVisible = store.isAvailable(kost);
                    await store.toggleAvailability(kost);
                    _showSnack(
                      context,
                      wasVisible
                          ? 'Listing disembunyikan dari marketplace.'
                          : 'Listing tayang lagi di marketplace.',
                    );
                  },
                  secondaryActionLabel: 'Edit Listing',
                  secondaryActionIcon: Icons.edit_outlined,
                  onSecondaryAction: () {
                    _openOwnerListingForm(context, listing: kost);
                  },
                );
              }),
          ],
        );
      },
    );
  }
}

class OwnerListingFormScreen extends StatefulWidget {
  const OwnerListingFormScreen({
    super.key,
    this.initialKost,
  });

  final Kost? initialKost;

  @override
  State<OwnerListingFormScreen> createState() => _OwnerListingFormScreenState();
}

class _OwnerListingFormScreenState extends State<OwnerListingFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
<<<<<<< HEAD
  String? _error;
  bool _saving = false;
=======
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _facilitiesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
>>>>>>> main
  String _category = 'Dekat Kampus';
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.initialKost != null;

  @override
  void initState() {
    super.initState();
    final Kost? initialKost = widget.initialKost;
    if (initialKost == null) {
      _distanceController.text = '1.0';
      _imageUrlController.text =
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80';
      _facilitiesController.text = 'WiFi, AC, Parkir';
      return;
    }
    _nameController.text = initialKost.name;
    _cityController.text = initialKost.city;
    _priceController.text = initialKost.price.toString();
    _distanceController.text = initialKost.distanceKm.toStringAsFixed(1);
    _addressController.text = initialKost.address;
    _imageUrlController.text = initialKost.imageUrl;
    _facilitiesController.text = initialKost.facilities.join(', ');
    _descriptionController.text = initialKost.description;
    _category = initialKost.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _distanceController.dispose();
    _addressController.dispose();
    _imageUrlController.dispose();
    _facilitiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = AuthService.instance.currentUser;
    return _RoleScaffold(
      title: _isEditing ? 'Edit Kost' : 'Tambah Kost',
      subtitle: _isEditing
          ? 'Perbarui detail listing owner dan sinkronkan perubahan ke Supabase.'
          : 'Listing owner dipublish langsung ke Supabase dan tersinkron ke aplikasi.',
      role: _Role.owner,
      children: <Widget>[
        _FormCard(
          children: <Widget>[
            Text(
              '${user?.name ?? 'Owner Kost'} - ${user?.phone ?? '-'}',
              style: KostText.label.copyWith(color: KostHuntTheme.teal),
            ),
            const SizedBox(height: 12),
            _TextInput(controller: _nameController, label: 'Nama kost'),
            _TextInput(controller: _cityController, label: 'Kota'),
            _TextInput(
              controller: _priceController,
              label: 'Harga per bulan',
              keyboardType: TextInputType.number,
            ),
            _TextInput(
              controller: _distanceController,
              label: 'Jarak ke titik utama (km)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _TextInput(controller: _addressController, label: 'Alamat'),
            _TextInput(
              controller: _imageUrlController,
              label: 'URL foto utama',
              keyboardType: TextInputType.url,
            ),
            _TextInput(
              controller: _facilitiesController,
              label: 'Fasilitas (pisahkan dengan koma)',
            ),
            _TextInput(
              controller: _descriptionController,
              label: 'Deskripsi singkat',
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>[
                'Dekat Kampus',
                'Premium',
                'Putri',
                'Kontrakan',
              ].map((String item) {
                return ChoiceChip(
                  label: Text(item),
                  selected: item == _category,
                  onSelected: (_) {
                    setState(() {
                      _category = item;
                    });
                  },
                );
              }).toList(),
            ),
<<<<<<< HEAD
=======
            const SizedBox(height: 12),
            const Text(
              'Contoh fasilitas: WiFi, AC, Parkir, Kamar Mandi Dalam',
              style: KostText.muted,
            ),
>>>>>>> main
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: KostText.label.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
<<<<<<< HEAD
            onPressed: _saving ? null : _saveDraft,
=======
            onPressed: _saving ? null : _submit,
>>>>>>> main
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
<<<<<<< HEAD
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan' : 'Simpan Draft'),
=======
                : Icon(
                    _isEditing ? Icons.save_outlined : Icons.publish_rounded,
                  ),
            label: Text(
              _saving
                  ? (_isEditing ? 'Menyimpan' : 'Mempublish')
                  : (_isEditing ? 'Simpan Perubahan' : 'Publish Kost'),
            ),
>>>>>>> main
          ),
        ),
      ],
    );
  }

<<<<<<< HEAD
  Future<void> _saveDraft() async {
    final String name = _nameController.text.trim();
    final String address = _addressController.text.trim();
    final int? price = int.tryParse(
      _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (name.isEmpty || address.isEmpty || price == null || price <= 0) {
      setState(() {
        _error = 'Nama, alamat, dan harga valid wajib diisi.';
=======
  Future<void> _submit() async {
    final int? price = int.tryParse(_priceController.text.trim());
    final double? distance = double.tryParse(_distanceController.text.trim());
    final List<String> facilities = _facilitiesController.text
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    if (_nameController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _imageUrlController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        price == null ||
        price <= 0 ||
        distance == null ||
        distance < 0 ||
        facilities.isEmpty) {
      setState(() {
        _error =
            'Lengkapi semua field. Harga harus lebih dari 0 dan fasilitas minimal satu.';
>>>>>>> main
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
<<<<<<< HEAD
    final Kost draft = await KostHuntStore.instance.createKostDraft(
      name: name,
      price: price,
      address: address,
      category: _category,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
    _showSnack(context, '${draft.name} disimpan sebagai draft listing.');
    Navigator.pushReplacementNamed(context, AppRoutes.ownerListings);
=======

    try {
      final Kost saved = _isEditing
          ? await KostHuntStore.instance.updateOwnerListing(
              listing: widget.initialKost!,
              name: _nameController.text.trim(),
              city: _cityController.text.trim(),
              address: _addressController.text.trim(),
              price: price,
              distanceKm: distance,
              imageUrl: _imageUrlController.text.trim(),
              facilities: facilities,
              category: _category,
              description: _descriptionController.text.trim(),
            )
          : await KostHuntStore.instance.publishOwnerListing(
              name: _nameController.text.trim(),
              city: _cityController.text.trim(),
              address: _addressController.text.trim(),
              price: price,
              distanceKm: distance,
              imageUrl: _imageUrlController.text.trim(),
              facilities: facilities,
              category: _category,
              description: _descriptionController.text.trim(),
            );
      if (!mounted) {
        return;
      }
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? '${saved.name} berhasil diperbarui.'
                : '${saved.name} berhasil dipublish ke marketplace.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _isEditing
            ? 'Update kost gagal. Cek koneksi internet dan policy Supabase owner.'
            : 'Publish kost gagal. Cek koneksi internet dan policy Supabase owner.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
>>>>>>> main
  }
}

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KostHuntStore store = KostHuntStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        final List<BookingRequest> ownerBookings = store.ownerBookings;
        return _RoleScaffold(
          title: 'Booking Masuk',
          subtitle: 'Konfirmasi pesanan dan kirim update WhatsApp.',
          role: _Role.owner,
          children: <Widget>[
            if (ownerBookings.isEmpty)
              const _EmptyRoleCard(
                icon: Icons.event_busy_rounded,
                title: 'Belum ada booking',
                subtitle: 'Permintaan baru dari customer akan muncul di sini.',
              )
            else
              ...ownerBookings.map((BookingRequest booking) {
                return _BookingWorkCard(
                  booking: booking,
                  onAccept: booking.status == 'Diterima'
                      ? null
                      : () async {
                          await store.updateBookingStatus(booking, 'Diterima');
                          if (context.mounted) {
                            _showSnack(
                                context, 'Konfirmasi dikirim ke WhatsApp.');
                          }
                        },
                  onReject: booking.status == 'Ditolak'
                      ? null
                      : () async {
                          await store.updateBookingStatus(booking, 'Ditolak');
                          if (context.mounted) {
                            _showSnack(
                                context, 'Penolakan dikirim ke WhatsApp.');
                          }
                        },
                );
              }),
          ],
        );
      },
    );
  }
}

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser? user = AuthService.instance.currentUser;
    final int listingCount = KostHuntStore.instance.ownerKosts.length;
    return _RoleScaffold(
      title: 'Profil Owner',
      subtitle: 'Akun pemilik, metode kontak, dan preferensi notifikasi.',
      role: _Role.owner,
      children: <Widget>[
        _ProfileSummary(
          name: user?.name ?? 'Owner Kost',
          role: 'Owner Aktif - $listingCount listing',
          phone: user?.phone ?? '-',
        ),
        _ActionPanel(
          title: 'WhatsApp Gateway',
          subtitle:
              'Booking masuk ke admin dan update status dikirim lewat backend WhatsApp.',
          primaryLabel: 'Booking Masuk',
          primaryIcon: Icons.chat_rounded,
          onPrimary: () =>
              Navigator.pushNamed(context, AppRoutes.ownerBookings),
          secondaryLabel: 'Ganti Akun',
          secondaryIcon: Icons.switch_account_rounded,
          onSecondary: () async {
            await _logoutToLogin(context);
          },
        ),
      ],
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KostHuntStore store = KostHuntStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        final int verified = store.kosts.where(store.isVerified).length;
        return _RoleScaffold(
          title: 'Admin Console',
          subtitle: 'Moderasi listing, owner, customer, dan kualitas platform.',
          role: _Role.admin,
          children: <Widget>[
            _MetricGrid(
              metrics: <_MetricData>[
                _MetricData(
                    store.kosts.length.toString().padLeft(2, '0'), 'Listing'),
                _MetricData(verified.toString().padLeft(2, '0'), 'Verified'),
                const _MetricData('03', 'Laporan'),
              ],
            ),
            _ActionPanel(
              title: 'Antrian Moderasi',
              subtitle:
                  'Listing baru perlu dicek foto, alamat, harga, fasilitas, dan kontak owner.',
              primaryLabel: 'Verifikasi Listing',
              primaryIcon: Icons.verified_outlined,
              onPrimary: () => Navigator.pushNamed(
                context,
                AppRoutes.adminListings,
              ),
              secondaryLabel: 'Lihat Laporan',
              secondaryIcon: Icons.report_outlined,
              onSecondary: () => Navigator.pushNamed(
                context,
                AppRoutes.adminReports,
              ),
            ),
          ],
        );
      },
    );
  }
}

class AdminListingsScreen extends StatelessWidget {
  const AdminListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KostHuntStore store = KostHuntStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        return _RoleScaffold(
          title: 'Moderasi Listing',
          subtitle: 'Aktifkan badge terverifikasi setelah listing valid.',
          role: _Role.admin,
          children: store.kosts.map((Kost kost) {
            final bool verified = store.isVerified(kost);
            return _ListingWorkCard(
              kost: kost,
              status: store.isAvailable(kost) ? 'Tayang' : 'Disembunyikan',
              badge: verified ? 'Terverifikasi' : 'Belum verified',
              primaryActionLabel: verified ? 'Cabut Verifikasi' : 'Verifikasi',
              primaryActionIcon:
                  verified ? Icons.verified_outlined : Icons.verified_rounded,
              onPrimaryAction: () async {
                await store.toggleVerified(kost);
                _showSnack(
                    context, 'Status verifikasi ${kost.name} diperbarui.');
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class AdminOwnersScreen extends StatelessWidget {
  const AdminOwnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleScaffold(
      title: 'Owner',
      subtitle: 'Kelola akun pemilik dan kualitas listing.',
      role: _Role.admin,
      children: <Widget>[
        _SimpleWorkCard(
          icon: Icons.badge_outlined,
          title: 'Ardi Properti',
          subtitle: '4 listing aktif - respons rata-rata 12 menit',
          badge: 'Terverifikasi',
        ),
        _SimpleWorkCard(
          icon: Icons.badge_outlined,
          title: 'Ratna Residence',
          subtitle: '3 listing aktif - perlu update foto utama',
          badge: 'Review',
        ),
      ],
    );
  }
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleScaffold(
      title: 'Users',
      subtitle: 'Pantau customer aktif dan aktivitas booking.',
      role: _Role.admin,
      children: <Widget>[
        _SimpleWorkCard(
          icon: Icons.person_outline_rounded,
          title: 'Nadia Putri',
          subtitle: '2 favorit - 1 booking diterima',
          badge: 'Customer',
        ),
        _SimpleWorkCard(
          icon: Icons.person_outline_rounded,
          title: 'Raka Pratama',
          subtitle: '5 favorit - 1 booking pending',
          badge: 'Customer',
        ),
      ],
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KostHuntStore store = KostHuntStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        final String firstListing =
            store.kosts.length > 2 ? store.kosts[2].name : 'Listing customer';
        final String secondListing =
            store.kosts.length > 3 ? store.kosts[3].name : 'Listing owner';
        return _RoleScaffold(
          title: 'Reports',
          subtitle: 'Tinjau laporan listing dan percakapan yang bermasalah.',
          role: _Role.admin,
          children: <Widget>[
            _SimpleWorkCard(
              icon: Icons.report_outlined,
              title: 'Foto kurang representatif',
              subtitle:
                  '$firstListing - butuh foto kamar mandi dan area parkir',
              badge: 'Prioritas',
            ),
            _SimpleWorkCard(
              icon: Icons.report_outlined,
              title: 'Harga tidak konsisten',
              subtitle: '$secondListing - harga chat berbeda dari listing',
              badge: 'Review',
            ),
          ],
        );
      },
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleScaffold(
      title: 'Settings',
      subtitle: 'Konfigurasi platform, kategori, dan template notifikasi.',
      role: _Role.admin,
      children: <Widget>[
        _SimpleWorkCard(
          icon: Icons.message_outlined,
          title: 'Template WhatsApp',
          subtitle: 'Booking baru, booking diterima, booking ditolak',
          badge: 'Aktif',
        ),
        _SimpleWorkCard(
          icon: Icons.category_outlined,
          title: 'Kategori Listing',
          subtitle: 'Premium, Putri, Kontrakan, Dekat Kampus',
          badge: '4 Kategori',
        ),
      ],
    );
  }
}

enum _Role { owner, admin }

class _RoleScaffold extends StatelessWidget {
  const _RoleScaffold({
    required this.title,
    required this.subtitle,
    required this.role,
    required this.children,
  });

  final String title;
  final String subtitle;
  final _Role role;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KostHuntTheme.paper,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _RoleHeader(
                  title: title,
                  subtitle: subtitle,
                  role: role,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _RoleNav(role: role)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      index == 0 ? 12 : 0,
                      20,
                      14,
                    ),
                    child: children[index],
                  );
                },
                childCount: children.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({
    required this.title,
    required this.subtitle,
    required this.role,
  });

  final String title;
  final String subtitle;
  final _Role role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: role == _Role.owner ? KostHuntTheme.ink : KostHuntTheme.teal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            role == _Role.owner
                ? Icons.dashboard_customize_rounded
                : Icons.admin_panel_settings_outlined,
            color: KostHuntTheme.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: KostText.title),
              const SizedBox(height: 3),
              Text(
                '${AuthService.instance.currentUser?.name ?? title} - $subtitle',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KostText.muted,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderButton(
          icon: Icons.logout_rounded,
          onTap: () async {
            await _logoutToLogin(context);
          },
        ),
      ],
    );
  }
}

class _RoleNav extends StatelessWidget {
  const _RoleNav({required this.role});

  final _Role role;

  @override
  Widget build(BuildContext context) {
    final List<_NavData> items = role == _Role.owner
        ? const <_NavData>[
            _NavData('Dashboard', AppRoutes.ownerDashboard),
            _NavData('Listing', AppRoutes.ownerListings),
            _NavData('Booking', AppRoutes.ownerBookings),
            _NavData('Profil', AppRoutes.ownerProfile),
          ]
        : const <_NavData>[
            _NavData('Dashboard', AppRoutes.adminDashboard),
            _NavData('Listing', AppRoutes.adminListings),
            _NavData('Owner', AppRoutes.adminOwners),
            _NavData('Users', AppRoutes.adminUsers),
            _NavData('Reports', AppRoutes.adminReports),
            _NavData('Settings', AppRoutes.adminSettings),
          ];
    final String current = ModalRoute.of(context)?.settings.name ?? '';
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          final _NavData item = items[index];
          final bool active = current == item.route;
          return ChoiceChip(
            label: Text(item.label),
            selected: active,
            onSelected: (_) {
              if (!active) {
                Navigator.pushReplacementNamed(context, item.route);
              }
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(width: 8);
        },
        itemCount: items.length,
      ),
    );
  }
}

class _NavData {
  const _NavData(this.label, this.route);

  final String label;
  final String route;
}

class _MetricData {
  const _MetricData(this.value, this.label);

  final String value;
  final String label;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: metrics.map((_MetricData metric) {
        final bool isLast = metric == metrics.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KostHuntTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KostHuntTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(metric.value, style: KostText.heading),
                  const SizedBox(height: 4),
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KostText.muted,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KostHuntTheme.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: KostText.heading.copyWith(color: KostHuntTheme.surface),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: KostText.body.copyWith(color: const Color(0xFFC9CEC5)),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon, size: 19),
                  label: Text(primaryLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KostHuntTheme.surface,
                    foregroundColor: KostHuntTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: Icon(secondaryIcon, size: 19),
                  label: Text(secondaryLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KostHuntTheme.surface,
                    side: const BorderSide(color: Color(0x66FFFFFF)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: KostText.heading);
  }
}

class _ListingWorkCard extends StatelessWidget {
  const _ListingWorkCard({
    required this.kost,
    required this.status,
    required this.badge,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  final Kost kost;
  final String status;
  final String badge;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                kost.imageUrl,
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Container(
                    width: 82,
                    height: 82,
                    color: KostHuntTheme.softSage,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: KostHuntTheme.sage,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _TinyPill(label: status),
                      _TinyPill(label: badge, soft: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kost.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KostText.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    kost.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KostText.muted,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_formatPrice(kost.price)}/bln • ${kost.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KostText.label.copyWith(color: KostHuntTheme.teal),
                  ),
                  const SizedBox(height: 10),
                  if (secondaryActionLabel != null &&
                      secondaryActionIcon != null &&
                      onSecondaryAction != null)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSecondaryAction,
                            icon: Icon(secondaryActionIcon, size: 18),
                            label: Text(secondaryActionLabel!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onPrimaryAction,
                            icon: Icon(primaryActionIcon, size: 18),
                            label: Text(primaryActionLabel),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onPrimaryAction,
                        icon: Icon(primaryActionIcon, size: 18),
                        label: Text(primaryActionLabel),
                      ),
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

class _BookingWorkCard extends StatelessWidget {
  const _BookingWorkCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  final BookingRequest booking;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _TinyPill(label: booking.status),
                _TinyPill(label: booking.notificationStatus, soft: true),
              ],
            ),
            const SizedBox(height: 10),
            Text(booking.kost.name, style: KostText.title),
            const SizedBox(height: 6),
            Text(
              '${booking.customerName} - ${booking.customerPhone}',
              style: KostText.muted,
            ),
            const SizedBox(height: 6),
            Text(booking.scheduleLabel, style: KostText.body),
            const SizedBox(height: 10),
            Text(
              booking.notificationMessage,
              style: KostText.muted,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept == null ? null : () => onAccept!(),
                    child: const Text('Terima'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject == null ? null : () => onReject!(),
                    child: const Text('Tolak'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleWorkCard extends StatelessWidget {
  const _SimpleWorkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: KostHuntTheme.softSage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: KostHuntTheme.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _TinyPill(label: badge, soft: true),
                  const SizedBox(height: 8),
                  Text(title, style: KostText.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: KostText.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.name,
    required this.role,
    required this.phone,
  });

  final String name;
  final String role;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: KostHuntTheme.ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: KostHuntTheme.surface,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: KostText.title),
                  const SizedBox(height: 5),
                  Text(role, style: KostText.muted),
                  const SizedBox(height: 5),
                  Text(phone, style: KostText.label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: KostHuntTheme.paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KostHuntTheme.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KostHuntTheme.line),
          ),
        ),
      ),
    );
  }
}

class _EmptyRoleCard extends StatelessWidget {
  const _EmptyRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Icon(icon, color: KostHuntTheme.muted, size: 34),
            const SizedBox(height: 10),
            Text(title, style: KostText.title),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: KostText.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, this.soft = false});

  final String label;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: soft ? KostHuntTheme.softSage : KostHuntTheme.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KostText.label.copyWith(
          color: soft ? KostHuntTheme.teal : KostHuntTheme.surface,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KostHuntTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: KostHuntTheme.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: KostHuntTheme.ink),
        ),
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _logoutToLogin(BuildContext context) async {
  await AuthService.instance.logout();
  if (!context.mounted) {
    return;
  }
  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.login,
    (Route<dynamic> route) => false,
  );
}

void _openOwnerListingForm(BuildContext context, {Kost? listing}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return OwnerListingFormScreen(initialKost: listing);
      },
    ),
  );
}

String _formatPrice(int value) {
  final String raw = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (var i = 0; i < raw.length; i += 1) {
    final int reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp$buffer';
}
