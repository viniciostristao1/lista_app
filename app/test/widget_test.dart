// Teste mínimo enquanto o app está no esqueleto.
// A tela real (main.dart) inicializa o Firebase, então não é testável aqui sem
// mock — os testes de verdade virão junto com a Fase 1 (widgets puros + mocks).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sanity: o harness de teste roda', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('ok'))),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
