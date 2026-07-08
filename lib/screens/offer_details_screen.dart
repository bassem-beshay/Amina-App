import 'package:flutter/material.dart';
import '../models/worker_offer_model.dart';
import '../models/booking_request_model.dart';
import '../services/worker_offer_service.dart';
import '../services/booking_service.dart';
import '../l10n/app_localizations.dart';
import 'offer_confirmation_screen.dart';
import '../widgets/connectivity_button.dart';

/// صفحة تحميل وعرض تفاصيل العرض بناءً على offer ID
/// يتم استخدامها عند الضغط على إشعار "عرض جديد"
class OfferDetailsScreen extends StatefulWidget {
  final int offerId;

  OfferDetailsScreen({
    super.key,
    required this.offerId,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  WorkerOffer? _offer;
  BookingRequest? _bookingRequest;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  Future<void> _loadOfferDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // جلب تفاصيل العرض
      final offer = await WorkerOfferService.getOfferById(widget.offerId);

      if (offer == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)?.noData ?? 'No data';
        });
        return;
      }

      // جلب تفاصيل طلب الحجز
      final bookingRequest = await BookingService.getBookingRequestById(offer.bookingRequestId);

      if (bookingRequest == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)?.noData ?? 'No data';
        });
        return;
      }

      setState(() {
        _offer = offer;
        _bookingRequest = bookingRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)?.errorOccurred ?? 'Error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.bookingDetails ?? 'Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.bookingDetails ?? 'Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Color(0xFFEF4444),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 24),
              ConnectivityButton(
                onPressed: _loadOfferDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.retry ?? 'Retry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // إذا تم تحميل البيانات بنجاح، افتح صفحة التأكيد
    if (_offer != null && _bookingRequest != null) {
      return OfferConfirmationScreen(
        offer: _offer!,
        bookingRequest: _bookingRequest!,
      );
    }

    // حالة غير متوقعة
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.bookingDetails ?? 'Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          AppLocalizations.of(context)?.errorOccurred ?? 'Error',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
