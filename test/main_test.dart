import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:prayertracker/main.dart';
import 'package:prayertracker/prayer_times_screen.dart';
import 'package:prayertracker/qibla_direction_screen.dart'; 

// Mock class for Geolocator
class MockGeolocator extends Mock implements Geolocator {}

// Test widget for testing stateful widgets
class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: HomePage(), // Testing HomePage widget
      ),
    );
  }
}

void main() {
  group('HomePage tests', () {
    late HomePageState homePageState;

    setUp(() {
      homePageState = HomePageState(); // Initialize HomePageState
    });

    testWidgets('Prayer status initialization test', (WidgetTester tester) async {
      await tester.pumpWidget(TestWidget());

      // Test if prayerStatus list is initialized properly
      expect(homePageState.prayerStatus.length, equals(5)); 
      expect(homePageState.prayerStatus.every((status) => !status), isTrue); 
    });

    testWidgets('Checkbox handling test', (WidgetTester tester) async {
      await tester.pumpWidget(TestWidget());

      // Test handling of checkbox changes
      homePageState._handleCheckboxChanged(0, true); 
      expect(homePageState.prayerStatus[0], isTrue);

      homePageState._handleCheckboxChanged(0, false); 
      expect(homePageState.prayerStatus[0], isFalse);
    });
  });

  group('BottomNavigationBar tests', () {
    testWidgets('Bottom navigation tap test', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PrayerTrackerApp()));

      // Test tapping on bottom navigation items
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.widgetWithIcon(BottomNavigationBarItem, Icons.access_time));
      await tester.pumpAndSettle();

      expect(find.byType(PrayerTimesScreen), findsOneWidget); 

      await tester.tap(find.widgetWithIcon(BottomNavigationBarItem, Icons.location_on));
      await tester.pumpAndSettle();

      expect(find.byType(QiblaDirectionScreen), findsOneWidget); 
    });

    testWidgets('Bottom navigation tap test with loading state', (WidgetTester tester) async {
      
      final mockGeolocator = MockGeolocator();
      when(mockGeolocator.getCurrentPosition(desiredAccuracy: anyNamed('desiredAccuracy')))
          .thenAnswer((_) => Future.error('Failed'));

      await tester.pumpWidget(MaterialApp(home: PrayerTrackerApp()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget); 

      // Test tapping on bottom navigation items with loading state
      await tester.tap(find.widgetWithIcon(BottomNavigationBarItem, Icons.access_time));
      await tester.pumpAndSettle();

      expect(find.text('Failed to get location'), findsOneWidget); 

      await tester.tap(find.widgetWithIcon(BottomNavigationBarItem, Icons.location_on));
      await tester.pumpAndSettle();

      expect(find.text('Failed to get location'), findsOneWidget); 
    });
  });

  group('HomePageContent tests', () {
    testWidgets('HomePageContent widget rendering test', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: HomePageContent(prayerStatus: List.filled(5, false), onCheckboxChanged: (index, value) {}))));

      // Test rendering of HomePageContent widget
      expect(find.text('Today\'s Prayer Table'), findsOneWidget); 
      expect(find.byType(CheckboxListTile), findsNWidgets(5)); 
    });

    testWidgets('Checkbox handling test in HomePageContent', (WidgetTester tester) async {
      late List<bool> prayerStatus;
      late Function(int, bool) onCheckboxChanged;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HomePageContent(
            prayerStatus: List.generate(5, (_) => false),
            onCheckboxChanged: (index, value) {
              prayerStatus[index] = value;
            },
          ),
        ),
      ));

      expect(find.byType(CheckboxListTile), findsNWidgets(5)); 

      // Test handling of checkboxes in HomePageContent
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(prayerStatus[0], isTrue); 
    });
  });
}
