import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hijri/hijri_calendar.dart';


class PrayerTimesScreen extends StatefulWidget {
  final PrayerTimes? prayerTimes;

  const PrayerTimesScreen({super.key, this.prayerTimes});

  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late AudioPlayer _audioPlayer;
  final Map<String, bool> _muteStates = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  late Timer _timer;
  late String _remainingTime = '';
  late String _currentPrayer = ''; 
  late Position _currentPosition;
  String _currentAddress = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _schedulePrayerTimeAlerts();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    _getAddressFromLatLng();
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            "${place.name}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Prayer Times',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.8,
            child: Image.asset(
              'bg2.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildDateTimeInfo(),
                  const SizedBox(height: 10),
                  if (widget.prayerTimes != null)
                    ..._buildPrayerTimes(widget.prayerTimes!)
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    HijriCalendar hijriCalendar = HijriCalendar.now();
    String islamicDate = hijriCalendar.toFormat("dd-MM-yyyy");
    String normalDate = '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';
    String location = _currentAddress.isNotEmpty
        ? _currentAddress
        : 'Location not available'; 

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.6), 
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Center( 
                  child: _buildCountdownWidget(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateTimeRow(Icons.calendar_today_outlined , 'Islamic Date: ', islamicDate),
                    const SizedBox(height: 20),
                    _buildDateTimeRow(Icons.calendar_today, 'Date: ', normalDate),
                    const SizedBox(height: 10),
                    _buildDateTimeRow(Icons.location_on, 'Location: ', 'Egham'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownWidget() {
    return Container(
      width: 150,
      height: 150,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 10.0, color: Colors.red),
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentPrayer,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _remainingTime,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDateTimeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white, 
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white, 
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPrayerTimes(PrayerTimes prayerTimes) {
    return [
      buildPrayerTime('Fajr', prayerTimes.fajr),
      buildPrayerTime('Sunrise', prayerTimes.sunrise),
      buildPrayerTime('Dhuhr', prayerTimes.dhuhr),
      buildPrayerTime('Asr', prayerTimes.asr),
      buildPrayerTime('Maghrib', prayerTimes.maghrib),
      buildPrayerTime('Isha', prayerTimes.isha),
    ];
  }

  Widget buildPrayerTime(String title, DateTime time) {
    final formattedHour = '${time.hour}'.padLeft(2, '0');
    final formattedMinute = '${time.minute}'.padLeft(2, '0');
    final formattedSecond = '${time.second}'.padLeft(2, '0');
    final formattedTime = '$formattedHour:$formattedMinute:$formattedSecond';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _toggleMute(title),
                  icon: Icon(
                    _muteStates[title] ?? false ? Icons.volume_off : Icons.volume_up,
                  ),
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMute(String title) async {
    setState(() {
      _muteStates[title] = !_muteStates[title]!;
    });

    if (!_muteStates[title]!) {
      if (_isPrayerTime(title)) {
        String audioPath = await _getAudioPathForPrayer(title);
        if (audioPath.isNotEmpty) {
          await _audioPlayer.setAsset(audioPath);
          await _audioPlayer.play();
        }
      }
    } else {
      _audioPlayer.stop();
    }
  }

  bool _isPrayerTime(String title) {
    DateTime? currentTime;
    switch (title) {
      case 'Fajr':
        currentTime = widget.prayerTimes?.fajr;
        break;
      case 'Sunrise':
        currentTime = widget.prayerTimes?.sunrise;
        break;
      case 'Dhuhr':
        currentTime = widget.prayerTimes?.dhuhr;
        break;
      case 'Asr':
        currentTime = widget.prayerTimes?.asr;
        break;
      case 'Maghrib':
        currentTime = widget.prayerTimes?.maghrib;
        break;
      case 'Isha':
        currentTime = widget.prayerTimes?.isha;
        break;
    }

    if (currentTime != null) {
      final now = DateTime.now();
      final difference = currentTime.difference(now);
      return difference.inSeconds <= 0 && difference.inSeconds >= -60; 
    }

    return false;
  }

  Future<String> _getAudioPathForPrayer(String title) async {
    Map<String, String> audioPaths = {
      'Fajr': 'assets/adhan.mp3',
      'Dhuhr': 'assets/adhan.mp3',
      'Asr': 'assets/adhan.mp3',
      'Maghrib': 'assets/adhan.mp3',
      'Isha': 'assets/adhan.mp3',
    };

    return audioPaths[title] ?? '';
  }

  void _schedulePrayerTimeAlerts() {
    if (widget.prayerTimes != null) {
      final prayerTimes = widget.prayerTimes!;
      final now = DateTime.now();
      for (final prayerTime in [
        prayerTimes.fajr,
        prayerTimes.dhuhr,
        prayerTimes.asr,
        prayerTimes.maghrib,
        prayerTimes.isha,
      ]) {
        final difference = prayerTime.difference(now);
        if (difference > Duration.zero) {
          Future.delayed(difference, () {
            if (!_muteStates.containsValue(true) && _isPrayerTimeForTime(prayerTime)) {
              _playAdhan();
            }
          });
        }
      }
    }
  }

  bool _isPrayerTimeForTime(DateTime prayerTime) {
    final now = DateTime.now();
    final difference = prayerTime.difference(now);
    return difference.inSeconds <= 0 && difference.inSeconds >= -60; 
  }

  void _playAdhan() async {
    await _audioPlayer.setAsset('assets/adhan.mp3');
    await _audioPlayer.play();
  }

  void _updateRemainingTime() {
    if (widget.prayerTimes != null) {
      final now = DateTime.now();
      String currentPrayer = _getCurrentPrayer(now);
      DateTime currentPrayerTime = _getnextPrayerTime(now);

      final difference = currentPrayerTime.difference(now);
      int remainingHours = difference.inHours;
      int remainingMinutes = difference.inMinutes.remainder(60);
      int remainingSeconds = difference.inSeconds.remainder(60);

      setState(() {
        _remainingTime = '${remainingHours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
        _currentPrayer = currentPrayer;
      });
    }
  }

  String _getCurrentPrayer(DateTime currentTime) {
    if (currentTime.isBefore(widget.prayerTimes!.sunrise)) {
      return 'Fajr';
    } else if (currentTime.isBefore(widget.prayerTimes!.dhuhr)) {
      return 'Sunrise';
    } else if (currentTime.isBefore(widget.prayerTimes!.asr)) {
      return 'Duhr';
    } else if (currentTime.isBefore(widget.prayerTimes!.maghrib)) {
      return 'Asr';
    } else if (currentTime.isBefore(widget.prayerTimes!.isha)) {
      return 'Maghrib';
    } else {
      return 'Isha';
    }
  }

  DateTime _getnextPrayerTime(DateTime currentTime) {
    if (currentTime.isBefore(widget.prayerTimes!.fajr)) {
      return widget.prayerTimes!.fajr;
    } else if (currentTime.isBefore(widget.prayerTimes!.sunrise)) {
      return widget.prayerTimes!.sunrise;
    } else if (currentTime.isBefore(widget.prayerTimes!.dhuhr)) {
      return widget.prayerTimes!.dhuhr;
    } else if (currentTime.isBefore(widget.prayerTimes!.asr)) {
      return widget.prayerTimes!.asr;
    }else if (currentTime.isBefore(widget.prayerTimes!.maghrib)) {
      return widget.prayerTimes!.maghrib;
    } else {
      return widget.prayerTimes!.isha;
    }
  }

}

