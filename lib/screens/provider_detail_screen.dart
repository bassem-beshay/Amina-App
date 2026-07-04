import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../services/provider_service.dart';
import '../l10n/app_localizations.dart';

class ProviderDetailScreen extends StatefulWidget {
  final int providerId;

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  Provider? _provider;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
  }

  Future<void> _loadProviderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = await ProviderService.getProviderById(widget.providerId);

      setState(() {
        _provider = provider;
        _isLoading = false;
      });

      if (provider == null) {
        setState(() {
          _errorMessage = 'Provider not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _provider != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                // Avatar
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 4),
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Name
                                Text(
                                  _provider!.fullName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _provider!.isAvailable
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _provider!.isAvailable
                                        ? (AppLocalizations.of(context)?.available ?? 'Available')
                                        : (AppLocalizations.of(context)?.notAvailable ?? 'Not Available'),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      )
                    : _provider != null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rating & Price Card
                                Container(
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
                                      // Rating
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Color(0xFFF59E0B),
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _provider!.averageRating?.toStringAsFixed(1) ?? '0.0',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_provider!.totalRatings ?? 0} ${AppLocalizations.of(context)?.rating ?? 'rating'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 50,
                                        color: Colors.grey[300],
                                      ),
                                      // Price
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              '${_provider!.hourlyRate?.toStringAsFixed(0) ?? '0'} ${AppLocalizations.of(context)?.currency ?? 'EGP'}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              AppLocalizations.of(context)?.perHour ?? '/hour',
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
                                ),

                                const SizedBox(height: 16),

                                // Bio Section
                                if (_provider!.bio != null && _provider!.bio!.isNotEmpty)
                                  Container(
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
                                          AppLocalizations.of(context)?.aboutMe ?? 'About Me',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _provider!.bio!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Contact Information
                                Container(
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
                                        AppLocalizations.of(context)?.contactInfo ?? 'Contact Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (_provider!.phone != null)
                                        _infoRow(
                                          Icons.phone,
                                          AppLocalizations.of(context)?.phone ?? 'Phone',
                                          _provider!.phone!,
                                        ),
                                      if (_provider!.email != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: _infoRow(
                                            Icons.email,
                                            AppLocalizations.of(context)?.email ?? 'Email',
                                            _provider!.email!,
                                          ),
                                        ),
                                      if (_provider!.city != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: _infoRow(
                                            Icons.location_on,
                                            AppLocalizations.of(context)?.city ?? 'City',
                                            _provider!.city!,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Book Now Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _provider!.isAvailable
                                        ? () {
                                            // TODO: Navigate to booking screen
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(AppLocalizations.of(context)?.comingSoon ?? 'Coming Soon'),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      disabledBackgroundColor: Colors.grey[300],
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)?.bookNow ?? 'Book Now',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 50),
                              ],
                            ),
                          )
                        : Container(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
