import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:beras_app/models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.20.136:5000/';
  final storage = const FlutterSecureStorage();

  Future<UserModel?> login(String username, String password) async {
    print("Attempting login with: $username, $password");

    final response = await http.post(
      Uri.parse('${baseUrl}login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    print("Login response: ${response.statusCode}");
    print("Login response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: data['access_token']);
      return UserModel.fromJson(data);
    } else {
      return null;
    }
  }

  Future<bool> register(String username, String namaLengkap, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'nama_lengkap': namaLengkap,
        'password': password,
      }),
    );

    print("Register response: ${response.statusCode}");
    print("Register response body: ${response.body}");

    return response.statusCode == 201;
  }

  Future<List<dynamic>?> detectImage(Uint8List imageBytes) async {
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      return null;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl}detect'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      return data['detection_result'];
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }

  Future<void> saveDetectionResults(UserModel user, Map<String, int> detectionCounts) async {
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      return;
    }

    final response = await http.post(
      Uri.parse('${baseUrl}save_detection_results'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'detection_counts': detectionCounts,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save detection results');
    }
  }
  
  Future<List<dynamic>?> detectFrame(Uint8List frameBytes) async {
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      return null;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl}detect_frame'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('frame', frameBytes));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      return data['detection_result'];
    } else {
      return null;
    }
  }
}
