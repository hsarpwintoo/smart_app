import 'package:geolocator/geolocator.dart';

/// Holds a single GPS capture result.
class GpsLocation {
  GpsLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  @override
  String toString() =>
      'GpsLocation(lat: $latitude, lng: $longitude, at: $timestamp)';
}

/// Lightweight GPS service for the Smart Check-in MVP.
///
/// Usage:
///   final location = await GpsService.capture();
class GpsService {
  GpsService._();

  /// Requests permission when needed, then returns the current location.
  ///
  /// Throws a [GpsServiceException] with a human-readable message on any
  /// failure so the UI only needs a single try/catch.
  static Future<GpsLocation> capture() async {
    // 1. Check if location services are enabled on the device.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw GpsServiceException(
        'Location services are disabled. Please enable GPS and try again.',
      );
    }

    // 2. Check / request permission.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw GpsServiceException(
          'Location permission was denied. Please allow access and try again.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw GpsServiceException(
        'Location permission is permanently denied. '
        'Open app settings to grant access.',
      );
    }

    // 3. Get the current position (balanced accuracy is fine for attendance).
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return GpsLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }
}

/// Thrown by [GpsService] on any location capture failure.
class GpsServiceException implements Exception {
  GpsServiceException(this.message);

  final String message;

  @override
  String toString() => 'GpsServiceException: $message';
}
