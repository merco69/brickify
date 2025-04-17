import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:brickify/services/model_share_service.dart';

@GenerateMocks([Directory, File, Share])
import 'model_share_service_test.mocks.dart';

void main() {
  group('ModelShareService Tests', () {
    late ModelShareService service;
    late MockFile mockFile;
    late MockDirectory mockDirectory;
    late MockDirectory mockTempDirectory;
    late MockDirectory mockDownloadsDirectory;
    late String testGlbPath;

    setUp(() {
      service = ModelShareService();
      mockFile = MockFile();
      mockDirectory = MockDirectory();
      mockTempDirectory = MockDirectory();
      mockDownloadsDirectory = MockDirectory();
      testGlbPath = 'test.glb';

      // Configuration des mocks
      when(mockFile.exists()).thenAnswer((_) async => true);
      when(mockFile.copy(any)).thenAnswer((_) async => mockFile);
      when(mockFile.delete()).thenAnswer((_) async => {});
      when(mockDirectory.path).thenReturn('/test/path');
      when(getTemporaryDirectory()).thenAnswer((_) async => mockTempDirectory);
      when(getExternalStorageDirectory()).thenAnswer((_) async => mockDownloadsDirectory);
    });

    test('Singleton instance', () {
      final instance1 = ModelShareService();
      final instance2 = ModelShareService();
      expect(identical(instance1, instance2), true);
    });

    test('Partage du modèle', () async {
      when(mockTempDirectory.path).thenReturn('/temp');
      when(File(testGlbPath)).thenReturn(mockFile);

      await service.shareModel(testGlbPath);

      verify(mockFile.exists()).called(1);
      verify(mockFile.copy('/temp/test.glb')).called(1);
      verify(Share.shareXFiles(
        [any],
        subject: 'Modèle 3D - test.glb',
      )).called(1);
      verify(mockFile.delete()).called(1);
    });

    test('Export du modèle', () async {
      when(mockDownloadsDirectory.path).thenReturn('/downloads');
      when(File(testGlbPath)).thenReturn(mockFile);

      final result = await service.exportModel(testGlbPath, 'glb');

      verify(mockFile.exists()).called(1);
      verify(mockFile.copy('/downloads/test.glb')).called(1);
      expect(result, '/downloads/test.glb');
    });

    test('Gestion des erreurs - fichier inexistant', () async {
      when(mockFile.exists()).thenAnswer((_) async => false);
      when(File(testGlbPath)).thenReturn(mockFile);

      expect(
        () => service.shareModel(testGlbPath),
        throwsException,
      );
      expect(
        () => service.exportModel(testGlbPath, 'glb'),
        throwsException,
      );
    });

    test('Gestion des erreurs - accès au dossier de téléchargements', () async {
      when(getExternalStorageDirectory()).thenAnswer((_) async => null);
      when(File(testGlbPath)).thenReturn(mockFile);

      expect(
        () => service.exportModel(testGlbPath, 'glb'),
        throwsException,
      );
    });

    test('Détection du dossier de téléchargements Android', () async {
      final androidDir = MockDirectory();
      when(androidDir.exists()).thenAnswer((_) async => true);
      when(Directory('/storage/emulated/0/Download')).thenReturn(androidDir);

      final result = await service.getDownloadsDirectory();
      expect(result, androidDir);
    });

    test('Fallback sur le dossier de stockage externe', () async {
      final androidDir = MockDirectory();
      when(androidDir.exists()).thenAnswer((_) async => false);
      when(Directory('/storage/emulated/0/Download')).thenReturn(androidDir);

      final result = await service.getDownloadsDirectory();
      expect(result, mockDownloadsDirectory);
    });
  });
} 