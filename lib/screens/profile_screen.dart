import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/address_service.dart';
import '../config/api_config.dart';
import 'edit_profile_screen.dart';
import 'document_viewer_screen.dart';
import 'offer_confirmation_screen.dart';
import '../models/booking_request_model.dart' as booking_model;
import '../models/worker_offer_model.dart';
import '../services/booking_service.dart';
import '../services/worker_offer_service.dart';
import '../widgets/ratings_section.dart';
import '../l10n/app_localizations.dart';
import '../mixins/connectivity_aware_mixin.dart';
import '../widgets/connectivity_button.dart';
import '../providers/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  final bool scrollToBookings;
  const ProfileScreen({super.key, required this.token, this.scrollToBookings = false});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with ConnectivityAwareMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = '';
  List<booking_model.BookingRequest> _bookings = [];
  bool _isLoadingBookings = false;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = false;
  int _actualTotalRatings = 0; // Actual ratings count from the database

  // ScrollController for scrolling to bookings section
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bookingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _loadBookings();
    // _loadAddresses will be called after fetchUserProfile completes

    // Scroll to bookings section if requested
    if (widget.scrollToBookings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBookings();
      });
    }
  }

  @override
  Future<void> fetchData() async {
    // Implementation required by ConnectivityAwareMixin
    await fetchUserProfile();
    await _loadBookings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBookings() {
    if (_bookingsKey.currentContext != null) {
      Scrollable.ensureVisible(
        _bookingsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> fetchUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Ensure ApiClient has the token (keeps headers consistent across app)
      ApiClient.setAuthToken(widget.token);

      final meResp = await ApiClient.get(ApiConfig.me, needsAuth: true);

      if (!meResp.success || meResp.rawResponse == null) {
        setState(() {
          errorMessage =
              'Failed to fetch user info: ${meResp.statusCode} ${meResp.error ?? ''}';
          isLoading = false;
        });
        return;
      }

      final meJson = meResp.rawResponse as Map<String, dynamic>;
      
      final role = meJson['role'] as String? ?? '';

      Map<String, dynamic> profileJson = {};
      
      
      if (role.toLowerCase() == 'client') {
        final pResp = await ApiClient.get(
          ApiConfig.clientProfile,
          needsAuth: true,
        );
        if (pResp.success && pResp.rawResponse != null) {
          profileJson = pResp.rawResponse as Map<String, dynamic>;
        }
      } else if (role.toLowerCase() == 'provider') {
        final pResp = await ApiClient.get(
          ApiConfig.providerProfile,
          needsAuth: true,
        );
        if (pResp.success && pResp.rawResponse != null) {
          profileJson = pResp.rawResponse as Map<String, dynamic>;
        } else {
        }
      } else {
      }

      final merged = <String, dynamic>{};
      merged.addAll(meJson);
      // Flatten profile fields (exclude nested 'user' map)
      profileJson.forEach((k, v) {
        if (k == 'user') return;
        merged[k] = v;
      });

      // Debug: print profile_picture to verify its value
      
      if (merged['profile_picture'] != null) {
      } else {
      }

      setState(() {
        userData = merged;
        isLoading = false;
      });

      // Load addresses after userData is set (for clients only)
      _loadAddresses();
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final bookings = await BookingService.getBookings();

      setState(() {
        _bookings = bookings;
        _isLoadingBookings = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  Future<void> _loadAddresses() async {
    // Load addresses for both clients and providers
    final roleValue = (userData?['role'] ?? '').toString().toLowerCase();
    final isClient = roleValue == 'client';
    final isProvider = roleValue == 'provider';


    if (!isClient && !isProvider) {
      return;
    }

    setState(() {
      _isLoadingAddresses = true;
    });

    try {

      // Call appropriate service based on role
      final response = isProvider
          ? await AddressService.getProviderAddresses()
          : await AddressService.getAddresses();


      if (response.data != null) {
      }

      if (response.success && response.data != null) {
        setState(() {
          _addresses = response.data!;
          _isLoadingAddresses = false;
        });
      } else {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleValue = (userData?['role'] ?? '').toString().toLowerCase();
    final isProvider =
        roleValue == 'provider' ||
        roleValue == 'providers' ||
        roleValue == 'PROVIDER'.toLowerCase();
    // Client: blue (existing), Provider: brown
    final accent = isProvider
        ? const Color(0xFF8B4513) // brown for providers
        : const Color(0xFF3B82F6); // blue for clients

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.profile ?? 'Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Language Toggle Icon
          GestureDetector(
            onTap: () {
              provider_pkg.Provider.of<LanguageProvider>(context, listen: false).toggleLanguage();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: provider_pkg.Consumer<LanguageProvider>(
                  builder: (context, languageProvider, child) => Text(
                    languageProvider.isArabic ? 'EN' : 'ع',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : RefreshIndicator(
              onRefresh: fetchUserProfile,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Header with gradient and avatar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withAlpha(204)], // 0.8 * 255 = 204
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar with verification badge
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                    backgroundImage: _getProfileImageProvider(userData),
                                    child: _getProfileImageProvider(userData) == null
                                        ? Text(
                                            (userData?['first_name'] ?? '').isNotEmpty
                                                ? (userData!['first_name'][0]
                                                      .toUpperCase())
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                // Verification badge (for providers only)
                                if (isProvider) ...[
                                  const SizedBox(height: 8),
                                  _buildVerificationBadge(userData?['verification_status']),
                                ],
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Name & role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context).colorScheme.surface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51), // 0.2 * 255 = 51
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (userData?['role'] ?? '')
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.surface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Edit button (full width)
                        SizedBox(
                          width: double.infinity,
                          child: ConnectivityIconButton(
                            onPressed: () async {
                              if (context.mounted && userData != null) {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => EditProfileScreen(
                                      token: widget.token,
                                      userData: userData!,
                                    ),
                                  ),
                                );
                                // If result is true, the edit was successful, refresh data
                                if (result == true) {
                                  fetchUserProfile();
                                  _loadAddresses(); // Reload addresses in case location was saved
                                }
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(AppLocalizations.of(context)?.editProfile ?? 'Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: accent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verification Status Card (for providers only)
                  if (isProvider && userData != null) ...[
                    _buildVerificationStatusCard(userData?['verification_status']),
                    const SizedBox(height: 12),
                  ],

                  // Provider Stats Card (for providers only)
                  if (isProvider && userData != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)?.ratingAndStats ?? 'Rating & Statistics',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Average rating badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRatingColor(
                                      (userData?['average_rating'] as num?)?.toDouble() ?? 0.0,
                                    ).withOpacity( 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: _getRatingColor(
                                          (userData?['average_rating'] as num?)?.toDouble() ?? 0.0,
                                        ),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ((userData?['average_rating'] as num?)?.toDouble() ?? 0.0)
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _getRatingColor(
                                            (userData?['average_rating'] as num?)?.toDouble() ?? 0.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stats row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.rate_review,
                                    label: AppLocalizations.of(context)?.ratings ?? 'Ratings',
                                    value: '$_actualTotalRatings',
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.check_circle,
                                    label: AppLocalizations.of(context)?.completedTasks ?? 'Completed Tasks',
                                    value: '${userData?['completed_jobs'] ?? 0}',
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            // Detailed ratings section
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            RatingsSection(
                              providerId: userData?['id'] ?? 0,
                              initialAverageRating: (userData?['average_rating'] as num?)?.toDouble(),
                              initialTotalRatings: userData?['total_ratings'] as int?,
                              onRatingsLoaded: (totalRatings) {
                                setState(() {
                                  _actualTotalRatings = totalRatings;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Info card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.personalInfo ?? 'Basic Information',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            AppLocalizations.of(context)?.emailAddress ?? 'Email',
                            userData?['email'] ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            AppLocalizations.of(context)?.firstName ?? 'First Name',
                            userData?['first_name'] ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            AppLocalizations.of(context)?.lastName ?? 'Last Name',
                            userData?['last_name'] ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
                            userData?['phone_number'] ??
                                userData?['phone'] ??
                                '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Identity document and health certificate (for providers only)
                  if (isProvider && userData != null) ...[
                    // Identity document
                    if (userData!['identity_document_url'] != null ||
                        userData!['identity_document'] != null)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _openDocument(
                            userData!['identity_document_url'] ??
                                userData!['identity_document'],
                            AppLocalizations.of(context)?.profile ?? 'Identity Document',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accent.withAlpha(26), // 0.1 * 255 = 26
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.badge_outlined,
                                    color: accent,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)?.identityDocument ?? 'Identity Document',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to view',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Health certificate
                    if (userData!['health_certificate_url'] != null ||
                        userData!['health_certificate'] != null)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _openDocument(
                            userData!['health_certificate_url'] ??
                                userData!['health_certificate'],
                            'Health Certificate',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(26), // 0.1 * 255 = 26
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.medical_information_outlined,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)?.healthCertificate ?? 'Health Certificate',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to view',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // Bio / Addresses
                  if (userData != null &&
                      userData!['bio'] != null &&
                      (userData!['bio'] as String).isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.aboutMe ?? 'About Me',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(userData!['bio'] ?? ''),
                          ],
                        ),
                      ),
                    ),

                  // Addresses Section (for clients and providers)
                  if (userData != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.savedAddresses ?? 'Saved Addresses',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingAddresses)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_addresses.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No saved addresses',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._addresses.map((addr) {
                                final label = addr['label'] ?? '';
                                final address = addr['address'] ?? '';
                                final city = addr['city'] ?? '';
                                final isDefault = addr['is_default'] ?? false;
                                final addressId = addr['id'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDefault
                                        ? accent.withAlpha(26)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDefault
                                          ? accent
                                          : Colors.grey.withAlpha(51),
                                      width: isDefault ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isDefault
                                                ? Icons.location_on
                                                : Icons.location_on_outlined,
                                            color: isDefault ? accent : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              label.isNotEmpty ? label : (AppLocalizations.of(context)?.address ?? 'Address'),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isDefault
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isDefault
                                                    ? accent
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isDefault)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: accent,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context)?.defaultLabel ?? 'Default',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(context).colorScheme.surface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) async {
                                              if (value == 'delete') {
                                                await _deleteAddress(addressId);
                                              } else if (value == 'default') {
                                                await _setDefaultAddress(addressId);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              if (!isDefault)
                                                PopupMenuItem(
                                                  value: 'default',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.check_circle_outline,
                                                          size: 18),
                                                      SizedBox(width: 8),
                                                      Text(AppLocalizations.of(context)?.setAsDefault ?? 'Set as Default'),
                                                    ],
                                                  ),
                                                ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline,
                                                        size: 18, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text(AppLocalizations.of(context)?.deleteAddress ?? 'Delete',
                                                        style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 28),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (address.isNotEmpty)
                                              Text(
                                                address,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            if (city.isNotEmpty)
                                              Text(
                                                city,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Logout button
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.red.withAlpha(13), // 0.05 * 255 = 13
                    child: InkWell(
                      onTap: () => _showLogoutDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)?.logout ?? 'Logout',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Future<void> _openDocument(String? url, String title) async {

    if (url == null || url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.documentNotAvailable ?? 'Document not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }


    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => DocumentViewerScreen(
            documentUrl: url,
            title: title,
          ),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.logout ?? 'Logout'),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)?.logoutConfirm ?? 'Are you sure you want to logout?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context)?.logout ?? 'Logout',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)?.loggingOut ?? 'Logging out...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final result = await AuthService.logout();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        if (result.success) {
          // Navigate to login screen and clear all routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)?.logoutSuccess ?? 'Logged out successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Logout failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {

      // Close loading dialog on error
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.logoutError ?? 'An error occurred during logout'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ImageProvider? _getProfileImageProvider(Map<String, dynamic>? userData) {
    if (userData == null) {
      return null;
    }

    // Try profile_picture_url first (from the new API)
    var profilePic = userData['profile_picture_url'];

    // If not found, try profile_picture (fallback)
    if (profilePic == null || (profilePic as String).isEmpty) {
      profilePic = userData['profile_picture'];
    }


    if (profilePic == null || (profilePic as String).isEmpty) {
      return null;
    }

    String imageUrl = profilePic;
    // If the URL doesn't start with http, we need to prepend the base URL
    if (!imageUrl.startsWith('http')) {
      imageUrl = '${ApiConfig.baseUrl}$imageUrl';
    }

    // Add timestamp to prevent caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    imageUrl = '$imageUrl?t=$timestamp';


    return NetworkImage(imageUrl);
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: TextStyle(color: Colors.grey[700])),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity( 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) {
      return Colors.green;
    } else if (rating >= 3.5) {
      return Colors.amber[700]!;
    } else if (rating >= 2.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildVerificationBadge(String? status) {
    IconData icon;
    Color bgColor;
    Color iconColor;
    String label;


    // Determine icon and color based on status
    switch (status?.toUpperCase()) {
      case 'VERIFIED':
        icon = Icons.check_circle;
        bgColor = Colors.green;
        iconColor = Colors.white;
        label = AppLocalizations.of(context)?.verified ?? 'Verified';
        break;
      case 'PENDING':
        icon = Icons.access_time;
        bgColor = Colors.orange;
        iconColor = Colors.white;
        label = AppLocalizations.of(context)?.underReview ?? 'Pending Review';
        break;
      case 'REJECTED':
        icon = Icons.cancel;
        bgColor = Colors.red;
        iconColor = Colors.white;
        label = AppLocalizations.of(context)?.rejected ?? 'Rejected';
        break;
      default:
        // If no status or data is missing
        icon = Icons.error_outline;
        bgColor = Colors.grey;
        iconColor = Colors.white;
        label = AppLocalizations.of(context)?.pleaseCompleteData ?? 'Please complete your data';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity( 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard(String? status) {
    IconData icon;
    Color statusColor;
    String title;
    String description;

    switch (status?.toUpperCase()) {
      case 'VERIFIED':
        icon = Icons.verified_user;
        statusColor = Colors.green;
        title = AppLocalizations.of(context)?.accountVerified ?? 'Your account is verified';
        description = AppLocalizations.of(context)?.accountVerifiedDescription ?? 'Your identity and health certificate have been verified successfully. You can now submit offers on client requests.';
        break;
      case 'PENDING':
        icon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        title = AppLocalizations.of(context)?.requestUnderReview ?? 'Your request is under review';
        description = AppLocalizations.of(context)?.requestUnderReviewDescription ?? 'Your documents are being reviewed by the administration. We will notify you once the review is complete.';
        break;
      case 'REJECTED':
        icon = Icons.error_outline;
        statusColor = Colors.red;
        title = AppLocalizations.of(context)?.requestRejected ?? 'Your request was rejected';
        description = AppLocalizations.of(context)?.requestRejectedDescription ?? 'Sorry, your documents were not accepted. Please update your identity document and health certificate from the Edit Profile page.';
        break;
      default:
        icon = Icons.info_outline;
        statusColor = Colors.grey;
        title = AppLocalizations.of(context)?.completeYourInfo ?? 'Please complete your information';
        description = AppLocalizations.of(context)?.verifiedProviderDescription ?? 'To become a verified service provider, you must upload your identity document and health certificate from the Edit Profile page.';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity( 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            // If status is rejected or incomplete, add edit button
            if (status?.toUpperCase() != 'VERIFIED' &&
                status?.toUpperCase() != 'PENDING') ...[
              const SizedBox(height: 16),
              ConnectivityIconButton(
                onPressed: () async {
                  if (context.mounted && userData != null) {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => EditProfileScreen(
                          token: widget.token,
                          userData: userData!,
                        ),
                      ),
                    );
                    if (result == true) {
                      fetchUserProfile();
                    }
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: Text(AppLocalizations.of(context)?.editProfile ?? 'Upload Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    // Show loading indicator
    if (_isLoadingBookings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: Color(0xFF3B82F6),
          ),
        ),
      );
    }

    // Show empty state if no bookings
    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'No bookings currently',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Take only the 3 most recent bookings
    final recentBookings = _bookings.take(3).toList();

    return Column(
      children: recentBookings.map((booking) {
        // Get service icon based on service title
        final IconData serviceIcon = _getServiceIcon(booking.serviceTitle ?? '');
        final Color serviceColor = _getServiceColor(booking.serviceTitle ?? '');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity( 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Service Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: serviceColor.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      serviceIcon,
                      color: serviceColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Service Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceTitle ?? 'Service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(booking.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Date and Time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(booking.bookingDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    booking.bookingTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                    ),
                  ),
                ],
              ),
              // Show offers button for all booking requests
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ConnectivityIconButton(
                  onPressed: () => _showOffersDialog(booking),
                  icon: const Icon(Icons.local_offer, size: 18),
                  label: Text(AppLocalizations.of(context)?.viewOffers ?? 'View Offers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods for booking display
  IconData _getServiceIcon(String serviceTitle) {
    final titleLower = serviceTitle.toLowerCase();
    if (titleLower.contains('cleaning')) return Icons.cleaning_services;
    if (titleLower.contains('cooking')) return Icons.restaurant;
    if (titleLower.contains('child') || titleLower.contains('kids')) return Icons.child_care;
    if (titleLower.contains('elder')) return Icons.accessible;
    if (titleLower.contains('laundry')) return Icons.local_laundry_service;
    if (titleLower.contains('ironing')) return Icons.checkroom;
    return Icons.home_repair_service;
  }

  Color _getServiceColor(String serviceTitle) {
    final titleLower = serviceTitle.toLowerCase();
    if (titleLower.contains('cleaning')) return const Color(0xFF10B981);
    if (titleLower.contains('cooking')) return const Color(0xFFF59E0B);
    if (titleLower.contains('child') || titleLower.contains('kids')) return const Color(0xFF3B82F6);
    if (titleLower.contains('elder')) return const Color(0xFF8B5CF6);
    if (titleLower.contains('laundry')) return const Color(0xFFEC4899);
    if (titleLower.contains('ironing')) return const Color(0xFF06B6D4);
    return const Color(0xFF3B82F6);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF3B82F6); // Blue for open
      case 'accepted':
        return const Color(0xFF10B981); // Green for accepted
      case 'completed':
        return const Color(0xFF059669); // Darker green for completed
      case 'cancelled':
        return const Color(0xFFEF4444); // Red for cancelled
      default:
        return const Color(0xFF9CA3AF); // Gray for unknown
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'accepted':
        return 'Accepted';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not specified';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Show offers dialog for a booking request
  Future<void> _showOffersDialog(booking_model.BookingRequest booking) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3B82F6),
        ),
      ),
    );

    // Fetch offers for this booking
    final offers = await WorkerOfferService.getOffers(bookingRequestId: booking.id);

    // Close loading
    if (mounted) Navigator.pop(context);

    if (!mounted) return;

    // Show offers dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              'Available Offers',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${offers.length} offers',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: offers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No offers available currently',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final isPriceHigher = offer.priceAction == 'counter';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity( 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Worker info
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person, color: Colors.white, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Worker #',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      offer.priceActionLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${offer.offeredPrice.toStringAsFixed(0)} EGP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isPriceHigher
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                  if (isPriceHigher)
                                    Text(
                                      '+${(offer.offeredPrice - (booking.clientBudget ?? 0)).toStringAsFixed(0)} EGP',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          // Message if available
                          if (offer.message != null && offer.message!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                offer.message!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Accept button
                          if (offer.status == 'pending')
                            SizedBox(
                              width: double.infinity,
                              child: ConnectivityButton(
                                onPressed: () => _acceptOffer(offer, booking),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Accept Offer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          // Status badge if not pending
                          if (offer.status != 'pending')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity( 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                offer.statusLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  // Accept an offer - Navigate to confirmation screens
  Future<void> _acceptOffer(WorkerOffer offer, booking_model.BookingRequest booking) async {
    // Close offers dialog
    Navigator.pop(context);

    // Navigate to OfferConfirmationScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferConfirmationScreen(
          offer: offer,
          bookingRequest: booking,
        ),
      ),
    );

    // If the user confirmed the offer (result == true), refresh the bookings
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context)?.bookingConfirmedSuccess ?? 'Booking confirmed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh bookings data
      await _loadBookings();
    }
  }

  // Delete an address
  Future<void> _deleteAddress(int addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.confirmDelete ?? 'Confirm Delete'),
          ],
        ),
        content: Text(AppLocalizations.of(context)?.deleteAddressConfirm ?? 'Are you sure you want to delete this address?'),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)?.deleteAddress ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Determine which service to use based on role
    final roleValue = (userData?['role'] ?? '').toString().toLowerCase();
    final isProvider = roleValue == 'provider';

    final response = isProvider
        ? await AddressService.deleteProviderAddress(addressId)
        : await AddressService.deleteAddress(addressId);

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.addressDeletedSuccess ?? 'Address deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAddresses();
    } else {
      final errorMsg = response.error ?? (AppLocalizations.of(context)?.failedToDeleteAddress ?? 'Failed to delete address');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Set an address as default
  Future<void> _setDefaultAddress(int addressId) async {
    // Determine which service to use based on role
    final roleValue = (userData?['role'] ?? '').toString().toLowerCase();
    final isProvider = roleValue == 'provider';

    final response = isProvider
        ? await AddressService.setProviderDefaultAddress(addressId)
        : await AddressService.setDefaultAddress(addressId);

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.defaultAddressSetSuccess ?? 'Default address set successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAddresses();
    } else {
      final errorMsg = response.error ?? (AppLocalizations.of(context)?.failedToSetDefaultAddress ?? 'Failed to set default address');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
