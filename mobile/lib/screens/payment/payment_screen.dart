import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final String sessionTitle;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.sessionTitle,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _api = ApiService();
  bool _isProcessing = false;
  String? _error;
  String? _paymentUrl;
  bool _paymentDone = false;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    setState(() => _isProcessing = true);
    final res = await _api.createPayment(widget.bookingId);
    if (res['data'] != null) {
      final data = res['data'];
      setState(() {
        _paymentUrl = data['redirect_url'];
        _isProcessing = false;
      });
    } else {
      setState(() { _error = res['message'] ?? 'Gagal memproses pembayaran'; _isProcessing = false; });
    }
  }

  Future<void> _openPaymentUrl() async {
    if (_paymentUrl == null) return;
    final uri = Uri.parse(_paymentUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (!mounted) return;
      // Refresh booking status from backend
      await _api.getPaymentStatus(widget.bookingId);
      if (!mounted) return;
      // After returning from in-app payment page, check payment status
      setState(() => _paymentDone = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran diproses. Silakan cek status booking Anda.'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka halaman pembayaran'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatRupiah(dynamic amount) {
    final value = (amount is int || amount is double) ? amount : double.tryParse(amount.toString()) ?? 0;
    return NumberFormat('#,###', 'id_ID').format((value as num).toInt());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: _isProcessing
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memproses pembayaran...'),
            ],
          ))
        : _error != null
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _initPayment, child: const Text('Coba Lagi')),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text('Detail Pembayaran', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _detailRow('Booking', '#${widget.bookingId}'),
                          _detailRow('Sesi', widget.sessionTitle),
                          const Divider(height: 24),
                          _detailRow('Total', 'Rp${_formatRupiah(widget.amount)}', isBold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_paymentDone && _paymentUrl != null)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _openPaymentUrl,
                            icon: const Icon(Icons.payment),
                            label: const Text('Bayar Sekarang via Midtrans'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda akan diarahkan ke halaman pembayaran Midtrans.\nPilih metode pembayaran dan selesaikan pembayaran.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Bayar Nanti'),
                        ),
                      ],
                    ),
                  if (_paymentDone)
                    Column(
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
                        const SizedBox(height: 16),
                        Text(
                          'Pembayaran telah diproses!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cek status booking Anda untuk konfirmasi.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Kembali ke Booking'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }
}
