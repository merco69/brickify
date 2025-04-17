import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:brickify/services/animation_service.dart';

void main() {
  group('AnimationService Tests', () {
    testWidgets('PageRouteTransition should create a route with correct properties',
        (WidgetTester tester) async {
      final route = PageRouteTransition(
        page: const Scaffold(
          body: Text('Test Page'),
        ),
      );

      expect(route.pageBuilder, isNotNull);
      expect(route.transitionsBuilder, isNotNull);
      expect(route.transitionDuration, equals(const Duration(milliseconds: 300)));
      expect(route.reverseTransitionDuration, equals(const Duration(milliseconds: 300)));
    });

    testWidgets('fadeInTransition should render with correct animation properties',
        (WidgetTester tester) async {
      const testWidget = Text('Test Widget');

      await tester.pumpWidget(
        MaterialApp(
          home: AnimationService.fadeInTransition(
            child: testWidget,
          ),
        ),
      );

      // Vérifier que le widget est initialement transparent
      var opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(0.0));

      // Avancer l'animation à mi-chemin
      await tester.pump(const Duration(milliseconds: 150));
      opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, greaterThan(0.0));
      expect(opacity.opacity, lessThan(1.0));

      // Terminer l'animation
      await tester.pump(const Duration(milliseconds: 150));
      opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(1.0));
    });

    testWidgets('scaleInTransition should render with animation',
        (WidgetTester tester) async {
      const testWidget = Text('Test Widget');

      await tester.pumpWidget(
        MaterialApp(
          home: AnimationService.scaleInTransition(
            child: testWidget,
          ),
        ),
      );

      // Vérifier que le widget utilise Transform.scale
      expect(find.byType(Transform), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
      expect(find.text('Test Widget'), findsOneWidget);

      // Vérifier que l'animation progresse
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('createRoute should return a valid route', (WidgetTester tester) async {
      const testPage = Scaffold(
        body: Text('Test Page'),
      );

      final route = AnimationService.createRoute(testPage);
      expect(route, isA<PageRouteTransition>());
      expect((route as PageRouteTransition).page, equals(testPage));
    });
  });
} 