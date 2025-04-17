import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickify/screens/import_model_screen.dart';
import 'package:brickify/theme/app_icons.dart';

void main() {
  group('ImportModelScreen Tests', () {
    testWidgets('Rendu de base avec toutes les options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModelScreen(),
        ),
      );

      // Vérification du titre
      expect(find.text('Importer un modèle'), findsOneWidget);
      expect(find.text('Choisissez votre méthode d\'importation'), findsOneWidget);

      // Vérification des options d'importation
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Vidéo'), findsOneWidget);
      expect(find.text('Modèle 3D'), findsOneWidget);

      // Vérification des descriptions
      expect(find.text('Importez une photo pour créer un modèle 3D'), findsOneWidget);
      expect(find.text('Importez une vidéo pour créer un modèle 3D'), findsOneWidget);
      expect(find.text('Importez un fichier 3D existant'), findsOneWidget);

      // Vérification des icônes
      expect(find.byIcon(AppIcons.image), findsOneWidget);
      expect(find.byIcon(AppIcons.video), findsOneWidget);
      expect(find.byIcon(AppIcons.model3d), findsOneWidget);
    });

    testWidgets('Bouton retour présent dans l\'AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModelScreen(),
        ),
      );

      expect(find.byType(AppBackButton), findsOneWidget);
    });

    testWidgets('Options d\'importation sont cliquables', (WidgetTester tester) async {
      bool photoTapped = false;
      bool videoTapped = false;
      bool modelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ImportModelScreen(),
        ),
      );

      // Simulation des clics
      await tester.tap(find.text('Photo'));
      await tester.tap(find.text('Vidéo'));
      await tester.tap(find.text('Modèle 3D'));

      // Vérification que les options sont bien des boutons interactifs
      expect(find.byType(InteractiveButton), findsNWidgets(3));
    });

    testWidgets('Style visuel cohérent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModelScreen(),
        ),
      );

      // Vérification du style des options
      final options = tester.widgetList(find.byType(Container));
      for (var option in options) {
        expect(option.decoration, isA<BoxDecoration>());
        final decoration = option.decoration as BoxDecoration;
        expect(decoration.borderRadius, isA<BorderRadius>());
      }
    });
  });
} 