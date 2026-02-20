import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ImgBBService {
  final String _apiKey = dotenv.get('IMGBB_API_KEY');
  final String _baseUrl = 'https://api.imgbb.com/1/upload';

  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['key'] = _apiKey;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr);
        return json['data']['url'] as String?;
      } else {
        throw Exception('ImgBB upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ImgBB Upload Error: $e');
      return null;
    }
  }
}
