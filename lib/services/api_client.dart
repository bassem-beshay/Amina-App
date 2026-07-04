import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  final int statusCode;
  final dynamic rawResponse; // Can be Map or List

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    required this.statusCode,
    this.rawResponse,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? data,
    int statusCode,
  ) {
    return ApiResponse(
      success: json['success'] ?? (statusCode >= 200 && statusCode < 300),
      message: json['message'],
      data: data,
      error: json['error'],
      statusCode: statusCode,
      rawResponse: json,
    );
  }
}

class ApiClient {
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static Map<String, String> _getHeaders({bool needsAuth = false}) {
    if (needsAuth && _authToken != null) {
      return ApiConfig.getAuthHeaders(_authToken!);
    }
    return ApiConfig.headers;
  }

  // GET Request
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool needsAuth = false,
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(needsAuth: needsAuth),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // POST Request
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    bool needsAuth = false,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}$endpoint';

      // Debug logging
      print('🌐 POST Request: $url');
      print('📦 Body: ${body != null ? jsonEncode(body) : 'null'}');
      print('🔐 Auth: ${needsAuth ? 'Yes (Token: ${_authToken?.substring(0, 10)}...)' : 'No'}');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(needsAuth: needsAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ POST Error: $e');
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // POST Multipart (for file uploads)
  static Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    bool needsAuth = false,
    Map<String, String>? fields,
    Map<String, String>? filePaths, // key: field name, value: local file path
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest('POST', uri);

      // Add headers (but do not set Content-Type explicitly; MultipartRequest sets it)
      final headers = _getHeaders(needsAuth: needsAuth);
      // Remove Content-Type if present because MultipartRequest will set boundary
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      if (fields != null) request.fields.addAll(fields);

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          final field = entry.key;
          final path = entry.value;
          if (path.isNotEmpty) {
            final file = File(path);
            if (await file.exists()) {
              final multipartFile = await http.MultipartFile.fromPath(
                field,
                path,
              );
              request.files.add(multipartFile);
            }
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // PUT Multipart (for file uploads when updating)
  static Future<ApiResponse<T>> putMultipart<T>(
    String endpoint, {
    bool needsAuth = false,
    Map<String, String>? fields,
    Map<String, String>? filePaths,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest('PUT', uri);

      // Add headers (but do not set Content-Type explicitly; MultipartRequest sets it)
      final headers = _getHeaders(needsAuth: needsAuth);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          final field = entry.key;
          final path = entry.value;
          if (path.isNotEmpty) {
            final file = File(path);
            if (await file.exists()) {
              final multipartFile = await http.MultipartFile.fromPath(
                field,
                path,
              );
              request.files.add(multipartFile);
            }
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // PUT Request
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    bool needsAuth = false,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(needsAuth: needsAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // PATCH Request
  static Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    bool needsAuth = false,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(needsAuth: needsAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // DELETE Request
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool needsAuth = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(needsAuth: needsAuth),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في الاتصال: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // Handle Response
  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      // Check if response body looks like HTML (common server error)
      final body = response.body.trim();
      if (body.startsWith('<!DOCTYPE') || body.startsWith('<html') || body.startsWith('<HTML')) {
        return ApiResponse<T>(
          success: false,
          error: 'السيرفر غير متاح حالياً. يرجى المحاولة لاحقاً (Status: ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      // Check if response is a List (for endpoints that return arrays directly)
      if (decoded is List) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          T? data;
          if (fromJson != null) {
            data = fromJson(decoded);
          }

          return ApiResponse<T>(
            success: true,
            message: null,
            data: data,
            statusCode: response.statusCode,
            rawResponse: decoded,
          );
        }
      }

      // Handle Map responses (standard format)
      final jsonResponse = decoded as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        T? data;
        if (fromJson != null) {
          if (jsonResponse['data'] != null) {
            data = fromJson(jsonResponse['data']);
          } else if (jsonResponse['user'] != null) {
            data = fromJson(jsonResponse['user']);
          } else {
            data = fromJson(jsonResponse);
          }
        }

        return ApiResponse<T>(
          success: true,
          message: jsonResponse['message'],
          data: data,
          statusCode: response.statusCode,
          rawResponse: jsonResponse,
        );
      } else {
        String? errorMessage = jsonResponse['error'];

        if (errorMessage == null && jsonResponse['non_field_errors'] != null) {
          final nonFieldErrors = jsonResponse['non_field_errors'];
          if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
            errorMessage = nonFieldErrors[0].toString();
          }
        }

        if (errorMessage == null && jsonResponse['detail'] != null) {
          errorMessage = jsonResponse['detail'].toString();
        }

        // إضافة معلومات debug للمساعدة في تشخيص المشكلة
        String detailedError = errorMessage ?? 'حدث خطأ غير معروف';

        // إذا ما كانش في رسالة خطأ واضحة، نحاول نستخرج أي معلومات متاحة
        if (errorMessage == null) {
          // جمع كل الأخطاء من كل الحقول
          final allErrors = <String>[];
          jsonResponse.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              allErrors.add('$key: ${value.join(", ")}');
            } else if (value is String && value.isNotEmpty && key != 'message') {
              allErrors.add('$key: $value');
            }
          });

          if (allErrors.isNotEmpty) {
            detailedError = 'حدث خطأ:\n${allErrors.join('\n')}';
          } else {
            detailedError = 'حدث خطأ غير معروف (Status: ${response.statusCode})';
          }
        }

        return ApiResponse<T>(
          success: false,
          error: detailedError,
          message: jsonResponse['message'],
          statusCode: response.statusCode,
          rawResponse: jsonResponse,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'خطأ في معالجة البيانات. يرجى المحاولة لاحقاً',
        statusCode: response.statusCode,
      );
    }
  }
}
