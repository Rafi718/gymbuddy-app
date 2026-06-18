import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymbuddy/main.dart';

void main() {
  testWidgets('App loads GymBuddy', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: GymBuddyApp()));
    expect(find.text('GymBuddy'), findsOneWidget);
  });
}
