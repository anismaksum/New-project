import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'profile_screen.dart';

const List<WasteCategory> wasteCategories = [
  WasteCategory(
    name: 'Plastik',
    assetPath: 'assets/images.jpg',
    pointsPerKg: 50,
    color: AppColors.primary,
    icon: Icons.local_drink_rounded,
    description: 'Botol, kemasan, dan plastik bersih siap daur ulang.',
    sortingTip: 'Bilas cepat, keringkan, lalu pipihkan agar hemat ruang.',
  ),
  WasteCategory(
    name: 'Logam',
    assetPath: 'assets/download(2).jpg',
    pointsPerKg: 120,
    color: AppColors.teal,
    icon: Icons.hardware_rounded,
    description: 'Kaleng, aluminium, dan logam rumah tangga non B3.',
    sortingTip:
        'Pisahkan dari sampah basah dan hindari material berkarat tajam.',
  ),
  WasteCategory(
    name: 'Kertas',
    assetPath: 'assets/download(3).jpg',
    pointsPerKg: 30,
    color: AppColors.amber,
    icon: Icons.article_rounded,
    description: 'Kardus, arsip, majalah, dan kertas kering.',
    sortingTip: 'Ikat rapi dan jauhkan dari minyak atau air.',
  ),
  WasteCategory(
    name: 'Kaca',
    assetPath: 'assets/wew.jpg',
    pointsPerKg: 80,
    color: AppColors.coral,
    icon: Icons.wine_bar_rounded,
    description: 'Botol kaca dan pecahan aman yang sudah dibungkus.',
    sortingTip: 'Bungkus pecahan kaca dan beri tanda agar aman diangkut.',
  ),
];

const List<String> _pickupSlots = [
  'Hari ini, 15.00',
  'Besok, 09.00',
  'Besok, 14.00',
  'Sabtu, 10.00',
];

class WasteCategory {
  const WasteCategory({
    required this.name,
    required this.assetPath,
    required this.pointsPerKg,
    required this.color,
    required this.icon,
    required this.description,
    required this.sortingTip,
  });

  final String name;
  final String assetPath;
  final int pointsPerKg;
  final Color color;
  final IconData icon;
  final String description;
  final String sortingTip;

  int pointsFor(double weightKg) => (pointsPerKg * weightKg).round();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _ecoPoints = 2450;
  int _pickupCount = 3;
  int _selectedCategoryIndex = 0;
  bool _pickupReminderEnabled = true;
  String _lastPickupSlot = 'Belum dijadwalkan';
  String _lastPickupNote = 'Tidak ada catatan';

  WasteCategory get _selectedCategory =>
      wasteCategories[_selectedCategoryIndex];

  void _selectCategory(int index) {
    setState(() => _selectedCategoryIndex = index);
  }

  void _logDeposit(int points) {
    setState(() => _ecoPoints += points);
  }

  void _schedulePickup(String slot, String note) {
    setState(() {
      _pickupCount += 1;
      _lastPickupSlot = slot;
      _lastPickupNote = note.trim().isEmpty ? 'Tidak ada catatan' : note.trim();
    });
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _showPickupDialog() async {
    final noteController = TextEditingController();
    var selectedSlot = _pickupSlots.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Jadwalkan Pickup'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedSlot,
                    decoration: const InputDecoration(
                      labelText: 'Waktu jemput',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: _pickupSlots
                        .map(
                          (slot) => DropdownMenuItem<String>(
                            value: slot,
                            child: Text(slot),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedSlot = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _schedulePickup(selectedSlot, noteController.text);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pickup dijadwalkan: $selectedSlot'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Jadwalkan'),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        ecoPoints: _ecoPoints,
        pickupCount: _pickupCount,
        selectedCategoryIndex: _selectedCategoryIndex,
        lastPickupSlot: _lastPickupSlot,
        selectedCategory: _selectedCategory,
        onCategorySelected: _selectCategory,
        onOpenTools: () => setState(() => _currentIndex = 1),
        onPickupPressed: _showPickupDialog,
      ),
      ToolsPage(
        key: const PageStorageKey<String>('tools-page'),
        selectedCategoryIndex: _selectedCategoryIndex,
        reminderEnabled: _pickupReminderEnabled,
        onCategoryChanged: _selectCategory,
        onDepositLogged: _logDeposit,
        onPickupScheduled: _schedulePickup,
        onReminderChanged: (value) {
          setState(() => _pickupReminderEnabled = value);
        },
      ),
      ProfileScreen(
        ecoPoints: _ecoPoints,
        pickupCount: _pickupCount,
        reminderEnabled: _pickupReminderEnabled,
        lastPickupSlot: _lastPickupSlot,
        lastPickupNote: _lastPickupNote,
        onReminderChanged: (value) {
          setState(() => _pickupReminderEnabled = value);
        },
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceSoft,
        elevation: 2,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.ecoPoints,
    required this.pickupCount,
    required this.selectedCategoryIndex,
    required this.lastPickupSlot,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onOpenTools,
    required this.onPickupPressed,
  });

  final int ecoPoints;
  final int pickupCount;
  final int selectedCategoryIndex;
  final String lastPickupSlot;
  final WasteCategory selectedCategory;
  final ValueChanged<int> onCategorySelected;
  final VoidCallback onOpenTools;
  final VoidCallback onPickupPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FAF1), AppColors.background],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                onNotificationPressed: () => _showNotification(context),
              ),
              const SizedBox(height: 18),
              _PointsHeroCard(ecoPoints: ecoPoints),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.local_shipping_rounded,
                      label: 'Pickup',
                      value: '$pickupCount kali',
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _MetricTile(
                      icon: Icons.energy_savings_leaf_rounded,
                      label: 'CO2 Hemat',
                      value: '18.6 kg',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ShortcutRail(
                onScanPressed: () => _showScanSheet(context),
                onStationPressed: () => _showStationDialog(context),
                onHistoryPressed: () => _showHistorySheet(context),
                onPickupPressed: onPickupPressed,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kategori Setoran',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpenTools,
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text('Hitung'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 4 : 2;
                  return GridView.builder(
                    itemCount: wasteCategories.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 4 ? 0.84 : 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final category = wasteCategories[index];
                      return WasteCategoryCard(
                        category: category,
                        selected: selectedCategoryIndex == index,
                        onTap: () {
                          onCategorySelected(index);
                          _showCategorySheet(context, category);
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              _PickupStatusCard(
                selectedCategory: selectedCategory,
                lastPickupSlot: lastPickupSlot,
                onPressed: onPickupPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak ada notifikasi baru saat ini.')),
    );
  }

  void _showScanSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ToolSheetHeader(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan Label',
                subtitle: 'Simulasi deteksi memilih plastik sebagai setoran.',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const _ConfidenceBar(label: 'Plastik PET', value: 0.86),
              const SizedBox(height: 8),
              const _ConfidenceBar(label: 'Kertas campur', value: 0.22),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onCategorySelected(0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori plastik dipilih.')),
                  );
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Gunakan Hasil Scan'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bank Sampah Terdekat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _StationTile(
                title: 'Bank Sampah Kota',
                subtitle: '1.2 km - buka sampai 16.00',
                icon: Icons.storefront_rounded,
              ),
              _StationTile(
                title: 'TPS3R Sumber Bersih',
                subtitle: '2.8 km - menerima kaca dan logam',
                icon: Icons.location_city_rounded,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ToolSheetHeader(
                icon: Icons.history_rounded,
                title: 'Riwayat Ringkas',
                subtitle: 'Aktivitas terbaru akun SmartWaste.',
                color: AppColors.amber,
              ),
              const SizedBox(height: 16),
              _HistoryTile(
                title: '$pickupCount pickup selesai',
                subtitle: 'Jadwal terakhir: $lastPickupSlot',
                icon: Icons.local_shipping_rounded,
              ),
              _HistoryTile(
                title: 'Kategori aktif: ${selectedCategory.name}',
                subtitle: '${selectedCategory.pointsPerKg} Eco Pts per kg',
                icon: selectedCategory.icon,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategorySheet(BuildContext context, WasteCategory category) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToolSheetHeader(
                icon: category.icon,
                title: category.name,
                subtitle: category.description,
                color: category.color,
              ),
              const SizedBox(height: 16),
              Text(
                '${category.pointsPerKg} Eco Pts / kg',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(category.sortingTip),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.done_rounded),
                label: const Text('Pilih Kategori'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ToolsPage extends StatefulWidget {
  const ToolsPage({
    super.key,
    required this.selectedCategoryIndex,
    required this.reminderEnabled,
    required this.onCategoryChanged,
    required this.onDepositLogged,
    required this.onPickupScheduled,
    required this.onReminderChanged,
  });

  final int selectedCategoryIndex;
  final bool reminderEnabled;
  final ValueChanged<int> onCategoryChanged;
  final ValueChanged<int> onDepositLogged;
  final void Function(String slot, String note) onPickupScheduled;
  final ValueChanged<bool> onReminderChanged;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final _noteController = TextEditingController();
  double _weightKg = 2.5;
  String _selectedSlot = _pickupSlots.first;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = wasteCategories[widget.selectedCategoryIndex];
    final estimatedPoints = category.pointsFor(_weightKg);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Tools', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Kalkulator, jadwal jemput, dan panduan sortasi.'),
            const SizedBox(height: 18),
            _CategorySelector(
              selectedIndex: widget.selectedCategoryIndex,
              onSelected: widget.onCategoryChanged,
            ),
            const SizedBox(height: 16),
            _ToolCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.calculate_rounded,
                    title: 'Kalkulator Eco Pts',
                    color: category.color,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          category.assetPath,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${category.pointsPerKg} Eco Pts per kg'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Kurangi berat',
                        onPressed: () {
                          setState(() {
                            _weightKg = (_weightKg - 0.5).clamp(0.5, 20);
                          });
                        },
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Slider(
                          value: _weightKg,
                          min: 0.5,
                          max: 20,
                          divisions: 39,
                          label: '${_weightKg.toStringAsFixed(1)} kg',
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() => _weightKg = value);
                          },
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Tambah berat',
                        onPressed: () {
                          setState(() {
                            _weightKg = (_weightKg + 0.5).clamp(0.5, 20);
                          });
                        },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      '${_weightKg.toStringAsFixed(1)} kg = $estimatedPoints Eco Pts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onDepositLogged(estimatedPoints);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Setoran ${category.name} menambah $estimatedPoints Eco Pts.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Catat Setoran'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ToolCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.local_shipping_rounded,
                    title: 'Jadwal Jemput',
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSlot,
                    decoration: const InputDecoration(
                      labelText: 'Waktu jemput',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: _pickupSlots
                        .map(
                          (slot) => DropdownMenuItem<String>(
                            value: slot,
                            child: Text(slot),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSlot = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan untuk kurir',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onPickupScheduled(
                        _selectedSlot,
                        _noteController.text,
                      );
                      _noteController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Kurir dijadwalkan: $_selectedSlot'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Panggil Kurir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ToolCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: widget.reminderEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder pickup'),
                    subtitle: const Text(
                      'Notifikasi ringan sebelum kurir datang.',
                    ),
                    secondary: const Icon(Icons.notifications_active_rounded),
                    onChanged: widget.onReminderChanged,
                  ),
                  const Divider(),
                  ...wasteCategories.map(
                    (category) => ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: Icon(category.icon, color: category.color),
                      title: Text(category.name),
                      childrenPadding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(category.sortingTip),
                        ),
                      ],
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

class WasteCategoryCard extends StatelessWidget {
  const WasteCategoryCard({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final WasteCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? category.color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(category.assetPath, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.ink.withValues(alpha: 0.58),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${category.pointsPerKg} Eco Pts / kg'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onNotificationPressed});

  final VoidCallback onNotificationPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, Anis', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Pantau setoran dan penjemputan hari ini.'),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Notifikasi',
          onPressed: onNotificationPressed,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _PointsHeroCard extends StatelessWidget {
  const _PointsHeroCard({required this.ecoPoints});

  final int ecoPoints;

  @override
  Widget build(BuildContext context) {
    final progress = (ecoPoints / 5000).clamp(0.0, 1.0);
    final remaining = (5000 - ecoPoints).clamp(0, 5000);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.lime),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SmartWaste Reward',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$ecoPoints Eco Pts',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining == 0
                ? 'Voucher hijau sudah bisa ditukar.'
                : '$remaining poin lagi menuju voucher hijau.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
        color: AppColors.surface,
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
                Text(label, overflow: TextOverflow.ellipsis),
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

class _ShortcutRail extends StatelessWidget {
  const _ShortcutRail({
    required this.onScanPressed,
    required this.onStationPressed,
    required this.onHistoryPressed,
    required this.onPickupPressed,
  });

  final VoidCallback onScanPressed;
  final VoidCallback onStationPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onPickupPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ShortcutButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan',
            color: AppColors.primary,
            onTap: onScanPressed,
          ),
          _ShortcutButton(
            icon: Icons.storefront_rounded,
            label: 'Bank',
            color: AppColors.teal,
            onTap: onStationPressed,
          ),
          _ShortcutButton(
            icon: Icons.history_rounded,
            label: 'Riwayat',
            color: AppColors.amber,
            onTap: onHistoryPressed,
          ),
          _ShortcutButton(
            icon: Icons.local_shipping_rounded,
            label: 'Jemput',
            color: AppColors.coral,
            onTap: onPickupPressed,
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: Icon(icon, color: color, size: 20),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PickupStatusCard extends StatelessWidget {
  const _PickupStatusCard({
    required this.selectedCategory,
    required this.lastPickupSlot,
    required this.onPressed,
  });

  final WasteCategory selectedCategory;
  final String lastPickupSlot;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(selectedCategory.icon, color: selectedCategory.color, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siap jemput ${selectedCategory.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Jadwal terakhir: $lastPickupSlot'),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Jadwalkan pickup',
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < wasteCategories.length; index++)
          ChoiceChip(
            selected: selectedIndex == index,
            avatar: Icon(wasteCategories[index].icon, size: 18),
            label: Text(wasteCategories[index].name),
            onSelected: (_) => onSelected(index),
            selectedColor: AppColors.surfaceSoft,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.child});

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _ToolSheetHeader extends StatelessWidget {
  const _ToolSheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value,
            backgroundColor: AppColors.surfaceSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
