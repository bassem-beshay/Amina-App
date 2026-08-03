import 'package:flutter/material.dart';

import 'provider_flow_requests_screen.dart';
import 'provider_flow_placeholder.dart';
import 'provider_offers_screen.dart';
import 'provider_bookings_screen.dart';
import 'provider_communication_screens.dart';
import 'provider_feedback_screens.dart';

/// Shared shell for the Figma provider/company operational flows.
///
/// The legacy provider screen remains available while the new flow is rolled
/// out.  This shell intentionally owns only navigation and the verified home
/// surface (P10/C10); each destination is added as a real screen in the next
/// implementation task rather than silently mixing the old flow into it.
class ProviderFlowHomeScreen extends StatelessWidget {
  const ProviderFlowHomeScreen({
    super.key,
    this.company = false,
    this.usePlaceholderDestinations = false,
  });

  final bool company;
  final bool usePlaceholderDestinations;

  @override
  Widget build(BuildContext context) {
    return _ProviderFlowScaffold(
      company: company,
      title: company ? 'Amina Home Services' : 'Karim Hassan',
      subtitle: company ? 'Verified company' : 'Verified provider',
      usePlaceholderDestinations: usePlaceholderDestinations,
    );
  }
}

class _ProviderFlowScaffold extends StatelessWidget {
  const _ProviderFlowScaffold({
    required this.company,
    required this.title,
    required this.subtitle,
    required this.usePlaceholderDestinations,
  });

  final bool company;
  final String title;
  final String subtitle;
  final bool usePlaceholderDestinations;

  static const _purple = Color(0xFF8B5CF6);
  static const _background = Color(0xFFF7F7F7);
  static const _muted = Color(0xFF808080);

  void _open(BuildContext context, String title) {
    if (!usePlaceholderDestinations &&
        (title == 'Available requests' || title == 'Customer requests')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProviderAvailableRequestsScreen(company: company),
        ),
      );
      return;
    }
    if (!usePlaceholderDestinations && title == 'My offers') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProviderOffersScreen(company: company),
        ),
      );
      return;
    }
    if (!usePlaceholderDestinations && title == 'Bookings') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProviderBookingsScreen(company: company),
        ),
      );
      return;
    }
    if (!usePlaceholderDestinations && title == 'Chats') {
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ProviderConversationsScreen()));
      return;
    }
    if (!usePlaceholderDestinations && title == 'Notifications') {
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ProviderNotificationsScreen()));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderFlowPlaceholderScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Container(
                      height: 212,
                      width: double.infinity,
                      color: _purple,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '9:41',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 27),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Hello, $title',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Text(
                                '○',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFFE7F6EC),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: _statCard('12', 'New requests')),
                            const SizedBox(width: 11),
                            Expanded(child: _statCard('5', 'Active bookings')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 58),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Quick actions',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 9,
                        runSpacing: 16,
                        children: [
                          _actionCard(
                            context,
                            company ? 'Add service' : 'Edit profile',
                            company ? 'A' : 'P',
                            () => _open(
                              context,
                              company
                                  ? 'Create company service'
                                  : 'Edit provider profile',
                            ),
                          ),
                          _actionCard(
                            context,
                            'View requests',
                            'V',
                            () => _open(context, 'Available requests'),
                          ),
                          _actionCard(
                            context,
                            company ? 'Company offers' : 'My offers',
                            'M',
                            () => _open(context, 'My offers'),
                          ),
                          _actionCard(
                            context,
                            'Notifications',
                            'N',
                            () => _open(context, 'Notifications'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Recent activity',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offer accepted',
                            style: TextStyle(
                              color: Color(0xFF16A385),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Home Cleaning · Ahmed Abbas',
                            style: TextStyle(
                                color: Color(0xFF1A1A1A), fontSize: 13),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Booking starts tomorrow at 10:00 AM',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: _purple, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionCard(
      BuildContext context, String label, String icon, VoidCallback onTap) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 49) / 2,
      height: 68,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon,
                      style: const TextStyle(
                          color: _purple,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    final labels = ['Home', 'Chats', 'Bookings', 'More'];
    final icons = [
      Icons.home_outlined,
      Icons.chat_bubble_outline,
      Icons.calendar_today_outlined,
      Icons.more_horiz
    ];
    return Container(
      height: 72,
      color: Colors.white,
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: InkWell(
              onTap: index == 0 ? null : () => _open(context, labels[index]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[index],
                      color: index == 0 ? _purple : _muted, size: 20),
                  const SizedBox(height: 5),
                  Text(labels[index],
                      style: TextStyle(
                          color: index == 0 ? _purple : _muted,
                          fontSize: 12,
                          fontWeight:
                              index == 0 ? FontWeight.w600 : FontWeight.w500)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
