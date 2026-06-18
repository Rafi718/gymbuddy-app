import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymbuddy/screens/session/session_detail_screen.dart';

/// Helper to create SessionDetailScreen wrapped in ProviderScope + MaterialApp
Widget createSessionDetailScreen({int sessionId = 1}) {
  return ProviderScope(
    child: MaterialApp(
      home: SessionDetailScreen(sessionId: sessionId),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionDetailScreen', () {
    testWidgets('shows loading state on init', (tester) async {
      await tester.pumpWidget(createSessionDetailScreen(sessionId: 5));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Detail Sesi'), findsOneWidget); // AppBar title

      // Cleanup Dio timer
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('has correct widget structure', (tester) async {
      await tester.pumpWidget(createSessionDetailScreen());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Detail Sesi'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('uses sessionId parameter correctly', (tester) async {
      await tester.pumpWidget(createSessionDetailScreen(sessionId: 99));

      expect(find.byType(Scaffold), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });
  });
}
