import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configurer le mock pour les appels de méthode Firebase
  const channel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'mock-api-key',
              'appId': 'mock-app-id',
              'messagingSenderId': 'mock-sender-id',
              'projectId': 'mock-project-id',
            },
            'pluginConstants': {},
          }
        ];
      case 'Firebase#initializeApp':
        return {
          'name': methodCall.arguments['appName'],
          'options': methodCall.arguments['options'],
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });
} 