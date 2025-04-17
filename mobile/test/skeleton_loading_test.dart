import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:brickify/widgets/skeleton_loading.dart';
import 'package:brickify/theme/app_styles.dart';

void main() {
  group('SkeletonLoading Widget Tests', () {
    testWidgets('SkeletonLoading should render with default properties',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(double.infinity));
      expect(container.constraints?.maxHeight, equals(20.0));
    });

    testWidgets('SkeletonLoading should respect custom dimensions',
        (WidgetTester tester) async {
      const width = 100.0;
      const height = 50.0;
      const borderRadius = 10.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(
              width: width,
              height: height,
              borderRadius: borderRadius,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(width));
      expect(container.constraints?.maxHeight, equals(height));
    });

    testWidgets('SkeletonLoading should animate', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(),
          ),
        ),
      );

      // Vérifier l'opacité initiale
      var opacity = tester.widget<Opacity>(find.byType(Opacity));
      final initialOpacity = opacity.opacity;

      // Avancer l'animation
      await tester.pump(const Duration(milliseconds: 250));
      opacity = tester.widget<Opacity>(find.byType(Opacity));
      final midOpacity = opacity.opacity;

      // L'opacité devrait avoir changé
      expect(initialOpacity, isNot(equals(midOpacity)));
    });
  });

  group('SkeletonCard Widget Tests', () {
    testWidgets('SkeletonCard should render with correct layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      // Vérifier la présence des éléments
      expect(find.byType(SkeletonLoading), findsNWidgets(4));
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Container), findsWidgets);

      // Vérifier le padding
      final container = tester.widget<Container>(find.byType(Container).first);
      final padding = container.padding as EdgeInsets;
      expect(padding.top, equals(AppStyles.paddingM));
      expect(padding.bottom, equals(AppStyles.paddingM));
      expect(padding.left, equals(AppStyles.paddingM));
      expect(padding.right, equals(AppStyles.paddingM));
    });

    testWidgets('SkeletonCard should have correct decoration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.borderRadius,
          equals(BorderRadius.circular(AppStyles.radiusL)));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, equals(1));
    });
  });
} 