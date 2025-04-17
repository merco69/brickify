import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:brickify/screens/import_model3d_screen.dart';
import 'package:brickify/theme/app_icons.dart';

void main() {
  group('ImportModel3DScreen Tests', () {
    testWidgets('Rendu de base avec les formats supportés', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      // Vérification du titre
      expect(find.text('Importer un modèle 3D'), findsOneWidget);
      expect(find.text('Formats supportés'), findsOneWidget);

      // Vérification des formats supportés
      expect(find.text('Wavefront OBJ'), findsOneWidget);
      expect(find.text('Autodesk FBX'), findsOneWidget);
      expect(find.text('GL Transmission Format Binary'), findsOneWidget);
      expect(find.text('GL Transmission Format'), findsOneWidget);
      expect(find.text('Stereolithography'), findsOneWidget);
      expect(find.text('3D Studio'), findsOneWidget);
      expect(find.text('Collada'), findsOneWidget);

      // Vérification de l'option d'importation
      expect(find.text('Choisir un fichier'), findsOneWidget);
      expect(find.text('Sélectionnez un fichier 3D existant'), findsOneWidget);
    });

    testWidgets('Bouton retour présent dans l\'AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      expect(find.byType(AppBackButton), findsOneWidget);
    });

    testWidgets('Option d\'importation est cliquable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      // Vérification que l'option est bien un bouton interactif
      expect(find.byType(InteractiveButton), findsOneWidget);
    });

    testWidgets('Style visuel cohérent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      // Vérification du style des options
      final options = tester.widgetList(find.byType(Container));
      for (var option in options) {
        expect(option.decoration, isA<BoxDecoration>());
        final decoration = option.decoration as BoxDecoration;
        expect(decoration.borderRadius, isA<BorderRadius>());
      }

      // Vérification du style des chips
      final chips = tester.widgetList(find.byType(Chip));
      for (var chip in chips) {
        expect(chip.backgroundColor, isA<Color>());
        expect(chip.labelStyle, isA<TextStyle>());
      }
    });

    testWidgets('Affichage de l\'indicateur de chargement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      // Simulation d'un clic sur l'option
      await tester.tap(find.text('Choisir un fichier'));

      // Vérification de l'indicateur de chargement
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Affichage du fichier sélectionné', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      // Simulation de la sélection d'un fichier
      final mockFile = PlatformFile(
        name: 'test_model.obj',
        size: 1024 * 1024, // 1 MB
        path: '/test/path/test_model.obj',
      );
      final state = tester.state<ImportModel3DScreenState>(find.byType(ImportModel3DScreen));
      state.setState(() {
        state._selectedFile = mockFile;
      });

      // Vérification de l'affichage du fichier sélectionné
      expect(find.text('Fichier sélectionné'), findsOneWidget);
      expect(find.text('test_model.obj'), findsOneWidget);
      expect(find.text('1.0 MB'), findsOneWidget);
      expect(find.text('Wavefront OBJ'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Importer le modèle'), findsOneWidget);
    });

    testWidgets('Suppression du fichier sélectionné', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      // Simulation de la sélection d'un fichier
      final mockFile = PlatformFile(
        name: 'test_model.obj',
        size: 1024 * 1024,
        path: '/test/path/test_model.obj',
      );
      final state = tester.state<ImportModel3DScreenState>(find.byType(ImportModel3DScreen));
      state.setState(() {
        state._selectedFile = mockFile;
      });

      // Vérification de l'affichage initial
      expect(find.text('Fichier sélectionné'), findsOneWidget);

      // Simulation de la suppression
      await tester.tap(find.byIcon(AppIcons.delete));

      // Vérification de la suppression
      expect(find.text('Fichier sélectionné'), findsNothing);
    });

    testWidgets('Format de la taille du fichier', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      final state = tester.state<ImportModel3DScreenState>(find.byType(ImportModel3DScreen));
      
      // Test avec différentes tailles
      expect(state._getFileSizeString(500), '500 B');
      expect(state._getFileSizeString(1024), '1.0 KB');
      expect(state._getFileSizeString(1024 * 1024), '1.0 MB');
      expect(state._getFileSizeString(1024 * 1024 * 1024), '1.0 GB');
      expect(state._getFileSizeString(null), '');
    });

    testWidgets('Extraction de l\'extension du fichier', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImportModel3DScreen(),
        ),
      );

      final state = tester.state<ImportModel3DScreenState>(find.byType(ImportModel3DScreen));
      
      // Test avec différents noms de fichiers
      expect(state._getFileExtension('model.obj'), 'obj');
      expect(state._getFileExtension('test.fbx'), 'fbx');
      expect(state._getFileExtension('file.without.extension'), 'extension');
      expect(state._getFileExtension('noextension'), '');
      expect(state._getFileExtension(null), '');
    });
  });
} 