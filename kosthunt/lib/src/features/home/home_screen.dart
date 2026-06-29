import 'package:flutter/material.dart';

import '../../models/booking_request.dart';
import '../../models/kost.dart';
import '../../models/support_message.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/kosthunt_store.dart';
import '../../theme/kosthunt_theme.dart';

class KostHuntHomeScreen extends StatefulWidget {
  const KostHuntHomeScreen({super.key});

  @override
  State<KostHuntHomeScreen> createState() => _KostHuntHomeScreenState();
}

class _KostHuntHomeScreenState extends State<KostHuntHomeScreen> {
  late final KostHuntStore _store;
  int _selectedIndex = 0;
  int _heroIndex = 0;
  String _filter = 'Semua';
  String _query = '';

  static const List<String> _filters = <String>[
    'Semua',
    'Tersedia',
    'Terverifikasi',
    'WiFi',
    'AC',
    'Parkir',
    'Premium',
    'Dekat Kampus',
  ];

  List<Kost> get _visibleKosts {
    return _store.marketplaceKosts.where((Kost kost) {
      final String search = _query.trim().toLowerCase();
      final bool matchesQuery = search.isEmpty ||
          kost.name.toLowerCase().contains(search) ||
          kost.city.toLowerCase().contains(search) ||
          kost.address.toLowerCase().contains(search) ||
          kost.category.toLowerCase().contains(search) ||
          kost.facilities.any(
            (String facility) => facility.toLowerCase().contains(search),
          );
      if (!matchesQuery) {
        return false;
      }
      if (_filter == 'Semua') {
        return true;
      }
      if (_filter == 'Tersedia') {
        return _store.isAvailable(kost);
      }
      if (_filter == 'Terverifikasi') {
        return _store.isVerified(kost);
      }
      return kost.category == _filter || kost.facilities.contains(_filter);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _store = KostHuntStore.instance;
    _store.addListener(_handleStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _buildTab(_selectedIndex),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: KostHuntTheme.surface,
          border: Border(top: BorderSide(color: KostHuntTheme.line)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Cari',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              label: 'Favorit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_available_rounded),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Pesan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    if (index == 0) {
      return _HomePage(
        key: const ValueKey<String>('home'),
        heroIndex: _heroIndex,
        filters: _filters,
        activeFilter: _filter,
        visibleKosts: _visibleKosts,
        store: _store,
        onHeroChanged: (int value) {
          setState(() {
            _heroIndex = value;
          });
        },
        onFilterChanged: (String value) {
          setState(() {
            _filter = value;
          });
        },
        onQueryChanged: (String value) {
          setState(() {
            _query = value;
          });
        },
        onOpenDetail: _openDetail,
        onBook: _bookKost,
      );
    }
    if (index == 2) {
      return _BookingPage(
        key: const ValueKey<String>('booking'),
        bookings: _store.bookings,
        onOpenDetail: _openDetail,
      );
    }
    if (index == 1) {
      return _FavoritePage(
        key: const ValueKey<String>('favorite'),
        favorites: _store.favorites,
        onOpenDetail: _openDetail,
      );
    }
    if (index == 3) {
      return _MessagesPage(
        key: const ValueKey<String>('messages'),
        messages: _store.supportMessages,
        onSend: _sendSupportMessage,
      );
    }
    return const _ProfilePage(
      key: ValueKey<String>('profile'),
    );
  }

  void _openDetail(Kost kost) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _KostDetailSheet(
          kost: kost,
          isFavorite: _store.isFavorite(kost),
          isAvailable: _store.isAvailable(kost),
          isVerified: _store.isVerified(kost),
          onFavorite: () => _store.toggleFavorite(kost),
          onBook: () => _bookKost(kost),
        );
      },
    );
  }

  Future<void> _bookKost(Kost kost) async {
    final BookingRequest booking = await _store.createBooking(kost);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${booking.id} dibuat dan dikirim ke WhatsApp admin.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _selectedIndex = 2;
    });
  }

  Future<void> _sendSupportMessage(String message) async {
    final SupportMessage sent = await _store.sendSupportMessage(message);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent.deliveryStatus),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    super.key,
    required this.heroIndex,
    required this.filters,
    required this.activeFilter,
    required this.visibleKosts,
    required this.store,
    required this.onHeroChanged,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onOpenDetail,
    required this.onBook,
  });

  final int heroIndex;
  final List<String> filters;
  final String activeFilter;
  final List<Kost> visibleKosts;
  final KostHuntStore store;
  final ValueChanged<int> onHeroChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Kost> onOpenDetail;
  final ValueChanged<Kost> onBook;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('home-scroll'),
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _TopBar()),
        SliverToBoxAdapter(
          child: _HeroShowcase(
            featuredKosts: visibleKosts,
            activeIndex: heroIndex,
            onChanged: onHeroChanged,
            onOpenDetail: onOpenDetail,
            onBook: onBook,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: _SearchField(onChanged: onQueryChanged),
        ),
        SliverToBoxAdapter(
          child: _FilterRail(
            filters: filters,
            activeFilter: activeFilter,
            onFilterChanged: onFilterChanged,
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Pilihan Kost Terbaik',
            action: '${visibleKosts.length} listing',
          ),
        ),
        if (visibleKosts.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: _EmptyResult(),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final Kost kost = visibleKosts[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  index == 0 ? 0 : 14,
                  20,
                  index == visibleKosts.length - 1 ? 18 : 0,
                ),
                child: _KostCard(
                  kost: kost,
                  isFavorite: store.isFavorite(kost),
                  isAvailable: store.isAvailable(kost),
                  isVerified: store.isVerified(kost),
                  onFavoriteTap: () => store.toggleFavorite(kost),
                  onTap: () => onOpenDetail(kost),
                ),
              );
            }, childCount: visibleKosts.length),
          ),
        const SliverToBoxAdapter(child: _OwnerDashboardPreview()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KostHuntTheme.ink,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: KostHuntTheme.surface,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('KostHunt', style: KostText.title),
                const SizedBox(height: 3),
                Text(
                  AuthService.instance.currentUser?.name ??
                      'Hunian terkurasi dekat kampus dan kantor.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KostText.muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconBox(icon: Icons.notifications_none_rounded, onTap: () {}),
          const SizedBox(width: 8),
          _IconBox(
            icon: Icons.logout_rounded,
            onTap: () async {
              await _logoutToLogin(context);
            },
          ),
        ],
      ),
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase({
    required this.featuredKosts,
    required this.activeIndex,
    required this.onChanged,
    required this.onOpenDetail,
    required this.onBook,
  });

  final List<Kost> featuredKosts;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final ValueChanged<Kost> onOpenDetail;
  final ValueChanged<Kost> onBook;

  @override
  Widget build(BuildContext context) {
    final List<Kost> featured = featuredKosts.take(3).toList();
    if (featured.isEmpty) {
      return const SizedBox(height: 16);
    }
    return SizedBox(
      height: 420,
      child: PageView.builder(
        itemCount: featured.length,
        onPageChanged: onChanged,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (BuildContext context, int index) {
          final Kost kost = featured[index];
          final bool isActive = index == activeIndex;
          return AnimatedPadding(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(
              isActive ? 0 : 8,
              isActive ? 0 : 18,
              isActive ? 12 : 20,
              isActive ? 0 : 18,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _NetworkPhoto(imageUrl: kost.imageUrl, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x22000000),
                          Color(0x33000000),
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _StatusPill(
                              label: kost.category,
                              background: KostHuntTheme.softSage,
                              foreground: KostHuntTheme.ink,
                            ),
                            const Spacer(),
                            _SlideCounter(
                              current: index + 1,
                              total: featured.length,
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Temukan ruang yang pas, tanpa ribet.',
                          style: TextStyle(
                            color: KostHuntTheme.surface,
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${kost.name} - ${kost.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFEDEAE2),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => onOpenDetail(kost),
                                child: const Text('Lihat Detail'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => onBook(kost),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: KostHuntTheme.surface,
                                  side: const BorderSide(
                                    color: Color(0x99FFFFFF),
                                  ),
                                ),
                                child: const Text('Booking'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.onChanged,
  });

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: KostHuntTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KostHuntTheme.line),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 16),
            const Icon(Icons.search_rounded, color: KostHuntTheme.muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: KostText.body,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari lokasi, kampus, atau nama kost',
                  hintStyle: KostText.muted,
                  isCollapsed: true,
                ),
              ),
            ),
            const Icon(Icons.tune_rounded, color: KostHuntTheme.ink),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.filters,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (BuildContext context, int index) {
          final String filter = filters[index];
          return ChoiceChip(
            label: Text(filter),
            selected: filter == activeFilter,
            onSelected: (_) => onFilterChanged(filter),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: KostText.heading)),
          Text(
            action,
            style: KostText.label.copyWith(color: KostHuntTheme.teal),
          ),
        ],
      ),
    );
  }
}

class _KostCard extends StatelessWidget {
  const _KostCard({
    required this.kost,
    required this.isFavorite,
    required this.isAvailable,
    required this.isVerified,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final Kost kost;
  final bool isFavorite;
  final bool isAvailable;
  final bool isVerified;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _NetworkPhoto(imageUrl: kost.imageUrl),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (isVerified)
                          const _StatusPill(
                            label: 'Terverifikasi',
                            background: KostHuntTheme.teal,
                            foreground: KostHuntTheme.surface,
                          ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: isAvailable ? 'Tersedia' : 'Penuh',
                          background: isAvailable
                              ? KostHuntTheme.softSage
                              : const Color(0xFFF0E3D2),
                          foreground: isAvailable
                              ? KostHuntTheme.teal
                              : KostHuntTheme.amber,
                        ),
                        const Spacer(),
                        Material(
                          color: const Color(0xDDFFFFFF),
                          borderRadius: BorderRadius.circular(13),
                          child: InkWell(
                            onTap: onFavoriteTap,
                            borderRadius: BorderRadius.circular(13),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? KostHuntTheme.amber
                                    : KostHuntTheme.ink,
                                size: 21,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: Text(kost.name, style: KostText.title)),
                      const SizedBox(width: 10),
                      Text(
                        '${_formatPrice(kost.price)}/bln',
                        style: KostText.titleSmall.copyWith(
                          color: KostHuntTheme.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${kost.address} - ${kost.distanceKm.toStringAsFixed(1)} km',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KostText.muted,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kost.facilities.take(4).map((String facility) {
                      return _FacilityTag(label: facility);
                    }).toList(),
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

class _OwnerDashboardPreview extends StatelessWidget {
  const _OwnerDashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: KostHuntTheme.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E332E),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: KostHuntTheme.softSage,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Owner Dashboard',
                    style: TextStyle(
                      color: KostHuntTheme.surface,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Pantau ketersediaan kamar, permintaan booking, dan performa listing dari satu tempat.',
              style: TextStyle(
                color: Color(0xFFC9CEC5),
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: <Widget>[
                Expanded(
                  child: _OwnerMetric(value: '12', label: 'Listing'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _OwnerMetric(value: '08', label: 'Tersedia'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _OwnerMetric(value: '05', label: 'Pending'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Sign in memakai akun Supabase dengan role owner untuk membuka dashboard owner.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Login',
                        onPressed: () async {
                          await _logoutToLogin(context);
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_home_work_rounded, size: 19),
                label: const Text('Buka Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KostHuntTheme.surface,
                  foregroundColor: KostHuntTheme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KostDetailSheet extends StatelessWidget {
  const _KostDetailSheet({
    required this.kost,
    required this.isFavorite,
    required this.isAvailable,
    required this.isVerified,
    required this.onFavorite,
    required this.onBook,
  });

  final Kost kost;
  final bool isFavorite;
  final bool isAvailable;
  final bool isVerified;
  final VoidCallback onFavorite;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          decoration: const BoxDecoration(
            color: KostHuntTheme.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 16 / 11,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                      child: _NetworkPhoto(imageUrl: kost.imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _IconBox(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Row(
                      children: <Widget>[
                        if (isVerified)
                          const _StatusPill(
                            label: 'Terverifikasi',
                            background: KostHuntTheme.teal,
                            foreground: KostHuntTheme.surface,
                          ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: isAvailable ? 'Tersedia' : 'Penuh',
                          background: KostHuntTheme.surface,
                          foreground: isAvailable
                              ? KostHuntTheme.teal
                              : KostHuntTheme.amber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(kost.name, style: KostText.headingLarge),
                    const SizedBox(height: 8),
                    Text(kost.description, style: KostText.body),
                    const SizedBox(height: 16),
                    Text(
                      '${_formatPrice(kost.price)} / bulan',
                      style: KostText.heading.copyWith(
                        color: KostHuntTheme.teal,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.place_outlined,
                      label: 'Alamat',
                      value: kost.address,
                    ),
                    _InfoRow(
                      icon: Icons.near_me_outlined,
                      label: 'Jarak',
                      value:
                          '${kost.distanceKm.toStringAsFixed(1)} km dari area utama',
                    ),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Pemilik',
                      value: kost.ownerName,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kost.facilities.map((String facility) {
                        return _FacilityTag(label: facility);
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 136,
                      decoration: BoxDecoration(
                        color: KostHuntTheme.softSage,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: KostHuntTheme.line),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.map_outlined,
                              color: KostHuntTheme.teal,
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text('Preview lokasi', style: KostText.label),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isAvailable
                                ? () {
                                    Navigator.of(context).pop();
                                    onBook();
                                  }
                                : null,
                            icon: const Icon(
                              Icons.event_available_rounded,
                              size: 19,
                            ),
                            label: Text(
                              isAvailable ? 'Ajukan Booking' : 'Tidak Tersedia',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onFavorite,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 19,
                            ),
                            label: Text(isFavorite ? 'Favorit' : 'Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingPage extends StatelessWidget {
  const _BookingPage({
    super.key,
    required this.bookings,
    required this.onOpenDetail,
  });

  final List<BookingRequest> bookings;
  final ValueChanged<Kost> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _TopBar()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Text('Booking Saya', style: KostText.headingLarge),
          ),
        ),
        if (bookings.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _EmptyStateCard(
                icon: Icons.event_busy_rounded,
                title: 'Belum ada booking',
                subtitle: 'Booking dari detail kost akan muncul di sini.',
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final BookingRequest booking = bookings[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    index == bookings.length - 1 ? 24 : 14,
                  ),
                  child: _BookingCard(
                    booking: booking,
                    onTap: () => onOpenDetail(booking.kost),
                  ),
                );
              },
              childCount: bookings.length,
            ),
          ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
  });

  final BookingRequest booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool accepted = booking.status == 'Diterima';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: _NetworkPhoto(imageUrl: booking.kost.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _StatusPill(
                      label: booking.status,
                      background: accepted
                          ? KostHuntTheme.softSage
                          : const Color(0xFFF0E3D2),
                      foreground:
                          accepted ? KostHuntTheme.teal : KostHuntTheme.amber,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      booking.kost.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KostText.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(booking.scheduleLabel, style: KostText.muted),
                    const SizedBox(height: 6),
                    Text(
                      booking.notificationStatus,
                      style: KostText.label.copyWith(color: KostHuntTheme.teal),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KostHuntTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritePage extends StatelessWidget {
  const _FavoritePage({
    super.key,
    required this.favorites,
    required this.onOpenDetail,
  });

  final List<Kost> favorites;
  final ValueChanged<Kost> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _TopBar()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Text('Favorit Tersimpan', style: KostText.headingLarge),
          ),
        ),
        if (favorites.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _EmptyStateCard(
                icon: Icons.favorite_border_rounded,
                title: 'Belum ada favorit',
                subtitle:
                    'Tekan ikon hati pada listing untuk menyimpan kost incaran.',
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final Kost kost = favorites[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    index == favorites.length - 1 ? 24 : 14,
                  ),
                  child: _FavoriteTile(
                    kost: kost,
                    onTap: () => onOpenDetail(kost),
                  ),
                );
              },
              childCount: favorites.length,
            ),
          ),
      ],
    );
  }
}

class _MessagesPage extends StatefulWidget {
  const _MessagesPage({
    super.key,
    required this.messages,
    required this.onSend,
  });

  final List<SupportMessage> messages;
  final Future<void> Function(String message) onSend;

  @override
  State<_MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<_MessagesPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _TopBar(),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Chat Admin', style: KostText.headingLarge),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: _AdminChatNotice(),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            itemCount: widget.messages.length,
            itemBuilder: (BuildContext context, int index) {
              return _MessageBubble(message: widget.messages[index]);
            },
          ),
        ),
        _MessageComposer(
          controller: _controller,
          sending: _sending,
          onSend: _handleSend,
        ),
      ],
    );
  }

  Future<void> _handleSend() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() {
      _sending = true;
    });
    _controller.clear();
    try {
      await widget.onSend(text);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String name =
        AuthService.instance.currentUser?.name ?? 'Calon Penghuni';
    final String phone = AuthService.instance.currentUser?.phone ?? '-';
    return CustomScrollView(
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _TopBar()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: KostHuntTheme.ink,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: KostHuntTheme.surface,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(name, style: KostText.title),
                              const SizedBox(height: 5),
                              Text(
                                'Customer - $phone',
                                style: KostText.muted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Mode Akses', style: KostText.heading),
                const SizedBox(height: 12),
                _RoleAccessCard(
                  icon: Icons.home_work_outlined,
                  title: 'Customer',
                  subtitle:
                      'Cari kost, simpan favorit, dan booking via WhatsApp.',
                  label: 'Sedang Aktif',
                  onTap: () {},
                ),
                _RoleAccessCard(
                  icon: Icons.dashboard_customize_rounded,
                  title: 'Owner',
                  subtitle:
                      'Kelola listing dan booking masuk dari calon penghuni.',
                  label: 'Buka Owner',
                  onTap: () => _showSwitchRoleSnack(
                    context,
                    'Sign in memakai akun Supabase dengan role owner untuk membuka dashboard owner.',
                  ),
                ),
                _RoleAccessCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin',
                  subtitle:
                      'Moderasi listing, owner, user, dan laporan platform.',
                  label: 'Buka Admin',
                  onTap: () => _showSwitchRoleSnack(
                    context,
                    'Sign in memakai akun Supabase dengan role admin untuk membuka admin console.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSwitchRoleSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Login',
          onPressed: () async {
            await _logoutToLogin(context);
          },
        ),
      ),
    );
  }
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

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.kost,
    required this.onTap,
  });

  final Kost kost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: _NetworkPhoto(imageUrl: kost.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _StatusPill(
                      label: 'Favorit',
                      background: KostHuntTheme.softSage,
                      foreground: KostHuntTheme.teal,
                    ),
                    const SizedBox(height: 10),
                    Text(kost.name, style: KostText.titleSmall),
                    const SizedBox(height: 6),
                    Text(kost.address, style: KostText.muted),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: KostHuntTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminChatNotice extends StatelessWidget {
  const _AdminChatNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KostHuntTheme.softSage,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KostHuntTheme.line),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KostHuntTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: KostHuntTheme.teal,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pesan yang kamu kirim di sini akan diteruskan ke WhatsApp admin KostHunt.',
              style: KostText.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.sentByCustomer;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine ? KostHuntTheme.ink : KostHuntTheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 6),
              bottomRight: Radius.circular(mine ? 6 : 18),
            ),
            border: mine ? null : Border.all(color: KostHuntTheme.line),
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.text,
                style: KostText.body.copyWith(
                  color: mine ? KostHuntTheme.surface : KostHuntTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${message.timeLabel} - ${message.deliveryStatus}',
                style: KostText.label.copyWith(
                  color: mine ? const Color(0xFFC9CEC5) : KostHuntTheme.muted,
                  fontSize: 10,
                ),
              ),
              if (message.reference != '-') ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  message.reference,
                  style: KostText.label.copyWith(
                    color: mine ? KostHuntTheme.softSage : KostHuntTheme.amber,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: KostHuntTheme.surface,
        border: Border(top: BorderSide(color: KostHuntTheme.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: KostHuntTheme.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KostHuntTheme.line),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tulis pesan untuk admin',
                  hintStyle: KostText.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: sending ? null : onSend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KostHuntTheme.surface,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleAccessCard extends StatelessWidget {
  const _RoleAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
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
                      Text(title, style: KostText.titleSmall),
                      const SizedBox(height: 4),
                      Text(subtitle, style: KostText.muted),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: KostText.label.copyWith(color: KostHuntTheme.teal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
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
        padding: const EdgeInsets.all(22),
        child: Column(
          children: <Widget>[
            Icon(icon, color: KostHuntTheme.teal, size: 40),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: KostText.title),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: KostText.body.copyWith(color: KostHuntTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: KostText.label.copyWith(color: foreground, fontSize: 11),
      ),
    );
  }
}

class _FacilityTag extends StatelessWidget {
  const _FacilityTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: KostHuntTheme.softSage,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KostText.label.copyWith(color: KostHuntTheme.sage, fontSize: 11),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KostHuntTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KostHuntTheme.line),
            ),
            child: Icon(icon, color: KostHuntTheme.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: KostText.label.copyWith(color: KostHuntTheme.muted),
                ),
                const SizedBox(height: 4),
                Text(value, style: KostText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideCounter extends StatelessWidget {
  const _SlideCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        '${current.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: KostHuntTheme.surface,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OwnerMetric extends StatelessWidget {
  const _OwnerMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF242823),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF343A33)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: KostHuntTheme.surface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC9CEC5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.onTap});

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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KostHuntTheme.line),
          ),
          child: Icon(icon, color: KostHuntTheme.ink, size: 22),
        ),
      ),
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.imageUrl, this.fit = BoxFit.cover});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return Container(
          color: KostHuntTheme.softSage,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: KostHuntTheme.sage,
              size: 34,
            ),
          ),
        );
      },
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: KostHuntTheme.softSage,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KostHuntTheme.teal,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KostHuntTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KostHuntTheme.line),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.search_off_rounded, color: KostHuntTheme.muted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Belum ada listing untuk filter ini.',
              style: KostText.muted,
            ),
          ),
        ],
      ),
    );
  }
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
