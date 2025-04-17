import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brickify/screens/import_video_screen.dart';
import 'package:brickify/theme/app_icons.dart';

void main() {
  group('ImportVideoScreen Tests', () {
    testWidgets('Rendu de base avec les options d\'importation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
        ),
      );

      // Vérification du titre
      expect(find.text('Importer une vidéo'), findsOneWidget);
      expect(find.text('Choisissez une méthode d\'importation'), findsOneWidget);

      // Vérification des options
      expect(find.text('Filmer une vidéo'), findsOneWidget);
      expect(find.text('Choisir depuis la galerie'), findsOneWidget);

      // Vérification des descriptions
      expect(find.text('Utilisez l\'appareil photo pour filmer (max 5 min)'), findsOneWidget);
      expect(find.text('Sélectionnez une vidéo existante (max 5 min)'), findsOneWidget);

      // Vérification des icônes
      expect(find.byIcon(AppIcons.camera), findsOneWidget);
      expect(find.byIcon(AppIcons.video), findsOneWidget);
    });

    testWidgets('Bouton retour présent dans l\'AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
        ),
      );

      expect(find.byType(AppBackButton), findsOneWidget);
    });

    testWidgets('Options d\'importation sont cliquables', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
        ),
      );

      // Vérification que les options sont bien des boutons interactifs
      expect(find.byType(InteractiveButton), findsNWidgets(2));
    });

    testWidgets('Style visuel cohérent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
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
          home: ImportVideoScreen(),
        ),
      );

      // Simulation d'un clic sur une option
      await tester.tap(find.text('Filmer une vidéo'));

      // Vérification de l'indicateur de chargement
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Affichage de la vidéo sélectionnée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
        ),
      );

      // Simulation de la sélection d'une vidéo
      final mockVideo = XFile('test_video.mp4');
      final state = tester.state<ImportVideoScreenState>(find.byType(ImportVideoScreen));
      state.setState(() {
        state._selectedVideo = mockVideo;
      });

      // Vérification de l'affichage de la vidéo sélectionnée
      expect(find.text('Vidéo sélectionnée'), findsOneWidget);
      expect(find.text('test_video.mp4'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Créer le modèle 3D'), findsOneWidget);
    });

    testWidgets('Suppression de la vidéo sélectionnée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
        ),
      );

      // Simulation de la sélection d'une vidéo
      final mockVideo = XFile('test_video.mp4');
      final state = tester.state<ImportVideoScreenState>(find.byType(ImportVideoScreen));
      state.setState(() {
        state._selectedVideo = mockVideo;
      });

      // Vérification de l'affichage initial
      expect(find.text('Vidéo sélectionnée'), findsOneWidget);

      // Simulation de la suppression
      await tester.tap(find.byIcon(AppIcons.delete));

      // Vérification de la suppression
      expect(find.text('Vidéo sélectionnée'), findsNothing);
    });

    testWidgets('Format de la durée de la vidéo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportVideoScreen(),
        ),
      );

      final state = tester.state<ImportVideoScreenState>(find.byType(ImportVideoScreen));
      
      // Test avec différentes durées
      expect(state._formatDuration(const Duration(minutes: 2, seconds: 30)), '02:30');
      expect(state._formatDuration(const Duration(minutes: 0, seconds: 45)), '00:45');
      expect(state._formatDuration(const Duration(minutes: 5, seconds: 0)), '05:00');
      expect(state._formatDuration(null), '');
    });
  });
} 