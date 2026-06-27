import 'package:flutter_test/flutter_test.dart';
import 'package:ecole_plus_mobile/app/app.dart';

void main() {
  testWidgets('ECOLE+ app démarre sans erreur', (WidgetTester tester) async {
    // Lancer l'application
    await tester.pumpWidget(const EcolePlusApp());

    // Vérifier que l'écran de connexion est présent
    expect(find.text('Connexion'), findsOneWidget);
  });
}
