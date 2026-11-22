import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:hps_connect/data/backend.dart';
import 'package:hps_connect/data/demo_backend.dart';
import 'package:hps_connect/main.dart';
import 'package:hps_connect/models/user_role.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  await tester.pumpWidget(
    HpsConnectApp(backend: DemoBackend(), splashDuration: Duration.zero),
  );
  await tester.pumpAndSettle();
  expect(find.text('HPS CONNECT'), findsOneWidget);
  await tester.tap(find.text('Login'));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  expect(find.text('Select Your Role'), findsOneWidget);
}

void main() {
  test('ছয়টি রোল আছে এবং id দিয়ে খুঁজে পাওয়া যায়', () {
    expect(UserRole.values.length, 6);
    for (final r in UserRole.values) {
      expect(UserRole.fromId(r.id), r);
    }
    expect(UserRole.fromId('unknown'), UserRole.teacher);
    expect(UserRole.superAdmin.canManageUsers, isTrue);
    expect(UserRole.teacher.canPublishNotices, isFalse);
  });

  test('User ID থেকে ইমেইল', () {
    expect(normalizeLoginId(' Saiful '), 'saiful@$kUserIdEmailDomain');
    expect(normalizeLoginId('a@b.com'), 'a@b.com');
  });

  testWidgets('ডেমো: শিক্ষক হিসেবে নোটিশ পড়ে স্বীকৃতি দেওয়া', (tester) async {
    await _login(tester);
    await tester.tap(find.text('Teacher/Staff'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Assalamu Alaikum'), findsOneWidget);
    expect(find.text('Leave Application'), findsOneWidget);

    await tester.tap(find.text('Notice Board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staff Meeting – This Saturday'));
    await tester.pumpAndSettle();
    expect(find.text('Viewed: 112 / 150'), findsOneWidget);
    await tester.tap(find.text('I have read and understood'));
    await tester.pumpAndSettle();
    expect(find.text('Acknowledged'), findsOneWidget);
  });

  testWidgets('ডেমো: চ্যাট, টাস্ক ও মিটিং স্ক্রিন', (tester) async {
    await _login(tester);
    await tester.tap(find.text('Teacher/Staff'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat').last);
    await tester.pumpAndSettle();
    expect(find.text('High Section Team'), findsOneWidget);
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Office'), findsNothing);

    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    expect(find.text('Prepare sports participant list'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meetings'));
    await tester.pumpAndSettle();
    expect(find.text('General Staff Meeting'), findsOneWidget);
  });

  testWidgets('ডেমো: প্রিন্সিপাল ড্যাশবোর্ড', (tester) async {
    await _login(tester);
    await tester.tap(find.text('Principal'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Principal Dashboard'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('Quick Overview'), findsOneWidget);
    expect(find.text('Send Notice'), findsOneWidget);
  });
}
