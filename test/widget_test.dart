import 'package:flutter_test/flutter_test.dart';
import 'package:sdkdemo/main.dart';

void main() {
  testWidgets('SDK demo smoke', (WidgetTester tester) async {
    await tester.pumpWidget(const SdkDemoApp());
    await tester.pump();
    expect(find.text('手表 SDK Demo'), findsOneWidget);
    expect(find.text('扫描设备'), findsOneWidget);
  });
}
