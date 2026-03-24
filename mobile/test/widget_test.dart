import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavla_online/app/app.dart';

void main() {
  testWidgets('should render login screen when app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TavlaApp()));

    expect(find.text('Tavla Online'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
  });
}
