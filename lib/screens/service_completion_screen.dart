import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/provider_model.dart';
import '../services/booking_service.dart';
import '../services/provider_service.dart';
import '../config/api_config.dart';
import '../widgets/connectivity_button.dart';

class ServiceCompletionScreen extends StatefulWidget {
  final int bookingId;

  const ServiceCompletionScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<ServiceCompletionScreen> createState() => _ServiceCompletionScreenState();
}

class _ServiceCompletionScreenState extends State<ServiceCompletionScreen> {
  bool _isLoading = true;
  bool _isConfirming = false;
  Booking? _booking;
  Provider? _provider;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load booking details
      final booking = await BookingService.getBookingDetails(widget.bookingId);

      if (booking == null) {
        setState(() {
          _errorMessage = 'Booking data not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _booking = booking;
      });

      // Load provider details
      final provider = await ProviderService.getProviderById(booking.providerId);
      setState(() {
        _provider = provider;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCompletion() async {
    if (_booking == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Service Completion'),
        content: Text(
          'Do you confirm that the service has been completed fully?\n\nAfter confirmation, the booking will be closed and you can rate the worker.',
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
            ),
            child: Text('Confirm Completion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final result = await BookingService.confirmCompletion(widget.bookingId);

      if (!mounted) return;

      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Service completion confirmed successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Navigate back to home and refresh
        Navigator.of(context).pop(true);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to confirm service completion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        title: Text(
          'Confirm Service Completion',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            ConnectivityIconButton(
              onPressed: _loadBookingDetails,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_booking == null) {
      return Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with completion icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Service Completed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The worker has completed the requested service.\nPlease review the details and confirm completion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Provider details
          if (_provider != null) _buildProviderCard(),

          SizedBox(height: 16),

          // Service details
          _buildServiceDetailsCard(),

          SizedBox(height: 16),

          // Booking details
          _buildBookingDetailsCard(),

          SizedBox(height: 24),

          // Confirm button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConnectivityButton(
              onPressed: _isConfirming ? null : _confirmCompletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConfirming
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Confirm Service Completion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    if (_provider == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
            'Worker Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Profile picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  image: _provider!.profilePicture != null
                      ? DecorationImage(
                          image: NetworkImage(
                            _provider!.profilePicture!.startsWith('http')
                                ? _provider!.profilePicture!
                                : '${ApiConfig.baseUrl}${_provider!.profilePicture!}',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _provider!.profilePicture == null
                    ? const Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF8B5CF6),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _provider!.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_provider!.averageRating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _provider!.averageRating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (_provider!.totalRatings != null)
                            Text(
                              ' (${_provider!.totalRatings} reviews)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
            'Service Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.cleaning_services,
            label: 'Service',
            value: 'Household Service',
            iconColor: Color(0xFF8B5CF6),
          ),
          Divider(height: 24),
          _buildDetailRow(
            icon: Icons.payments_outlined,
            label: 'Agreed Price',
            value: '${_booking!.agreedPrice.toStringAsFixed(0)} EGP',
            iconColor: Color(0xFF10B981),
          ),
          Divider(height: 24),
          _buildDetailRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: _booking!.statusLabel,
            iconColor: Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: DateFormat('yyyy-MM-dd').format(_booking!.bookingDate),
            iconColor: Color(0xFF8B5CF6),
          ),
          Divider(height: 24),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: _booking!.bookingTime,
            iconColor: Color(0xFF10B981),
          ),
          Divider(height: 24),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Location',
            value: _booking!.location,
            iconColor: Color(0xFFEF4444),
          ),
          if (_booking!.startedAt != null) ...[
            Divider(height: 24),
            _buildDetailRow(
              icon: Icons.play_circle_outline,
              label: 'Started at',
              value: DateFormat('yyyy-MM-dd HH:mm').format(_booking!.startedAt!),
              iconColor: Color(0xFF3B82F6),
            ),
          ],
          if (_booking!.completedAt != null) ...[
            Divider(height: 24),
            _buildDetailRow(
              icon: Icons.check_circle_outline,
              label: 'Completed at',
              value: DateFormat('yyyy-MM-dd HH:mm').format(_booking!.completedAt!),
              iconColor: Color(0xFF10B981),
            ),
          ],
          if (_booking!.clientNotes != null && _booking!.clientNotes!.isNotEmpty) ...[
            Divider(height: 24),
            _buildDetailRow(
              icon: Icons.note,
              label: 'Customer Notes',
              value: _booking!.clientNotes!,
              iconColor: Color(0xFF666666),
            ),
          ],
          if (_booking!.providerNotes != null && _booking!.providerNotes!.isNotEmpty) ...[
            Divider(height: 24),
            _buildDetailRow(
              icon: Icons.note_alt,
              label: 'Worker Notes',
              value: _booking!.providerNotes!,
              iconColor: Color(0xFF8B5CF6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
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
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
