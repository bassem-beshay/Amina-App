import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class ProviderService {
  /// Get all providers (workers)
  static Future<List<Provider>> getProviders() async {
    try {

      final token = ApiClient.authToken;
      final headers = token != null
          ? ApiConfig.getAuthHeaders(token)
          : ApiConfig.headers;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/providers/'),
        headers: headers,
      );


      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        // Check if response is a list or an object
        List<dynamic> data;
        if (decodedBody is List) {
          data = decodedBody;
        } else if (decodedBody is Map && decodedBody.containsKey('results')) {
          // Django REST framework pagination response
          data = decodedBody['results'] as List<dynamic>;
        } else if (decodedBody is Map && decodedBody.containsKey('data')) {
          data = decodedBody['data'] as List<dynamic>;
        } else {
          return [];
        }


        final providers = data.map((json) => Provider.fromJson(json)).toList();

        // Debug: print first provider if available
        if (providers.isNotEmpty) {
        }

        return providers;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get provider by ID
  static Future<Provider?> getProviderById(int id) async {
    try {

      final token = ApiClient.authToken;
      final headers = token != null
          ? ApiConfig.getAuthHeaders(token)
          : ApiConfig.headers;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/providers/$id/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Provider.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get available providers only
  static Future<List<Provider>> getAvailableProviders() async {
    try {
      final allProviders = await getProviders();
      return allProviders.where((provider) => provider.isAvailable).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get top rated providers
  static Future<List<Provider>> getTopRatedProviders({int limit = 10}) async {
    try {
      final allProviders = await getProviders();

      // Filter out providers without ratings
      final ratedProviders = allProviders
          .where((provider) => provider.averageRating != null && provider.averageRating! > 0)
          .toList();


      // If no providers have ratings, return all providers (up to limit)
      if (ratedProviders.isEmpty) {
        final allProvidersLimited = allProviders.take(limit).toList();
        return allProvidersLimited;
      }

      // Sort by rating (descending)
      ratedProviders.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));

      // Return top providers up to limit
      final topProviders = ratedProviders.take(limit).toList();

      return topProviders;
    } catch (e) {
      return [];
    }
  }
}
