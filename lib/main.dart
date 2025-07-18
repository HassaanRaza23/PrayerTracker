import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'prayer_times_screen.dart';
import 'qibla_direction_screen.dart';

void main() {
  runApp(PrayerTrackerApp());
}

// Main application widget
class PrayerTrackerApp extends StatelessWidget {
  const PrayerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prayer Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

// Home page widget, stateful
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

// State class for the home page
class HomePageState extends State<HomePage> {
  late double qiblaAngle; // Angle for Qibla direction
  late PrayerTimes prayerTimes; // Object to store prayer times
  bool isLoading = true; // Loading indicator
  late List<bool> prayerStatus; // Status of prayers (checked or not)
  int _selectedIndex = 0; // Index for the bottom navigation bar

  @override
  void initState() {
    super.initState();
    // Initializing prayer status list with false values
    prayerStatus = List.filled(5, false);
    // Fetching user's location and prayer times and calculating Qibla angle
    getLocationAndPrayerTimes();
    calculateQiblaAngle();
  }

  // Function to calculate Qibla angle
  Future<double> calculateQiblaAngle() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    Coordinates coordinates = Coordinates(position.latitude, position.longitude);
    double angle = Qibla(coordinates).direction;
    return angle;
  }

  // Function to fetch user's location and prayer times
  Future<void> getLocationAndPrayerTimes() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    Coordinates coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes.today(coordinates, params);
    setState(() {
      this.prayerTimes = prayerTimes;
      isLoading = false; // Loading complete
    });
  }

  // Callback function for handling checkbox changes
  void _handleCheckboxChanged(int index, bool value) {
    setState(() {
      prayerStatus[index] = value; // Update prayer status
    });
  }

  // Callback function for bottom navigation bar item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold widget for the main structure
      body: SafeArea(
        // SafeArea widget to avoid UI overlap with system status bar
        child: Stack(
          children: [
            // Background container with blurred image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('bg2.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            // Main content centered in the stack
            Center(
              child: isLoading
                  ? const CircularProgressIndicator() // Display loading indicator
                  : _widgetOptions()[_selectedIndex], // Display appropriate content based on selected index
            ),
          ],
        ),
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.red,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.white : Colors.black), // Home icon
            label: 'Home', // Label for home page
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time, color: _selectedIndex == 1 ? Colors.white : Colors.black), // Prayer times icon
            label: 'Prayer Times', // Label for prayer times page
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on, color: _selectedIndex == 2 ? Colors.white : Colors.black), // Qibla direction icon
            label: 'Qibla Direction', // Label for Qibla direction page
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped, // Callback function for item selection
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Function to return appropriate widgets based on selected index
  List<Widget> _widgetOptions() {
    return <Widget>[
      HomePageContent(prayerStatus: prayerStatus, onCheckboxChanged: _handleCheckboxChanged), // Home page content
      PrayerTimesScreen(prayerTimes: prayerTimes), // Prayer times page
      QiblaDirectionScreen(calculateQiblaAngle: (position) => calculateQiblaAngle()), // Qibla direction page
    ];
  }
}

// Widget for home page content
class HomePageContent extends StatelessWidget {
  final List<bool> prayerStatus; // List to store prayer status
  final Function(int, bool) onCheckboxChanged; // Callback function for checkbox change

  const HomePageContent({
    super.key,
    required this.prayerStatus,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      // Centering the content vertically
      child: Padding(
        padding: const EdgeInsets.symmetric(),
        child: Column(
          children: <Widget>[
            // Container for displaying header
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Text(
                'Today\'s Prayer Table', // Header text
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 150), // Spacer
            // List of checkboxes for prayers
            Column(
              children: List.generate(
                prayerNames.length,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width:5.0, color: Colors.red),
                  ),
                  // Checkbox for each prayer
                  child: CheckboxListTile(
                    title: Text(
                      prayerNames[index], // Prayer name
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: prayerStatus[index], // Value of checkbox
                    onChanged: (bool? value) {
                      if (value != null) {
                        onCheckboxChanged(index, value); // Callback function on checkbox change
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// List of prayer names
final List<String> prayerNames = [
  'Fajr',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];
