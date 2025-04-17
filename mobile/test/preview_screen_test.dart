import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:brickify/screens/preview_screen.dart';
import 'package:brickify/services/model_conversion_service.dart';
import 'package:brickify/services/model_import_service.dart';
import 'package:brickify/services/model_share_service.dart';

@GenerateMocks([ModelConversionService, ModelImportService, ModelShareService])
import 'preview_screen_test.mocks.dart';

void main() {
  late MockModelConversionService mockConversionService;
  late MockModelImportService mockImportService;
  late MockModelShareService mockShareService;
  late String testModelId;
  late String testGlbPath;

  setUp(() {
    mockConversionService = MockModelConversionService();
    mockImportService = MockModelImportService();
    mockShareService = MockModelShareService();
    testModelId = 'test-model-id';
    testGlbPath = 'test.glb';
  });

  group('PreviewScreen Tests', () {
    testWidgets('should display initial screen with all controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      expect(find.byType(ModelPreview), findsOneWidget);
      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Partager'), findsOneWidget);
      expect(find.text('Exporter'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('should toggle rendering controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump();

      expect(find.byIcon(Icons.tune_off), findsOneWidget);
    });

    testWidgets('should toggle auto-rotation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.pump();

      expect(find.byIcon(Icons.rotate_left), findsOneWidget);
    });

    testWidgets('should toggle camera controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      expect(find.byIcon(Icons.camera_alt_off), findsOneWidget);
    });

    testWidgets('should share model successfully', (tester) async {
      when(mockShareService.shareModel(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Partager'));
      await tester.pump();

      verify(mockShareService.shareModel('test.glb')).called(1);
    });

    testWidgets('should show error when sharing fails', (tester) async {
      when(mockShareService.shareModel(any)).thenThrow(Exception('Share failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Partager'));
      await tester.pump();

      expect(find.text('Erreur lors du partage: Exception: Share failed'), findsOneWidget);
    });

    testWidgets('should export model successfully', (tester) async {
      when(mockShareService.exportModel(any, any)).thenAnswer((_) async => 'exported.glb');

      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Exporter'));
      await tester.pump();

      verify(mockShareService.exportModel('test.glb', 'glb')).called(1);
      expect(find.text('Modèle exporté vers: exported.glb'), findsOneWidget);
    });

    testWidgets('should show error when export fails', (tester) async {
      when(mockShareService.exportModel(any, any)).thenThrow(Exception('Export failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Exporter'));
      await tester.pump();

      expect(find.text('Erreur lors de l\'export: Exception: Export failed'), findsOneWidget);
    });

    testWidgets('should disable export button while exporting', (tester) async {
      when(mockShareService.exportModel(any, any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'exported.glb';
      });

      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Exporter'));
      await tester.pump();

      expect(find.byIcon(Icons.downloading), findsOneWidget);
      expect(find.text('Exporter'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Supprimer'));
      await tester.pump();

      expect(find.text('Supprimer le modèle'), findsOneWidget);
      expect(find.text('Êtes-vous sûr de vouloir supprimer ce modèle ? Cette action est irréversible.'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('should delete model when confirmed', (tester) async {
      when(mockConversionService.deleteConvertedModel(any)).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Supprimer'));
      await tester.pump();

      await tester.tap(find.text('Supprimer'));
      await tester.pump();

      verify(mockConversionService.deleteConvertedModel(testModelId)).called(1);
    });

    testWidgets('should not delete model when cancelled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.text('Supprimer'));
      await tester.pump();

      await tester.tap(find.text('Annuler'));
      await tester.pump();

      verifyNever(mockConversionService.deleteConvertedModel(testModelId));
    });

    testWidgets('Style visuel des boutons d\'action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Partager'),
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

    testWidgets('Retour haptique sur les boutons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            modelId: testModelId,
            glbFilePath: testGlbPath,
            type: ImportType.photo,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.tap(find.text('Partager'));
      await tester.tap(find.text('Exporter'));
      await tester.tap(find.text('Supprimer'));

      // Vérifier que les boutons sont bien des InteractiveButton
      expect(find.byType(InteractiveButton), findsNWidgets(6));
    });
  });
} 