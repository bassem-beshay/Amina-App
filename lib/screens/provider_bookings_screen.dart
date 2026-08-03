import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'provider_booking_details_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen(
      {super.key, this.company = false, this.bookingsFuture});

  final bool company;
  final Future<List<Booking>>? bookingsFuture;

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  late Future<List<Booking>> _bookings;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _bookings = widget.bookingsFuture ?? BookingService.getProviderBookings();
  }

  Future<void> _refresh() async {
    setState(() => _bookings = BookingService.getProviderBookings());
    await _bookings;
  }

  List<Booking> _filtered(List<Booking> items) {
    if (_filter == 'all') return items;
    return items.where((item) => item.status.toLowerCase() == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _filters(),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Booking>>(
                future: _bookings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = _filtered(snapshot.data ?? const []);
                  if (items.isEmpty) {
                    return Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('No bookings found'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: _refresh, child: const Text('Try again'))
                    ]));
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) => _card(context, items[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
            left: 12,
            top: 46,
            child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, size: 28))),
        Positioned(
            left: 0,
            right: 0,
            top: 61,
            child: Text(widget.company ? 'Company Bookings' : 'My Bookings',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))
      ]));

  Widget _filters() => SizedBox(
      height: 26,
      child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _filterChip('All', 'all', 54),
            const SizedBox(width: 10),
            _filterChip('Confirmed', 'confirmed', 86),
            const SizedBox(width: 10),
            _filterChip('In progress', 'in_progress', 88),
            const SizedBox(width: 10),
            _filterChip('Pending payment', 'pending_payment', 105)
          ]));

  Widget _filterChip(String label, String value, double width) =>
      GestureDetector(
          onTap: () => setState(() => _filter = value),
          child: Container(
              width: width,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color:
                      _filter == value ? const Color(0xFFEDE8FE) : Colors.white,
                  borderRadius: BorderRadius.circular(13)),
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600))));

  Widget _card(BuildContext context, Booking booking) {
    final status = booking.status.toLowerCase();
    final label = switch (status) {
      'pending_payment' => 'Pending payment',
      'in_progress' => 'In progress',
      'completed' => 'Completed',
      'canceled' || 'cancelled' => 'Canceled',
      _ => 'Confirmed'
    };
    final color = status == 'completed'
        ? const Color(0xFF16A385)
        : status == 'canceled' || status == 'cancelled'
            ? const Color(0xFFDB2626)
            : const Color(0xFF8B5CF6);
    final service = booking.serviceTitleEn ??
        booking.serviceTitle ??
        (booking.serviceId == null
            ? 'Service request'
            : 'Service #${booking.serviceId}');
    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(
              builder: (_) =>
                  ProviderBookingDetailsScreen(bookingId: booking.id)))
          .then((_) => _refresh()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
          height: 130,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(
                  radius: 21,
                  backgroundColor: Color(0xFF16A385),
                  child: Text('AA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      booking.clientName ?? 'Client #${booking.clientId}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEDE8FE),
                      borderRadius: BorderRadius.circular(13)),
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)))
            ]),
            const SizedBox(height: 10),
            Text(service,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: Text(
                      '${booking.bookingDate.day}/${booking.bookingDate.month} · ${booking.bookingTime}',
                      style: const TextStyle(
                          color: Color(0xFF808080), fontSize: 12))),
              const Text('View details ›',
                  style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600))
            ])
          ])),
    );
  }
}
