// lib/services/ai_service.dart

import 'dart:io';
import 'package:dio/dio.dart';

class AIService {
  static const String serverUrl =
      'https://parkinson-ai-backend-production.up.railway.app';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<Map<String, dynamic>> checkServer() async {
    try {
      final response = await _dio.get('$serverUrl/health');

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> analyzeFinger(File videoFile) async {
    return _uploadVideo(
      videoFile,
      '/analyze/finger',
    );
  }

  Future<Map<String, dynamic>> analyzeRomberg(File videoFile) async {
    return _uploadVideo(
      videoFile,
      '/analyze/romberg',
    );
  }

  Future<Map<String, dynamic>> analyzeTandem(File videoFile) async {
    return _uploadVideo(
      videoFile,
      '/analyze/tandem',
    );
  }

  Future<Map<String, dynamic>> _uploadVideo(
    File videoFile,
    String endpoint,
  ) async {
    try {
      print('Uploading video...');
      print('Endpoint: $endpoint');
      print('Video path: ${videoFile.path}');

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: 'video.mp4',
        ),
      });

      final response = await _dio.post(
        '$serverUrl$endpoint',
        data: formData,
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}',
      };
    } on DioException catch (e) {
      print('Dio Error: ${e.response?.data}');
      print('Dio Message: ${e.message}');

      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      print('General Error: $e');

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  void dispose() {
    _dio.close();
  }
}