import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:brickify/services/model_conversion_service.dart';
import 'package:brickify/services/model_import_service.dart';

@GenerateMocks([http.Client])
import 'model_conversion_service_test.mocks.dart';

void main() {
  group('ModelConversionService Tests', () {
    late ModelConversionService service;
    late MockClient mockClient;
    late ModelImportService importService;

    setUp(() {
      service = ModelConversionService();
      mockClient = MockClient();
      importService = ModelImportService();
    });

    test('Singleton instance', () {
      final instance1 = ModelConversionService();
      final instance2 = ModelConversionService();
      expect(identical(instance1, instance2), true);
    });

    test('Conversion d\'une photo en modèle 3D', () async {
      // Simuler l'import d'une photo
      final importResult = await importService.importPhoto(
        source: ImageSource.gallery,
      );

      // Simuler les réponses HTTP
      when(mockClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"status": "success"}', 200));

      when(mockClient.get(any)).thenAnswer((_) async => http.Response(
        '{"status": "completed", "progress": 1.0, "message": "Conversion terminée", "glbUrl": "https://example.com/model.glb"}',
        200,
      ));

      // Simuler le téléchargement du GLB
      when(mockClient.get(Uri.parse('https://example.com/model.glb')))
          .thenAnswer((_) async => http.Response('fake_glb_data', 200));

      final result = await service.convertTo3D(
        modelId: importResult.modelId,
        type: ImportType.photo,
        onProgress: (progress) {
          expect(progress.status, isA<ConversionStatus>());
          expect(progress.progress, isA<double>());
          expect(progress.message, isA<String>());
        },
      );

      expect(result.modelId, importResult.modelId);
      expect(result.glbFilePath, contains('model.glb'));
      expect(result.metadata['originalType'], isNotNull);
      expect(result.metadata['processingTime'], isNotNull);
      expect(result.metadata['fileSize'], isNotNull);
    });

    test('Conversion d\'une vidéo en modèle 3D', () async {
      // Simuler l'import d'une vidéo
      final importResult = await importService.importVideo(
        source: ImageSource.gallery,
      );

      // Simuler les réponses HTTP
      when(mockClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"status": "success"}', 200));

      when(mockClient.get(any)).thenAnswer((_) async => http.Response(
        '{"status": "completed", "progress": 1.0, "message": "Conversion terminée", "glbUrl": "https://example.com/model.glb"}',
        200,
      ));

      // Simuler le téléchargement du GLB
      when(mockClient.get(Uri.parse('https://example.com/model.glb')))
          .thenAnswer((_) async => http.Response('fake_glb_data', 200));

      final result = await service.convertTo3D(
        modelId: importResult.modelId,
        type: ImportType.video,
        onProgress: (progress) {
          expect(progress.status, isA<ConversionStatus>());
          expect(progress.progress, isA<double>());
          expect(progress.message, isA<String>());
        },
      );

      expect(result.modelId, importResult.modelId);
      expect(result.glbFilePath, contains('model.glb'));
      expect(result.metadata['originalType'], isNotNull);
      expect(result.metadata['processingTime'], isNotNull);
      expect(result.metadata['fileSize'], isNotNull);
    });

    test('Conversion d\'un modèle 3D existant', () async {
      // Simuler l'import d'un modèle 3D
      final importResult = await importService.importModel3D();

      // Simuler les réponses HTTP
      when(mockClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"status": "success"}', 200));

      when(mockClient.get(any)).thenAnswer((_) async => http.Response(
        '{"status": "completed", "progress": 1.0, "message": "Conversion terminée", "glbUrl": "https://example.com/model.glb"}',
        200,
      ));

      // Simuler le téléchargement du GLB
      when(mockClient.get(Uri.parse('https://example.com/model.glb')))
          .thenAnswer((_) async => http.Response('fake_glb_data', 200));

      final result = await service.convertTo3D(
        modelId: importResult.modelId,
        type: ImportType.model3d,
        onProgress: (progress) {
          expect(progress.status, isA<ConversionStatus>());
          expect(progress.progress, isA<double>());
          expect(progress.message, isA<String>());
        },
      );

      expect(result.modelId, importResult.modelId);
      expect(result.glbFilePath, contains('model.glb'));
      expect(result.metadata['originalType'], isNotNull);
      expect(result.metadata['processingTime'], isNotNull);
      expect(result.metadata['fileSize'], isNotNull);
    });

    test('Gestion des erreurs de conversion', () async {
      // Simuler l'import d'une photo
      final importResult = await importService.importPhoto(
        source: ImageSource.gallery,
      );

      // Simuler une erreur de conversion
      when(mockClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"status": "success"}', 200));

      when(mockClient.get(any)).thenAnswer((_) async => http.Response(
        '{"status": "failed", "error": "Erreur de conversion"}',
        200,
      ));

      expect(
        () => service.convertTo3D(
          modelId: importResult.modelId,
          type: ImportType.photo,
          onProgress: (progress) {
            expect(progress.status, ConversionStatus.failed);
            expect(progress.message, contains('Erreur de conversion'));
          },
        ),
        throwsException,
      );
    });

    test('Annulation de la conversion', () async {
      // Simuler l'import d'une photo
      final importResult = await importService.importPhoto(
        source: ImageSource.gallery,
      );

      // Simuler l'annulation réussie
      when(mockClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"status": "success"}', 200));

      await service.cancelConversion(importResult.modelId);
      verify(mockClient.post(
        Uri.parse('${service._baseUrl}/cancel/${importResult.modelId}'),
        body: anyNamed('body'),
      )).called(1);
    });

    test('Suppression du modèle converti', () async {
      // Simuler l'import d'une photo
      final importResult = await importService.importPhoto(
        source: ImageSource.gallery,
      );

      await service.deleteConvertedModel(importResult.modelId);
      expect(await importService.isModelExists(importResult.modelId), false);
    });
  });
} 