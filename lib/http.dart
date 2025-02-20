import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> checkNearbyCameras(double lat, double lon) async {
  final url = Uri.parse(
      "http://192.168.1.73:8080/api/cameras/nearby?userLat=$lat&userLon=$lon");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> cameras = json.decode(response.body);
    if (cameras.isNotEmpty) {
      print("🚨 ALERT: You are near a camera!");
    } else {
      print("✅ No cameras nearby.");
    }
  }
}
