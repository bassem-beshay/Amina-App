import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/rating_model.dart';
import '../config/api_config.dart';
import '../services/rating_service.dart';

class ClientDetailsScreen extends StatefulWidget {
  final User clientUser;

  const ClientDetailsScreen({
    super.key,
    required this.clientUser,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  bool _isLoadingRatings = true;
  List<Rating> _ratings = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _loadClientRatings();
  }

  Future<void> _loadClientRatings() async {
    setState(() {
      _isLoadingRatings = true;
    });

    try {
      final response = await RatingService.getClientRatings(widget.clientUser.id);

      if (response.success && response.data != null) {
        final ratings = response.data!;

        // Calculate average rating
        if (ratings.isNotEmpty) {
          final sum = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
          final average = sum / ratings.length;

          setState(() {
            _ratings = ratings;
            _averageRating = average;
            _totalRatings = ratings.length;
            _isLoadingRatings = false;
          });

        } else {
          setState(() {
            _ratings = [];
            _averageRating = 0.0;
            _totalRatings = 0;
            _isLoadingRatings = false;
          });
        }
      } else {
        setState(() {
          _isLoadingRatings = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRatings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل العميل',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildClientDetails(),
    );
  }

  Widget _buildClientDetails() {
    final fullName = widget.clientUser.fullName;
    final email = widget.clientUser.email;
    final clientProfile = widget.clientUser.clientProfile;

    final profilePicture = clientProfile?.profilePictureUrl ?? clientProfile?.profilePicture;
    final displayName = clientProfile?.displayName ?? fullName;
    final city = clientProfile?.city ?? '';
    final country = clientProfile?.country ?? '';
    final formattedAddress = clientProfile?.formattedAddress ?? '';
    final preferredServices = clientProfile?.preferredServiceCategoriesList ?? [];

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
                  displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Client Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'عميل',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rating Section
                if (_isLoadingRatings)
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4F46E5),
                  )
                else if (_totalRatings > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($_totalRatings تقييم)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Preferred Services Section
          if (preferredServices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionCard(
                title: 'الخدمات المفضلة',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: preferredServices.map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        service,
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
            const SizedBox(height: 16),
          ],

          // Info Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (email.isNotEmpty) ...[
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'البريد الإلكتروني',
                    value: email,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                ],

                if (city.isNotEmpty || country.isNotEmpty) ...[
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'الموقع',
                    value: city.isNotEmpty && country.isNotEmpty
                        ? '$city, $country'
                        : city.isNotEmpty ? city : country,
                    iconColor: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                ],

                if (formattedAddress.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'العنوان',
                    child: Text(
                      formattedAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 80),
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
    final fullName = widget.clientUser.fullName;
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
            color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
