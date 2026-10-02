import 'package:badelha/core/theme/app_theme.dart';
import 'package:badelha/features/auth/data/auth_repository.dart';
import 'package:badelha/features/auth/presentation/login_screen.dart';
import 'package:badelha/features/auth/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// مثال على فائدة Repository Pattern: الواجهة تُختبر بدون خادم.
class FakeAuthRepository implements AuthRepository {
  final sent = <String>[];
  final verified = <(String, String)>[];

  @override
  Future<void> sendEmailCode(String email) async => sent.add(email);

  @override
  Future<void> verifyEmailCode(String email, String code) async =>
      verified.add((email, code));

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('sends code then verifies (accepts Arabic-Indic digits)', (tester) async {
    final fake = FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(textDirection: TextDirection.rtl, child: LoginScreen()),
      ),
    ));

    // بريد غير صالح لا يُرسل
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('أرسل رمز الدخول'));
    await tester.pump();
    expect(fake.sent, isEmpty);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.tap(find.text('أرسل رمز الدخول'));
    await tester.pumpAndSettle();
    expect(fake.sent, ['user@example.com']);

    // يظهر حقل الرمز، والإرسال تلقائي عند اكتمال 6 أرقام
    await tester.enterText(find.byType(TextField).last, '١٢٣٤٥٦');
    await tester.pumpAndSettle();
    expect(fake.verified.single, ('user@example.com', '123456'));
  });
}
