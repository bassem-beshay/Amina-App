import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// P25: a provider asks the customer to move an already confirmed booking.
class ProviderRequestRescheduleScreen extends StatefulWidget {
  const ProviderRequestRescheduleScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<ProviderRequestRescheduleScreen> createState() =>
      _ProviderRequestRescheduleScreenState();
}

class _ProviderRequestRescheduleScreenState
    extends State<ProviderRequestRescheduleScreen> {
  late DateTime _date;
  late TimeOfDay _time;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _date = widget.booking.bookingDate.add(const Duration(days: 1));
    _time = _parseTime(widget.booking.bookingTime) ??
        const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add a reason')));
      return;
    }
    setState(() => _busy = true);
    final result = await BookingService.createReschedule(
        bookingId: widget.booking.id,
        date: _date,
        time: _time.format(context),
        reason: reason);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule request sent')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Could not send request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              _header(context, 'Request reschedule'),
              _panel(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _muted('Current date'),
                    Text(_dateLabel(widget.booking.bookingDate), style: _value),
                    const Divider(height: 26),
                    _muted('Current time'),
                    Text(widget.booking.bookingTime, style: _value),
                  ])),
              const SizedBox(height: 26),
              const Text('New schedule',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _picker('Date', _dateLabel(_date), () async {
                  final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: _date.isBefore(DateTime.now())
                          ? DateTime.now()
                          : _date);
                  if (picked != null) setState(() => _date = picked);
                })),
                const SizedBox(width: 11),
                Expanded(
                    child: _picker('Time', _time.format(context), () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                })),
              ]),
              const SizedBox(height: 24),
              const Text('Reason',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                  controller: _reason,
                  maxLines: 4,
                  decoration: _decoration(
                      'Tell the customer why you need to reschedule')),
              const SizedBox(height: 18),
              _info('The customer must approve this schedule change.'),
              const SizedBox(height: 20),
              SizedBox(
                  height: 49,
                  child: ElevatedButton(
                      onPressed: _busy ? null : _send,
                      style: _button,
                      child: _busy
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send request'))),
            ]),
      ),
    );
  }
}

/// P26: provider reviews a customer's incoming schedule request.
class ProviderIncomingRescheduleScreen extends StatefulWidget {
  const ProviderIncomingRescheduleScreen(
      {super.key, required this.bookingId, this.reschedulesFuture});
  final int bookingId;
  final Future<List<BookingReschedule>>? reschedulesFuture;

  @override
  State<ProviderIncomingRescheduleScreen> createState() =>
      _ProviderIncomingRescheduleScreenState();
}

class _ProviderIncomingRescheduleScreenState
    extends State<ProviderIncomingRescheduleScreen> {
  late Future<List<BookingReschedule>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.reschedulesFuture ?? _load();
  }

  Future<List<BookingReschedule>> _load() async {
    final response =
        await BookingService.getReschedules(bookingId: widget.bookingId);
    return response.data ?? const [];
  }

  Future<void> _decision(BookingReschedule item, bool approve) async {
    setState(() => _busy = true);
    final ok = approve
        ? await BookingService.approveReschedule(item.id)
        : await BookingService.rejectReschedule(item.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (approve ? 'Request approved' : 'Request rejected')
            : 'Action failed')));
    if (ok) setState(() => _future = Future.value([]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
            child: FutureBuilder<List<BookingReschedule>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final item = (snapshot.data ?? const <BookingReschedule>[])
                .where((e) => e.status.toUpperCase() == 'PENDING')
                .firstOrNull;
            if (item == null)
              return ListView(padding: const EdgeInsets.all(20), children: [
                _header(context, 'Reschedule Request'),
                const SizedBox(height: 170),
                const Center(child: Text('No pending reschedule request'))
              ]);
            return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _header(context, 'Reschedule Request'),
                  _panel(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _muted('Current date'),
                        Text('Booking date', style: _value),
                        const Divider(height: 26),
                        _muted('Current time'),
                        Text('Booking time', style: _value)
                      ])),
                  const SizedBox(height: 26),
                  const Text('New schedule',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _picker('Date', _dateLabel(item.newDate), null)),
                    const SizedBox(width: 11),
                    Expanded(child: _picker('Time', item.newTime, null))
                  ]),
                  const SizedBox(height: 24),
                  const Text('Reason',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _panel(Text(item.reason)),
                  const SizedBox(height: 18),
                  _info('Approve or reject the customer’s requested schedule.'),
                  const SizedBox(height: 20),
                  SizedBox(
                      height: 49,
                      child: ElevatedButton(
                          onPressed: _busy ? null : () => _decision(item, true),
                          style: _button,
                          child: _busy
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Approve request'))),
                  TextButton(
                      onPressed: _busy ? null : () => _decision(item, false),
                      child: const Text('Reject request',
                          style: TextStyle(
                              color: Color(0xFFD1292E),
                              fontWeight: FontWeight.w600))),
                ]);
          },
        )),
      );
}

Widget _header(BuildContext context, String title) => SizedBox(
      height: 72,
      child: Stack(children: [
        Positioned(
            left: -8,
            top: 22,
            child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, size: 28))),
        Positioned(
            left: 0,
            right: 0,
            top: 27,
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600))),
      ]),
    );

Widget _panel(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: child,
    );

Widget _muted(String text) =>
    Text(text, style: const TextStyle(color: Color(0xFF808080), fontSize: 12));

Widget _info(String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFEDE8FE),
          borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );

Widget _picker(String label, String value, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 8),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: onTap == null
                    ? const Color(0xFFE3E3E8)
                    : const Color(0xFF8B5CF6)),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _muted(label),
          const SizedBox(height: 8),
          Text(value, style: _value),
        ]),
      ),
    );
InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3E3E8))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3E3E8))));
const _value = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
final _button = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF8B5CF6),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));
String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
String _month(int month) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][month - 1];
TimeOfDay? _parseTime(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) return null;
  return TimeOfDay(
      hour: int.parse(match.group(1)!), minute: int.parse(match.group(2)!));
}
