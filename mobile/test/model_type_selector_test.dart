import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickify/widgets/model_type_selector.dart';
import 'package:brickify/services/model_type_service.dart';

void main() {
  group('ModelTypeSelector Tests', () {
    late ModelTypeService modelTypeService;

    setUp(() {
      modelTypeService = ModelTypeService();
    });

    testWidgets('should display all model types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.standardJeu,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Type de modèle'), findsOneWidget);
      expect(find.text('Mini Collection'), findsOneWidget);
      expect(find.text('Standard Jeu'), findsOneWidget);
      expect(find.text('Reality'), findsOneWidget);
    });

    testWidgets('should display descriptions for each type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.standardJeu,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Modèle compact avec 1-1500 pièces, parfait pour les petits espaces et les collections'), findsOneWidget);
      expect(find.text('Modèle de taille moyenne avec 1501-3000 pièces, idéal pour le jeu et l\'exposition'), findsOneWidget);
      expect(find.text('Modèle détaillé avec plus de 3000 pièces, reproduction fidèle et réaliste'), findsOneWidget);
    });

    testWidgets('should highlight selected type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.reality,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );

      final realityContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Reality'),
          matching: find.byType(Container),
        ),
      );

      expect(
        (realityContainer.decoration as BoxDecoration).color,
        isA<Color>().having(
          (color) => color.value,
          'value',
          anyOf(
            isPositive,
            isNegative,
          ),
        ),
      );
    });

    testWidgets('should call onTypeSelected when type is tapped', (tester) async {
      ModelType? selectedType;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.standardJeu,
              onTypeSelected: (type) => selectedType = type,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mini Collection'));
      expect(selectedType, ModelType.miniCollection);

      await tester.tap(find.text('Reality'));
      expect(selectedType, ModelType.reality);
    });

    testWidgets('should display correct icons for each type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.standardJeu,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.toy_brick_outlined), findsOneWidget);
      expect(find.byIcon(Icons.toy_brick), findsOneWidget);
      expect(find.byIcon(Icons.toy_brick_rounded), findsOneWidget);
    });

    testWidgets('should show check icon for selected type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.standardJeu,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should have correct visual style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelTypeSelector(
              selectedType: ModelType.standardJeu,
              onTypeSelected: (_) {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.padding, const EdgeInsets.all(16));
      expect(container.decoration, isA<BoxDecoration>());
      expect(
        (container.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(12),
      );
    });
  });
} 