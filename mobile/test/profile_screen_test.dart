import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymbuddy/services/auth_provider.dart';
import 'package:gymbuddy/screens/profile/profile_screen.dart';

/// Create a test AuthState with mock user data
AuthState createTestAuthState({
  bool isLoggedIn = true,
  String role = 'member',
  String nama = 'Siti Test',
  String email = 'test@test.com',
}) {
  return AuthState(
    isLoggedIn: isLoggedIn,
    user: {
      'nama': nama,
      'email': email,
      'role': role,
    },
    token: 'test-token',
  );
}

/// Simple notifier that extends AuthNotifier with no-op API methods
class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(AuthState state) : super.test(state);

  @override
  Future<void> logout() async {
    state = const AuthState();
  }

  @override
  Future<void> refreshUser() async {}

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<bool> register(Map<String, dynamic> data) async => true;
}

/// Helper to create ProfileScreen with a given auth state
Widget createProfileScreen(AuthState authState) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => TestAuthNotifier(authState)),
    ],
    child: MaterialApp(
      home: ProfileScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileScreen', () {
    testWidgets('has back arrow button', (tester) async {
      await tester.pumpWidget(createProfileScreen(createTestAuthState()));

      expect(find.byIcon(Icons.arrow_back), findsWidgets);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('has correct AppBar title', (tester) async {
      await tester.pumpWidget(createProfileScreen(createTestAuthState()));

      expect(find.text('Profil'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows role badge for member', (tester) async {
      await tester.pumpWidget(createProfileScreen(
        createTestAuthState(role: 'member', nama: 'Member Test'),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Member'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows role badge for admin', (tester) async {
      await tester.pumpWidget(createProfileScreen(
        createTestAuthState(role: 'admin', nama: 'Admin Test'),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Admin'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows role badge for trainer', (tester) async {
      await tester.pumpWidget(createProfileScreen(
        createTestAuthState(role: 'trainer', nama: 'Trainer Test'),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Trainer'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows user name after loading', (tester) async {
      await tester.pumpWidget(createProfileScreen(
        createTestAuthState(nama: 'Budi Test'),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Budi Test'), findsWidgets);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(createProfileScreen(createTestAuthState()));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Keluar'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('has edit button when not editing', (tester) async {
      await tester.pumpWidget(createProfileScreen(createTestAuthState()));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.edit), findsWidgets);

      await tester.pump(const Duration(seconds: 10));
    });
  });
}
