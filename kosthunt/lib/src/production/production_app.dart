import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/kosthunt_theme.dart';
import 'production_models.dart';
import 'production_store.dart';

class KostHuntProductionApp extends ConsumerWidget {
  const KostHuntProductionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProductionStore store = ref.watch(productionStoreProvider);
    final GoRouter router = GoRouter(
      refreshListenable: store,
      initialLocation: '/login',
      redirect: (BuildContext context, GoRouterState state) {
        final KhUser? user = store.currentUser;
        final String location = state.matchedLocation;
        if (user == null) {
          return location == '/login' ? null : '/login';
        }
        final String home = rolePath(user.role);
        if (location == '/login' || location == '/') {
          return home;
        }
        if (location.startsWith('/customer') && user.role != KhRole.customer) {
          return home;
        }
        if (location.startsWith('/owner') && user.role != KhRole.owner) {
          return home;
        }
        if (location.startsWith('/admin') && user.role != KhRole.admin) {
          return home;
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(path: '/', redirect: (_, __) => '/login'),
        GoRoute(path: '/login', builder: (_, __) => const ProductionLoginScreen()),
        GoRoute(path: '/customer', builder: (_, __) => const CustomerHomeScreen()),
        GoRoute(path: '/owner', builder: (_, __) => const OwnerHomeScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'KostHunt',
      debugShowCheckedModeBanner: false,
      theme: KostHuntTheme.light,
      routerConfig: router,
    );
  }
}

class ProductionLoginScreen extends ConsumerStatefulWidget {
  const ProductionLoginScreen({super.key});

  @override
  ConsumerState<ProductionLoginScreen> createState() => _ProductionLoginScreenState();
}

class _ProductionLoginScreenState extends ConsumerState<ProductionLoginScreen> {
  final TextEditingController _email = TextEditingController(text: 'customer@kosthunt.test');
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController(text: '628129990001');
  int _mode = 0;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KostHuntTheme.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _BrandHeader(),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SegmentedButton<int>(
                            segments: const <ButtonSegment<int>>[
                              ButtonSegment<int>(value: 0, icon: Icon(Icons.login), label: Text('Login')),
                              ButtonSegment<int>(value: 1, icon: Icon(Icons.person_add_alt), label: Text('Customer')),
                              ButtonSegment<int>(value: 2, icon: Icon(Icons.storefront), label: Text('Owner')),
                            ],
                            selected: <int>{_mode},
                            onSelectionChanged: (Set<int> value) {
                              setState(() {
                                _mode = value.first;
                                _error = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_mode != 0) ...<Widget>[
                            TextField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: 10),
                            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _submit,
                            icon: Icon(_mode == 0 ? Icons.login : Icons.check_circle_outline),
                            label: Text(_mode == 0 ? 'Masuk' : 'Daftar dan Masuk'),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _DemoChip(label: 'Customer', email: 'customer@kosthunt.test', onPick: _pickDemo),
                              _DemoChip(label: 'Owner', email: 'owner@kosthunt.test', onPick: _pickDemo),
                              _DemoChip(label: 'Admin', email: 'admin@kosthunt.test', onPick: _pickDemo),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _showInfo(
                              context,
                              'Reset password',
                              'Di production, reset password dikirim lewat Supabase Auth email. Sandbox lokal ini mencatat flow tanpa mengirim email.',
                            ),
                            icon: const Icon(Icons.lock_reset),
                            label: const Text('Forgot password'),
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

  void _pickDemo(String email) {
    setState(() {
      _mode = 0;
      _email.text = email;
      _phone.text = email.startsWith('owner') ? '628122220002' : '628129990001';
      _error = null;
    });
  }

  void _submit() {
    final ProductionStore store = ref.read(productionStoreProvider);
    try {
      if (_mode == 0) {
        store.signIn(_email.text);
      } else if (_mode == 1) {
        store.registerCustomer(name: _name.text, email: _email.text, phone: _phone.text);
      } else {
        store.registerOwner(name: _name.text, email: _email.text, phone: _phone.text);
      }
      final KhUser user = store.currentUser!;
      context.go(rolePath(user.role));
    } on Object catch (error) {
      setState(() {
        _error = error is ArgumentError ? error.message.toString() : 'Aksi gagal.';
      });
    }
  }
}

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _tab = 0;
  String _query = '';
  final Set<String> _activeFilters = <String>{};

  static const List<String> _marketplaceFilters = <String>[
    'WiFi',
    'AC',
    'Parkir',
    '<=1 km kampus',
    'Kost',
    'Kontrakan',
    'Premium',
  ];

  @override
  Widget build(BuildContext context) {
    final ProductionStore store = ref.watch(productionStoreProvider);
    final KhUser user = store.currentUser!;
    return _RoleScaffold(
      title: 'Marketplace',
      user: user,
      selectedIndex: _tab,
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.search), label: 'Cari'),
        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Booking'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        NavigationDestination(icon: Icon(Icons.support_agent), label: 'CS'),
        NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Profil'),
      ],
      onDestinationSelected: (int value) => setState(() => _tab = value),
      child: _customerBody(store, user),
    );
  }

  Widget _customerBody(ProductionStore store, KhUser user) {
    switch (_tab) {
      case 1:
        return _CustomerBookings(store: store, user: user);
      case 2:
        return _ConversationList(store: store, user: user);
      case 3:
        return _SupportCenter(store: store, user: user);
      case 4:
        return _ProfileAndNotifications(store: store, user: user);
      case 0:
      default:
        final List<KostListing> visible = store.publishedListings.where((KostListing item) {
          final String q = _query.trim().toLowerCase();
          final bool matchesQuery = q.isEmpty ||
              item.title.toLowerCase().contains(q) ||
              item.city.toLowerCase().contains(q) ||
              item.area.toLowerCase().contains(q) ||
              item.facilities.any((String value) => value.toLowerCase().contains(q));
          if (!matchesQuery) {
            return false;
          }
          for (final String filter in _activeFilters) {
            if (!_matchesMarketplaceFilter(item, filter)) {
              return false;
            }
          }
          return true;
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SearchBox(onChanged: (String value) => setState(() => _query = value)),
            const SizedBox(height: 10),
            _MarketplaceFilterChips(
              filters: _marketplaceFilters,
              activeFilters: _activeFilters,
              onToggle: (String value) {
                setState(() {
                  if (!_activeFilters.add(value)) {
                    _activeFilters.remove(value);
                  }
                });
              },
              onClear: _activeFilters.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _activeFilters.clear();
                      });
                    },
            ),
            const SizedBox(height: 12),
            _SectionTitle(title: 'Listing published', trailing: '${visible.length} properti'),
            for (final KostListing listing in visible)
              _ListingCard(
                store: store,
                listing: listing,
                user: user,
                onOpen: () => _showListingDetail(context, store, user, listing),
              ),
          ],
        );
    }
  }
}

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final ProductionStore store = ref.watch(productionStoreProvider);
    final KhUser user = store.currentUser!;
    return _RoleScaffold(
      title: 'Owner Console',
      user: user,
      selectedIndex: _tab,
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Listing'),
        NavigationDestination(icon: Icon(Icons.event_available), label: 'Booking'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Saldo'),
        NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Profil'),
      ],
      onDestinationSelected: (int value) => setState(() => _tab = value),
      child: _ownerBody(context, store, user),
    );
  }

  Widget _ownerBody(BuildContext context, ProductionStore store, KhUser user) {
    if (_tab == 1) {
      final List<KostListing> listings = store.listingsForOwner(user.id);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FilledButton.icon(
            onPressed: () => _showCreateListingDialog(context, store, user),
            icon: const Icon(Icons.add_home_work_outlined),
            label: const Text('Tambah listing dan publish'),
          ),
          const SizedBox(height: 12),
          for (final KostListing listing in listings)
            _OwnerListingTile(store: store, user: user, listing: listing),
        ],
      );
    }
    if (_tab == 2) {
      return _OwnerBookings(store: store, user: user);
    }
    if (_tab == 3) {
      return _OwnerBalanceView(store: store, user: user);
    }
    if (_tab == 4) {
      return _ProfileAndNotifications(store: store, user: user);
    }
    final List<KostListing> owned = store.listingsForOwner(user.id);
    final List<Booking> ownerBookings = store.bookingsForUser(user.id);
    final OwnerBalance balance = store.balanceForOwner(user.id);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _MetricGrid(items: <_MetricItem>[
          _MetricItem('Listing', owned.length.toString(), Icons.home_work_outlined),
          _MetricItem('Booking', ownerBookings.length.toString(), Icons.event_available),
          _MetricItem('Pending', formatRupiah(balance.pendingAmount), Icons.hourglass_bottom),
          _MetricItem('Available', formatRupiah(balance.availableAmount), Icons.payments_outlined),
        ]),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Chat masuk', trailing: '${store.conversationsForUser(user.id).length} room'),
        _ConversationList(store: store, user: user, compact: true),
      ],
    );
  }
}

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final ProductionStore store = ref.watch(productionStoreProvider);
    final KhUser user = store.currentUser!;
    return _RoleScaffold(
      title: 'Admin Console',
      user: user,
      selectedIndex: _tab,
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Listing'),
        NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Finance'),
        NavigationDestination(icon: Icon(Icons.support_agent), label: 'Support'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Audit'),
      ],
      onDestinationSelected: (int value) => setState(() => _tab = value),
      child: _adminBody(store, user),
    );
  }

  Widget _adminBody(ProductionStore store, KhUser user) {
    if (_tab == 1) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SectionTitle(title: 'Moderasi listing', trailing: '${store.listings.length} listing'),
          for (final KostListing listing in store.listings)
            _AdminListingTile(store: store, admin: user, listing: listing),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Users dan owners', trailing: '${store.users.length} user'),
          for (final KhUser account in store.users) _UserTile(user: account),
        ],
      );
    }
    if (_tab == 2) {
      return _AdminFinance(store: store, admin: user);
    }
    if (_tab == 3) {
      return _AdminSupportAndReports(store: store, admin: user);
    }
    if (_tab == 4) {
      return _AuditView(store: store, user: user);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _MetricGrid(items: <_MetricItem>[
          _MetricItem('Users', store.users.length.toString(), Icons.people_outline),
          _MetricItem('Payment', store.payments.length.toString(), Icons.payments_outlined),
          _MetricItem('Payout', store.payouts.length.toString(), Icons.account_balance),
          _MetricItem('Report', store.reports.length.toString(), Icons.flag_outlined),
        ]),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Payment events', trailing: '${store.paymentEvents.length} callback'),
        for (final PaymentEvent event in store.paymentEvents)
          _SimpleTile(
            icon: Icons.webhook_outlined,
            title: event.merchantOrderId,
            subtitle: '${event.eventType} - signature ${event.signatureValid} - amount ${event.amountMatch}',
          ),
      ],
    );
  }
}

class _CustomerBookings extends StatelessWidget {
  const _CustomerBookings({required this.store, required this.user});

  final ProductionStore store;
  final KhUser user;

  @override
  Widget build(BuildContext context) {
    final List<Booking> items = store.bookingsForUser(user.id);
    if (items.isEmpty) {
      return const _EmptyState(icon: Icons.receipt_long, title: 'Belum ada booking', body: 'Pilih listing dan booking unit yang tersedia.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (final Booking booking in items)
          _BookingTile(
            store: store,
            user: user,
            booking: booking,
            customerMode: true,
          ),
      ],
    );
  }
}

class _OwnerBookings extends StatelessWidget {
  const _OwnerBookings({required this.store, required this.user});

  final ProductionStore store;
  final KhUser user;

  @override
  Widget build(BuildContext context) {
    final List<Booking> items = store.bookingsForUser(user.id);
    if (items.isEmpty) {
      return const _EmptyState(icon: Icons.event_available, title: 'Belum ada booking', body: 'Booking customer akan muncul di sini realtime.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (final Booking booking in items)
          _BookingTile(store: store, user: user, booking: booking, customerMode: false),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.store,
    required this.user,
    required this.booking,
    required this.customerMode,
  });

  final ProductionStore store;
  final KhUser user;
  final Booking booking;
  final bool customerMode;

  @override
  Widget build(BuildContext context) {
    final KostListing listing = store.listingById(booking.kostId);
    final KostUnit unit = store.unitById(booking.unitId);
    final Payment? payment = _paymentForBooking(store, booking.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                _StatusChip(label: _bookingLabel(booking.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('${unit.name} - ${booking.durationMonths} bulan - ${formatRupiah(booking.rentAmount)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (customerMode && payment == null)
                  FilledButton.icon(
                    onPressed: () => store.createPayment(user.id, booking.id),
                    icon: const Icon(Icons.payment),
                    label: const Text('Buat payment'),
                  ),
                if (customerMode && payment != null && payment.status == PaymentStatus.waitingPayment)
                  FilledButton.icon(
                    onPressed: () => store.simulateDuitkuPaid(user.id, payment.id),
                    icon: const Icon(Icons.verified),
                    label: const Text('Simulasi bayar Duitku'),
                  ),
                if (!customerMode && booking.status == BookingStatus.paid)
                  FilledButton.icon(
                    onPressed: () => store.confirmBooking(user.id, booking.id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm'),
                  ),
                if (!customerMode && booking.status == BookingStatus.confirmed)
                  OutlinedButton.icon(
                    onPressed: () => store.completeBooking(user.id, booking.id),
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Selesai'),
                  ),
                if (customerMode && payment != null && payment.status == PaymentStatus.paid)
                  OutlinedButton.icon(
                    onPressed: () => _showRefundDialog(context, store, user, payment),
                    icon: const Icon(Icons.replay_circle_filled_outlined),
                    label: const Text('Minta refund'),
                  ),
                if (customerMode && booking.status == BookingStatus.completed)
                  OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(context, store, user, booking),
                    icon: const Icon(Icons.star_border),
                    label: const Text('Review'),
                  ),
              ],
            ),
            if (payment != null) ...<Widget>[
              const SizedBox(height: 10),
              Text('Payment: ${_paymentLabel(payment.status)} - ${payment.merchantOrderId}', style: const TextStyle(color: KostHuntTheme.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationList extends StatefulWidget {
  const _ConversationList({required this.store, required this.user, this.compact = false});

  final ProductionStore store;
  final KhUser user;
  final bool compact;

  @override
  State<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<_ConversationList> {
  final TextEditingController _message = TextEditingController();
  String? _selectedId;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Conversation> conversations = widget.store.conversationsForUser(widget.user.id);
    if (conversations.isEmpty) {
      return const _EmptyState(icon: Icons.chat_bubble_outline, title: 'Belum ada chat', body: 'Customer bisa mulai chat dari detail kost.');
    }
    final Conversation selected = conversations.firstWhere(
      (Conversation item) => item.id == (_selectedId ?? conversations.first.id),
      orElse: () => conversations.first,
    );
    final List<ChatMessage> messages = widget.store.messagesForConversation(selected.id);
    return ListView(
      padding: EdgeInsets.all(widget.compact ? 0 : 16),
      shrinkWrap: widget.compact,
      physics: widget.compact ? const NeverScrollableScrollPhysics() : null,
      children: <Widget>[
        for (final Conversation conversation in conversations)
          ListTile(
            selected: conversation.id == selected.id,
            leading: const Icon(Icons.forum_outlined),
            title: Text(widget.store.listingById(conversation.kostId).title),
            subtitle: Text('${conversation.participantUserIds.length} participant'),
            onTap: () => setState(() => _selectedId = conversation.id),
          ),
        const Divider(),
        for (final ChatMessage message in messages)
          _MessageBubble(
            mine: message.senderUserId == widget.user.id,
            sender: widget.store.userById(message.senderUserId)?.name ?? '-',
            body: message.body,
            time: clock(message.createdAt),
          ),
        _Composer(
          controller: _message,
          hint: 'Tulis pesan chat',
          onSend: () {
            widget.store.sendChatMessage(widget.user.id, selected.id, _message.text);
            _message.clear();
            setState(() {});
          },
        ),
      ],
    );
  }
}

class _SupportCenter extends StatefulWidget {
  const _SupportCenter({required this.store, required this.user});

  final ProductionStore store;
  final KhUser user;

  @override
  State<_SupportCenter> createState() => _SupportCenterState();
}

class _SupportCenterState extends State<_SupportCenter> {
  final TextEditingController _message = TextEditingController();
  String? _selectedId;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<SupportThread> threads = widget.store.supportThreadsForUser(widget.user.id);
    final SupportThread? selected = threads.isEmpty
        ? null
        : threads.firstWhere(
            (SupportThread item) => item.id == (_selectedId ?? threads.first.id),
            orElse: () => threads.first,
          );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        FilledButton.icon(
          onPressed: () {
            final SupportThread thread = widget.store.openSupportThread(customerUserId: widget.user.id, subject: 'Bantuan KostHunt');
            setState(() => _selectedId = thread.id);
          },
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('Buka support ticket'),
        ),
        const SizedBox(height: 12),
        if (selected == null)
          const _EmptyState(icon: Icons.support_agent, title: 'Belum ada support ticket', body: 'Buat ticket untuk chat langsung dengan admin.')
        else ...<Widget>[
          for (final SupportThread thread in threads)
            ListTile(
              selected: thread.id == selected.id,
              leading: const Icon(Icons.support_agent),
              title: Text(thread.subject),
              subtitle: Text('Status ${thread.status.name}'),
              onTap: () => setState(() => _selectedId = thread.id),
            ),
          const Divider(),
          for (final SupportNote note in widget.store.messagesForSupportThread(selected.id))
            _MessageBubble(
              mine: note.senderUserId == widget.user.id,
              sender: widget.store.userById(note.senderUserId)?.name ?? '-',
              body: note.body,
              time: clock(note.createdAt),
            ),
          _Composer(
            controller: _message,
            hint: 'Tulis pesan ke admin',
            onSend: () {
              widget.store.sendSupportMessage(widget.user.id, selected.id, _message.text);
              _message.clear();
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}

class _ProfileAndNotifications extends StatelessWidget {
  const _ProfileAndNotifications({required this.store, required this.user});

  final ProductionStore store;
  final KhUser user;

  @override
  Widget build(BuildContext context) {
    final List<AppNotification> items = store.notificationsForUser(user.id);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text('${user.email} - ${user.roleLabel}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => store.requestAccountDeletion(user.id),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Request account deletion'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      store.logout();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Notification center', trailing: '${store.unreadCount(user.id)} unread'),
        for (final AppNotification item in items)
          ListTile(
            leading: Icon(item.readAt == null ? Icons.notifications_active : Icons.notifications_none),
            title: Text(item.title),
            subtitle: Text('${item.body}\n${clock(item.createdAt)}'),
            isThreeLine: true,
            onTap: () => store.markNotificationRead(item.id),
          ),
      ],
    );
  }
}

class _OwnerListingTile extends StatelessWidget {
  const _OwnerListingTile({required this.store, required this.user, required this.listing});

  final ProductionStore store;
  final KhUser user;
  final KostListing listing;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              _StatusChip(label: listing.status.name),
            ],
          ),
          const SizedBox(height: 6),
          Text('${listing.typeLabel} - ${listing.area}, ${listing.city} - ${formatRupiah(listing.minPrice)}'),
          Text('${listing.campusDistanceKm.toStringAsFixed(1)} km dari kampus'),
          if (listing.isPremiumActive)
            Text('Premium aktif - ${listing.adCredits} ad credits', style: const TextStyle(color: KostHuntTheme.teal, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => store.updateListingStatus(
                  user.id,
                  listing.id,
                  listing.status == ListingStatus.paused ? ListingStatus.published : ListingStatus.paused,
                ),
                icon: Icon(listing.status == ListingStatus.paused ? Icons.play_arrow : Icons.pause),
                label: Text(listing.status == ListingStatus.paused ? 'Publish' : 'Pause'),
              ),
              FilledButton.icon(
                onPressed: listing.isPremiumActive ? null : () => store.promoteListing(user.id, listing.id),
                icon: const Icon(Icons.campaign_outlined),
                label: Text(listing.isPremiumActive ? 'Premium aktif' : 'Promosikan Rp99.000'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerBalanceView extends StatelessWidget {
  const _OwnerBalanceView({required this.store, required this.user});

  final ProductionStore store;
  final KhUser user;

  @override
  Widget build(BuildContext context) {
    final OwnerBalance balance = store.balanceForOwner(user.id);
    final List<Payout> ownerPayouts = store.payouts.where((Payout item) => item.ownerUserId == user.id).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _MetricGrid(items: <_MetricItem>[
          _MetricItem('Pending', formatRupiah(balance.pendingAmount), Icons.hourglass_bottom),
          _MetricItem('Available', formatRupiah(balance.availableAmount), Icons.payments_outlined),
          _MetricItem('Paid out', formatRupiah(balance.paidOutAmount), Icons.account_balance),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: balance.availableAmount <= 0
              ? null
              : () => store.requestPayout(user.id, balance.availableAmount),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Ajukan payout semua saldo available'),
        ),
        const SizedBox(height: 12),
        for (final Payout payout in ownerPayouts)
          _SimpleTile(
            icon: Icons.account_balance,
            title: '${formatRupiah(payout.amount)} - ${payout.status.name}',
            subtitle: payout.bankSnapshot,
          ),
      ],
    );
  }
}

class _AdminListingTile extends StatelessWidget {
  const _AdminListingTile({required this.store, required this.admin, required this.listing});

  final ProductionStore store;
  final KhUser admin;
  final KostListing listing;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w800))),
              _StatusChip(label: listing.status.name),
            ],
          ),
          Text('${store.userById(listing.ownerUserId)?.name ?? '-'} - ${listing.typeLabel} - ${listing.city}'),
          Text('${listing.campusDistanceKm.toStringAsFixed(1)} km dari kampus${listing.isPremiumActive ? ' - Premium aktif' : ''}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => store.updateListingStatus(admin.id, listing.id, ListingStatus.suspended),
                icon: const Icon(Icons.block),
                label: const Text('Suspend'),
              ),
              OutlinedButton.icon(
                onPressed: () => store.updateListingStatus(admin.id, listing.id, ListingStatus.published),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Restore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminFinance extends StatelessWidget {
  const _AdminFinance({required this.store, required this.admin});

  final ProductionStore store;
  final KhUser admin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionTitle(title: 'Payments', trailing: '${store.payments.length} item'),
        for (final Payment payment in store.payments)
          _SimpleTile(
            icon: Icons.payments_outlined,
            title: '${payment.merchantOrderId} - ${_paymentLabel(payment.status)}',
            subtitle: '${formatRupiah(payment.amount)} - owner ${formatRupiah(payment.ownerAmount)}',
          ),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Refunds', trailing: '${store.refunds.length} item'),
        for (final RefundRequest refund in store.refunds)
          _ActionTile(
            icon: Icons.replay_circle_filled_outlined,
            title: '${formatRupiah(refund.amount)} - ${refund.status.name}',
            subtitle: refund.reason,
            actionLabel: 'Process',
            onAction: () => store.processRefund(admin.id, refund.id),
          ),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Payouts', trailing: '${store.payouts.length} item'),
        for (final Payout payout in store.payouts)
          _ActionTile(
            icon: Icons.account_balance,
            title: '${formatRupiah(payout.amount)} - ${payout.status.name}',
            subtitle: payout.bankSnapshot,
            actionLabel: 'Mark paid',
            onAction: () => store.processPayout(admin.id, payout.id, PayoutStatus.paid),
          ),
      ],
    );
  }
}

class _AdminSupportAndReports extends StatefulWidget {
  const _AdminSupportAndReports({required this.store, required this.admin});

  final ProductionStore store;
  final KhUser admin;

  @override
  State<_AdminSupportAndReports> createState() => _AdminSupportAndReportsState();
}

class _AdminSupportAndReportsState extends State<_AdminSupportAndReports> {
  final TextEditingController _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionTitle(title: 'Customer service', trailing: '${widget.store.supportThreads.length} thread'),
        for (final SupportThread thread in widget.store.supportThreads)
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${thread.subject} - ${thread.status.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                for (final SupportNote note in widget.store.messagesForSupportThread(thread.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${widget.store.userById(note.senderUserId)?.name ?? '-'}: ${note.body}'),
                  ),
                _Composer(
                  controller: _reply,
                  hint: 'Balas thread ini',
                  onSend: () {
                    widget.store.sendSupportMessage(widget.admin.id, thread.id, _reply.text);
                    _reply.clear();
                    setState(() {});
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => widget.store.updateSupportStatus(widget.admin.id, thread.id, SupportStatus.resolved),
                    child: const Text('Resolve'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Reports', trailing: '${widget.store.reports.length} report'),
        for (final ReportItem report in widget.store.reports)
          _ActionTile(
            icon: Icons.flag_outlined,
            title: '${report.targetType} - ${report.status.name}',
            subtitle: report.reason,
            actionLabel: 'Resolve',
            onAction: () => widget.store.resolveReport(widget.admin.id, report.id, ReportStatus.resolved),
          ),
      ],
    );
  }
}

class _AuditView extends StatelessWidget {
  const _AuditView({required this.store, required this.user});

  final ProductionStore store;
  final KhUser user;

  @override
  Widget build(BuildContext context) {
    final List<AppNotification> items = store.notificationsForUser(user.id);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text('${user.email} - ${user.roleLabel}'),
              Text('${items.length} notification tercatat untuk admin.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Audit logs', trailing: '${store.auditLogs.length} event'),
        for (final AuditLog log in store.auditLogs)
          _SimpleTile(
            icon: Icons.history,
            title: log.action,
            subtitle: '${log.targetType}/${log.targetId} - ${log.metadata}',
          ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.store, required this.listing, required this.user, required this.onOpen});

  final ProductionStore store;
  final KostListing listing;
  final KhUser user;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                listing.photos.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: KostHuntTheme.softSage,
                  child: Center(child: Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(listing.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                      if (listing.isPremiumActive)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: _StatusChip(label: 'Premium'),
                        ),
                      IconButton(
                        tooltip: 'Favorit',
                        onPressed: () => store.toggleFavorite(user.id, listing.id),
                        icon: Icon(store.isFavorite(user.id, listing.id) ? Icons.favorite : Icons.favorite_border),
                      ),
                    ],
                  ),
                  Text('${listing.typeLabel} - ${listing.area}, ${listing.city}'),
                  Text('${listing.campusDistanceKm.toStringAsFixed(1)} km dari kampus', style: const TextStyle(color: KostHuntTheme.muted)),
                  const SizedBox(height: 8),
                  Text('Mulai ${formatRupiah(listing.minPrice)}/bulan', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: listing.facilities.map((String item) => Chip(label: Text(item))).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleScaffold extends ConsumerWidget {
  const _RoleScaffold({
    required this.title,
    required this.user,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.child,
  });

  final String title;
  final KhUser user;
  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProductionStore store = ref.watch(productionStoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Center(child: Text('${store.unreadCount(user.id)}')),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              store.logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.home_work_rounded, size: 46, color: KostHuntTheme.teal),
        SizedBox(height: 10),
        Text('KostHunt', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        SizedBox(height: 6),
        Text('Marketplace kost dengan listing, booking, payment, chat, support, notification, payout, refund, report, dan audit sandbox.'),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.email, required this.onPick});

  final String label;
  final String email;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: () => onPick(email));
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: child));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          Text(trailing, style: const TextStyle(color: KostHuntTheme.muted)),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        labelText: 'Cari kota, area, fasilitas, atau nama kost',
      ),
    );
  }
}

class _MarketplaceFilterChips extends StatelessWidget {
  const _MarketplaceFilterChips({
    required this.filters,
    required this.activeFilters,
    required this.onToggle,
    required this.onClear,
  });

  final List<String> filters;
  final Set<String> activeFilters;
  final ValueChanged<String> onToggle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final String filter in filters) ...<Widget>[
            FilterChip(
              label: Text(filter),
              selected: activeFilters.contains(filter),
              onSelected: (_) => onToggle(filter),
            ),
            const SizedBox(width: 8),
          ],
          if (onClear != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reset'),
            ),
        ],
      ),
    );
  }
}

bool _matchesMarketplaceFilter(KostListing listing, String filter) {
  switch (filter) {
    case 'WiFi':
    case 'AC':
    case 'Parkir':
      return listing.facilities.any(
        (String value) => value.toLowerCase() == filter.toLowerCase(),
      );
    case '<=1 km kampus':
      return listing.campusDistanceKm <= 1.0;
    case 'Kost':
      return listing.propertyType == PropertyType.kost;
    case 'Kontrakan':
      return listing.propertyType == PropertyType.kontrakan;
    case 'Premium':
      return listing.isPremiumActive;
    default:
      return true;
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int count = constraints.maxWidth > 720 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          childAspectRatio: 1.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: <Widget>[
            for (final _MetricItem item in items)
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.icon, color: KostHuntTheme.teal),
                    const SizedBox(height: 8),
                    Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.actionLabel, required this.onAction});

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final KhUser user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(user.name),
      subtitle: Text('${user.email} - ${user.roleLabel} - trust ${user.trustLevel}'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: KostHuntTheme.teal),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.mine, required this.sender, required this.body, required this.time});

  final bool mine;
  final String sender;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: mine ? KostHuntTheme.ink : KostHuntTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: KostHuntTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(sender, style: TextStyle(fontWeight: FontWeight.w800, color: mine ? Colors.white : KostHuntTheme.ink)),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: mine ? Colors.white : KostHuntTheme.ink)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : KostHuntTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.hint, required this.onSend});

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: hint))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}

void _showListingDetail(BuildContext context, ProductionStore store, KhUser user, KostListing listing) {
  final List<KostUnit> units = store.unitsForListing(listing.id);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Text(listing.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _StatusChip(label: listing.typeLabel),
                  _StatusChip(label: '${listing.campusDistanceKm.toStringAsFixed(1)} km dari kampus'),
                  if (listing.isPremiumActive) const _StatusChip(label: 'Premium / Iklan aktif'),
                ],
              ),
              const SizedBox(height: 10),
              Text('${listing.address}\n${listing.description}'),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: listing.facilities.map((String value) => Chip(label: Text(value))).toList()),
              const SizedBox(height: 10),
              _SectionTitle(title: 'Unit tersedia', trailing: '${units.length} unit'),
              for (final KostUnit unit in units)
                ListTile(
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text(unit.name),
                  subtitle: Text('${formatRupiah(unit.monthlyPrice)}/bulan - ${unit.status.name}'),
                  trailing: FilledButton(
                    onPressed: unit.status != UnitStatus.available
                        ? null
                        : () {
                            final Booking booking = store.createBooking(
                              customerUserId: user.id,
                              listingId: listing.id,
                              unitId: unit.id,
                              durationMonths: 1,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Booking ${booking.id} dibuat.')),
                            );
                          },
                    child: const Text('Booking'),
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  final Conversation conversation = store.openConversation(customerUserId: user.id, listingId: listing.id);
                  store.sendChatMessage(user.id, conversation.id, 'Halo, saya tertarik dengan ${listing.title}.');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat owner'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  store.createReport(
                    reporterUserId: user.id,
                    targetType: 'kost',
                    targetId: listing.id,
                    reason: 'Customer melaporkan listing untuk ditinjau admin.',
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report listing'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showCreateListingDialog(BuildContext context, ProductionStore store, KhUser user) {
  final TextEditingController title = TextEditingController();
  final TextEditingController city = TextEditingController(text: 'Yogyakarta');
  final TextEditingController area = TextEditingController(text: 'Seturan');
  final TextEditingController address = TextEditingController();
  final TextEditingController price = TextEditingController(text: '1500000');
  final TextEditingController campusDistance = TextEditingController(text: '1.0');
  PropertyType selectedType = PropertyType.kost;
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Tambah listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<PropertyType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe properti'),
                items: const <DropdownMenuItem<PropertyType>>[
                  DropdownMenuItem<PropertyType>(value: PropertyType.kost, child: Text('Kost')),
                  DropdownMenuItem<PropertyType>(value: PropertyType.kontrakan, child: Text('Kontrakan')),
                ],
                onChanged: (PropertyType? value) {
                  selectedType = value ?? PropertyType.kost;
                },
              ),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Nama properti')),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'Kota')),
              TextField(controller: area, decoration: const InputDecoration(labelText: 'Area')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Alamat')),
              TextField(controller: campusDistance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jarak ke kampus terdekat (km)')),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga bulanan')),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              store.createListing(
                ownerUserId: user.id,
                title: title.text,
                city: city.text,
                area: area.text,
                address: address.text,
                monthlyPrice: int.tryParse(price.text) ?? 0,
                propertyType: selectedType,
                campusDistanceKm: double.tryParse(campusDistance.text.replaceAll(',', '.')) ?? 1.0,
              );
              Navigator.pop(context);
            },
            child: const Text('Publish'),
          ),
        ],
      );
    },
  );
}

void _showRefundDialog(BuildContext context, ProductionStore store, KhUser user, Payment payment) {
  final TextEditingController reason = TextEditingController(text: 'Customer meminta refund karena batal sewa.');
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Minta refund'),
      content: TextField(controller: reason, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Alasan')),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            store.requestRefund(user.id, payment.id, reason.text);
            Navigator.pop(context);
          },
          child: const Text('Kirim'),
        ),
      ],
    ),
  );
}

void _showReviewDialog(BuildContext context, ProductionStore store, KhUser user, Booking booking) {
  final TextEditingController body = TextEditingController(text: 'Kost bersih dan owner responsif.');
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Review kost'),
      content: TextField(controller: body, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Review')),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            store.addReview(customerUserId: user.id, bookingId: booking.id, rating: 5, body: body.text);
            Navigator.pop(context);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

void _showInfo(BuildContext context, String title, String body) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}

String _bookingLabel(BookingStatus status) {
  switch (status) {
    case BookingStatus.pendingPayment:
      return 'pending_payment';
    case BookingStatus.paid:
      return 'paid';
    case BookingStatus.confirmed:
      return 'confirmed';
    case BookingStatus.checkedIn:
      return 'checked_in';
    case BookingStatus.completed:
      return 'completed';
    case BookingStatus.cancelled:
      return 'cancelled';
    case BookingStatus.refunded:
      return 'refunded';
    case BookingStatus.disputed:
      return 'disputed';
    case BookingStatus.draft:
      return 'draft';
  }
}

String _paymentLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.waitingPayment:
      return 'waiting_payment';
    case PaymentStatus.partiallyRefunded:
      return 'partially_refunded';
    default:
      return status.name;
  }
}

Payment? _paymentForBooking(ProductionStore store, String bookingId) {
  for (final Payment payment in store.payments) {
    if (payment.bookingId == bookingId) {
      return payment;
    }
  }
  return null;
}
