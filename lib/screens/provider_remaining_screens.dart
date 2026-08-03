import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking_model.dart' show BookingNotification, Complaint;
import '../models/rating_model.dart' as rating_model;
import '../models/user_model.dart';
import '../providers/language_provider.dart';
import '../services/address_service.dart';
import '../services/profile_service.dart';
import '../services/rating_service.dart';
import 'provider_feedback_screens.dart';

class ProviderRatingsReviewsScreen extends StatefulWidget {
  const ProviderRatingsReviewsScreen({super.key, this.ratingsFuture});
  final Future<List<rating_model.Rating>>? ratingsFuture;
  @override
  State<ProviderRatingsReviewsScreen> createState() => _RatingsState();
}

class _RatingsState extends State<ProviderRatingsReviewsScreen> {
  late Future<List<rating_model.Rating>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.ratingsFuture ?? _load();
  }

  Future<List<rating_model.Rating>> _load() async {
    final me = await ProfileService.getCurrentUser();
    final id = me.data?.id;
    if (id == null) return const [];
    return (await RatingService.getProviderRatings(id)).data ?? const [];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            title: const Text('Ratings & Reviews'),
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true),
        body: FutureBuilder<List<rating_model.Rating>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final ratings = snap.data ?? const <rating_model.Rating>[];
            final average = ratings.isEmpty
                ? 0.0
                : ratings.map((r) => r.rating).reduce((a, b) => a + b) /
                    ratings.length;
            final children = <Widget>[
              _panel(Column(children: [
                Text(average.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w600)),
                const Text('★★★★★',
                    style: TextStyle(fontSize: 23, color: _orange)),
                Text('${ratings.length} ratings received',
                    style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('Trusted independent provider',
                    style: TextStyle(color: _teal, fontSize: 13)),
              ])),
              const SizedBox(height: 18),
            ];
            if (ratings.isEmpty) {
              children.add(const Center(child: Text('No ratings yet')));
            } else {
              children.addAll(ratings.map(_ratingCard));
            }
            return ListView(
                padding: const EdgeInsets.all(20), children: children);
          },
        ),
      );
  Widget _ratingCard(rating_model.Rating r) =>
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(r.ratedByName ?? 'Customer',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('★ ${r.rating}.0', style: const TextStyle(color: _orange))
        ]),
        const SizedBox(height: 8),
        Text(r.comment ?? 'No comment'),
        const SizedBox(height: 8),
        Text(_date(r.createdAt),
            style: const TextStyle(color: _muted, fontSize: 11))
      ]));
}

class ProviderComplaintDetailsScreen extends StatelessWidget {
  const ProviderComplaintDetailsScreen({super.key, required this.complaint});
  final Complaint complaint;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            title: const Text('Complaint Details'),
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_status(complaint.status),
                        style: const TextStyle(
                            color: Color(0xFFD97505),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text('Complaint #CMP-${complaint.id}',
                        style: const TextStyle(color: _muted, fontSize: 12))
                  ])),
          const SizedBox(height: 18),
          _panel(
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(complaint.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('Description',
                style: TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(complaint.description),
            if (complaint.resolution?.isNotEmpty == true) ...[
              const Divider(height: 28),
              const Text('Resolution',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(complaint.resolution!)
            ]
          ])),
        ]),
      );
}

class ProviderNotificationsAllReadScreen extends StatelessWidget {
  const ProviderNotificationsAllReadScreen(
      {super.key, this.notificationsFuture});
  final Future<List<BookingNotification>>? notificationsFuture;
  @override
  Widget build(BuildContext context) =>
      ProviderNotificationsScreen(notificationsFuture: notificationsFuture);
}

class ProviderProfileMoreScreen extends StatefulWidget {
  const ProviderProfileMoreScreen({super.key, this.userFuture});
  final Future<User?>? userFuture;
  @override
  State<ProviderProfileMoreScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProviderProfileMoreScreen> {
  late Future<User?> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.userFuture ?? _load();
  }

  Future<User?> _load() async => (await ProfileService.getCurrentUser()).data;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            title: const Text('Provider Profile'),
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true),
        body: FutureBuilder<User?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              final user = snap.data;
              return ListView(padding: const EdgeInsets.all(20), children: [
                _panel(Row(children: [
                  const CircleAvatar(
                      radius: 36,
                      backgroundColor: _purple,
                      child: Text('K',
                          style: TextStyle(color: Colors.white, fontSize: 26))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(user?.fullName ?? 'Karim Hassan',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Chip(
                            label: Text(
                                user?.providerProfile?.isVerified == true
                                    ? 'Verified'
                                    : 'Pending verification')),
                      ])),
                ])),
                const SizedBox(height: 18),
                _item(
                    context,
                    'Edit profile',
                    Icons.edit,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProviderEditProfileScreen(user: user)))),
                _item(
                    context,
                    'Saved addresses',
                    Icons.location_on_outlined,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ProviderSavedAddressesScreen()))),
                _item(
                    context,
                    'Ratings & Reviews',
                    Icons.star_border,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ProviderRatingsReviewsScreen()))),
                _item(
                    context,
                    'Language',
                    Icons.language,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ProviderLanguageSettingsScreen()))),
              ]);
            }),
      );
  Widget _item(BuildContext context, String title, IconData icon,
          VoidCallback onTap) =>
      Card(
          elevation: 0,
          child: ListTile(
              leading: Icon(icon, color: _purple),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              onTap: onTap));
}

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key, this.user});
  final User? user;
  @override
  State<ProviderEditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends State<ProviderEditProfileScreen> {
  late final TextEditingController _first, _last, _phone, _bio;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _first = TextEditingController(text: u?.firstName);
    _last = TextEditingController(text: u?.lastName);
    _phone = TextEditingController(text: u?.phoneNumber);
    _bio = TextEditingController(text: u?.providerProfile?.bio);
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final result = await ProfileService.updateProviderProfile(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        phoneNumber: _phone.text.trim(),
        bio: _bio.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success)
      Navigator.pop(context, true);
    else
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Profile update failed')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
          title: const Text('Edit Provider Profile'),
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Update the information customers can see',
            textAlign: TextAlign.center, style: TextStyle(color: _muted)),
        const SizedBox(height: 24),
        _field('First name', _first),
        _field('Last name', _last),
        _field('Phone number', _phone),
        _field('Bio', _bio, lines: 4),
        const SizedBox(height: 20),
        SizedBox(
            height: 49,
            child: ElevatedButton(
                onPressed: _busy ? null : _save,
                style: _button,
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save changes')))
      ]));
  Widget _field(String label, TextEditingController controller,
          {int lines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 7),
            TextField(
                controller: controller,
                maxLines: lines,
                decoration: _decoration(label))
          ]));
}

class ProviderSavedAddressesScreen extends StatefulWidget {
  const ProviderSavedAddressesScreen({super.key, this.addressesFuture});
  final Future<List<Map<String, dynamic>>>? addressesFuture;
  @override
  State<ProviderSavedAddressesScreen> createState() => _AddressesState();
}

class _AddressesState extends State<ProviderSavedAddressesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.addressesFuture ?? _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      (await AddressService.getProviderAddresses()).data ?? const [];
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            title: const Text('Saved Addresses'),
            backgroundColor: _bg,
            elevation: 0,
            actions: [
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ProviderAddEditAddressScreen())),
                  child: const Text('+ Add address'))
            ]),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final list = snap.data ?? const <Map<String, dynamic>>[];
            if (list.isEmpty)
              return const Center(child: Text('No saved addresses'));
            final cards = list
                .map<Widget>((a) => Card(
                      elevation: 0,
                      child: ListTile(
                        title: Text('${a['label'] ?? 'Address'}'),
                        subtitle:
                            Text('${a['address'] ?? ''}, ${a['city'] ?? ''}'),
                        trailing: a['is_default'] == true
                            ? const Chip(label: Text('Default'))
                            : null,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProviderAddEditAddressScreen(address: a))),
                      ),
                    ))
                .toList();
            return ListView(padding: const EdgeInsets.all(20), children: cards);
          },
        ),
      );
}

class ProviderAddEditAddressScreen extends StatefulWidget {
  const ProviderAddEditAddressScreen({super.key, this.address});
  final Map<String, dynamic>? address;
  @override
  State<ProviderAddEditAddressScreen> createState() => _AddressEditState();
}

class _AddressEditState extends State<ProviderAddEditAddressScreen> {
  late final TextEditingController _label, _address, _city;
  bool _default = false, _busy = false;
  @override
  void initState() {
    super.initState();
    final a = widget.address ?? {};
    _label = TextEditingController(text: a['label']?.toString() ?? 'Home');
    _address = TextEditingController(text: a['address']?.toString() ?? '');
    _city = TextEditingController(text: a['city']?.toString() ?? 'Nasr City');
    _default = a['is_default'] == true;
  }

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_address.text.trim().isEmpty || _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address and city are required')));
      return;
    }
    setState(() => _busy = true);
    final id = widget.address?['id'];
    final result = id == null
        ? await AddressService.addProviderAddress(
            label: _label.text.trim(),
            latitude: 30.06,
            longitude: 31.33,
            address: _address.text.trim(),
            city: _city.text.trim(),
            isDefault: _default)
        : await AddressService.updateProviderAddress(
            addressId: id as int,
            label: _label.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            isDefault: _default);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            title: const Text('Provider Address'),
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
              height: 150,
              decoration: BoxDecoration(
                  color: const Color(0xFFEBF0F0),
                  borderRadius: BorderRadius.circular(16)),
              child: const Center(
                  child: Text('CAIRO · NASR CITY',
                      style: TextStyle(
                          color: _teal, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 22),
          _addressField('Address label', _label),
          _addressField('Address', _address),
          _addressField('City', _city),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default'),
              value: _default,
              onChanged: (value) => setState(() => _default = value)),
          const SizedBox(height: 16),
          SizedBox(
              height: 49,
              child: ElevatedButton(
                  onPressed: _busy ? null : _save,
                  style: _button,
                  child: _busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save address'))),
        ]),
      );
  Widget _addressField(String hint, TextEditingController controller) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child:
              TextField(controller: controller, decoration: _decoration(hint)));
}

class ProviderLanguageSettingsScreen extends StatelessWidget {
  const ProviderLanguageSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    late final LanguageProvider language;
    try {
      language = Provider.of<LanguageProvider>(context, listen: false);
    } catch (_) {
      language = LanguageProvider();
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
          title: const Text('Language'),
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(
            elevation: 0,
            child: ListTile(
                title: const Text('English'),
                subtitle: const Text('English interface'),
                trailing: language.isEnglish
                    ? const Icon(Icons.check, color: _purple)
                    : null)),
        Card(
          elevation: 0,
          child: ListTile(
            title: const Text('Arabic'),
            subtitle: const Text('Arabic interface'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Arabic interface is not enabled yet')),
            ),
          ),
        ),
      ]),
    );
  }
}

const _bg = Color(0xFFF7F7F7),
    _muted = Color(0xFF808080),
    _purple = Color(0xFF8B5CF6),
    _teal = Color(0xFF16A385),
    _orange = Color(0xFFF29E1F);
final _button = ElevatedButton.styleFrom(
    backgroundColor: _purple,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));
Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: child);
InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3E3E8))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3E3E8))));
String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
String _status(String value) => switch (value.toUpperCase()) {
      'PENDING' || 'UNDER_REVIEW' => 'Under review',
      'RESOLVED' => 'Resolved',
      _ => value
    };
