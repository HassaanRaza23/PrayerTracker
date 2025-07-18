import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class QiblaDirectionScreen extends StatefulWidget {
  final Future<double> Function(Position) calculateQiblaAngle;

  const QiblaDirectionScreen({super.key, required this.calculateQiblaAngle});

  @override
  _QiblaDirectionScreenState createState() => _QiblaDirectionScreenState();
}

class _QiblaDirectionScreenState extends State<QiblaDirectionScreen> {  
  double azimuth = 0;
  String location = '';
  double qiblaAngle = 0; 
  late Image compassImage;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _startListening();
    _loadCompassImage();
  }

  void _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        location = '${position.latitude}, ${position.longitude}';
        _calculateQiblaAngle(position);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _calculateQiblaAngle(Position position) async {
    double angle = await widget.calculateQiblaAngle(position);
    setState(() {
      qiblaAngle = angle;
    });
  }

  void _startListening() {
    accelerometerEvents.listen((event) {
      setState(() {
        final x = event.x;
        final y = event.y;
        azimuth = math.atan2(y, x);
      });
    });
  }

  void _loadCompassImage() {
    compassImage = Image.asset('compass.png', width: 250); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Qibla Direction',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("bgg.png"), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
          ),
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 35, color: Colors.white), 
                  const SizedBox(width: 8),
                  Text(location,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: CompassPainter(qiblaAngle: qiblaAngle, compassImage: compassImage),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red, width: 6),
              ),
              child: Text('Qibla Angle: ${qiblaAngle.toStringAsFixed(2)}°',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassPainter extends StatelessWidget {
  final double qiblaAngle; 
  final Image compassImage;

  const CompassPainter({super.key, required this.qiblaAngle, required this.compassImage});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -qiblaAngle,
      child: Container(
        color: Colors.white.withOpacity(0.0),
        child: compassImage,
      ),
    );
  }
}
