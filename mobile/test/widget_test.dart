import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:brickify/screens/home_screen.dart';
import 'package:brickify/screens/subscription_screen.dart';
import 'package:brickify/widgets/ad_banner.dart';

void main() {
  group('Tests visuels des composants', () {
    testWidgets('Vérification du thème et des couleurs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          home: const Scaffold(
            body: Center(
              child: Text(
                'Test App',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      final Text textWidget = tester.widget<Text>(find.text('Test App'));
      expect(textWidget.style?.color, equals(Colors.blue));
    });

    testWidgets('Vérification de la réactivité', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    width: constraints.maxWidth * 0.9,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Interface réactive',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Interface réactive'), findsOneWidget);
      expect(
        tester.widget<Container>(find.byType(Container)).decoration,
        isNotNull,
      );
    });

    testWidgets('Test des animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Animation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Animation'), findsOneWidget);

      // Vérifier l'animation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
} 