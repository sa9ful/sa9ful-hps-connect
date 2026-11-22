import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:hps_connect/main.dart';
import 'package:hps_connect/models/user_role.dart';

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

  testWidgets('Firebase না থাকলে সেটআপ স্ক্রিন দেখায়', (tester) async {
    await tester.pumpWidget(const HpsConnectApp(firebaseError: 'no config'));
    expect(find.text('Firebase সেটআপ বাকি'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
