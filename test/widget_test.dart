import 'package:flutter_test/flutter_test.dart';
import 'package:smart_clinic_app/main.dart';

void main() {

  testWidgets(
    'MedLink login screen test',
        (WidgetTester tester) async {

      await tester.pumpWidget(
        const SmartClinicApp(),
      );

      expect(
        find.text('MedLink'),
        findsOneWidget,
      );

      expect(
        find.text('Login'),
        findsOneWidget,
      );

      expect(
        find.text('Login to your account'),
        findsOneWidget,
      );
    },
  );
}