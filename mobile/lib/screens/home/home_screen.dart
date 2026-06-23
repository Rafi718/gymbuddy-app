import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ApiService();
  List<dynamic> _sessions = [];
  List<dynamic> _bookings = [];
  bool _loading = true;
  String _activeTab = 'sessions';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _api.getSessions(limit: 10);
      if (!mounted) return;
      setState(() {
        _sessions = (res['data'] as List?) ?? [];
      });
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _api.getMyBookings();
      if (!mounted) return;
      setState(() {
        _bookings = (res['data'] as List?) ?? [];
      });
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTabChanged(String tab) {
    setState(() => _activeTab = tab);
    if (tab == 'bookings' && _bookings.isEmpty) {
      _loadBookings();
    } else if (tab == 'sessions' && _sessions.isEmpty) {
      _loadSessions();
    }
  }

  Future<void> _refresh() async {
    if (_activeTab == 'sessions') {
      await _loadSessions();
    } else {
      await _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymBuddy'),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => _showProfileMenu(context, auth),
            )
          else
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login'),
            ),
        ],
      ),
      body: _buildBody(auth, theme),
      bottomNavigationBar: auth.isLoggedIn
          ? BottomNavigationBar(
              currentIndex: 0,
              onTap: (i) {
                // Gunakan go() untuk tab switch (ganti route, bukan push)
                if (i == 0 && ModalRoute.of(context)?.settings.name != '/') context.go('/');
                if (i == 1 && !auth.isTrainer && !auth.isAdmin) context.go('/find-trainers');
                if (i == 1 && auth.isTrainer) context.go('/my-bookings');
                if (i == 1 && auth.isAdmin) context.go('/admin');
                if (i == 2 && !auth.isTrainer) context.go('/my-bookings');
              },
              selectedItemColor: theme.colorScheme.primary,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                if (auth.isTrainer) ...[
                  const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Sesi'),
                  const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
                ] else if (auth.isAdmin) ...[
                  const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'),
                ] else ...[
                  const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
                  const BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Booking'),
                ],
              ],
            )
          : null,
    );
  }

  Widget _buildBody(AuthState auth, ThemeData theme) {
    if (!auth.isLoggedIn) {
      return _buildGuestView(theme);
    }
    return _buildMemberView(theme);
  }

  Widget _buildGuestView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GymBuddy',
              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Platform Fitness Purwokerto\nTemukan trainer terbaik untukmu!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('MASUK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Belum punya akun? Daftar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberView(ThemeData theme) {
    final items = _activeTab == 'sessions' ? _sessions : _bookings;
    final isEmpty = items.isEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Selamat Datang!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _activeTab == 'sessions'
                  ? 'Temukan sesi latihan terbaik untukmu'
                  : 'Kelola booking sesi latihanmu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Tabs
            Row(
              children: [
                _buildTab('Sesi Tersedia', 'sessions'),
                const SizedBox(width: 8),
                _buildTab('Booking Saya', 'bookings'),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _activeTab == 'sessions' ? 'Belum ada sesi tersedia' : 'Belum ada booking',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildItemCard(item, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, String tab) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => _onTabChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item, ThemeData theme) {
    final isSession = _activeTab == 'sessions';
    final title = isSession
        ? (item['title'] ?? 'Sesi Latihan')
        : (item['session_title'] ?? 'Booking');
    final price = isSession
        ? (item['price'] ?? 0)
        : (item['payment_amount'] ?? 0);
    final startTime = item['start_time'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['start_time']))
        : '--';
    final trainerName = item['trainer_name'] ?? 'Trainer';
    final trainerPhoto = item['trainer_photo'] ?? item['foto'] ?? '';
    final status = item['status'] ?? '';
    final paymentStatus = item['payment_status'] ?? '';
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isSession)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: paymentStatus == 'settlement'
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      paymentStatus == 'settlement' ? 'LUNAS' : 'MENUNGGU',
                      style: TextStyle(
                        color: paymentStatus == 'settlement'
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    'Rp${NumberFormat('#,###', 'id_ID').format(num.tryParse(price.toString()) ?? 0)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Trainer photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: trainerPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: '$baseUrl/$trainerPhoto',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                          errorWidget: (ctx, url, err) => Container(
                            width: 28,
                            height: 28,
                            color: theme.colorScheme.primary.withAlpha(25),
                            child: Center(
                              child: Text(
                                trainerName[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              trainerName[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Text(trainerName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (!isSession && status.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: status == 'Confirmed'
                          ? Colors.green[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Confirmed'
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 2),
                Text(startTime, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthState auth) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (auth.user?['nama'] ?? 'U').toString()[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(auth.user?['nama'] ?? 'User'),
              subtitle: Text(auth.user?['email'] ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Lihat Profil'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.pop(ctx);
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
