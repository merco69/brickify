import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickify/theme/app_icons.dart';

void main() {
  group('AppIcons Tests', () {
    test('Tailles des icônes sont correctement définies', () {
      expect(AppIcons.sizeXS, 16.0);
      expect(AppIcons.sizeS, 20.0);
      expect(AppIcons.sizeM, 24.0);
      expect(AppIcons.sizeL, 32.0);
      expect(AppIcons.sizeXL, 48.0);
    });

    test('Icônes de navigation sont correctement définies', () {
      expect(AppIcons.home, Icons.home_rounded);
      expect(AppIcons.back, Icons.arrow_back_ios_rounded);
      expect(AppIcons.forward, Icons.arrow_forward_ios_rounded);
      expect(AppIcons.menu, Icons.menu_rounded);
      expect(AppIcons.close, Icons.close_rounded);
    });

    test('Icônes d\'action sont correctement définies', () {
      expect(AppIcons.add, Icons.add_rounded);
      expect(AppIcons.edit, Icons.edit_rounded);
      expect(AppIcons.delete, Icons.delete_rounded);
      expect(AppIcons.save, Icons.save_rounded);
      expect(AppIcons.share, Icons.share_rounded);
    });
  });

  group('AppIcon Widget Tests', () {
    testWidgets('Rendu de base avec taille par défaut', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIcon(AppIcons.home),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);

      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, AppIcons.sizeM);
    });

    testWidgets('Rendu avec taille personnalisée', (WidgetTester tester) async {
      const customSize = 40.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIcon(
              AppIcons.home,
              size: customSize,
            ),
          ),
        ),
      );

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.size, customSize);
    });

    testWidgets('Rendu avec couleur personnalisée', (WidgetTester tester) async {
      const customColor = Colors.red;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIcon(
              AppIcons.home,
              color: customColor,
            ),
          ),
        ),
      );

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.color, customColor);
    });

    testWidgets('Animation est appliquée quand activée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIcon(
              AppIcons.loading,
              animated: true,
            ),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder), findsOneWidget);
      expect(find.byType(Transform), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
    });

    testWidgets('Pas d\'animation quand désactivée', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIcon(
              AppIcons.home,
              animated: false,
            ),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder), findsNothing);
      expect(find.byType(Transform), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });
  });
} 