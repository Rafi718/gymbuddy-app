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
  List<dynamic> _myBookings = [];
  bool _loading = true;
  String? _error;
  Set<int> _bookedSessionIds = {};

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
      final results = await Future.wait([
        _api.getSessions(limit: 50, search: search),
        _api.getMyBookings(),
      ]);
      final sessions = (results[0]['data'] as List?) ?? [];
      final bookings = (results[1]['data'] as List?) ?? [];
      setState(() {
        _sessions = sessions;
        _myBookings = bookings;
        _bookedSessionIds = bookings
            .map<int?>((b) => b['session_id'] as int?)
            .where((id) => id != null)
            .cast<int>()
            .toSet();
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Gagal memuat data');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredSessions {
    if (_sessions.isEmpty) return [];
    final minDate = DateTime(2026, 6, 27);
    final seenTrainers = <int>{};
    final query = _searchController.text.toLowerCase();

    var result = _sessions.where((s) {
      final start = DateTime.tryParse(s['start_time'] ?? '') ?? DateTime.now();
      return start.isAfter(minDate) || start.isAtSameMomentAs(minDate);
    }).toList();

    result.sort((a, b) {
      final aTime = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    result = result.where((s) {
      final name = (s['trainer_name'] ?? '').toString().toLowerCase();
      final title = (s['title'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty && !name.contains(query) && !title.contains(query)) {
        return false;
      }
      final trainerId = s['trainer_id'] as int?;
      if (trainerId != null && seenTrainers.contains(trainerId)) return false;
      if (trainerId != null) seenTrainers.add(trainerId);
      return true;
    }).toList();

    return result;
  }

  Future<void> _bookSession(int sessionId) async {
    if (_bookedSessionIds.contains(sessionId)) return;
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
          await _loadData();
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

  void _showTrainerSessions(int trainerId, String trainerName) {
    final trainerSessions = _sessions
        .where((s) => s['trainer_id'] == trainerId)
        .toList();
    trainerSessions.sort((a, b) {
      final aTime = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sesi dari $trainerName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trainerSessions.length} sesi tersedia',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: trainerSessions.length,
                      itemBuilder: (context, index) {
                        final session = trainerSessions[index];
                        final sid = session['id'] as int? ?? 0;
                        final isBooked = _bookedSessionIds.contains(sid);
                        final st = session['start_time'] != null
                            ? DateFormat('dd MMM yyyy, HH:mm')
                                .format(DateTime.parse(session['start_time']))
                            : '--';
                        final price = session['price'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session['title'] ?? 'Sesi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(st, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    const Spacer(),
                                    Text(
                                      'Rp${NumberFormat('#,###', 'id_ID').format(num.tryParse(price.toString()) ?? 0)}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isBooked
                                        ? null
                                        : () async {
                                            Navigator.pop(ctx);
                                            await _bookSession(sid);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isBooked
                                          ? Colors.green[100]
                                          : Theme.of(context).colorScheme.primary,
                                      foregroundColor: isBooked ? Colors.green[700] : Colors.white,
                                      disabledBackgroundColor: Colors.green[100],
                                      disabledForegroundColor: Colors.green[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(isBooked ? 'Booked ✓' : 'Ambil Sesi'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

    final filtered = _filteredSessions;

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Text(
            'Sesi Tersedia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
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
            ...filtered.map((session) => _buildSessionCard(session, theme)),
        ],
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
    final trainerPhoto = session['trainer_photo'] ?? '';
    final sessionId = session['id'] as int? ?? 0;
    final isBooked = _bookedSessionIds.contains(sessionId);

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
                          imageUrl: '${ApiService.photoBaseUrl}/$trainerPhoto',
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
                            child: Center(child: Text(trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'T', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'T', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))),
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
                onPressed: isBooked
                    ? null
                    : () {
                        final trainerId = session['trainer_id'] as int? ?? 0;
                        _showTrainerSessions(trainerId, trainerName);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBooked
                      ? Colors.green[100]
                      : theme.colorScheme.primary,
                  foregroundColor: isBooked ? Colors.green[700] : Colors.white,
                  disabledBackgroundColor: Colors.green[100],
                  disabledForegroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isBooked ? 'Booked ✓' : 'Cek Sesi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
