import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymbuddy/screens/booking/my_bookings_screen.dart';

/// Helper to create MyBookingsScreen wrapped in ProviderScope + MaterialApp
Widget createMyBookingsScreen() {
  return ProviderScope(
    child: MaterialApp(
      home: MyBookingsScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyBookingsScreen', () {
    testWidgets('shows loading state on init', (tester) async {
      await tester.pumpWidget(createMyBookingsScreen());

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Booking Saya'), findsOneWidget); // AppBar title

      // Cleanup Dio timer
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('has back arrow button', (tester) async {
      await tester.pumpWidget(createMyBookingsScreen());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('has correct widget structure', (tester) async {
      await tester.pumpWidget(createMyBookingsScreen());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Booking Saya'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });
  });
}
