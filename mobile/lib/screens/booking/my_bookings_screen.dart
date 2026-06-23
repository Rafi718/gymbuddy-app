import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  final _api = ApiService();
  List<dynamic> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getMyBookings();
      setState(() {
        _bookings = (res['data'] as List?) ?? [];
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Gagal memuat data booking');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      final res = await _api.cancelBooking(bookingId);
      if (res['success'] != false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking dibatalkan'),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
        _loadBookings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal membatalkan'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membatalkan booking'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _payBooking(int bookingId) async {
    if (!mounted) return;
    // Navigate to payment screen with booking info
    final booking = _bookings.firstWhere(
      (b) => (b['booking_id'] ?? b['id']) == bookingId,
      orElse: () => ({}),
    );
    if (booking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking tidak ditemukan'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final payBookingId = booking['booking_id'] ?? bookingId;
    final title = Uri.encodeComponent(booking['session_title'] ?? 'Sesi Latihan');
    final amount = double.tryParse((booking['payment_amount'] ?? 0).toString()) ?? 0;
    
    final result = await context.push<bool>('/payment/$payBookingId?title=$title&amount=$amount');
    
    // Refresh bookings after payment attempt
    if (result == true) {
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Saya'),          leading: IconButton(
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
      body: _buildContent(theme),
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
              onPressed: _loadBookings,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada booking',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Cari trainer dan ambil sesi untuk memulai',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    final activeBookings = _bookings.where((b) =>
      b['status'] == 'Pending' || b['status'] == 'Confirmed'
    ).toList();

    final pastBookings = _bookings.where((b) =>
      b['status'] == 'Cancel' || b['status'] == 'Completed'
    ).toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats cards
          Row(
            children: [
              _buildStatCard('Aktif', activeBookings.length, Colors.green, theme),
              const SizedBox(width: 12),
              _buildStatCard('Menunggu', _bookings.where((b) => b['payment_status'] == 'pending').length, Colors.orange, theme),
              const SizedBox(width: 12),
              _buildStatCard('Lunas', _bookings.where((b) => b['payment_status'] == 'settlement').length, Colors.blue, theme),
            ],
          ),
          const SizedBox(height: 24),

          // Active bookings
          if (activeBookings.isNotEmpty) ...[
            Text(
              'Booking Aktif',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...activeBookings.map((b) => _buildBookingCard(b, theme, isActive: true)),
            const SizedBox(height: 24),
          ],

          // Past bookings
          if (pastBookings.isNotEmpty) ...[
            Text(
              'Riwayat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...pastBookings.map((b) => _buildBookingCard(b, theme, isActive: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, MaterialColor color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color[200]!),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking, ThemeData theme, {required bool isActive}) {
    final title = booking['session_title'] ?? 'Sesi Latihan';
    final startTime = booking['start_time'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(booking['start_time']))
        : '--';
    final trainerName = booking['trainer_name'] ?? 'Trainer';
    final trainerPhoto = booking['trainer_photo'] ?? '';
    final status = booking['status'] ?? '';
    final paymentStatus = booking['payment_status'] ?? '';
    final paymentAmount = booking['payment_amount'] ?? 0;
    final bookingId = booking['booking_id'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(status, paymentStatus),
              ],
            ),
            const SizedBox(height: 8),

            // Details with trainer photo
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: trainerPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: '${ApiService.baseUrl.replaceAll('/api', '')}/$trainerPhoto',
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(width: 22, height: 22, color: Colors.grey[200]),
                          errorWidget: (ctx, url, err) => Container(
                            width: 22,
                            height: 22,
                            color: theme.colorScheme.primary.withAlpha(25),
                            child: Center(
                              child: Text(trainerName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                        )
                      : Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(trainerName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Text(trainerName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(startTime, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),

            // Amount
            Text(
              'Rp${NumberFormat('#,###', 'id_ID').format(num.tryParse(paymentAmount.toString()) ?? 0)}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            // Actions for active bookings
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (status == 'Pending' && paymentStatus != 'settlement')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _payBooking(bookingId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Bayar', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  if (status == 'Pending')
                    const SizedBox(width: 8),
                  if (status == 'Pending')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelBooking(bookingId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Batalkan', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String paymentStatus) {
    Color bgColor;
    Color textColor;
    String label;

    if (paymentStatus == 'settlement') {
      bgColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      label = 'LUNAS';
    } else if (status == 'Confirmed') {
      bgColor = Colors.blue[50]!;
      textColor = Colors.blue[700]!;
      label = 'KONFIRM';
    } else if (status == 'Cancel') {
      bgColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      label = 'BATAL';
    } else {
      bgColor = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
