import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/profile_service.dart';
import '../services/address_service.dart';
import '../services/service_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  State<EditClientProfileScreen> createState() =>
      _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Form fields
  File? _profilePicture;
  List<int> _selectedCategories = [];
  List<ServiceCategory> _availableCategories = [];

  // Location fields
  double? _latitude;
  double? _longitude;
  String? _formattedAddress;
  String? _city;
  String? _country;

  // UI state
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  ClientProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCategories();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      // Load client profile
      final response = await ProfileService.getClientProfile();
      if (response.success && response.data != null) {
        setState(() {
          _currentProfile = response.data;
          _selectedCategories =
              response.data!.preferredServiceCategories ?? [];

          // Update controllers with basic info only
          _firstNameController.text = response.data!.user?.firstName ?? '';
          _lastNameController.text = response.data!.user?.lastName ?? '';
          _phoneController.text = response.data!.user?.phoneNumber ?? '';
        });
      } else {
        _showError(response.error ?? (AppLocalizations.of(context)?.translate('failedToLoadData') ?? 'فشل تحميل البيانات'));
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showError('${localizations?.errorLoadingData ?? 'خطأ في تحميل البيانات'}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final categories = await ServiceService.getCategories();
      setState(() {
        _availableCategories = categories;
      });
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showError('${localizations?.errorLoadingCategories ?? 'خطأ في تحميل الفئات'}: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _profilePicture = File(image.path);
      });
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final localizations = AppLocalizations.of(context);
          _showError(localizations?.locationPermissionDeniedMessage ?? 'تم رفض إذن الموقع');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final localizations = AppLocalizations.of(context);
        _showError(localizations?.locationPermissionDeniedPermanently ?? 'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من الإعدادات');
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocoding to get address details
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        // Build formatted address
        String formattedAddr = '';
        if (place.street != null && place.street!.isNotEmpty) {
          formattedAddr = place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          formattedAddr += formattedAddr.isEmpty ? place.locality! : ', ${place.locality}';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty && place.administrativeArea != place.locality) {
          formattedAddr += formattedAddr.isEmpty ? place.administrativeArea! : ', ${place.administrativeArea}';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          formattedAddr += formattedAddr.isEmpty ? place.country! : ', ${place.country}';
        }

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          final localizations = AppLocalizations.of(context);
          _city = place.locality ?? place.administrativeArea ?? (localizations?.unspecifiedText ?? 'غير محدد');
          _country = place.country ?? '';
          _formattedAddress = formattedAddr.isNotEmpty ? formattedAddr : (localizations?.unspecifiedText ?? 'غير محدد');
        });
        final localizations = AppLocalizations.of(context);
        _showSuccess(localizations?.locationDetectedSuccess ?? 'تم تحديد الموقع بنجاح');
      } else {
        final localizations = AppLocalizations.of(context);
        _showError(localizations?.noLocationInfo ?? 'لم يتم العثور على معلومات الموقع');
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showError('${localizations?.errorDetectingLocation ?? 'خطأ في تحديد الموقع'}: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      // Get values from controllers
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();


      final response = await ProfileService.updateClientProfile(
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
        profilePicture: _profilePicture,
        country: _country,
        preferredServiceCategories: _selectedCategories,
      );

      if (response.success) {
        // If location is detected, save it as an address automatically
        if (_latitude != null && _longitude != null && _formattedAddress != null) {
          final addressResponse = await AddressService.addAddress(
            label: null,
            latitude: _latitude!,
            longitude: _longitude!,
            address: _formattedAddress!,
            city: _city ?? '',
            country: _country,
            isDefault: false,
          );

          if (addressResponse.success) {
            // Check if it's a duplicate address
            final isDuplicate = addressResponse.rawResponse?['is_duplicate'] == true;
            if (isDuplicate) {
            } else {
            }
          } else {
          }
        }

        // Refresh user data from server to get updated country
        final authResult = await AuthService.fetchCurrentUser();
        if (authResult.success) {
        } else {
        }

        final localizations = AppLocalizations.of(context);
        _showSuccess(localizations?.profileUpdatedSuccess ?? 'تم تحديث الملف الشخصي بنجاح');
        await _loadProfile(); // Reload to get updated data

        // Return true to trigger address reload in profile screen
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        final localizations = AppLocalizations.of(context);
        _showError(response.error ?? (localizations?.failedToUpdateProfile ?? 'فشل تحديث الملف الشخصي'));
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showError('${localizations?.errorUpdating ?? 'خطأ في التحديث'}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildPreferredCategoriesSection() {
    // Map of category names to icons and colors
    final categoryIcons = {
      'تنظيف منزلي': {'icon': Icons.cleaning_services, 'color': const Color(0xFF10B981)},
      'طبخ': {'icon': Icons.restaurant, 'color': const Color(0xFFF59E0B)},
      'رعاية أطفال': {'icon': Icons.child_care, 'color': const Color(0xFF3B82F6)},
      'رعاية مسنين': {'icon': Icons.accessible, 'color': const Color(0xFF8B5CF6)},
      'غسيل ملابس': {'icon': Icons.local_laundry_service, 'color': const Color(0xFFEC4899)},
      'كي ملابس': {'icon': Icons.checkroom, 'color': const Color(0xFF06B6D4)},
    };

    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    if (_availableCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppLocalizations.of(context)?.noCategoriesAvailable ?? 'لا توجد فئات خدمات متاحة حالياً',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _availableCategories.map((category) {
        final isSelected = _selectedCategories.contains(category.id);
        final iconData = categoryIcons[category.name];
        final icon = iconData?['icon'] as IconData? ?? Icons.category;
        final color = iconData?['color'] as Color? ?? const Color(0xFF8B5CF6);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity( 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity( 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  if (!_selectedCategories.contains(category.id)) {
                    _selectedCategories.add(category.id);
                  }
                } else {
                  _selectedCategories.remove(category.id);
                }
              });
            },
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            activeColor: color,
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.editProfile),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icons/app-icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _profilePicture != null
                                  ? FileImage(_profilePicture!)
                                  : (_currentProfile?.hasProfilePicture ?? false
                                      ? NetworkImage(
                                          _currentProfile!.profilePictureUrl!)
                                      : null) as ImageProvider?,
                              child: (_profilePicture == null &&
                                      !(_currentProfile?.hasProfilePicture ??
                                          false))
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Theme.of(context).colorScheme.surface,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // First Name Field
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: localizations.firstName,
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? localizations.fieldRequired : null,
                    ),
                    const SizedBox(height: 16),

                    // Last Name Field
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: localizations.lastName,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? localizations.fieldRequired : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: localizations.phoneNumber,
                        prefixIcon: const Icon(Icons.phone),
                        hintText: '01XXXXXXXXX',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return localizations.fieldRequired;
                        }
                        final phoneRegex = RegExp(r'^(\+?2)?01[0125][0-9]{8}$');
                        if (!phoneRegex.hasMatch(value!.replaceAll(' ', ''))) {
                          return 'يرجى إدخال رقم هاتف صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Preferred Service Categories Section
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.preferredServices ?? 'الخدمات المفضلة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.selectPreferredServicesHint ?? 'اختر الخدمات التي تهتم بها لتسهيل عملية البحث',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPreferredCategoriesSection(),
                    const SizedBox(height: 24),

                    // Location Section
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.optionalLocation ?? 'الموقع (اختياري)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Detect Location Button
                    ConnectivityIconButton(
                      onPressed: _isLoading ? null : _detectLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(AppLocalizations.of(context)?.detectCurrentLocation ?? 'تحديد موقعي الحالي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)?.locationDetected ?? 'تم تحديد الموقع',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '📍 ${AppLocalizations.of(context)?.addressLabelText ?? 'العنوان'}: $_formattedAddress',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🏙️ ${AppLocalizations.of(context)?.cityLabelText ?? 'المدينة'}: $_city',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)?.addressWillBeSavedAuto ?? 'سيتم حفظ هذا العنوان تلقائياً في العناوين المحفوظة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Save Button
                    const SizedBox(height: 20),
                    ConnectivityButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              localizations.save,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

}
