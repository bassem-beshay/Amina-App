import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'provider_reschedule_screens.dart';

class ProviderBookingDetailsScreen extends StatefulWidget {
  const ProviderBookingDetailsScreen(
      {super.key, required this.bookingId, this.booking, this.bookingFuture});

  final int bookingId;
  final Booking? booking;
  final Future<Booking?>? bookingFuture;

  @override
  State<ProviderBookingDetailsScreen> createState() =>
      _ProviderBookingDetailsScreenState();
}

class _ProviderBookingDetailsScreenState
    extends State<ProviderBookingDetailsScreen> {
  late Future<Booking?> _booking;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.bookingFuture ??
        (widget.booking != null
            ? Future.value(widget.booking)
            : BookingService.getBookingDetails(widget.bookingId));
  }

  Future<void> _action(Booking booking) async {
    final status = booking.status.toUpperCase();
    setState(() => _busy = true);
    final result = status == 'CONFIRMED' || status == 'PAYMENT_COMPLETED'
        ? await BookingService.startBooking(booking.id)
        : await BookingService.completeBooking(booking.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? (status == 'IN_PROGRESS'
                ? 'Service marked complete'
                : 'Service started')
            : (result.error ?? 'Action failed'))));
    if (result.success) setState(() => _booking = Future.value(result.booking));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: FutureBuilder<Booking?>(
          future: _booking,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final booking = snapshot.data;
            if (booking == null)
              return const Center(child: Text('Could not load booking'));
            return _content(context, booking);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Booking booking) {
    final status = booking.status.toUpperCase();
    final label = _label(status);
    final color = status == 'COMPLETED'
        ? const Color(0xFF16A385)
        : status == 'CANCELED'
            ? const Color(0xFFDB2626)
            : const Color(0xFF8B5CF6);
    final service = booking.serviceTitleEn ??
        booking.serviceTitle ??
        (booking.serviceId == null
            ? 'Service request'
            : 'Service #${booking.serviceId}');
    final canStart = status == 'CONFIRMED' || status == 'PAYMENT_COMPLETED';
    final canComplete = status == 'IN_PROGRESS';
    final pendingPayment = status == 'PENDING_PAYMENT';
    return Column(children: [
      _header(context),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
            Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
                decoration: BoxDecoration(
                    color: pendingPayment
                        ? const Color(0xFFEDE8FE)
                        : const Color(0xFFE7F6EC),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pendingPayment ? 'Pending payment' : label,
                          style: TextStyle(
                              color: pendingPayment
                                  ? const Color(0xFF8B5CF6)
                                  : color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      Text(_statusSubtitle(status, booking),
                          style: const TextStyle(
                              color: Color(0xFF808080), fontSize: 12))
                    ])),
            const SizedBox(height: 18),
            _panel(Row(children: [
              const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF16A385),
                  child: Text('AA',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.clientName ?? 'Client #${booking.clientId}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(booking.clientPhone ?? 'Customer',
                    style:
                        const TextStyle(color: Color(0xFF808080), fontSize: 12))
              ])
            ])),
            const SizedBox(height: 18),
            _panel(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _kv('Service', service),
              _kv('Date & Time',
                  '${booking.bookingDate.day}/${booking.bookingDate.month} · ${booking.bookingTime}'),
              _kv('Location', booking.location),
              _kv('Payment', '${booking.agreedPrice.toStringAsFixed(0)} EGP'),
              _kv('Provider notes',
                  booking.providerNotes ?? 'Add service notes',
                  last: true)
            ])),
            if (booking.clientNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              _panel(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer note',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(booking.clientNotes!,
                        style: const TextStyle(
                            color: Color(0xFF808080), fontSize: 13))
                  ]))
            ],
            if (pendingPayment) ...[
              const SizedBox(height: 18),
              _panel(const Text(
                  'Payment must be completed before the service can start.',
                  style: TextStyle(fontSize: 12)))
            ],
            const SizedBox(height: 18),
            if (canStart || canComplete)
              SizedBox(
                  height: 49,
                  child: ElevatedButton(
                      onPressed: _busy ? null : () => _action(booking),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: _busy
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              canStart
                                  ? 'Start service'
                                  : 'Mark service complete',
                              style: const TextStyle(fontSize: 16)))),
            if (status == 'CONFIRMED' ||
                status == 'PAYMENT_COMPLETED' ||
                status == 'IN_PROGRESS')
              OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProviderRequestRescheduleScreen(
                              booking: booking))),
                  icon: const Icon(Icons.event_repeat),
                  label: const Text('Request reschedule'))
          ])),
    ]);
  }

  Widget _header(BuildContext context) => SizedBox(
      height: 94,
      child: Stack(children: [
        const Positioned(
            left: 24,
            top: 18,
            child: Text('9:41',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        Positioned(
            left: 8,
            top: 46,
            child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, size: 28))),
        const Positioned(
            left: 0,
            right: 0,
            top: 61,
            child: Text('Booking Details',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))
      ]));
  Widget _panel(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: child);
  Widget _kv(String label, String value, {bool last = false}) => Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF808080), fontSize: 12)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
      ]));
  String _label(String status) => switch (status) {
        'CONFIRMED' || 'PAYMENT_COMPLETED' => 'Confirmed · Payment completed',
        'IN_PROGRESS' => 'In progress',
        'PROVIDER_COMPLETED' => 'Pending completion',
        'COMPLETED' => 'Completed',
        'CANCELED' || 'CANCELLED' => 'Canceled',
        _ => status
      };
  String _statusSubtitle(String status, Booking booking) => switch (status) {
        'CONFIRMED' ||
        'PAYMENT_COMPLETED' =>
          'Accepted offer · Starts ${booking.bookingDate.day}/${booking.bookingDate.month}',
        'IN_PROGRESS' => 'Service is currently in progress',
        'PROVIDER_COMPLETED' => 'Waiting for customer confirmation',
        'COMPLETED' => 'Service completed successfully',
        'CANCELED' || 'CANCELLED' => booking.cancelReason ?? 'Booking canceled',
        _ => status
      };
}
