import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Requests permission (if needed) and returns the device's current
  /// GPS position. Throws a [LocationServiceException] on failure so the
  /// UI layer can show an actionable message instead of crashing.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'خدمة الموقع غير مفعّلة. برجاء تفعيل GPS من إعدادات الجهاز.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'تم رفض إذن الوصول للموقع. الموقع مطلوب لعرض المدرسين القريبين منك.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'إذن الموقع مرفوض بشكل دائم. برجاء تفعيله يدويًا من إعدادات التطبيق.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<GeoPoint> getCurrentGeoPoint() async {
    final position = await getCurrentPosition();
    return GeoPoint(position.latitude, position.longitude);
  }

  /// Haversine formula: great-circle distance between two points on Earth
  /// in kilometers. Used as the client-side / Cloud Function fallback for
  /// precise distance display ("Away by X KM") after Firestore's geohash
  /// query has already narrowed candidates down to a bounding radius.
  double distanceInKm(GeoPoint from, GeoPoint to) {
    const earthRadiusKm = 6371.0;

    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final deltaLat = _degToRad(to.latitude - from.latitude);
    final deltaLon = _degToRad(to.longitude - from.longitude);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}
