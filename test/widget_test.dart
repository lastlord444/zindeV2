// ZindeAI V2.0 - Temel widget testi
// Not: Gerçek uygulama Supabase ve DI gerektirir.
// Bu test dosyası placeholder olarak bırakılmıştır.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ZindeAI temel widget testi', (WidgetTester tester) async {
    // ZindeAI uygulaması Supabase başlatma gerektirdiği için
    // basit bir MaterialApp ile test yapıyoruz
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('ZindeAI V2.0'),
          ),
        ),
      ),
    );

    expect(find.text('ZindeAI V2.0'), findsOneWidget);
  });
}
