import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:prayertracker/prayer_times_screen.dart';


class MockGeolocator extends Mock implements Geolocator {}

void main() {
  group('PrayerTimesScreen tests', () {
    late MockGeolocator mockGeolocator;

    setUp(() {
      mockGeolocator = MockGeolocator(); // Initialize MockGeolocator
    });

    testWidgets('Prayer times screen initialization', (WidgetTester tester) async {
      
      when(mockGeolocator.getCurrentPosition())
          .thenAnswer((_) => Future.value(const Position(latitude: 0, longitude: 0))); // Mock getCurrentPosition method

      await tester.pumpWidget(const MaterialApp(home: PrayerTimesScreen(prayerTimes: null)));

      
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // Expect CircularProgressIndicator while loading

      
      await tester.pumpWidget(MaterialApp(home: PrayerTimesScreen(prayerTimes: PrayerTimes())));

      
      expect(find.text('Prayer Times'), findsOneWidget); // Expect 'Prayer Times' text
      expect(find.text('Fajr'), findsOneWidget); // Expect 'Fajr' text
    });

    testWidgets('Audio functionalities test', (WidgetTester tester) async {
      
      when(mockGeolocator.getCurrentPosition())
          .thenAnswer((_) => Future.value(const Position(latitude: 0, longitude: 0))); // Mock getCurrentPosition method

      final prayerTimes = PrayerTimes(
        fajr: DateTime.now().add(const Duration(minutes: 1)),
      );

      await tester.pumpWidget(MaterialApp(home: PrayerTimesScreen(prayerTimes: prayerTimes)));

      
      await tester.pump(const Duration(minutes: 1)); // Wait for 1 minute
      expect(find.byIcon(Icons.volume_up), findsOneWidget); // Expect volume icon to be present

      
      await tester.tap(find.byIcon(Icons.volume_up)); // Tap on volume icon
      await tester.pump();
      expect(find.byIcon(Icons.volume_off), findsOneWidget); // Expect volume off icon to be present
    });

    testWidgets('Countdown timer logic test', (WidgetTester tester) async {
      final prayerTimes = PrayerTimes(
        fajr: DateTime.now().add(const Duration(minutes: 2)), 
      );

      await tester.pumpWidget(MaterialApp(home: PrayerTimesScreen(prayerTimes: prayerTimes)));

      
      await tester.pump(const Duration(minutes: 1)); // Wait for 1 minute
      expect(find.text('00:01:00'), findsOneWidget); // Expect countdown timer to show 1 minute

      await tester.pump(const Duration(minutes: 1)); // Wait for another minute
      expect(find.text('00:00:00'), findsOneWidget); // Expect countdown timer to show 0 minutes
    });

    
  });
}
