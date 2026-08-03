import 'package:flutter/material.dart';

import '../models/worker_offer_model.dart';
import '../services/worker_offer_service.dart';

class ProviderOfferEditScreen extends StatefulWidget {
  const ProviderOfferEditScreen({super.key, required this.offer});

  final WorkerOffer offer;

  @override
  State<ProviderOfferEditScreen> createState() =>
      _ProviderOfferEditScreenState();
}

class _ProviderOfferEditScreenState extends State<ProviderOfferEditScreen> {
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _message;
  late String _action;
  bool _saving = false;

  bool get _readOnly => widget.offer.status.toLowerCase() != 'pending';

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
        text: widget.offer.offeredPrice.toStringAsFixed(0));
    _duration = TextEditingController(
        text: widget.offer.estimatedDuration?.toString() ?? '');
    _message = TextEditingController(text: widget.offer.message ?? '');
    _action = widget.offer.priceAction;
  }

  @override
  void dispose() {
    _price.dispose();
    _duration.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid offer price')));
      return;
    }
    setState(() => _saving = true);
    final result = await WorkerOfferService.updateOffer(
      offerId: widget.offer.id,
      priceAction: _action,
      offeredPrice: price,
      message: _message.text.trim(),
      estimatedDuration: int.tryParse(_duration.text.trim()),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'Offer updated'
            : (result.error ?? 'Could not update offer'))));
    if (result.success) Navigator.of(context).pop(true);
  }

  Future<void> _withdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this offer?'),
        content: const Text(
            'The offer will become withdrawn and can no longer be accepted by the customer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep offer')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Withdraw offer')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    final result = await WorkerOfferService.withdrawOffer(widget.offer.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Offer withdrawn')));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Could not withdraw offer')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.offer.status.toLowerCase();
    final title = _readOnly ? 'Offer Details' : 'Edit Offer';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _budget(status),
                  const SizedBox(height: 28),
                  const Text('Pricing',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _choice('Accept budget', 'accept'),
                    const SizedBox(width: 10),
                    _choice('Counter offer', 'counter')
                  ]),
                  const SizedBox(height: 24),
                  _label('Offer price'),
                  TextField(
                      controller: _price,
                      readOnly: _readOnly,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _decoration('EGP')),
                  const SizedBox(height: 16),
                  _label('Estimated duration'),
                  TextField(
                      controller: _duration,
                      readOnly: _readOnly,
                      keyboardType: TextInputType.number,
                      decoration: _decoration('hours')),
                  const SizedBox(height: 16),
                  _label('Message'),
                  TextField(
                      controller: _message,
                      readOnly: _readOnly,
                      maxLines: 2,
                      decoration: _decoration('Message')),
                  const SizedBox(height: 18),
                  if (_readOnly)
                    _statusBanner(status)
                  else ...[
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF5DB),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Text(
                            'Counter prices must be higher than the customer budget.',
                            style: TextStyle(fontSize: 12))),
                    const SizedBox(height: 22),
                    SizedBox(
                        height: 49,
                        child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: _buttonStyle(),
                            child: _saving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Save changes'))),
                    const SizedBox(height: 14),
                    TextButton(
                        onPressed: _saving ? null : _withdraw,
                        child: const Text('Withdraw offer',
                            style: TextStyle(
                                color: Color(0xFFDB2626),
                                fontWeight: FontWeight.w600))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) => SizedBox(
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))
      ]));

  Widget _budget(String status) => Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
          color: const Color(0xFFE7F6EC),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Offer',
              style: TextStyle(color: Color(0xFF808080), fontSize: 12)),
          SizedBox(height: 5)
        ]),
        Text('${widget.offer.offeredPrice.toStringAsFixed(0)} EGP',
            style: const TextStyle(
                color: Color(0xFF16A385),
                fontSize: 22,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: Text(_statusLabel(status),
                style: const TextStyle(
                    color: Color(0xFF16A385),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)))
      ]));

  Widget _choice(String label, String value) => Expanded(
      child: GestureDetector(
          onTap: _readOnly ? null : () => setState(() => _action = value),
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
                            ? 'Customer budget'
                            : 'Set another price',
                        style: const TextStyle(
                            color: Color(0xFF808080), fontSize: 12))
                  ]))));
  Widget _statusBanner(String status) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: status == 'rejected'
              ? const Color(0xFFFEF2F2)
              : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(14)),
      child: Text(
          'This offer is ${_statusLabel(status).toLowerCase()} and cannot be edited.',
          style: const TextStyle(fontSize: 12)));
  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
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
  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));
  String _statusLabel(String status) => switch (status) {
        'accepted' => 'Accepted',
        'rejected' => 'Rejected',
        'withdrawn' => 'Withdrawn',
        'pending' => 'Pending',
        _ => status
      };
}
