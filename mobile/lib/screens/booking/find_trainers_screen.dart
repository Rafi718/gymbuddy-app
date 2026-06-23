import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

class FindTrainersScreen extends ConsumerStatefulWidget {
  const FindTrainersScreen({super.key});

  @override
  ConsumerState<FindTrainersScreen> createState() => _FindTrainersScreenState();
}

class _FindTrainersScreenState extends ConsumerState<FindTrainersScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<dynamic> _sessions = [];
  List<dynamic> _trainers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? search}) async {
    setState(() => _loading = true);
    try {
      // Load both sessions and trainers in parallel
      final results = await Future.wait([
        _api.getSessions(limit: 20, search: search),
        _api.getTrainers(),
      ]);
      setState(() {
        _sessions = (results[0]['data'] as List?) ?? [];
        _trainers = (results[1]['data'] as List?) ?? [];
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Gagal memuat data');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _bookSession(int sessionId) async {
    try {
      final res = await _api.createBooking(sessionId);
      if (res['success'] == true || res['data'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking berhasil!'),
              backgroundColor: Colors.green[700],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal booking'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal booking. Coba lagi.'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Trainer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari sesi atau trainer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length > 2) {
                  _loadData(search: value);
                } else if (value.isEmpty) {
                  _loadData();
                }
              },
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Trainer Cards Section
          if (_trainers.isNotEmpty) ...[
            Text(
              'Personal Trainer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trainers.length,
                itemBuilder: (context, index) {
                  final trainer = _trainers[index];
                  return _buildTrainerCard(trainer, theme);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Sessions Section
          Text(
            'Sesi Tersedia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          if (_sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada sesi ditemukan',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._sessions.map((session) => _buildSessionCard(session, theme)),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(dynamic trainer, ThemeData theme) {
    final name = trainer['nama'] ?? 'Trainer';
    final foto = trainer['foto'] ?? '';
    final kota = trainer['kota'] ?? '';
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');

    // Gradient colors based on trainer index untuk variasi visual
    final gradients = [
      [const Color(0xFFE53935), const Color(0xFF1565C0)], // Red to Blue
      [const Color(0xFF43A047), const Color(0xFF1B5E20)], // Green
      [const Color(0xFFFF6F00), const Color(0xFFBF360C)], // Orange to Deep Orange
    ];
    final gradientIdx = name.hashCode % gradients.length;
    final gradientColors = gradients[gradientIdx];

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Photo with gradient fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: foto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: '$baseUrl/$foto',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (kota.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  kota,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(dynamic session, ThemeData theme) {
    final title = session['title'] ?? 'Sesi Latihan';
    final price = session['price'] ?? 0;
    final startTime = session['start_time'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(session['start_time']))
        : '--';
    final trainerName = session['trainer_name'] ?? 'Trainer';
    final trainerPhoto = session['trainer_photo'] ?? session['foto'] ?? '';
    final sessionId = session['id'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trainer photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: trainerPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: '${ApiService.baseUrl.replaceAll('/api', '')}/$trainerPhoto',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          ),
                          errorWidget: (ctx, url, err) => Container(
                            width: 56,
                            height: 56,
                            color: theme.colorScheme.primary.withAlpha(30),
                            child: Center(child: Text(trainerName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(trainerName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            trainerName,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp${NumberFormat('#,###', 'id_ID').format(num.tryParse(price.toString()) ?? 0)}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  startTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _bookSession(sessionId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ambil Sesi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
