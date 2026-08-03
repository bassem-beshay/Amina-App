import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';

class ProviderRateCustomerScreen extends StatefulWidget {
  const ProviderRateCustomerScreen(
      {super.key, required this.booking, this.customerName});
  final Booking booking;
  final String? customerName;
  @override
  State<ProviderRateCustomerScreen> createState() => _RateState();
}

class _RateState extends State<ProviderRateCustomerScreen> {
  int rating = 5;
  final review = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    review.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    final r = await BookingService.createRating(
        bookingId: widget.booking.id,
        rating: rating,
        review: review.text.trim());
    if (!mounted) return;
    setState(() => busy = false);
    if (r.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
            title: const Text('Rate Customer'),
            backgroundColor: bg,
            elevation: 0,
            centerTitle: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.customerName ?? widget.booking.clientName ?? 'Customer',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Center(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        5,
                        (i) => IconButton(
                            onPressed: () => setState(() => rating = i + 1),
                            icon: Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: orange))))),
            const Center(
                child: Text('How was your experience?',
                    style: TextStyle(color: mutedColor, fontSize: 12))),
            const SizedBox(height: 8),
            Center(
                child: Text('Booking #${widget.booking.id} · Completed',
                    style: const TextStyle(color: teal, fontSize: 13))),
          ])),
          const SizedBox(height: 18),
          const Text('Your comment',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
              controller: review,
              maxLines: 4,
              decoration: input('Write a comment')),
          const SizedBox(height: 20),
          SizedBox(
              height: 49,
              child: ElevatedButton(
                  onPressed: busy ? null : submit,
                  style: button,
                  child: busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit rating'))),
        ]),
      );
}

class ProviderComplaintsScreen extends StatefulWidget {
  const ProviderComplaintsScreen({super.key, this.complaintsFuture});
  final Future<List<Complaint>>? complaintsFuture;
  @override
  State<ProviderComplaintsScreen> createState() => _ComplaintsState();
}

class _ComplaintsState extends State<ProviderComplaintsScreen> {
  late Future<List<Complaint>> future;
  @override
  void initState() {
    super.initState();
    future = widget.complaintsFuture ?? _load();
  }

  Future<List<Complaint>> _load() async =>
      (await BookingService.getComplaints()).data ?? const [];
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
            title: const Text('Complaints'), backgroundColor: bg, elevation: 0),
        body: FutureBuilder<List<Complaint>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final list = snap.data ?? const <Complaint>[];
            if (list.isEmpty) return const Center(child: Text('No complaints'));
            final cards = list
                .map<Widget>((c) => Card(
                    elevation: 0,
                    child: ListTile(
                        title: Text(c.title),
                        subtitle: Text(c.description, maxLines: 2),
                        trailing: Text(c.status))))
                .toList();
            return ListView(padding: const EdgeInsets.all(20), children: cards);
          },
        ),
      );
}

class ProviderCreateComplaintScreen extends StatefulWidget {
  const ProviderCreateComplaintScreen({super.key, required this.booking});
  final Booking booking;
  @override
  State<ProviderCreateComplaintScreen> createState() => _CreateComplaintState();
}

class _CreateComplaintState extends State<ProviderCreateComplaintScreen> {
  final title = TextEditingController(), description = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and description are required')));
      return;
    }
    setState(() => busy = true);
    final r = await BookingService.createComplaint(
        bookingId: widget.booking.id,
        title: title.text.trim(),
        description: description.text.trim(),
        againstId: widget.booking.clientId);
    if (!mounted) return;
    setState(() => busy = false);
    if (r.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
          title: const Text('Create Complaint'),
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          muted('Booking'),
          Text(
              '#${widget.booking.id} · ${widget.booking.serviceTitleEn ?? widget.booking.serviceTitle ?? 'Service'}',
              style: value),
          const Divider(height: 25),
          muted('Customer'),
          Text(widget.booking.clientName ?? 'Customer', style: value)
        ])),
        const SizedBox(height: 24),
        const Text('Complaint details',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(controller: title, decoration: input('Title')),
        const SizedBox(height: 12),
        TextField(
            controller: description,
            maxLines: 5,
            decoration: input('Description')),
        const SizedBox(height: 18),
        info(
            'Complaints can be submitted after the service is fully completed.'),
        const SizedBox(height: 20),
        SizedBox(
            height: 49,
            child: ElevatedButton(
                onPressed: busy ? null : submit,
                style: button,
                child: busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit complaint')))
      ]));
}

class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key, this.notificationsFuture});
  final Future<List<BookingNotification>>? notificationsFuture;
  @override
  State<ProviderNotificationsScreen> createState() => _NotificationsState();
}

class _NotificationsState extends State<ProviderNotificationsScreen> {
  late Future<List<BookingNotification>> future;
  @override
  void initState() {
    super.initState();
    future = widget.notificationsFuture ?? BookingService.getNotifications();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: bg,
            elevation: 0,
            actions: [
              TextButton(
                  onPressed: () async {
                    await BookingService.markAllNotificationsAsRead();
                    if (mounted)
                      setState(
                          () => future = BookingService.getNotifications());
                  },
                  child: const Text('Read all'))
            ]),
        body: FutureBuilder<List<BookingNotification>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final list = snap.data ?? const <BookingNotification>[];
            if (list.isEmpty)
              return const Center(child: Text('No notifications'));
            final cards = list
                .map<Widget>((n) => Card(
                    elevation: 0,
                    child: ListTile(
                        leading: const Icon(Icons.notifications_none),
                        title: Text(n.title),
                        subtitle: Text(n.message),
                        onTap: () =>
                            BookingService.markNotificationAsRead(n.id))))
                .toList();
            return ListView(padding: const EdgeInsets.all(20), children: cards);
          },
        ),
      );
}

const bg = Color(0xFFF7F7F7),
    mutedColor = Color(0xFF808080),
    teal = Color(0xFF16A385),
    orange = Color(0xFFF29E1F);
const value = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: child);
Widget muted(String text) =>
    Text(text, style: const TextStyle(color: mutedColor, fontSize: 12));
Widget info(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFFEDE8FE),
        borderRadius: BorderRadius.circular(14)),
    child: Text(text, style: const TextStyle(fontSize: 12)));
InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3E3E8))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3E3E8))));
final button = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF8B5CF6),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));
