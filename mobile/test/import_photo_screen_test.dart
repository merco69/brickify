import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brickify/screens/import_photo_screen.dart';
import 'package:brickify/theme/app_icons.dart';

void main() {
  group('ImportPhotoScreen Tests', () {
    testWidgets('Rendu de base avec les options d\'importation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
        ),
      );

      // Vérification du titre
      expect(find.text('Importer une photo'), findsOneWidget);
      expect(find.text('Choisissez une méthode d\'importation'), findsOneWidget);

      // Vérification des options
      expect(find.text('Prendre une photo'), findsOneWidget);
      expect(find.text('Choisir depuis la galerie'), findsOneWidget);

      // Vérification des descriptions
      expect(find.text('Utilisez l\'appareil photo pour capturer une image'), findsOneWidget);
      expect(find.text('Sélectionnez une photo existante'), findsOneWidget);

      // Vérification des icônes
      expect(find.byIcon(AppIcons.camera), findsOneWidget);
      expect(find.byIcon(AppIcons.image), findsOneWidget);
    });

    testWidgets('Bouton retour présent dans l\'AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
        ),
      );

      expect(find.byType(AppBackButton), findsOneWidget);
    });

    testWidgets('Options d\'importation sont cliquables', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
        ),
      );

      // Vérification que les options sont bien des boutons interactifs
      expect(find.byType(InteractiveButton), findsNWidgets(2));
    });

    testWidgets('Style visuel cohérent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
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

    testWidgets('Affichage de l\'indicateur de chargement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
        ),
      );

      // Simulation d'un clic sur une option
      await tester.tap(find.text('Prendre une photo'));

      // Vérification de l'indicateur de chargement
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Affichage de la photo sélectionnée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
        ),
      );

      // Simulation de la sélection d'une photo
      final mockImage = XFile('test_image.jpg');
      final state = tester.state<ImportPhotoScreenState>(find.byType(ImportPhotoScreen));
      state.setState(() {
        state._selectedImage = mockImage;
      });

      // Vérification de l'affichage de la photo sélectionnée
      expect(find.text('Photo sélectionnée'), findsOneWidget);
      expect(find.text('test_image.jpg'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Créer le modèle 3D'), findsOneWidget);
    });

    testWidgets('Suppression de la photo sélectionnée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportPhotoScreen(),
        ),
      );

      // Simulation de la sélection d'une photo
      final mockImage = XFile('test_image.jpg');
      final state = tester.state<ImportPhotoScreenState>(find.byType(ImportPhotoScreen));
      state.setState(() {
        state._selectedImage = mockImage;
      });

      // Vérification de l'affichage initial
      expect(find.text('Photo sélectionnée'), findsOneWidget);

      // Simulation de la suppression
      await tester.tap(find.byIcon(AppIcons.delete));

      // Vérification de la suppression
      expect(find.text('Photo sélectionnée'), findsNothing);
    });
  });
} 