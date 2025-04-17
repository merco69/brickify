import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:brickify/screens/conversion_screen.dart';
import 'package:brickify/services/model_conversion_service.dart';
import 'package:brickify/services/model_import_service.dart';

@GenerateMocks([ModelConversionService, ModelImportService])
import 'conversion_screen_test.mocks.dart';

void main() {
  group('ConversionScreen Tests', () {
    late MockModelConversionService mockConversionService;
    late MockModelImportService mockImportService;
    late String testModelId;

    setUp(() {
      mockConversionService = MockModelConversionService();
      mockImportService = MockModelImportService();
      testModelId = 'test-model-id';
    });

    testWidgets('Affichage initial de l\'écran', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.photo,
          ),
        ),
      );

      expect(find.text('Conversion en cours'), findsOneWidget);
      expect(find.text('Votre photo est en cours de conversion en modèle 3D. Cela peut prendre quelques minutes.'), findsOneWidget);
      expect(find.byType(ConversionProgressWidget), findsOneWidget);
    });

    testWidgets('Gestion de la progression de la conversion', (WidgetTester tester) async {
      when(mockConversionService.convertTo3D(
        modelId: testModelId,
        type: ImportType.photo,
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async {
        final onProgress = _.namedArguments[const Symbol('onProgress')] as Function(ConversionProgress);
        onProgress(ConversionProgress(
          progress: 0.5,
          message: 'Conversion en cours...',
          status: ConversionStatus.processing,
        ));
        return ModelConversionResult(
          modelId: testModelId,
          glbFilePath: 'test.glb',
          completedAt: DateTime.now(),
          metadata: {},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Conversion en cours...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Gestion des erreurs de conversion', (WidgetTester tester) async {
      when(mockConversionService.convertTo3D(
        modelId: testModelId,
        type: ImportType.photo,
        onProgress: anyNamed('onProgress'),
      )).thenThrow(Exception('Erreur de conversion'));

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('Annulation de la conversion', (WidgetTester tester) async {
      when(mockConversionService.convertTo3D(
        modelId: testModelId,
        type: ImportType.photo,
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async {
        final onProgress = _.namedArguments[const Symbol('onProgress')] as Function(ConversionProgress);
        onProgress(ConversionProgress(
          progress: 0.5,
          message: 'Conversion en cours...',
          status: ConversionStatus.processing,
        ));
        return ModelConversionResult(
          modelId: testModelId,
          glbFilePath: 'test.glb',
          completedAt: DateTime.now(),
          metadata: {},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      verify(mockConversionService.cancelConversion(testModelId)).called(1);
    });

    testWidgets('Réessai après une erreur', (WidgetTester tester) async {
      when(mockConversionService.convertTo3D(
        modelId: testModelId,
        type: ImportType.photo,
        onProgress: anyNamed('onProgress'),
      )).thenThrow(Exception('Erreur de conversion'));

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      when(mockConversionService.convertTo3D(
        modelId: testModelId,
        type: ImportType.photo,
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async {
        final onProgress = _.namedArguments[const Symbol('onProgress')] as Function(ConversionProgress);
        onProgress(ConversionProgress(
          progress: 0.5,
          message: 'Conversion en cours...',
          status: ConversionStatus.processing,
        ));
        return ModelConversionResult(
          modelId: testModelId,
          glbFilePath: 'test.glb',
          completedAt: DateTime.now(),
          metadata: {},
        );
      });

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Conversion en cours...'), findsOneWidget);
      verify(mockConversionService.convertTo3D(
        modelId: testModelId,
        type: ImportType.photo,
        onProgress: anyNamed('onProgress'),
      )).called(2);
    });

    testWidgets('Description adaptée selon le type d\'import', (WidgetTester tester) async {
      // Test pour une photo
      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.photo,
          ),
        ),
      );
      expect(find.text('Votre photo est en cours de conversion en modèle 3D. Cela peut prendre quelques minutes.'), findsOneWidget);

      // Test pour une vidéo
      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.video,
          ),
        ),
      );
      expect(find.text('Votre vidéo est en cours de conversion en modèle 3D. Cela peut prendre plusieurs minutes.'), findsOneWidget);

      // Test pour un modèle 3D
      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            modelId: testModelId,
            type: ImportType.model3d,
          ),
        ),
      );
      expect(find.text('Votre modèle 3D est en cours de conversion. Cela peut prendre quelques minutes.'), findsOneWidget);
    });
  });
} 