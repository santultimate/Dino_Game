import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_game/main.dart'; // adapte si ton nom de projet est différent

void main() {
  testWidgets('Affichage du bouton Play', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DinoGame()));

    // Vérifie que le bouton Play est présent
    expect(find.text("▶️ Play"), findsOneWidget);

    // Appuie dessus
    await tester.tap(find.text("▶️ Play"));
    await tester.pump();

    // Après avoir cliqué, le bouton devrait être désactivé
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
  });
}
