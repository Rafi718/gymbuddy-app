import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymbuddy/screens/payment/payment_screen.dart';

/// Helper to create a PaymentScreen wrapped in ProviderScope + MaterialApp
Widget createPaymentScreen({
  int bookingId = 1,
  String sessionTitle = 'Sesi Latihan Test',
  double amount = 50000,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: PaymentScreen(
        bookingId: bookingId,
        sessionTitle: sessionTitle,
        amount: amount,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PaymentScreen', () {
    testWidgets('shows loading state on init', (tester) async {
      await tester.pumpWidget(createPaymentScreen());

      // Should show loading indicator and "Memproses pembayaran..." text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memproses pembayaran...'), findsOneWidget);
      expect(find.text('Pembayaran'), findsOneWidget); // AppBar title

      // Cleanup: let Dio's async timer expire
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('has correct widget structure', (tester) async {
      await tester.pumpWidget(createPaymentScreen(
        bookingId: 42,
        sessionTitle: 'Sesi Spesial',
        amount: 100000,
      ));

      // Should have a Scaffold and AppBar
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Pembayaran'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('initial state shows loading indicator', (tester) async {
      await tester.pumpWidget(createPaymentScreen());

      final finder = find.byType(CircularProgressIndicator);
      expect(finder, findsOneWidget);
      expect(find.text('Memproses pembayaran...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });
  });
}
