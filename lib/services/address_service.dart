import 'api_client.dart';
import '../config/api_config.dart';

class AddressService {
  /// Get all addresses for the current user
  static Future<ApiResponse<List<Map<String, dynamic>>>> getAddresses() async {

    final response = await ApiClient.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/users/client-profile/addresses/',
      needsAuth: true,
    );


    if (response.success) {
      // Check if we have rawResponse (for List endpoints)
      final dynamic responseData = response.rawResponse ?? response.data;

      if (responseData != null) {

        final addresses = (responseData as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        for (var addr in addresses) {
        }

        return ApiResponse(
          success: true,
          data: addresses,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse(
      success: false,
      error: response.error ?? 'Failed to fetch addresses',
      statusCode: response.statusCode,
    );
  }

  /// Add a new address
  static Future<ApiResponse<Map<String, dynamic>>> addAddress({
    String? label,
    required double latitude,
    required double longitude,
    required String address,
    required String city,
    String? country,
    bool isDefault = false,
  }) async {

    final body = {
      if (label != null && label.isNotEmpty) 'label': label,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'address': address,
      'city': city,
      if (country != null && country.isNotEmpty) 'country': country,
      'is_default': isDefault,
    };

    final response = await ApiClient.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/users/client-profile/add_address/',
      body: body,
      needsAuth: true,
    );

    if (response.success) {
      return response;
    }

    return ApiResponse(
      success: false,
      error: response.error ?? 'Failed to add address',
      statusCode: response.statusCode,
    );
  }

  /// Update an existing address
  static Future<ApiResponse<Map<String, dynamic>>> updateAddress({
    required int addressId,
    String? label,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (latitude != null) body['latitude'] = latitude.toString();
    if (longitude != null) body['longitude'] = longitude.toString();
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (country != null) body['country'] = country;
    if (isDefault != null) body['is_default'] = isDefault;

    final response = await ApiClient.put<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/users/client-profile/$addressId/update_address/',
      body: body,
      needsAuth: true,
    );

    return response;
  }

  /// Set an address as default
  static Future<ApiResponse<Map<String, dynamic>>> setDefaultAddress(
      int addressId) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/users/client-profile/$addressId/set_default/',
      needsAuth: true,
    );

    return response;
  }

  /// Delete an address
  static Future<ApiResponse<void>> deleteAddress(int addressId) async {
    final response = await ApiClient.delete(
      '${ApiConfig.apiPrefix}/users/client-profile/$addressId/delete_address/',
      needsAuth: true,
    );

    return response;
  }

  // ============================================================
  // Provider Address Methods
  // ============================================================

  /// Get all addresses for the provider
  static Future<ApiResponse<List<Map<String, dynamic>>>> getProviderAddresses() async {

    final response = await ApiClient.get<List<dynamic>>(
      ApiConfig.providerAddresses,
      needsAuth: true,
    );


    if (response.success) {
      // Check if we have rawResponse (for List endpoints)
      final dynamic responseData = response.rawResponse ?? response.data;

      if (responseData != null) {

        final addresses = (responseData as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        for (var addr in addresses) {
        }

        return ApiResponse(
          success: true,
          data: addresses,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse(
      success: false,
      error: response.error ?? 'Failed to fetch addresses',
      statusCode: response.statusCode,
    );
  }

  /// Add a new address for provider
  static Future<ApiResponse<Map<String, dynamic>>> addProviderAddress({
    String? label,
    required double latitude,
    required double longitude,
    required String address,
    required String city,
    String? country,
    bool isDefault = false,
  }) async {

    final body = {
      if (label != null && label.isNotEmpty) 'label': label,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'address': address,
      'city': city,
      if (country != null && country.isNotEmpty) 'country': country,
      'is_default': isDefault,
    };

    final response = await ApiClient.post<Map<String, dynamic>>(
      ApiConfig.addProviderAddress,
      body: body,
      needsAuth: true,
    );

    if (response.success) {
      return response;
    }

    return ApiResponse(
      success: false,
      error: response.error ?? 'Failed to add address',
      statusCode: response.statusCode,
    );
  }

  /// Set an address as default for provider
  static Future<ApiResponse<Map<String, dynamic>>> setProviderDefaultAddress(
      int addressId) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      ApiConfig.setProviderDefaultAddress(addressId),
      needsAuth: true,
    );

    return response;
  }

  /// Delete a provider address
  static Future<ApiResponse<void>> deleteProviderAddress(int addressId) async {
    final response = await ApiClient.delete(
      ApiConfig.deleteProviderAddress(addressId),
      needsAuth: true,
    );

    return response;
  }
}
