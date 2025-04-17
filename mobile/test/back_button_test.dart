import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickify/widgets/back_button.dart';
import 'package:brickify/theme/app_icons.dart';
import 'package:brickify/theme/app_styles.dart';

void main() {
  group('AppBackButton Tests', () {
    testWidgets('Rendu de base avec label', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBackButton(
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(AppIcon), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
      expect(find.byType(InteractiveButton), findsOneWidget);
    });

    testWidgets('Rendu sans label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBackButton(
              onPressed: () {},
              showLabel: false,
            ),
          ),
        ),
      );

      expect(find.byType(AppIcon), findsOneWidget);
      expect(find.text('Retour'), findsNothing);
    });

    testWidgets('Rendu avec label personnalisé', (WidgetTester tester) async {
      const customLabel = 'Annuler';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBackButton(
              onPressed: () {},
              label: customLabel,
            ),
          ),
        ),
      );

      expect(find.text(customLabel), findsOneWidget);
    });

    testWidgets('Rendu avec taille personnalisée', (WidgetTester tester) async {
      const customSize = 40.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBackButton(
              onPressed: () {},
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
            body: AppBackButton(
              onPressed: () {},
              color: customColor,
            ),
          ),
        ),
      );

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.color, customColor);
    });

    testWidgets('Appel du callback onPressed', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBackButton(
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InteractiveButton));
      expect(pressed, true);
    });
  });
} 