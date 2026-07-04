import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/connectivity_button.dart';

/// Service in progress screen - shown to worker after starting service
class ServiceInProgressScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic> bookingData;

  const ServiceInProgressScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<ServiceInProgressScreen> createState() =>
      _ServiceInProgressScreenState();
}

class _ServiceInProgressScreenState extends State<ServiceInProgressScreen> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final clientName = widget.bookingData['client_info']?['full_name'] ?? 'العميل';
    final serviceName = widget.bookingData['service_title'] ?? 'الخدمة';
    final city = widget.bookingData['city'] ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        title: Text(
          'Service in Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.surface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header with animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Animated icon
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_circle,
                          size: 64,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                Text(
                  'Service in Progress Now',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Performing service for customer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Service details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Service name
                          _buildDetailRow(
                            icon: Icons.cleaning_services,
                            label: 'Service',
                            value: serviceName,
                            color: Color(0xFF4F46E5),
                          ),
                          SizedBox(height: 16),

                          // Client name
                          _buildDetailRow(
                            icon: Icons.person,
                            label: 'Customer',
                            value: clientName,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(height: 16),

                          // Location
                          _buildDetailRow(
                            icon: Icons.location_on,
                            label: 'City',
                            value: city,
                            color: Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Instructions card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFF59E0B),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'After completing the service, click "Complete Service" below',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Complete service button (fixed at bottom)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Complete service button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ConnectivityIconButton(
                      onPressed: _isCompleting ? null : _completeService,
                      icon: _isCompleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 24),
                      label: Text(
                        _isCompleting ? 'Completing...' : 'Complete Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Report issue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _reportIssue,
                      icon: const Icon(Icons.report_problem_outlined, size: 24),
                      label: Text(
                        'Report an Issue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: color),
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
                  fontSize: 16,
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

  Future<void> _completeService() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 28),
            SizedBox(width: 12),
            Text('Complete Service'),
          ],
        ),
        content: Text(
          'Have you completed the service fully?\n\nThe customer will be notified and asked to confirm completion.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Confirm Completion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final response = await ApiClient.post(
        '/api/bookings/${widget.bookingId}/complete/',
        needsAuth: true,
      );

      if (!mounted) return;

      setState(() {
        _isCompleting = false;
      });

      if (response.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Service completed - Awaiting customer confirmation'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4F46E5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to bookings list
        Navigator.pop(context, true); // Return true to refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.error ?? "Failed to complete service"}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _reportIssue() {
    final complaintController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the issue:'),
            SizedBox(height: 12),
            TextField(
              controller: complaintController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type the issue here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () {
              complaintController.dispose();
              Navigator.pop(ctx);
            },
            child: Text('Cancel'),
          ),
          ConnectivityButton(
            onPressed: () async {
              final complaint = complaintController.text.trim();
              if (complaint.isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              complaintController.dispose();

              // Wait a bit for dialog to close
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;

              _submitComplaint(complaint);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Send Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint(String complaint) async {
    try {
      final response = await ApiClient.post(
        '/api/bookings/complaints/create/',
        needsAuth: true,
        body: {
          'booking': widget.bookingId,
          'title': 'Complaint from Worker',
          'description': complaint,
        },
      );

      if (!mounted) return;

      if (response.success) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
                SizedBox(width: 12),
                Text('Report Sent'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Report submitted successfully.\n\nIt will be reviewed by the administration and you will be contacted soon.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            actions: [
              ConnectivityButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.error ?? "Failed to send report"}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

}
