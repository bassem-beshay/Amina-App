import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../models/booking_request_model.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart' hide BookingRequest, WorkerOffer;
import '../models/worker_offer_model.dart';
import '../services/address_service.dart';
import '../services/api_client.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/provider_service.dart';
import '../services/service_service.dart';
import '../services/worker_offer_service.dart';
import 'client_flow_screens.dart';

const _primary = Color(0xff087f82);
const _text = Color(0xff172b4d);

String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

class ClientExtendedScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool nav;
  const ClientExtendedScaffold({super.key, required this.title, required this.body, this.nav = false});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff8fafb),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: _text,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: body,
        bottomNavigationBar: nav ? const ClientExtendedBottomNav() : null,
      );
}

class ClientExtendedBottomNav extends StatelessWidget {
  const ClientExtendedBottomNav({super.key});
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        selectedItemColor: _primary,
        currentIndex: 0,
        onTap: (i) {
          final page = i == 0
              ? const ClientHomeFlowScreen()
              : i == 1
                  ? const ClientCategoriesScreen()
                  : i == 2
                      ? const ClientBookingsFlowScreen()
                      : const ClientMoreScreen();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'More'),
        ],
      );
}

Widget _panel(Widget child) => Card(
      elevation: .5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );

Widget _action(String text, VoidCallback onTap, {bool outline = false}) => SizedBox(
      width: double.infinity,
      child: outline
          ? OutlinedButton(onPressed: onTap, child: Text(text))
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: Text(text),
            ),
    );

Widget _input(TextEditingController c, String label, {int lines = 1, TextInputType? type}) => TextField(
      controller: c,
      maxLines: lines,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );

class _Load<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T value) builder;
  const _Load({required this.future, required this.builder});
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primary));
          return builder(s.data as T);
        },
      );
}

class ClientCompaniesScreen extends StatelessWidget {
  const ClientCompaniesScreen({super.key});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(
        title: 'Companies',
        nav: true,
        body: _Load(future: ProviderService.getProviders(), builder: (items) {
          final companies = items.where((p) => p.isCompany).toList();
          final list = companies.isEmpty ? items : companies;
          return ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Verified Companies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...list.map((p) => _panel(ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business, color: _primary)),
                  title: Text(p.fullName),
                  subtitle: Text('${p.city ?? 'Cairo'}  •  ★ ${(p.averageRating ?? 0).toStringAsFixed(1)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientCompanyProfileScreen(provider: p))),
                )))
          ]);
        }),
      );
}

class ClientCompanyProfileScreen extends StatelessWidget {
  final Provider provider;
  const ClientCompanyProfileScreen({super.key, required this.provider});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(
        title: provider.fullName,
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _panel(Column(children: [
            const CircleAvatar(radius: 38, child: Icon(Icons.business, size: 34)),
            const SizedBox(height: 10),
            Text(provider.fullName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            Text(provider.bio ?? 'Verified company for home services'),
          ])),
          _action('Request company service', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientServiceDetailsScreen()))),
        ]),
      );
}

class ClientServiceDetailsScreen extends StatelessWidget {
  final Service? service;
  const ClientServiceDetailsScreen({super.key, this.service});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(
        title: 'Service details',
        body: _Load(future: service == null ? ServiceService.getServices().then((v) => v.isEmpty ? null : v.first) : Future.value(service), builder: (s) {
          if (s == null) return const Center(child: Text('No service available'));
          return ListView(padding: const EdgeInsets.all(20), children: [
            _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.nameEn, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _text)),
              const SizedBox(height: 8),
              Text(s.description),
              const SizedBox(height: 12),
              Text('From ${s.basePrice.toStringAsFixed(0)} EGP  •  ${s.estimatedDuration} hours', style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
            ])),
            _action('Request this service', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRequestTypeScreen(service: s)))),
          ]);
        }),
      );
}

class ClientRequestDraft {
  Service? service;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  String time = '10:00';
  String city = 'Cairo';
  String address = '';
  String notes = '';
  double budget = 0;
  int duration = 2;
  int? requestId;
}

class ClientRequestTypeScreen extends StatelessWidget {
  final Service? service;
  const ClientRequestTypeScreen({super.key, this.service});
  @override
  Widget build(BuildContext context) {
    final draft = ClientRequestDraft()..service = service;
    return ClientExtendedScaffold(
      title: 'Create request',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _panel(const ListTile(leading: Icon(Icons.home_work_outlined, color: _primary), title: Text('General request'), subtitle: Text('Receive offers from providers'))),
        _panel(const ListTile(leading: Icon(Icons.business_outlined, color: _primary), title: Text('Company service'), subtitle: Text('Request from a verified company'))),
        _action('Continue', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRequestDetailsScreen(draft: draft)))),
      ]),
    );
  }
}

class ClientRequestDetailsScreen extends StatelessWidget {
  final ClientRequestDraft draft;
  const ClientRequestDetailsScreen({super.key, required this.draft});
  @override
  Widget build(BuildContext context) {
    final notes = TextEditingController();
    return ClientExtendedScaffold(
      title: 'Request details',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _panel(Column(children: [
          _input(notes, 'Describe your requirements', lines: 5),
        ])),
        _action('Continue', () {
          draft.notes = notes.text;
          Navigator.push(context, MaterialPageRoute(builder: (_) => ClientScheduleAddressScreen(draft: draft)));
        }),
      ]),
    );
  }
}

class ClientScheduleAddressScreen extends StatelessWidget {
  final ClientRequestDraft draft;
  const ClientScheduleAddressScreen({super.key, required this.draft});
  @override
  Widget build(BuildContext context) {
    final address = TextEditingController(text: draft.address);
    return ClientExtendedScaffold(
      title: 'Schedule & address',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _panel(Column(children: [
          ListTile(leading: const Icon(Icons.event, color: _primary), title: Text(_fmt(draft.date)), onTap: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: draft.date);
            if (d != null) draft.date = d;
          }),
          _input(address, 'Address'),
        ])),
        _action('Continue', () {
          draft.address = address.text;
          Navigator.push(context, MaterialPageRoute(builder: (_) => ClientBudgetReviewScreen(draft: draft)));
        }),
      ]),
    );
  }
}

class ClientBudgetReviewScreen extends StatefulWidget {
  final ClientRequestDraft draft;
  const ClientBudgetReviewScreen({super.key, required this.draft});
  @override State<ClientBudgetReviewScreen> createState() => _BudgetState();
}
class _BudgetState extends State<ClientBudgetReviewScreen> {
  final budget = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(
        title: 'Budget & review',
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.draft.service?.nameEn ?? 'Service request'), Text(_fmt(widget.draft.date)), Text(widget.draft.address), const SizedBox(height: 12), _input(budget, 'Budget (EGP)', type: TextInputType.number)])),
          _action(loading ? 'Publishing…' : 'Publish request', loading ? () {} : () async {
            if (widget.draft.service == null) return;
            setState(() => loading = true);
            final result = await BookingService.createBookingRequest(serviceId: widget.draft.service!.id, categoryId: widget.draft.service!.category.id, bookingDate: widget.draft.date, bookingTime: widget.draft.time, durationHours: widget.draft.duration, city: widget.draft.city, address: widget.draft.address, clientBudget: double.tryParse(budget.text) ?? widget.draft.service!.basePrice);
            if (!mounted) return;
            setState(() => loading = false);
            if (result.success) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClientRequestSubmittedScreen(draft: widget.draft..requestId = result.bookingRequest?.id)));
          }),
        ]),
      );
}

class ClientRequestSubmittedScreen extends StatelessWidget {
  final ClientRequestDraft draft;
  const ClientRequestSubmittedScreen({super.key, required this.draft});
  @override
  Widget build(BuildContext context) {
    return ClientExtendedScaffold(
      title: 'Request submitted',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle, color: _primary, size: 72),
            const Text('Your request is live', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            _action('View my request', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClientRequestPendingScreen(requestId: draft.requestId ?? 0)))),
          ]),
        ),
      ),
    );
  }
}

class ClientRequestsScreen extends StatelessWidget {
  const ClientRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ClientExtendedScaffold(
      title: 'My requests', nav: true,
      body: _Load(future: BookingService.getBookings(), builder: (items) {
        return ListView(padding: const EdgeInsets.all(20), children: items.map<Widget>((r) {
          return _panel(ListTile(title: Text(r.serviceTitleEn ?? r.customServiceTitle ?? 'Request'), subtitle: Text('${_fmt(r.bookingDate)}  •  ${r.offersCount} offers'), trailing: Text(r.statusLabel), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRequestPendingScreen(requestId: r.id)) )));
        }).toList());
      }),
    );
  }
}

class ClientRequestPendingScreen extends StatelessWidget {
  final int requestId;
  const ClientRequestPendingScreen({super.key, required this.requestId});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Request details', body: _Load(future: BookingService.getBookingRequestById(requestId), builder: (r) {
        if (r == null) return const Center(child: Text('Request unavailable'));
        return ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.serviceTitleEn ?? r.customServiceTitle ?? 'Request', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('${_fmt(r.bookingDate)}  •  ${r.bookingTime}'), Text(r.address), Text('${r.offersCount} offers')])), _action('View offers', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientOffersScreen(request: r)))), _action('Edit request', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientEditRequestScreen(request: r))), outline: true), _action('Cancel request', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientCancelRequestScreen(request: r))), outline: true)]);
      }));
}

class ClientEditRequestScreen extends StatelessWidget {
  final BookingRequest request;
  const ClientEditRequestScreen({super.key, required this.request});
  @override
  Widget build(BuildContext context) {
    final notes = TextEditingController(text: request.notes);
    return ClientExtendedScaffold(title: 'Edit request', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(_input(notes, 'Details', lines: 5)), _action('Save changes', () async { final r = await BookingService.updateBookingRequest(request.id, notes: notes.text); if (context.mounted && r.success) Navigator.pop(context); })]));
  }
}

class ClientCancelRequestScreen extends StatelessWidget {
  final BookingRequest request;
  const ClientCancelRequestScreen({super.key, required this.request});
  @override
  Widget build(BuildContext context) {
    return ClientExtendedScaffold(title: 'Cancel request', body: Center(child: Padding(padding: const EdgeInsets.all(24), child: _panel(Column(children: [
      const Icon(Icons.warning_amber, color: Colors.orange, size: 52),
      const Text('Cancel this request?'),
      _action('Cancel request', () async { final r = await BookingService.cancelBookingRequest(request.id, reason: 'Cancelled by client'); if (context.mounted && r.success) Navigator.popUntil(context, (route) => route.isFirst); }, outline: true),
      _action('Keep request', () => Navigator.pop(context)),
    ])))));
  }
}

class ClientOffersScreen extends StatelessWidget {
  final BookingRequest request;
  const ClientOffersScreen({super.key, required this.request});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Offers received', body: _Load(future: WorkerOfferService.getOffers(bookingRequestId: request.id), builder: (offers) => ListView(padding: const EdgeInsets.all(20), children: [if (offers.length > 1) _action('Compare all', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientCompareOffersScreen(offers: offers)))), ...offers.map<Widget>((o) => _panel(ListTile(title: Text('${o.offeredPrice.toStringAsFixed(0)} EGP'), subtitle: Text(o.message ?? 'Provider offer'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientOfferDetailsScreen(offer: o, request: request))))))])));
}

class ClientCompareOffersScreen extends StatelessWidget {
  final List<WorkerOffer> offers;
  const ClientCompareOffersScreen({super.key, required this.offers});
  @override
  Widget build(BuildContext context) {
    return ClientExtendedScaffold(title: 'Compare offers', body: ListView(padding: const EdgeInsets.all(20), children: offers.map<Widget>((o) {
      return _panel(ListTile(title: Text('Provider #${o.workerId}'), subtitle: Text('${o.offeredPrice.toStringAsFixed(0)} EGP  •  ${o.estimatedDuration ?? 1} hours'), trailing: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientOfferDetailsScreen(offer: o))), child: const Text('Select'))));
    }).toList()));
  }
}

class ClientOfferDetailsScreen extends StatelessWidget {
  final WorkerOffer offer;
  final BookingRequest? request;
  const ClientOfferDetailsScreen({super.key, required this.offer, this.request});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Offer details', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Provider #${offer.workerId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(offer.message ?? 'Professional provider'), Text('${offer.offeredPrice.toStringAsFixed(0)} EGP', style: const TextStyle(fontSize: 25, color: _primary, fontWeight: FontWeight.bold))])), _action('Accept offer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientAcceptOfferScreen(offer: offer, request: request))))]));
}

class ClientAcceptOfferScreen extends StatelessWidget {
  final WorkerOffer offer;
  final BookingRequest? request;
  const ClientAcceptOfferScreen({super.key, required this.offer, this.request});
  @override
  Widget build(BuildContext context) {
    return ClientExtendedScaffold(title: 'Accept offer', body: Center(child: Padding(padding: const EdgeInsets.all(24), child: _panel(Column(children: [
      const Icon(Icons.verified, color: _primary, size: 52),
      Text('Accept ${offer.offeredPrice.toStringAsFixed(0)} EGP offer?'),
      _action('Accept offer', () async {
        final accepted = await WorkerOfferService.acceptOffer(offer.id);
        Booking? booking;
        if (accepted.success && request != null) {
          final result = await BookingService.createBooking(bookingRequestId: request!.id, acceptedOfferId: offer.id);
          booking = result.booking;
        }
        if (context.mounted && accepted.success) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClientBookingConfirmedScreen(booking: booking)));
      }),
    ])))));
  }
}

class ClientBookingConfirmedScreen extends StatelessWidget {
  final Booking? booking;
  const ClientBookingConfirmedScreen({super.key, this.booking});
  @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Booking confirmed', body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, color: _primary, size: 72), const Text('Your booking is confirmed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), _action('My bookings', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientBookingsFlowScreen())))]))));
}
class ClientBookingsFlowScreen extends StatelessWidget {
  const ClientBookingsFlowScreen({super.key});
  @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'My bookings', nav: true, body: _Load(future: BookingService.getBookings(), builder: (items) => ListView(padding: const EdgeInsets.all(20), children: items.map<Widget>((r) {
    return _panel(ListTile(title: Text(r.serviceTitleEn ?? 'Booking'), subtitle: Text('${_fmt(r.bookingDate)}  •  ${r.statusLabel}'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientBookingInProgressScreen(bookingId: r.id)) )));
  }).toList())));
}
class ClientBookingInProgressScreen extends StatelessWidget { final int bookingId; const ClientBookingInProgressScreen({super.key, required this.bookingId}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Booking in progress', body: _Load(future: BookingService.getBookingDetails(bookingId), builder: (b) { if (b == null) return const Center(child: Text('Booking unavailable')); return ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Booking #${b.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(b.location), Text('${_fmt(b.bookingDate)}  •  ${b.bookingTime}'), Text(b.status)])), _action('Request reschedule', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRescheduleScreen(booking: b)))), _action('Cancel booking', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientCancelBookingScreen(booking: b))), outline: true)]); })); }

class ClientPendingCompletionScreen extends StatelessWidget { final Booking booking; const ClientPendingCompletionScreen({super.key, required this.booking}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Pending completion', body: _action('Review and confirm', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientConfirmCompletionScreen(booking: booking))))); }
class ClientConfirmCompletionScreen extends StatelessWidget { final Booking booking; const ClientConfirmCompletionScreen({super.key, required this.booking}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Confirm completion', body: ListView(padding: const EdgeInsets.all(20), children: [_action('Confirm completion', () async { final r = await BookingService.confirmCompletion(booking.id); if (context.mounted && r.success) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClientBookingCompletedScreen(booking: booking))); }), _action('Create complaint', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientCreateComplaintScreen(booking: booking))), outline: true)])); }
class ClientBookingCompletedScreen extends StatelessWidget { final Booking booking; const ClientBookingCompletedScreen({super.key, required this.booking}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Booking completed', body: _action('Rate provider', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRatingScreen(booking: booking))))); }

class ClientRescheduleScreen extends StatefulWidget { final Booking booking; const ClientRescheduleScreen({super.key, required this.booking}); @override State<ClientRescheduleScreen> createState() => _RescheduleState(); }
class _RescheduleState extends State<ClientRescheduleScreen> { final reason = TextEditingController(); DateTime date = DateTime.now().add(const Duration(days: 2)); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Request reschedule', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(children: [ListTile(title: Text(_fmt(date)), leading: const Icon(Icons.event), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date); if (d != null) setState(() => date = d); }), _input(reason, 'Reason', lines: 3)])), _action('Send request', () async { final r = await BookingService.createReschedule(bookingId: widget.booking.id, date: date, time: '10:00', reason: reason.text); if (context.mounted && r.success) Navigator.pop(context); })])); }
class ClientIncomingRescheduleScreen extends StatelessWidget { final BookingReschedule reschedule; const ClientIncomingRescheduleScreen({super.key, required this.reschedule}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Incoming reschedule', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Text('${_fmt(reschedule.newDate)} at ${reschedule.newTime}\n${reschedule.reason}')), _action('Approve', () async { if (await BookingService.approveReschedule(reschedule.id) && context.mounted) Navigator.pop(context); }), _action('Reject', () async { if (await BookingService.rejectReschedule(reschedule.id) && context.mounted) Navigator.pop(context); }, outline: true)])); }
class ClientCancelBookingScreen extends StatelessWidget { final Booking booking; const ClientCancelBookingScreen({super.key, required this.booking}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Cancel booking', body: ListView(padding: const EdgeInsets.all(20), children: [_action('Cancel booking', () async { final r = await BookingService.cancelBooking(booking.id, reason: 'Cancelled by client'); if (context.mounted && r.success) Navigator.pop(context); }, outline: true), _action('Keep booking', () => Navigator.pop(context))])); }

class ClientConversationsScreen extends StatelessWidget {
  const ClientConversationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ClientExtendedScaffold(title: 'Conversations', nav: true, body: _Load(future: ChatService.getConversations(), builder: (items) {
      final rows = items.map<Widget>((c) {
        return _panel(ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(c.serviceNameEn ?? c.serviceName),
          subtitle: Text(c.lastMessage?.content ?? 'Open conversation'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientChatScreen(conversationId: c.id))),
        ));
      }).toList();
      return ListView(padding: const EdgeInsets.all(20), children: rows);
    }));
  }
}
class ClientChatScreen extends StatefulWidget { final int conversationId; const ClientChatScreen({super.key, required this.conversationId}); @override State<ClientChatScreen> createState() => _ChatState(); }
class _ChatState extends State<ClientChatScreen> { late Future<List<dynamic>> future; final controller = TextEditingController(); @override void initState() { super.initState(); future = ChatService.getMessages(widget.conversationId); } @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Chat', body: Column(children: [Expanded(child: _Load(future: future, builder: (items) => ListView(padding: const EdgeInsets.all(20), children: items.map<Widget>((m) => Align(alignment: Alignment.centerLeft, child: _panel(Text(m.content)))).toList()))), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: _input(controller, 'Message')), IconButton(onPressed: () async { if (controller.text.trim().isEmpty) return; await ChatService.sendMessage(widget.conversationId, controller.text.trim()); controller.clear(); setState(() => future = ChatService.getMessages(widget.conversationId)); }, icon: const Icon(Icons.send, color: _primary))]))])); }

class ClientRatingScreen extends StatefulWidget { final Booking booking; const ClientRatingScreen({super.key, required this.booking}); @override State<ClientRatingScreen> createState() => _RatingState(); }
class _RatingState extends State<ClientRatingScreen> {
  int rating = 0;
  final comment = TextEditingController();
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(
        title: 'Rate provider',
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _panel(Column(children: [
            const Text('How was your experience?'),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(onPressed: () => setState(() => rating = i + 1), icon: Icon(Icons.star, color: i < rating ? Colors.amber : Colors.grey)))),
            _input(comment, 'Comment', lines: 4),
          ])),
          _action('Submit rating', () async { final r = await BookingService.createRating(bookingId: widget.booking.id, rating: rating, review: comment.text); if (context.mounted && r.success) Navigator.pop(context); }),
        ]),
      );
}

class ClientComplaintsScreen extends StatelessWidget {
  const ClientComplaintsScreen({super.key});
  @override
  Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Complaints', nav: true, body: _Load(future: BookingService.getComplaints(), builder: (r) {
    final list = r.data ?? <Complaint>[];
    final rows = list.map<Widget>((c) {
      return _panel(ListTile(title: Text(c.title), subtitle: Text(c.status), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientComplaintDetailsScreen(complaint: c)))));
    }).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [_action('New complaint', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCreateComplaintScreen()))), ...rows]);
  }));
}
class ClientComplaintDetailsScreen extends StatelessWidget { final Complaint complaint; const ClientComplaintDetailsScreen({super.key, required this.complaint}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Complaint details', body: Padding(padding: const EdgeInsets.all(20), child: _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(complaint.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(complaint.status), Text(complaint.description)])))); }
class ClientCreateComplaintScreen extends StatefulWidget { final Booking? booking; const ClientCreateComplaintScreen({super.key, this.booking}); @override State<ClientCreateComplaintScreen> createState() => _ComplaintState(); }
class _ComplaintState extends State<ClientCreateComplaintScreen> { final title = TextEditingController(); final description = TextEditingController(); final id = TextEditingController(); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Create complaint', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(children: [_input(id, 'Booking ID', type: TextInputType.number), _input(title, 'Subject'), _input(description, 'Description', lines: 5)])), _action('Submit complaint', () async { final bookingId = widget.booking?.id ?? int.tryParse(id.text); if (bookingId == null) return; final r = await BookingService.createComplaint(bookingId: bookingId, title: title.text, description: description.text); if (context.mounted && r.success) Navigator.pop(context); })])); }

class ClientNotificationsScreen extends StatefulWidget { const ClientNotificationsScreen({super.key}); @override State<ClientNotificationsScreen> createState() => _NotificationState(); }
class _NotificationState extends State<ClientNotificationsScreen> { late Future<List<dynamic>> future; @override void initState() { super.initState(); future = NotificationService.getNotifications(); } @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Notifications', body: _Load(future: future, builder: (items) => ListView(padding: const EdgeInsets.all(20), children: items.map<Widget>((n) => _panel(ListTile(title: Text(n.title), subtitle: Text(n.message)))).toList()))); }

class ClientMoreScreen extends StatelessWidget { const ClientMoreScreen({super.key}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Profile & more', nav: true, body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(children: [_link(context, 'Edit profile', const ClientEditProfileFlowScreen()), _link(context, 'Saved addresses', const ClientSavedAddressesScreen()), _link(context, 'My requests', const ClientRequestsScreen()), _link(context, 'Complaints', const ClientComplaintsScreen()), _link(context, 'Notifications', const ClientNotificationsScreen()), _link(context, 'Language', const ClientLanguageScreen())]))])); }
Widget _link(BuildContext c, String text, Widget page) => ListTile(title: Text(text), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)));
class ClientEditProfileFlowScreen extends StatefulWidget { const ClientEditProfileFlowScreen({super.key}); @override State<ClientEditProfileFlowScreen> createState() => _EditProfileState(); }
class _EditProfileState extends State<ClientEditProfileFlowScreen> { final first = TextEditingController(); final last = TextEditingController(); final phone = TextEditingController(); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Edit profile', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(children: [_input(first, 'First name'), _input(last, 'Last name'), _input(phone, 'Phone', type: TextInputType.phone)])), _action('Save changes', () async { final r = await ProfileService.updateClientProfile(firstName: first.text, lastName: last.text, phoneNumber: phone.text); if (context.mounted && r.success) Navigator.pop(context); })])); }
class ClientSavedAddressesScreen extends StatelessWidget { const ClientSavedAddressesScreen({super.key}); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Saved addresses', body: _Load(future: AddressService.getAddresses(), builder: (r) => ListView(padding: const EdgeInsets.all(20), children: (r.data ?? []).map<Widget>((a) => _panel(ListTile(title: Text(a['label']?.toString() ?? 'Address'), subtitle: Text(a['address']?.toString() ?? '')))).toList()))); }
class ClientAddAddressScreen extends StatefulWidget { const ClientAddAddressScreen({super.key}); @override State<ClientAddAddressScreen> createState() => _AddAddressState(); }
class _AddAddressState extends State<ClientAddAddressScreen> { final label = TextEditingController(); final address = TextEditingController(); final city = TextEditingController(text: 'Cairo'); @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Add address', body: ListView(padding: const EdgeInsets.all(20), children: [_panel(Column(children: [_input(label, 'Label'), _input(address, 'Full address', lines: 3), _input(city, 'City')])), _action('Save address', () async { final r = await AddressService.addAddress(label: label.text, latitude: 30.0444, longitude: 31.2357, address: address.text, city: city.text); if (context.mounted && r.success) Navigator.pop(context); })])); }
class ClientLanguageScreen extends StatefulWidget { const ClientLanguageScreen({super.key}); @override State<ClientLanguageScreen> createState() => _LanguageState(); }
class _LanguageState extends State<ClientLanguageScreen> { String value = 'English'; @override Widget build(BuildContext context) => ClientExtendedScaffold(title: 'Language settings', body: ListView(padding: const EdgeInsets.all(20), children: ['English', 'العربية', 'System default'].map((l) => _panel(RadioListTile(value: l, groupValue: value, title: Text(l), onChanged: (v) => setState(() => value = v!)))).toList())); }
