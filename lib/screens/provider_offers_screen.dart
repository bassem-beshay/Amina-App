import 'package:flutter/material.dart';

import '../models/worker_offer_model.dart';
import '../services/worker_offer_service.dart';
import 'provider_offer_edit_screen.dart';

class ProviderOffersScreen extends StatefulWidget {
  const ProviderOffersScreen({super.key, this.company = false});

  final bool company;

  @override
  State<ProviderOffersScreen> createState() => _ProviderOffersScreenState();
}

class _ProviderOffersScreenState extends State<ProviderOffersScreen> {
  late Future<List<WorkerOffer>> _offers;

  @override
  void initState() {
    super.initState();
    _offers = WorkerOfferService.getOffers();
  }

  Future<void> _refresh() async {
    setState(() => _offers = WorkerOfferService.getOffers());
    await _offers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<List<WorkerOffer>>(
                future: _offers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final offers = snapshot.data ?? const <WorkerOffer>[];
                  if (offers.isEmpty) {
                    return _empty(_refresh);
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: offers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) =>
                          _offerCard(context, offers[index]),
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
              child: Text(widget.company ? 'Company Offers' : 'My Offers',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _empty(Future<void> Function() retry) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('No offers yet'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: retry, child: const Text('Try again'))
      ]));

  Widget _offerCard(BuildContext context, WorkerOffer offer) {
    final status = offer.status.toLowerCase();
    final color = status == 'accepted'
        ? const Color(0xFF16A385)
        : status == 'pending'
            ? const Color(0xFFF29E1F)
            : status == 'rejected'
                ? const Color(0xFFDB2626)
                : const Color(0xFF808080);
    final background = status == 'accepted'
        ? const Color(0xFFE7F6EC)
        : status == 'pending'
            ? const Color(0xFFFFF5DB)
            : status == 'rejected'
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF7F7F7);
    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(
              builder: (_) => ProviderOfferEditScreen(offer: offer)))
          .then((_) => _refresh()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 104,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Request #${offer.bookingRequestId}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: background, borderRadius: BorderRadius.circular(13)),
                child: Text(_label(status),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)))
          ]),
          const Spacer(),
          Row(children: [
            Text('${offer.offeredPrice.toStringAsFixed(0)} EGP',
                style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(status == 'pending' ? 'Edit offer' : 'View details',
                style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600))
          ]),
        ]),
      ),
    );
  }

  String _label(String status) => switch (status) {
        'pending' => 'Pending',
        'accepted' => 'Accepted',
        'rejected' => 'Rejected',
        'withdrawn' => 'Withdrawn',
        _ => status
      };
}
