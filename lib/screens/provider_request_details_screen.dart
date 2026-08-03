import 'package:flutter/material.dart';

import '../models/booking_request_model.dart';
import '../services/booking_service.dart';
import '../services/worker_offer_service.dart';

class ProviderRequestDetailsScreen extends StatelessWidget {
  const ProviderRequestDetailsScreen({super.key, required this.requestId});

  final int requestId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: FutureBuilder<BookingRequest?>(
          future: BookingService.getBookingRequestById(requestId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final request = snapshot.data;
            if (request == null) {
              return const Center(child: Text('Could not load request'));
            }
            return _Details(request: request);
          },
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.request});

  final BookingRequest request;

  @override
  Widget build(BuildContext context) {
    final client = request.clientInfo?.fullName.trim();
    final service = request.getLocalizedServiceTitle('en').isEmpty
        ? 'General customer request'
        : request.getLocalizedServiceTitle('en');
    return Column(
      children: [
        _top(context, 'Request Details'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _panel(
                const Text('General customer request',
                    style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                color: const Color(0xFFEDE8FE),
              ),
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
                  Text(client?.isNotEmpty == true ? client! : 'Ahmed Abbas',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  const Text('New customer',
                      style: TextStyle(color: Color(0xFF808080), fontSize: 12)),
                ]),
              ])),
              const SizedBox(height: 18),
              _infoPanel(service),
              if (request.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 18),
                _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer note',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text(request.notes!,
                          style: const TextStyle(
                              color: Color(0xFF808080), fontSize: 13)),
                    ])),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 49,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              ProviderSubmitOfferScreen(request: request))),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Send an offer',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _top(BuildContext context, String title) => SizedBox(
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
          Positioned(
              left: 0,
              right: 0,
              top: 61,
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _panel(Widget child, {Color color = Colors.white}) => Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: child);

  Widget _infoPanel(String service) =>
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _kv('Service', service),
        _kv('Date & Time',
            '${request.bookingDate.day}/${request.bookingDate.month} · ${request.bookingTime}'),
        _kv(
            'Location',
            request.address.isEmpty
                ? (request.city ?? 'Not specified')
                : request.address),
        _kv('Duration', '${request.durationHours} hours'),
        _kv(
            'Customer budget',
            request.clientBudget == null
                ? 'Not specified'
                : '${request.clientBudget!.toStringAsFixed(0)} EGP',
            accent: true,
            last: true),
      ]));

  Widget _kv(String label, String value,
          {bool accent = false, bool last = false}) =>
      Padding(
          padding: EdgeInsets.only(bottom: last ? 0 : 15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: Color(0xFF808080), fontSize: 12)),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    color: accent
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: accent ? FontWeight.w600 : FontWeight.w500))
          ]));
}

class ProviderSubmitOfferScreen extends StatefulWidget {
  const ProviderSubmitOfferScreen({super.key, required this.request});

  final BookingRequest request;

  @override
  State<ProviderSubmitOfferScreen> createState() =>
      _ProviderSubmitOfferScreenState();
}

class _ProviderSubmitOfferScreenState extends State<ProviderSubmitOfferScreen> {
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _message;
  String _action = 'accept';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
        text: widget.request.clientBudget?.toStringAsFixed(0) ?? '');
    _duration =
        TextEditingController(text: widget.request.durationHours.toString());
    _message = TextEditingController(
        text: 'We can complete the service at the requested time.');
  }

  @override
  void dispose() {
    _price.dispose();
    _duration.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid offer price')));
      return;
    }
    if (_action == 'counter' &&
        widget.request.clientBudget != null &&
        price <= widget.request.clientBudget!) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Counter offer must be higher than the customer budget')));
      return;
    }
    setState(() => _saving = true);
    final result = await WorkerOfferService.createOffer(
      bookingRequestId: widget.request.id,
      priceAction: _action,
      offeredPrice: price,
      message: _message.text.trim(),
      estimatedDuration: int.tryParse(_duration.text.trim()),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Offer submitted')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Could not submit offer')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.request.clientBudget;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
          child: Column(children: [
        _top(context),
        Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
              Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE7F6EC),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer budget',
                            style: TextStyle(
                                color: Color(0xFF808080), fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(
                            budget == null
                                ? 'Not specified'
                                : '${budget.toStringAsFixed(0)} EGP',
                            style: const TextStyle(
                                color: Color(0xFF16A385),
                                fontSize: 22,
                                fontWeight: FontWeight.w600))
                      ])),
              const SizedBox(height: 28),
              const Text('Pricing',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                _choice('Accept budget', 'accept'),
                const SizedBox(width: 10),
                _choice('Counter offer', 'counter')
              ]),
              const SizedBox(height: 28),
              _fieldLabel('Offer price'),
              TextField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('EGP')),
              const SizedBox(height: 18),
              _fieldLabel('Estimated duration'),
              TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('hours')),
              const SizedBox(height: 18),
              _fieldLabel('Message'),
              TextField(
                  controller: _message,
                  maxLines: 2,
                  decoration: _decoration('Message')),
              const SizedBox(height: 18),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF5DB),
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(
                      _action == 'counter'
                          ? 'Counter prices must be higher than the customer budget.'
                          : 'Your offer will be sent to the customer for review.',
                      style: const TextStyle(fontSize: 12))),
              const SizedBox(height: 24),
              SizedBox(
                  height: 49,
                  child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Submit offer',
                              style: TextStyle(fontSize: 16)))),
            ])),
      ])),
    );
  }

  Widget _top(BuildContext context) => SizedBox(
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
            child: Text('Send Offer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))
      ]));

  Widget _choice(String label, String value) => Expanded(
      child: InkWell(
          onTap: () => setState(() => _action = value),
          child: Container(
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _action == value
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFE3E3E8))),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: _action == value
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                        value == 'accept'
                            ? '${widget.request.clientBudget?.toStringAsFixed(0) ?? ''} EGP'
                            : 'Set another price',
                        style: const TextStyle(
                            color: Color(0xFF808080), fontSize: 12))
                  ]))));

  Widget _fieldLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)));
  InputDecoration _decoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E3E8))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E3E8))));
}
