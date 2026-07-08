import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/profile_service.dart';
import '../services/address_service.dart';
import '../services/service_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/connectivity_button.dart';

class EditProfileScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;
  const EditProfileScreen({
    super.key,
    required this.token,
    required this.userData,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController bioController;
  late TextEditingController phoneController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;

  // Client-specific controllers
  late TextEditingController cityController;
  late TextEditingController formattedAddressController;

  bool isLoading = false;
  String message = '';
  String? profilePicturePath;
  String? identityDocumentPath;
  String? healthCertificatePath;

  // Client location (optional)
  double? latitude;
  double? longitude;
  String? country; // Country extracted from GPS
  bool isLoadingLocation = false;

  // Provider service categories
  List<dynamic> _allCategories = [];
  Set<int> _selectedCategories = {};
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    phoneController = TextEditingController(
      text: widget.userData['phone_number'] ?? widget.userData['phone'] ?? '',
    );
    firstNameController = TextEditingController(
      text: widget.userData['first_name'] ?? '',
    );
    lastNameController = TextEditingController(
      text: widget.userData['last_name'] ?? '',
    );
    addressController = TextEditingController(
      text: widget.userData['address_line_1'] ?? '',
    );

    // Client-specific fields
    cityController = TextEditingController(text: widget.userData['city'] ?? '');
    formattedAddressController = TextEditingController(
      text: widget.userData['formatted_address'] ?? '',
    );

    // Initialize location if exists
    if (widget.userData['latitude'] != null) {
      latitude = double.tryParse(widget.userData['latitude'].toString());
    }
    if (widget.userData['longitude'] != null) {
      longitude = double.tryParse(widget.userData['longitude'].toString());
    }

    // Load categories for both providers and clients
    final role = widget.userData['role']?.toString().toUpperCase();
    if (role == 'PROVIDER' || role == 'CLIENT') {
      _loadCategories();
    }

    // Debug: طباعة البيانات المستلمة
  }

  @override
  void dispose() {
    bioController.dispose();
    phoneController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    formattedAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      // Load all categories
      final categories = await ServiceService.getCategories();

      // Get current user's preferences

      final List<int> currentPreferences =
          widget.userData['preferred_service_categories'] != null
              ? List<int>.from(widget.userData['preferred_service_categories'])
              : [];


      setState(() {
        _allCategories = categories;
        _selectedCategories = Set<int>.from(currentPreferences);
        _isLoadingCategories = false;
      });

    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفئات: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // التحقق من الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('الرجاء السماح بالوصول للموقع'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض إذن الموقع نهائيًا. الرجاء تفعيله من الإعدادات'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // الحصول على الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      // الحصول على العنوان من الإحداثيات
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          // بناء العنوان التفصيلي
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }

          String formattedAddress = addressParts.join('، ');

          setState(() {
            // تحديث المدينة (read-only)
            cityController.text = place.locality ?? place.administrativeArea ?? '';
            // تحديث الدولة
            country = place.country ?? '';
            // تحديث العنوان التفصيلي
            formattedAddressController.text = formattedAddress;
          });


          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('تم تحديد موقعك بنجاح'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        // حتى لو فشل العنوان، الإحداثيات تم حفظها
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديد الموقع، لكن فشل الحصول على اسم المدينة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحصول على الموقع: \u200F${e.toString()}\u200F'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      isLoadingLocation = false;
    });
  }

  Future<void> updateProfile() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      isLoading = true;
      message = '';
    });

    final roleValue = (widget.userData['role'] ?? '').toString().toLowerCase();
    try {
      if (roleValue == 'provider' || roleValue == 'provider'.toLowerCase()) {
        final fields = {
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'phone_number': phoneController.text,
          'bio': bioController.text,
        };

        // Add location fields if available
        if (latitude != null) {
          fields['latitude'] = latitude.toString();
        }
        if (longitude != null) {
          fields['longitude'] = longitude.toString();
        }
        if (formattedAddressController.text.isNotEmpty) {
          fields['formatted_address'] = formattedAddressController.text;
        }
        if (cityController.text.isNotEmpty) {
          fields['city'] = cityController.text;
        }

        // Add preferred service categories
        if (_selectedCategories.isNotEmpty) {
          int index = 0;
          for (int categoryId in _selectedCategories) {
            fields['preferred_service_categories[$index]'] = categoryId.toString();
            index++;
          }
        }

        // التأكد من اختيار الملفات الصحيحة
        final files = <String, String>{};
        if (profilePicturePath != null && profilePicturePath!.isNotEmpty) {
          final file = File(profilePicturePath!);
          if (await file.exists()) {
            files['profile_picture'] = profilePicturePath!;
          } else {
          }
        } else {
        }

        if (identityDocumentPath != null && identityDocumentPath!.isNotEmpty) {
          final file = File(identityDocumentPath!);
          if (await file.exists()) {
            files['identity_document'] = identityDocumentPath!;
          } else {
          }
        }

        if (healthCertificatePath != null && healthCertificatePath!.isNotEmpty) {
          final file = File(healthCertificatePath!);
          if (await file.exists()) {
            files['health_certificate'] = healthCertificatePath!;
          } else {
          }
        }


        final resp = files.isNotEmpty
            ? await ApiClient.putMultipart(
                ApiConfig.updateProviderProfile,
                needsAuth: true,
                fields: fields,
                filePaths: files,
              )
            : await ApiClient.put(
                ApiConfig.updateProviderProfile,
                needsAuth: true,
                body: fields,
              );
        
        
        if (resp.success) {

          // If location is detected, save it as an address automatically (for providers)
          if (latitude != null && longitude != null && formattedAddressController.text.isNotEmpty) {
            final addressResponse = await AddressService.addProviderAddress(
              label: null,
              latitude: latitude!,
              longitude: longitude!,
              address: formattedAddressController.text,
              city: cityController.text.isEmpty ? '' : cityController.text,
              country: country,
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

          // لو تم رفع وثائق جديدة، أظهر رسالة توضيحية
          if (files.isNotEmpty && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تم رفع الوثائق بنجاح! حسابك الآن قيد المراجعة من قبل الإدارة',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (resp.rawResponse != null && resp.rawResponse!['profile_picture'] != null) {
          }

          // Refresh user data from server to get updated country
          final authResult = await AuthService.fetchCurrentUser();
          if (authResult.success) {
          } else {
          }

          // رجع البيانات المحدثة
          if (context.mounted) Navigator.of(context).pop(true);
        } else {
          setState(() {
            message = resp.error ?? 'Failed to update profile';
          });
        }
      } else {
        // client - استخدام ProfileService

        File? profilePicFile;
        if (profilePicturePath != null && profilePicturePath!.isNotEmpty) {
          profilePicFile = File(profilePicturePath!);
        }

        // Get first and last name from controllers
        final firstName = firstNameController.text.trim();
        final lastName = lastNameController.text.trim();
        final phoneNumber = phoneController.text.trim();

        final resp = await ProfileService.updateClientProfile(
          firstName: firstName.isNotEmpty ? firstName : null,
          lastName: lastName.isNotEmpty ? lastName : null,
          phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
          profilePicture: profilePicFile,
          city: cityController.text.isNotEmpty ? cityController.text : null,
          formattedAddress: formattedAddressController.text.isNotEmpty
              ? formattedAddressController.text
              : null,
          latitude: latitude,
          longitude: longitude,
          preferredServiceCategories: _selectedCategories.toList(),
        );



        if (resp.success) {

          // If location is detected, save it as an address automatically
          if (latitude != null && longitude != null && formattedAddressController.text.isNotEmpty) {
            final addressResponse = await AddressService.addAddress(
              label: null,
              latitude: latitude!,
              longitude: longitude!,
              address: formattedAddressController.text,
              city: cityController.text.isEmpty ? '' : cityController.text,
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

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(localizations.success),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            message = resp.error ?? 'فشل تحديث الملف الشخصي';
          });
        }
      }
    } catch (e) {
      setState(() {
        message = 'An error occurred: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  ImageProvider? _getEditImageProvider() {
    // لو اختار صورة جديدة، اعرضها
    if (profilePicturePath != null && profilePicturePath!.isNotEmpty) {
      return FileImage(File(profilePicturePath!));
    }

    // لو فيه صورة قديمة، اعرضها
    // جرب profile_picture_url الأول (من الـ API الجديد)
    var currentPicture = widget.userData['profile_picture_url'];

    // لو مش موجود، جرب profile_picture (fallback)
    if (currentPicture == null || (currentPicture as String).isEmpty) {
      currentPicture = widget.userData['profile_picture'];
    }

    if (currentPicture != null && (currentPicture as String).isNotEmpty) {
      String imageUrl = currentPicture;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }
      return NetworkImage(imageUrl);
    }

    return null;
  }

  Widget _buildDocumentPicker({
    required String title,
    required IconData icon,
    String? currentPath,
    String? existingDocUrl,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    // تحديد حالة الوثيقة
    bool hasNewFile = currentPath != null && currentPath.isNotEmpty;
    bool hasExistingFile = existingDocUrl != null && existingDocUrl.isNotEmpty;
    bool hasAnyFile = hasNewFile || hasExistingFile;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isLocked) {
      statusText = '🔒 لا يمكن التعديل - الحساب موثق';
      statusColor = Colors.grey[600]!;
      statusIcon = Icons.lock;
    } else if (hasNewFile) {
      statusText = 'ملف جديد محدد - جاهز للرفع';
      statusColor = Colors.orange;
      statusIcon = Icons.upload_file;
    } else if (hasExistingFile) {
      statusText = 'الوثيقة مرفوعة - اضغط لتغييرها';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'اضغط لاختيار ملف (PDF, JPG, PNG)';
      statusColor = Colors.grey[600]!;
      statusIcon = Icons.upload_file;
    }

    return InkWell(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[200] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked ? Colors.grey[400]! : (hasAnyFile ? statusColor : Colors.grey[300]!),
            width: hasAnyFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: hasAnyFile || isLocked ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              statusIcon,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.editProfile)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // الاسم الأول
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: localizations.firstName,
                hintText: 'مثال: أحمد',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // اسم العائلة
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: localizations.lastName,
                hintText: 'مثال: السعيد',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // رقم الهاتف
            TextField(
              controller: phoneController,
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
            ),
            const SizedBox(height: 16),

            // قائمة فئات الخدمات المفضلة - للعملاء والمزودين
            Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A148C).withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.category,
                              color: Color(0xFF4A148C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'فئات الخدمات المفضلة',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.userData['role']?.toString().toUpperCase() == 'PROVIDER'
                                      ? 'اختر الخدمات التي تقدمها'
                                      : 'اختر الخدمات التي تهتم بها',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_allCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'لا توجد فئات متاحة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allCategories.length,
                        itemBuilder: (context, index) {
                          final category = _allCategories[index];
                          final categoryId = category.id;
                          final isSelected = _selectedCategories.contains(categoryId);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCategories.add(categoryId);
                                } else {
                                  _selectedCategories.remove(categoryId);
                                }
                              });
                            },
                            title: Text(
                              category.name,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: category.description != null && category.description!.isNotEmpty
                                ? Text(
                                    category.description!,
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            activeColor: const Color(0xFF4A148C),
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF4A148C).withOpacity( 0.05),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

            // Provider-specific fields (Bio and documents)
            if ((widget.userData['role']?.toString().toUpperCase() == 'PROVIDER') ||
                (widget.userData['role']?.toString().toLowerCase() == 'provider')) ...[
              TextField(
                controller: bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio (Optional)'),
              ),
              const SizedBox(height: 24),

              // صورة البروفايل للمزود
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() => profilePicturePath = picked.path);
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        backgroundImage: _getEditImageProvider(),
                        child: _getEditImageProvider() == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
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
              const SizedBox(height: 8),
              Center(
                child: Text(
                  profilePicturePath != null
                      ? 'صورة جديدة محددة'
                      : 'اضغط لتغيير الصورة',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // وثيقة الهوية
              _buildDocumentPicker(
                title: 'وثيقة الهوية',
                icon: Icons.badge,
                currentPath: identityDocumentPath,
                existingDocUrl: widget.userData['identity_document_url'] ??
                               widget.userData['identity_document'],
                isLocked: _isVerified(),
                onTap: () async {
                  // لو الحساب موثق، امنع التغيير
                  if (_isVerified()) {
                    _showVerifiedAccountDialog(
                      'لا يمكن تغيير وثيقة الهوية',
                      'حسابك موثق بالفعل. لا يمكن تغيير وثيقة الهوية إلا بعد التواصل مع الإدارة.',
                    );
                    return;
                  }

                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setState(() => identityDocumentPath = result.files.single.path);
                  }
                },
              ),
              const SizedBox(height: 16),
              // الشهادة الصحية
              _buildDocumentPicker(
                title: 'الشهادة الصحية',
                icon: Icons.health_and_safety,
                currentPath: healthCertificatePath,
                existingDocUrl: widget.userData['health_certificate_url'] ??
                               widget.userData['health_certificate'],
                isLocked: _isVerified(),
                onTap: () async {
                  // لو الحساب موثق، امنع التغيير
                  if (_isVerified()) {
                    _showVerifiedAccountDialog(
                      'لا يمكن تغيير الشهادة الصحية',
                      'حسابك موثق بالفعل. لا يمكن تغيير الشهادة الصحية إلا بعد التواصل مع الإدارة.',
                    );
                    return;
                  }

                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setState(() => healthCertificatePath = result.files.single.path);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Location Section for Provider
              const Divider(height: 32),
              const Text(
                'معلومات الموقع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // زر تحديد الموقع للـ Provider
              ConnectivityIconButton(
                onPressed: isLoadingLocation ? null : _getCurrentLocation,
                icon: isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isLoadingLocation ? 'جاري تحديد الموقع...' : 'تحديد موقعي الحالي',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // المدينة (read-only - تتحدد من GPS فقط)
              TextField(
                controller: cityController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'المدينة',
                  hintText: 'اضغط على "تحديد موقعي الحالي" لملء المدينة',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  suffixIcon: const Tooltip(
                    message: 'يتم تحديد المدينة تلقائيًا من موقعك',
                    child: Icon(Icons.lock, color: Colors.grey),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // العنوان التفصيلي
              TextField(
                controller: formattedAddressController,
                decoration: InputDecoration(
                  labelText: 'العنوان التفصيلي',
                  hintText: 'مثال: حي النخيل، شارع الملك فهد',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // عرض الإحداثيات إذا كانت موجودة
              if (latitude != null && longitude != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity( 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GPS: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // Client-specific fields
              const Text(
                'معلومات الملف الشخصي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // صورة البروفايل للعميل
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() => profilePicturePath = picked.path);
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        backgroundImage: _getEditImageProvider(),
                        child: _getEditImageProvider() == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
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
              const SizedBox(height: 8),
              Center(
                child: Text(
                  profilePicturePath != null
                      ? 'صورة جديدة محددة ✓'
                      : 'اضغط لإضافة صورة',
                  style: TextStyle(
                    color: profilePicturePath != null
                        ? Colors.green
                        : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: profilePicturePath != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // زر تحديد الموقع
              ConnectivityIconButton(
                onPressed: isLoadingLocation ? null : _getCurrentLocation,
                icon: isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isLoadingLocation ? 'جاري تحديد الموقع...' : 'تحديد موقعي الحالي',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // المدينة (read-only - تتحدد من GPS فقط)
              TextField(
                controller: cityController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'المدينة',
                  hintText: 'اضغط على "تحديد موقعي الحالي" لملء المدينة',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  suffixIcon: const Tooltip(
                    message: 'يتم تحديد المدينة تلقائيًا من موقعك',
                    child: Icon(Icons.lock, color: Colors.grey),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // العنوان التفصيلي
              TextField(
                controller: formattedAddressController,
                decoration: InputDecoration(
                  labelText: 'العنوان التفصيلي',
                  hintText: 'مثال: حي النخيل، شارع الملك فهد',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // عرض الإحداثيات إذا كانت موجودة
              if (latitude != null && longitude != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity( 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'الموقع: ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            isLoading
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
                : ConnectivityButton(
                    onPressed: updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.save,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            if (message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.contains('success') || message.contains('نجح')
                      ? Colors.green.withAlpha(26) // 0.1 * 255 = 26
                      : Colors.red.withAlpha(26), // 0.1 * 255 = 26
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: message.contains('success') || message.contains('نجح')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message.contains('success') || message.contains('نجح')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // دالة للتحقق من أن الحساب موثق
  bool _isVerified() {
    final status = widget.userData['verification_status']?.toString().toUpperCase();
    return status == 'VERIFIED';
  }

  // دالة لعرض رسالة للحساب الموثق
  void _showVerifiedAccountDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
