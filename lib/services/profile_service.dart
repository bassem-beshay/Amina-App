import 'dart:io';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'storage_service.dart';

class ProfileService {
  // Update the authenticated company's profile and verification files.
  static Future<ApiResponse<Map<String, dynamic>>> updateCompanyProfile({
    File? logo,
    File? commercialRegisterDocument,
  }) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'Authentication token not found',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);
      final filePaths = <String, String>{};
      if (logo != null) filePaths['logo'] = logo.path;
      if (commercialRegisterDocument != null) {
        filePaths['commercial_register_document'] = commercialRegisterDocument.path;
      }

      return await ApiClient.putMultipart<Map<String, dynamic>>(
        ApiConfig.companyProfileMe,
        needsAuth: true,
        filePaths: filePaths.isEmpty ? null : filePaths,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Company profile update failed: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Get Client Profile
  static Future<ApiResponse<ClientProfile>> getClientProfile() async {
    try {

      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<ClientProfile>(
          success: false,
          error: 'لم يتم العثور على رمز المصادقة',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);

      final response = await ApiClient.get<ClientProfile>(
        '/api/users/client-profile/',
        needsAuth: true,
        fromJson: (json) {
          return ClientProfile.fromJson(json as Map<String, dynamic>);
        },
      );

      if (response.success && response.data != null) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse<ClientProfile>(
        success: false,
        error: 'خطأ في جلب الملف الشخصي: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // Update Client Profile
  static Future<ApiResponse<Map<String, dynamic>>> updateClientProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    File? profilePicture,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? city,
    String? country,
    List<int>? preferredServiceCategories,
  }) async {
    try {

      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'لم يتم العثور على رمز المصادقة',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);

      // Prepare fields
      Map<String, String> fields = {};
      if (firstName != null) fields['first_name'] = firstName;
      if (lastName != null) fields['last_name'] = lastName;
      if (phoneNumber != null) fields['phone_number'] = phoneNumber;
      if (latitude != null) fields['latitude'] = latitude.toString();
      if (longitude != null) fields['longitude'] = longitude.toString();
      if (formattedAddress != null) fields['formatted_address'] = formattedAddress;
      if (city != null) fields['city'] = city;
      if (country != null) fields['country'] = country;

      // Add preferred service categories (send as array using [] notation)
      if (preferredServiceCategories != null && preferredServiceCategories.isNotEmpty) {
        for (int i = 0; i < preferredServiceCategories.length; i++) {
          fields['preferred_service_categories[$i]'] = preferredServiceCategories[i].toString();
        }
      }


      // Prepare files
      Map<String, String>? filePaths;
      if (profilePicture != null) {
        filePaths = {'profile_picture': profilePicture.path};
      }


      final response = await ApiClient.putMultipart<Map<String, dynamic>>(
        '/api/users/client-profile/update_profile/',
        needsAuth: true,
        fields: fields,
        filePaths: filePaths,
        fromJson: (json) {
          return json as Map<String, dynamic>;
        },
      );

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'خطأ في تحديث الملف الشخصي: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // Get Provider Profile
  static Future<ApiResponse<ServiceProviderProfile>> getProviderProfile() async {
    try {

      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<ServiceProviderProfile>(
          success: false,
          error: 'لم يتم العثور على رمز المصادقة',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);

      final response = await ApiClient.get<ServiceProviderProfile>(
        '/api/users/provider-profile/',
        needsAuth: true,
        fromJson: (json) {
          return ServiceProviderProfile.fromJson(json as Map<String, dynamic>);
        },
      );

      if (response.success && response.data != null) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse<ServiceProviderProfile>(
        success: false,
        error: 'خطأ في جلب الملف الشخصي: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  // Update Provider Profile
  static Future<ApiResponse<Map<String, dynamic>>> updateProviderProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? city,
    String? formattedAddress,
    String? country,
    double? latitude,
    double? longitude,
    File? profilePicture,
    File? identityDocument,
    File? healthCertificate,
    List<int>? preferredServiceCategories,
  }) async {
    try {

      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'لم يتم العثور على رمز المصادقة',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);

      // Prepare fields
      Map<String, String> fields = {};
      if (firstName != null) fields['first_name'] = firstName;
      if (lastName != null) fields['last_name'] = lastName;
      if (phoneNumber != null) fields['phone_number'] = phoneNumber;
      if (bio != null) fields['bio'] = bio;
      if (city != null) fields['city'] = city;
      if (formattedAddress != null) fields['formatted_address'] = formattedAddress;
      if (country != null) fields['country'] = country;
      if (latitude != null) fields['latitude'] = latitude.toString();
      if (longitude != null) fields['longitude'] = longitude.toString();

      // Add preferred service categories
      // Send each category with indexed key for Django to parse as list
      if (preferredServiceCategories != null && preferredServiceCategories.isNotEmpty) {
        for (int i = 0; i < preferredServiceCategories.length; i++) {
          // Use indexed keys: preferred_service_categories[0], preferred_service_categories[1], etc.
          fields['preferred_service_categories[$i]'] = preferredServiceCategories[i].toString();
        }
      }


      // Prepare files
      Map<String, String> filePaths = {};
      if (profilePicture != null) {
        filePaths['profile_picture'] = profilePicture.path;
      }
      if (identityDocument != null) {
        filePaths['identity_document'] = identityDocument.path;
      }
      if (healthCertificate != null) {
        filePaths['health_certificate'] = healthCertificate.path;
      }

      final response = await ApiClient.putMultipart<Map<String, dynamic>>(
        '/api/users/provider-profile/update_profile/',
        needsAuth: true,
        fields: fields,
        filePaths: filePaths.isNotEmpty ? filePaths : null,
        fromJson: (json) {
          return json as Map<String, dynamic>;
        },
      );

      if (response.success) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'خطأ في تحديث الملف الشخصي: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }

  /// Submit the completed provider onboarding payload for admin review.
  static Future<ApiResponse<Map<String, dynamic>>> submitProviderVerification() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'Authentication token not found',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);
      return ApiClient.post<Map<String, dynamic>>(
        ApiConfig.submitProviderVerification,
        needsAuth: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Failed to submit verification: $e',
        statusCode: 0,
      );
    }
  }

  // Get User Info (Current authenticated user)
  static Future<ApiResponse<User>> getCurrentUser() async {
    try {

      final token = await StorageService.getAuthToken();
      if (token == null) {
        return ApiResponse<User>(
          success: false,
          error: 'لم يتم العثور على رمز المصادقة',
          statusCode: 401,
        );
      }

      ApiClient.setAuthToken(token);

      final response = await ApiClient.get<User>(
        '/api/users/auth/me/',
        needsAuth: true,
        fromJson: (json) {
          return User.fromJson(json as Map<String, dynamic>);
        },
      );

      if (response.success && response.data != null) {
      } else {
      }

      return response;
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        error: 'خطأ في جلب بيانات المستخدم: \u200F${e.toString()}\u200F',
        statusCode: 0,
      );
    }
  }
}
