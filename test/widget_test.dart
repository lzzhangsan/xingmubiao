// This is a basic Flutter widget test for the 星目标 app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:xingmubiao/main.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';

void main() {
  testWidgets('星目标应用启动测试', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('星目标'), findsOneWidget);
    
    // Verify that the main screen is displayed.
    expect(find.byType(MainScreen), findsOneWidget);
    
    // Verify that navigation bar is present.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}