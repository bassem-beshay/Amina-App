import 'package:flutter/material.dart';
import '../models/booking_request_model.dart' as booking_model;
import '../models/worker_offer_model.dart';
import '../services/booking_service.dart';
import '../services/worker_offer_service.dart';
import '../widgets/connectivity_button.dart';
import 'offer_confirmation_screen.dart';
import '../l10n/app_localizations.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  List<booking_model.BookingRequest> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await BookingService.getBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // الرجوع للـ home
        Navigator.pushNamedAndRemoveUntil(context, '/customer-home', (route) => false);
      },
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          localizations?.myBookingsTitle ?? 'حجوزاتي',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF4F46E5) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: localizations?.refresh ?? 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        localizations?.noBookingsCurrentlyMessage ?? 'لا توجد حجوزات حالياً',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations?.startBookingNewService ?? 'ابدأ بحجز خدمة جديدة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  color: const Color(0xFF4F46E5),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return _buildBookingCard(booking, localizations);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildBookingCard(booking_model.BookingRequest booking, AppLocalizations? localizations) {
    final locale = Localizations.localeOf(context).languageCode;
    final localizedServiceTitle = booking.getLocalizedServiceTitle(locale);
    final serviceIcon = _getServiceIcon(localizedServiceTitle);
    final serviceColor = _getServiceColor(localizedServiceTitle);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service icon and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  serviceColor.withOpacity(0.1),
                  serviceColor.withOpacity(0.05),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Service Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: serviceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    serviceIcon,
                    color: serviceColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                // Service Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedServiceTitle.isNotEmpty ? localizedServiceTitle : (localizations?.serviceLabel ?? 'خدمة'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#${booking.id}',
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
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(booking.status, localizations),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(booking.bookingDate, localizations),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking.bookingTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description (if available)
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // View Offers Button
                SizedBox(
                  width: double.infinity,
                  child: ConnectivityIconButton(
                    onPressed: () => _showOffersDialog(booking),
                    icon: const Icon(Icons.local_offer, size: 20),
                    label: Text(
                      localizations?.viewAvailableOffers ?? 'عرض العروض المتاحة',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

  // Helper methods
  IconData _getServiceIcon(String serviceTitle) {
    final titleLower = serviceTitle.toLowerCase();
    if (titleLower.contains('تنظيف')) return Icons.cleaning_services;
    if (titleLower.contains('طبخ')) return Icons.restaurant;
    if (titleLower.contains('أطفال')) return Icons.child_care;
    if (titleLower.contains('مسن')) return Icons.accessible;
    if (titleLower.contains('غسيل')) return Icons.local_laundry_service;
    if (titleLower.contains('كي')) return Icons.checkroom;
    return Icons.home_repair_service;
  }

  Color _getServiceColor(String serviceTitle) {
    final titleLower = serviceTitle.toLowerCase();
    if (titleLower.contains('تنظيف')) return const Color(0xFF10B981);
    if (titleLower.contains('طبخ')) return const Color(0xFFF59E0B);
    if (titleLower.contains('أطفال')) return const Color(0xFF3B82F6);
    if (titleLower.contains('مسن')) return const Color(0xFF4F46E5);
    if (titleLower.contains('غسيل')) return const Color(0xFFEC4899);
    if (titleLower.contains('كي')) return const Color(0xFF06B6D4);
    return const Color(0xFF3B82F6);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _getStatusLabel(String status, AppLocalizations? localizations) {
    switch (status.toLowerCase()) {
      case 'open':
        return localizations?.openStatus ?? 'مفتوح';
      case 'accepted':
        return localizations?.accepted ?? 'مقبول';
      case 'completed':
        return localizations?.completed ?? 'مكتمل';
      case 'cancelled':
        return localizations?.cancelled ?? 'ملغي';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date, AppLocalizations? localizations) {
    if (date == null) return localizations?.unspecifiedText ?? 'غير محدد';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return localizations?.today ?? 'اليوم';
    } else if (difference == 1) {
      return localizations?.tomorrow ?? 'غداً';
    } else if (difference == -1) {
      return localizations?.yesterday ?? 'أمس';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Show offers dialog
  Future<void> _showOffersDialog(booking_model.BookingRequest booking) async {
    final localizations = AppLocalizations.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
        ),
      ),
    );

    // Fetch offers
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
              localizations?.availableOffersTitle ?? 'العروض المتاحة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${offers.length} ${localizations?.offer ?? 'عرض'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        content: offers.isEmpty
            ? SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations?.noOffersYet ?? 'لا توجد عروض بعد',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations?.waitForProviders ?? 'انتظر حتى يتقدم مقدمو الخدمة بعروضهم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return _buildOfferCard(offer, booking);
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.closeButton ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(WorkerOffer offer, booking_model.BookingRequest booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4F46E5).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Worker avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 12),
              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)?.serviceProvider ?? 'مقدم خدمة'} #${offer.workerId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${offer.offeredPrice} دك',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)?.priceLabel ?? 'السعر',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.message!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Accept button
          SizedBox(
            width: double.infinity,
            child: ConnectivityButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OfferConfirmationScreen(
                      offer: offer,
                      bookingRequest: booking,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadBookings(); // Refresh bookings
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(AppLocalizations.of(context)?.acceptOffer ?? 'قبول العرض'),
            ),
          ),
        ],
      ),
    );
  }
}
