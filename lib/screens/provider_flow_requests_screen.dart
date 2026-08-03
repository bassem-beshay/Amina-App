import 'package:flutter/material.dart';

import '../models/booking_request_model.dart';
import '../services/booking_service.dart';
import 'provider_request_details_screen.dart';

/// P11/C13 shared request inbox. The provider and company permissions are
/// enforced by the backend; this screen only renders the authenticated list.
class ProviderAvailableRequestsScreen extends StatefulWidget {
  const ProviderAvailableRequestsScreen({
    super.key,
    this.company = false,
    this.requestsFuture,
  });

  final bool company;
  final Future<List<BookingRequest>>? requestsFuture;

  @override
  State<ProviderAvailableRequestsScreen> createState() =>
      _ProviderAvailableRequestsScreenState();
}

class _ProviderAvailableRequestsScreenState
    extends State<ProviderAvailableRequestsScreen> {
  final _searchController = TextEditingController();
  late Future<List<BookingRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests =
        widget.requestsFuture ?? BookingService.getBookings(status: 'PENDING');
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _requests = BookingService.getBookings(status: 'PENDING'));
    await _requests;
  }

  List<BookingRequest> _filtered(List<BookingRequest> source) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((request) {
      final text = [
        request.serviceTitle,
        request.serviceTitleEn,
        request.customServiceTitle,
        request.categoryName,
        request.categoryNameEn,
        request.city,
      ].whereType<String>().join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search requests',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF808080)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3E3E8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3E3E8)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _FilterRow(),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<BookingRequest>>(
                future: _requests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _StateMessage(
                      title: 'Could not load requests',
                      action: _refresh,
                    );
                  }
                  final items = _filtered(snapshot.data ?? const []);
                  if (items.isEmpty) {
                    return _StateMessage(
                      title: 'No available requests',
                      action: _refresh,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) => _RequestCard(
                        request: items[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProviderRequestDetailsScreen(
                                requestId: items[index].id),
                          ),
                        ),
                      ),
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

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 94,
      child: Stack(
        children: [
          const Positioned(
            left: 24,
            top: 18,
            child: Text('9:41',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 61,
            child: Text(
              widget.company ? 'Customer Requests' : 'Available Requests',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            left: 12,
            top: 48,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: const [
          _FilterChip(label: 'All', selected: true, width: 54),
          SizedBox(width: 10),
          _FilterChip(label: 'Preferred', selected: true, width: 100),
          SizedBox(width: 10),
          _FilterChip(label: 'Other categories', green: true, width: 106),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.width,
      this.selected = false,
      this.green = false});

  final String label;
  final double width;
  final bool selected;
  final bool green;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: green || selected
            ? (green ? const Color(0xFFE7F6EC) : const Color(0xFFEDE8FE))
            : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: green ? const Color(0xFF16A385) : const Color(0xFF8B5CF6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final BookingRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final client = request.clientInfo?.fullName.trim();
    final initials = client == null || client.isEmpty
        ? 'AM'
        : client
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.isEmpty ? '' : part[0])
            .join()
            .toUpperCase();
    final title = request.getLocalizedServiceTitle('en').isEmpty
        ? 'Service request'
        : request.getLocalizedServiceTitle('en');
    final date =
        '${_weekday(request.bookingDate.weekday)}, ${request.bookingDate.day} ${_month(request.bookingDate.month)} · ${request.bookingTime}';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 148,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: const Color(0xFF8B5CF6),
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            client?.isNotEmpty == true ? client! : 'Client',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE7F6EC),
                          borderRadius: BorderRadius.circular(13)),
                      child: const Text('Open',
                          style: TextStyle(
                              color: Color(0xFF16A385),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                        child: Text(date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF808080), fontSize: 12))),
                    if (request.clientBudget != null)
                      Text('${request.clientBudget!.toStringAsFixed(0)} EGP',
                          style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                const Align(
                    alignment: Alignment.centerRight,
                    child: Text('View request  ›',
                        style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weekday(int value) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value - 1];
  String _month(int value) => const [
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
      ][value - 1];
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.title, required this.action});

  final String title;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    );
  }
}
