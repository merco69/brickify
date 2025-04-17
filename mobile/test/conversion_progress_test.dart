import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickify/widgets/conversion_progress.dart';
import 'package:brickify/services/model_conversion_service.dart';

void main() {
  group('ConversionProgressWidget Tests', () {
    testWidgets('Affichage de l\'état en attente', (WidgetTester tester) async {
      final progress = ConversionProgress(
        progress: 0.0,
        message: 'Préparation de la conversion...',
        status: ConversionStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(progress: progress),
          ),
        ),
      );

      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('Préparation de la conversion...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Annuler'), findsNothing);
    });

    testWidgets('Affichage de l\'état en cours', (WidgetTester tester) async {
      final progress = ConversionProgress(
        progress: 0.5,
        message: 'Conversion en cours...',
        status: ConversionStatus.processing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(progress: progress),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Conversion en cours...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('Affichage de l\'état terminé', (WidgetTester tester) async {
      final progress = ConversionProgress(
        progress: 1.0,
        message: 'Conversion terminée',
        status: ConversionStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(progress: progress),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Conversion terminée'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Annuler'), findsNothing);
    });

    testWidgets('Affichage de l\'état échoué', (WidgetTester tester) async {
      final progress = ConversionProgress(
        progress: 0.0,
        message: 'Erreur lors de la conversion',
        status: ConversionStatus.failed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(progress: progress),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Erreur lors de la conversion'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Annuler'), findsNothing);
    });

    testWidgets('Bouton d\'annulation masqué', (WidgetTester tester) async {
      final progress = ConversionProgress(
        progress: 0.5,
        message: 'Conversion en cours...',
        status: ConversionStatus.processing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(
              progress: progress,
              showCancelButton: false,
            ),
          ),
        ),
      );

      expect(find.text('Annuler'), findsNothing);
    });

    testWidgets('Appel du callback d\'annulation', (WidgetTester tester) async {
      bool cancelCalled = false;
      final progress = ConversionProgress(
        progress: 0.5,
        message: 'Conversion en cours...',
        status: ConversionStatus.processing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(
              progress: progress,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Annuler'));
      expect(cancelCalled, true);
    });

    testWidgets('Style visuel cohérent', (WidgetTester tester) async {
      final progress = ConversionProgress(
        progress: 0.5,
        message: 'Conversion en cours...',
        status: ConversionStatus.processing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversionProgressWidget(progress: progress),
          ),
        ),
      );

      // Vérifier le conteneur principal
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(LinearProgressIndicator),
          matching: find.byType(Container),
        ),
      );
      expect(container.padding, const EdgeInsets.all(16));
      expect(container.decoration, isA<BoxDecoration>());

      // Vérifier la barre de progression
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5);
      expect(progressIndicator.minHeight, 8);
    });
  });
} 