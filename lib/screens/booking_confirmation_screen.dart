import 'package:flutter/material.dart';
import '../models/booking_request_model.dart';
import '../models/worker_offer_model.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookingRequest bookingRequest;
  final WorkerOffer offer;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingRequest,
    required this.offer,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final TextEditingController _notesController = TextEditingController();
  Map<String, dynamic>? _providerData;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      final response = await ApiClient.get(
        ApiConfig.providerDetail(widget.offer.workerId),
      );

      if (mounted) {
        setState(() {
          // ApiClient.get returns ApiResponse, we need the data
          if (response.data != null && response.data is Map<String, dynamic>) {
            _providerData = response.data as Map<String, dynamic>;
          } else if (response.rawResponse != null && response.rawResponse is Map<String, dynamic>) {
            _providerData = response.rawResponse as Map<String, dynamic>;
          }
        });
      }
    } catch (e) {
    }
  }

  String get _workerName {
    if (_providerData != null && _providerData!['full_name'] != null) {
      return _providerData!['full_name'];
    }
    return '${AppLocalizations.of(context)?.serviceProvider ?? 'Service Provider'} #${widget.offer.workerId}';
  }

  double get _workerRating {
    if (_providerData != null && _providerData!['average_rating'] != null) {
      return (_providerData!['average_rating'] as num).toDouble();
    }
    return 0.0;
  }

  int get _workerReviews {
    if (_providerData != null && _providerData!['total_ratings'] != null) {
      return (_providerData!['total_ratings'] as num).toInt();
    }
    return 0;
  }

  String get _serviceName {
    return widget.bookingRequest.serviceTitle ?? (AppLocalizations.of(context)?.householdService ?? 'Household Service');
  }

  String get _date {
    final date = widget.bookingRequest.bookingDate;
    return '${date.day}/${date.month}/${date.year}';
  }

  String get _time {
    return widget.bookingRequest.bookingTime;
  }

  String get _duration {
    return '${widget.bookingRequest.durationHours} ${AppLocalizations.of(context)?.hours ?? 'hours'}';
  }

  String get _selectedAddress {
    return widget.bookingRequest.city ?? (AppLocalizations.of(context)?.notSpecified ?? 'Not specified');
  }

  double get _price {
    return widget.offer.offeredPrice;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            _buildSuccessHeader(),

            const SizedBox(height: 20),

            // Worker Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildWorkerInfoCard(),
            ),

            const SizedBox(height: 16),

            // Service Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildServiceDetailsCard(),
            ),

            const SizedBox(height: 16),

            // Address Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAddressSection(),
            ),

            const SizedBox(height: 16),

            // Notes Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildNotesSection(),
            ),

            const SizedBox(height: 16),

            // Price Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPriceSummary(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)?.confirmBooking ?? 'Confirm Booking',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity( 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 50,
            ),
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.offerAcceptedSuccessfully ?? 'Offer Accepted Successfully!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.confirmBookingDetailsMessage ?? 'Confirm booking details to complete the process',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerInfoCard() {
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
          // Worker Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5), width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
              ),
            ),
            child: Center(
              child: Text(
                _workerName.isNotEmpty ? _workerName[0].toUpperCase() : '👤',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Worker Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _workerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                          SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)?.verified ?? 'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _workerRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($_workerReviews ${AppLocalizations.of(context)?.reviews ?? 'reviews'})',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.serviceDetails ?? 'Service Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(Icons.cleaning_services, AppLocalizations.of(context)?.serviceLabel ?? 'Service', _serviceName),
          SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today, AppLocalizations.of(context)?.date ?? 'Date', _date),
          SizedBox(height: 12),
          _buildDetailRow(Icons.access_time, AppLocalizations.of(context)?.time ?? 'Time', _time),
          SizedBox(height: 12),
          _buildDetailRow(Icons.timer, AppLocalizations.of(context)?.duration ?? 'Duration', _duration),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity( 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4F46E5),
            size: 20,
          ),
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }

  Widget _buildAddressSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.serviceAddress ?? 'Service Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              ConnectivityTextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)?.addressSelectionComingSoon ?? 'Address selection page will be added later')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF4F46E5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 4),
                    Text(AppLocalizations.of(context)?.change ?? 'Change'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity( 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4F46E5).withOpacity( 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.additionalNotesOptional ?? 'Additional Notes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.addNotesOrInstructions ?? 'Add any notes or special instructions...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final total = _price;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.priceSummary ?? 'Price Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.total ?? 'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} ${AppLocalizations.of(context)?.egp ?? 'EGP'}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ConnectivityButton(
            onPressed: _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 22),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.confirmBooking ?? 'Confirm Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4F46E5),
          ),
        ),
      );

      // Call create booking API directly
      final response = await ApiClient.post(
        ApiConfig.createBooking,
        needsAuth: true,
        body: {
          'booking_request_id': widget.bookingRequest.id,
          'accepted_offer_id': widget.offer.id,
        },
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.success) {
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                  SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.bookingConfirmed ?? 'Booking Confirmed!',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              content: Text(
                response.message ?? (AppLocalizations.of(context)?.bookingConfirmedMessage ?? 'Your booking has been confirmed successfully. You can track the booking status from the "My Bookings" page.'),
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Go back to offer confirmation with success result
                    Navigator.pop(context, true); // Go back to profile with success result
                  },
                  child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? (AppLocalizations.of(context)?.errorConfirmingBooking ?? 'An error occurred while confirming the booking')),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
