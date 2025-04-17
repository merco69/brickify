import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:brickify/services/model_import_service.dart';

void main() {
  group('ModelImportService Tests', () {
    late ModelImportService service;
    late Directory tempDir;

    setUpAll(() async {
      service = ModelImportService();
      tempDir = await getTemporaryDirectory();
    });

    tearDownAll(() async {
      // Nettoyage des fichiers temporaires
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Singleton instance', () {
      final instance1 = ModelImportService();
      final instance2 = ModelImportService();
      expect(identical(instance1, instance2), true);
    });

    test('Formats 3D supportés', () {
      expect(ModelImportService.supported3DFormats['obj'], 'Wavefront OBJ');
      expect(ModelImportService.supported3DFormats['fbx'], 'Autodesk FBX');
      expect(ModelImportService.supported3DFormats['glb'], 'GL Transmission Format Binary');
      expect(ModelImportService.supported3DFormats['gltf'], 'GL Transmission Format');
      expect(ModelImportService.supported3DFormats['stl'], 'Stereolithography');
      expect(ModelImportService.supported3DFormats['3ds'], '3D Studio');
      expect(ModelImportService.supported3DFormats['dae'], 'Collada');
    });

    test('Import photo depuis la galerie', () async {
      final result = await service.importPhoto(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        quality: 85,
      );

      expect(result.type, ImportType.photo);
      expect(result.metadata['width'], 1920);
      expect(result.metadata['height'], 1080);
      expect(result.metadata['quality'], 85);
      expect(File(result.filePath).existsSync(), true);
    });

    test('Import vidéo depuis la caméra', () async {
      final result = await service.importVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      expect(result.type, ImportType.video);
      expect(result.metadata['maxDuration'], 300); // 5 minutes en secondes
      expect(File(result.filePath).existsSync(), true);
    });

    test('Import modèle 3D', () async {
      final result = await service.importModel3D();

      expect(result.type, ImportType.model3d);
      expect(result.metadata['format'], isNotNull);
      expect(result.metadata['size'], isNotNull);
      expect(File(result.filePath).existsSync(), true);
    });

    test('Suppression d\'un modèle', () async {
      final result = await service.importPhoto(source: ImageSource.gallery);
      
      expect(await service.isModelExists(result.modelId), true);
      await service.deleteModel(result.modelId);
      expect(await service.isModelExists(result.modelId), false);
    });

    test('Récupération d\'un modèle', () async {
      final result = await service.importPhoto(source: ImageSource.gallery);
      
      final retrieved = await service.getModel(result.modelId);
      expect(retrieved, isNotNull);
      expect(retrieved!.modelId, result.modelId);
      expect(retrieved.type, result.type);
      expect(retrieved.filePath, result.filePath);
    });

    test('Vérification de l\'existence d\'un modèle', () async {
      final result = await service.importPhoto(source: ImageSource.gallery);
      
      expect(await service.isModelExists(result.modelId), true);
      expect(await service.isModelExists('invalid_id'), false);
    });

    test('Gestion des erreurs', () async {
      // Test avec une source invalide
      expect(
        () => service.importPhoto(source: null as ImageSource),
        throwsException,
      );

      // Test avec une durée de vidéo invalide
      expect(
        () => service.importVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: -1),
        ),
        throwsException,
      );

      // Test avec un format de fichier non supporté
      expect(
        () => service.importModel3D(),
        throwsException,
      );
    });
  });
} 