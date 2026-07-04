import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../widgets/ratings_section.dart';
import '../l10n/app_localizations.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final int providerId;

  ProviderDetailsScreen({
    super.key,
    required this.providerId,
  });

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  Map<String, dynamic>? _providerData;
  bool _isLoading = true;
  String? _errorMessage;
  int _completedServicesCount = 0;
  double _calculatedAverageRating = 0.0;
  int _totalRatingsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
    _loadProviderRatings();
  }

  Future<void> _loadProviderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        ApiConfig.providerDetail(widget.providerId),
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        setState(() {
          _providerData = response.rawResponse as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? AppLocalizations.of(context)?.error ?? 'Error';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)?.errorOccurred ?? 'Error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompletedServices() async {
    try {
      final response = await ApiClient.get(
        ApiConfig.providerStats(widget.providerId),
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        final data = response.rawResponse as Map<String, dynamic>;
        setState(() {
          _completedServicesCount = data['completed_services_count'] ?? 0;
        });
      } else {
        // نستخدم البيانات من provider details كـ fallback
      }
    } catch (e) {
      // في حالة الخطأ، نستخدم القيمة من provider details
    }
  }

  Future<void> _loadProviderRatings() async {
    try {
      final response = await ApiClient.get(
        ApiConfig.providerRatings(widget.providerId),
        needsAuth: true,
      );

      if (response.success && response.rawResponse != null) {
        final data = response.rawResponse;
        List<dynamic> ratings = [];

        // Handle different response formats
        if (data is List) {
          ratings = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('results')) {
            ratings = data['results'] as List? ?? [];
          } else if (data.containsKey('data')) {
            ratings = data['data'] as List? ?? [];
          } else if (data.containsKey('ratings')) {
            ratings = data['ratings'] as List? ?? [];
          }
        }


        if (ratings.isNotEmpty) {
          // حساب متوسط التقييمات
          double totalRating = 0.0;
          int validRatingsCount = 0;

          for (var rating in ratings) {
            if (rating is Map<String, dynamic> && rating.containsKey('rating')) {
              final ratingValue = rating['rating'];
              if (ratingValue != null) {
                totalRating += (ratingValue is int) ? ratingValue.toDouble() : (ratingValue as num).toDouble();
                validRatingsCount++;
              }
            }
          }

          if (validRatingsCount > 0) {
            final average = totalRating / validRatingsCount;
            setState(() {
              _calculatedAverageRating = average;
              _totalRatingsCount = validRatingsCount;
            });
          } else {
          }
        } else {
        }
      } else {
      }
    } catch (e) {
      // في حالة الخطأ، نستخدم القيمة من provider details
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF4F46E5)
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)?.providerProfile ?? 'Provider',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProviderDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProviderDetails(),
    );
  }

  Widget _buildProviderDetails() {
    if (_providerData == null) return const SizedBox();

    final fullName = _providerData!['full_name'] ?? (AppLocalizations.of(context)?.notAvailable ?? 'Not Available');
    // استخدام المتوسط المحسوب من API التقييمات، وإن مكانش متاح نستخدم القيمة من provider details
    final averageRating = _calculatedAverageRating > 0 ? _calculatedAverageRating : ((_providerData!['average_rating'] ?? 0.0) as num).toDouble();
    final totalRatings = _totalRatingsCount > 0 ? _totalRatingsCount : (_providerData!['total_ratings'] ?? 0);
    final verificationStatus = _providerData!['verification_status'] ?? 'PENDING';
    final bio = _providerData!['bio'] ?? '';
    final profilePicture = _providerData!['profile_picture_url'] ?? _providerData!['profile_picture'];
    final yearsOfExperience = _providerData!['years_of_experience'];
    // استخدام العدد من API الخاص بالمهام المكتملة، وإن مكانش متاح نستخدم القيمة القديمة
    final completedJobs = _completedServicesCount > 0 ? _completedServicesCount : (_providerData!['completed_jobs'] ?? 0);

    // Preferred Services - الخدمات المفضلة
    final preferredServices = _providerData!['preferred_services'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4F46E5), width: 3),
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(profilePicture),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 24),
                    const SizedBox(width: 6),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($totalRatings ${AppLocalizations.of(context)?.ratingLabelText ?? 'تقييم'})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Verification Status
                if (verificationStatus == 'VERIFIED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)?.verified ?? 'Verified',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Preferred Services Section
          if (preferredServices.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionCard(
                title: AppLocalizations.of(context)?.services ?? 'Services',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: preferredServices.map((service) {
                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                    print('DEBUG: isArabic=$isArabic, service=$service');
                    final serviceName = isArabic
                        ? (service['name'] ?? service['service_name'] ?? AppLocalizations.of(context)?.services ?? 'Service')
                        : (service['name_en'] ?? service['name'] ?? service['service_name'] ?? AppLocalizations.of(context)?.services ?? 'Service');
                    print('DEBUG: serviceName=$serviceName');
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFF4F46E5).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Info Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (yearsOfExperience != null) ...[
                  _buildInfoCard(
                    icon: Icons.work,
                    title: AppLocalizations.of(context)?.experience ?? 'Experience',
                    value: '$yearsOfExperience ${AppLocalizations.of(context)?.yearUnit ?? 'year'}',
                    iconColor: Color(0xFF4F46E5),
                  ),
                  SizedBox(height: 12),
                ],

                _buildInfoCard(
                  icon: Icons.task_alt,
                  title: AppLocalizations.of(context)?.completedTasks ?? 'Completed Tasks',
                  value: '$completedJobs ${AppLocalizations.of(context)?.taskUnit ?? 'task'}',
                  iconColor: Color(0xFF10B981),
                ),

                // Bio Section
                if (bio.isNotEmpty) ...[
                  SizedBox(height: 20),
                  _buildSectionCard(
                    title: AppLocalizations.of(context)?.personalInfo ?? 'Info',
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // Ratings Section
                SizedBox(height: 20),
                RatingsSection(
                  providerId: widget.providerId,
                  initialAverageRating: averageRating.toDouble(),
                  initialTotalRatings: totalRatings,
                ),

                SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profilePicture) {
    if (profilePicture != null && profilePicture.isNotEmpty) {
      String imageUrl = profilePicture;

      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      imageUrl = '$imageUrl?t=$timestamp';

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4F46E5),
            ),
          );
        },
      );
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    final fullName = _providerData?['full_name'] ?? '';
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '👤',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
