import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/connectivity_button.dart';

/// Service tracking screen for customers
/// Shows service status from payment to final confirmation
class ServiceTrackingScreen extends StatefulWidget {
  final int bookingId;

  const ServiceTrackingScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<ServiceTrackingScreen> createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen> {
  // Mock Data - will be updated when API is added
  String _serviceStatus = 'PAYMENT_COMPLETED'; // PAYMENT_COMPLETED, IN_PROGRESS, PROVIDER_COMPLETED, COMPLETED
  String _serviceName = 'Household Cleaning Service';
  String _providerName = 'Sarah Ahmed';
  String _bookingDate = '2025-10-30';
  String _bookingTime = '10:00 AM';
  String _address = 'University Street, Maadi, Cairo';
  DateTime? _startTime;
  DateTime? _estimatedEndTime;

  @override
  void initState() {
    super.initState();
    // Mock: Set expected start time
    _startTime = DateTime.now().add(const Duration(hours: 1));
    _estimatedEndTime = _startTime?.add(const Duration(hours: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Service Tracking',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Status Timeline
              _buildStatusTimeline(),

              const SizedBox(height: 20),

              // Service Details Card
              _buildServiceDetailsCard(),

              const SizedBox(height: 16),

              // Provider Info Card
              _buildProviderCard(),

              const SizedBox(height: 16),

              // Location Card
              _buildLocationCard(),

              const SizedBox(height: 16),

              // Action Buttons (based on status)
              _buildActionButtons(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Mock: Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // Update data here
      });
    }
  }

  Widget _buildStatusTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        children: [
          // Status Icon
          _buildStatusIcon(),

          const SizedBox(height: 16),

          // Status Text
          Text(
            _getStatusTitle(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _getStatusDescription(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Timeline Steps
          _buildTimelineSteps(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (_serviceStatus) {
      case 'PAYMENT_COMPLETED':
        icon = Icons.payment;
        color = const Color(0xFF10B981);
        break;
      case 'IN_PROGRESS':
        icon = Icons.build_circle;
        color = const Color(0xFF3B82F6);
        break;
      case 'PROVIDER_COMPLETED':
        icon = Icons.check_circle_outline;
        color = const Color(0xFFF59E0B);
        break;
      case 'COMPLETED':
        icon = Icons.verified;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 56,
        color: color,
      ),
    );
  }

  String _getStatusTitle() {
    switch (_serviceStatus) {
      case 'PAYMENT_COMPLETED':
        return 'Payment Completed Successfully';
      case 'IN_PROGRESS':
        return 'Service In Progress';
      case 'PROVIDER_COMPLETED':
        return 'Awaiting Your Confirmation';
      case 'COMPLETED':
        return 'Service Completed';
      default:
        return 'Service Status';
    }
  }

  String _getStatusDescription() {
    switch (_serviceStatus) {
      case 'PAYMENT_COMPLETED':
        return 'The worker is on the way - Service will start soon';
      case 'IN_PROGRESS':
        return 'The worker is currently performing the service';
      case 'PROVIDER_COMPLETED':
        return 'The worker has completed the service - Please review and confirm';
      case 'COMPLETED':
        return 'Thank you for using Amina platform';
      default:
        return '';
    }
  }

  Widget _buildTimelineSteps() {
    final steps = [
      {'title': 'Paid', 'status': 'PAYMENT_COMPLETED'},
      {'title': 'In Progress', 'status': 'IN_PROGRESS'},
      {'title': 'Completed', 'status': 'PROVIDER_COMPLETED'},
      {'title': 'Confirmed', 'status': 'COMPLETED'},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == _serviceStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isActive = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              // Step Indicator
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF4F46E5)
                          : Colors.white,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.surface,
                          )
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted && index < currentIndex
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Step Label
              Text(
                steps[index]['title']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? const Color(0xFF1a1a1a)
                      : const Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
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
            value: _serviceName,
            iconColor: Color(0xFF4F46E5),
          ),

          Divider(height: 24),

          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _bookingDate,
            iconColor: Color(0xFF10B981),
          ),

          Divider(height: 24),

          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: _bookingTime,
            iconColor: Color(0xFF3B82F6),
          ),

          if (_serviceStatus == 'IN_PROGRESS' && _estimatedEndTime != null) ...[
            Divider(height: 24),
            _buildDetailRow(
              icon: Icons.hourglass_bottom,
              label: 'Expected Completion Time',
              value: DateFormat('hh:mm a').format(_estimatedEndTime!),
              iconColor: Color(0xFFF59E0B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
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
      child: Row(
        children: [
          // Provider Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4F46E5).withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: Color(0xFF4F46E5),
            ),
          ),

          const SizedBox(width: 16),

          // Provider Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _providerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(125 تقييم)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call Button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.phone,
                color: Color(0xFF10B981),
                size: 24,
              ),
              onPressed: () {
                // Mock: Call the worker
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling...'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Service Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _address,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_serviceStatus == 'PROVIDER_COMPLETED') {
      // Worker completed - Customer needs to confirm
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Confirm completion
            ConnectivityButton(
              onPressed: () {
                _showConfirmCompletionDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Yes, Service Completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),

            SizedBox(height: 12),

            // Report issue
            OutlinedButton(
              onPressed: () {
                _showReportIssueDialog();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Report an Issue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_serviceStatus == 'COMPLETED') {
      // Service completed - Show rating button
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConnectivityIconButton(
          onPressed: () {
            // Mock: Go to rating screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rating screen...'),
                backgroundColor: Color(0xFF4F46E5),
              ),
            );
          },
          icon: Icon(Icons.star_outline),
          label: Text(
            'Rate Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      );
    }

    return SizedBox.shrink();
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

  void _showConfirmCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Service Completion'),
        content: Text(
          'Do you confirm that the service has been completed satisfactorily?\n\nAfter confirmation, the booking will be closed.',
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ConnectivityButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Mock: Confirm completion
              setState(() {
                _serviceStatus = 'COMPLETED';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Service completion confirmed successfully'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the issue:'),
            SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type the issue here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ConnectivityButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Issue reported - We will contact you soon'),
                  backgroundColor: Color(0xFF4F46E5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
            ),
            child: Text('Send Report'),
          ),
        ],
      ),
    );
  }
}
