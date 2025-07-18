import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:prayertracker/qibla_direction_screen.dart'; 

// Mock class for Geolocator
class MockGeolocator extends Mock implements Geolocator {}

void main() {
  // Grouping tests related to QiblaDirectionScreen
  group('QiblaDirectionScreen tests', () {
    late MockGeolocator mockGeolocator;

    setUp(() {
      mockGeolocator = MockGeolocator();
    });

    // Test for initialization of state
    testWidgets('Initialization of state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: QiblaDirectionScreen(calculateQiblaAngle: (position) async => 0)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CompassPainter), findsOneWidget);
    });

    // Test for location retrieval
    testWidgets('Location retrieval', (WidgetTester tester) async {
      when(mockGeolocator.getCurrentPosition(
        desiredAccuracy: anyNamed('desiredAccuracy'),
        headingAccuracy: anyNamed('headingAccuracy'), 
        speed: anyNamed('speed'), 
        speedAccuracy: anyNamed('speedAccuracy'), 
      )).thenAnswer((_) => Future.value(const Position(latitude: 0, longitude: 0)));

      await tester.pumpWidget(MaterialApp(home: QiblaDirectionScreen(calculateQiblaAngle: (position) async => 0)));

      await tester.pumpAndSettle();

      expect(find.text('0.0, 0.0'), findsOneWidget);
    });

    // Test for calculation of Qibla angle
    testWidgets('Calculation of Qibla angle', (WidgetTester tester) async {
      const double mockQiblaAngle = 123.45;
      when(mockGeolocator.getCurrentPosition(
        desiredAccuracy: anyNamed('desiredAccuracy'),
        headingAccuracy: anyNamed('headingAccuracy'), 
        speed: anyNamed('speed'), 
        speedAccuracy: anyNamed('speedAccuracy'), 
      )).thenAnswer((_) => Future.value(const Position(latitude: 0, longitude: 0)));

      await tester.pumpWidget(MaterialApp(home: QiblaDirectionScreen(calculateQiblaAngle: (position) async => mockQiblaAngle)));

      await tester.pumpAndSettle();

      expect(find.text('Qibla Angle: $mockQiblaAngle°'), findsOneWidget);
    });

    // Test for handling sensor events
    testWidgets('Handling sensor events', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: QiblaDirectionScreen(calculateQiblaAngle: (position) async => 0)));

      await tester.pumpAndSettle();

      expect(find.byType(GyroscopeEvent), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GyroscopeEvent), findsOneWidget);
    });

    // Test for loading of compass image
    testWidgets('Loading of compass image', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: QiblaDirectionScreen(calculateQiblaAngle: (position) async => 0)));

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
    });

    // Test for rendering of UI elements
    testWidgets('Rendering of UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: QiblaDirectionScreen(calculateQiblaAngle: (position) async => 0)));

      await tester.pumpAndSettle();

      expect(find.text('Qibla Direction'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.byType(CompassPainter), findsOneWidget);
    });
  });
}
