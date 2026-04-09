import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final Dio _dio = Dio();

  /// Gets the current GPS position after requesting permissions
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permission denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissions are permanently denied
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  /// Searches for addresses using OpenStreetMap Nominatim
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
          'countrycodes': 'ma',
        },
        options: Options(
          headers: {
            'User-Agent': 'LivrApp/1.0 (contact@livrapp.local)',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final List data = response.data;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      // Nominatim may be blocked on web (CORS) or timeout — silently return empty
      if (e is DioException) {
        print('Nominatim Search Error (${e.type}): ${e.message}');
      } else {
        print('Nominatim Search Error: $e');
      }
      return [];
    }
  }

  /// Reverse geocodes coordinates to get an address and city
  Future<Map<String, dynamic>?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'LivrApp/1.0 (contact@livrapp.local)'},
        ),
      );

      return response.data as Map<String, dynamic>?;
    } catch (e) {
      print('Nominatim Reverse Geocoding Error: $e');
      return null;
    }
  }
}
