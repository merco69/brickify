import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickify/widgets/model_preview.dart';

void main() {
  group('ModelPreview Tests', () {
    const testGlbPath = 'test.glb';

    testWidgets('Affichage initial du widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
          ),
        ),
      );

      expect(find.byType(ModelViewer), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Container), findsNWidgets(2)); // Conteneurs pour les contrôles
    });

    testWidgets('Affichage des contrôles de rendu', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            shadowIntensity: true,
            exposure: true,
            environmentIntensity: true,
          ),
        ),
      );

      expect(find.text('Intensité des ombres'), findsOneWidget);
      expect(find.text('Exposition'), findsOneWidget);
      expect(find.text('Intensité de l\'environnement'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(3));
    });

    testWidgets('Masquage des contrôles de rendu', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            shadowIntensity: false,
            exposure: false,
            environmentIntensity: false,
          ),
        ),
      );

      expect(find.text('Intensité des ombres'), findsNothing);
      expect(find.text('Exposition'), findsNothing);
      expect(find.text('Intensité de l\'environnement'), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('Bouton de fermeture', (WidgetTester tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            onClose: () => closeCalled = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(closeCalled, true);
    });

    testWidgets('Contrôles de caméra', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            cameraControls: true,
            autoRotate: true,
          ),
        ),
      );

      final modelViewer = tester.widget<ModelViewer>(find.byType(ModelViewer));
      expect(modelViewer.cameraControls, true);
      expect(modelViewer.autoRotate, true);
    });

    testWidgets('Désactivation des contrôles de caméra', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            cameraControls: false,
            autoRotate: false,
          ),
        ),
      );

      final modelViewer = tester.widget<ModelViewer>(find.byType(ModelViewer));
      expect(modelViewer.cameraControls, false);
      expect(modelViewer.autoRotate, false);
    });

    testWidgets('Style visuel des contrôles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            shadowIntensity: true,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Intensité des ombres'),
          matching: find.byType(Container),
        ),
      );

      expect(container.padding, const EdgeInsets.all(16));
      expect(container.decoration, isA<BoxDecoration>());
      expect(
        (container.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(12),
      );
    });

    testWidgets('Valeurs des curseurs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            shadowIntensity: true,
            exposure: true,
            environmentIntensity: true,
          ),
        ),
      );

      final sliders = tester.widgetList<Slider>(find.byType(Slider));
      for (final slider in sliders) {
        expect(slider.min, 0.0);
        expect(slider.max, 1.0);
        expect(slider.divisions, 10);
        expect(slider.value, 1.0);
      }
    });

    testWidgets('Changement des valeurs des curseurs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelPreview(
            glbFilePath: testGlbPath,
            shadowIntensity: true,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 1.0);

      await tester.drag(find.byType(Slider), const Offset(-100, 0));
      await tester.pump();

      final updatedSlider = tester.widget<Slider>(find.byType(Slider));
      expect(updatedSlider.value, lessThan(1.0));
    });
  });
} 