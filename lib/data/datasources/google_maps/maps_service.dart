import 'dart:convert';
import 'package:http/http.dart' as http;

class MapsService {
  final String apiKey;

  MapsService(this.apiKey);

  Future<Map<String, dynamic>> getDistanceAndTime({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];

        return {
          'distance_meters': leg['distance']['value'],
          'duration_seconds': leg['duration']['value'],
        };
      } else {
        throw Exception('No route found');
      }
    } else {
      throw Exception('Failed to fetch directions');
    }
  }
}
