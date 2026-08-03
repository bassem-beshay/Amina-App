import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/onboarding_data.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';
import '../services/address_service.dart';
import '../services/profile_service.dart';
import '../services/provider_service.dart';
import '../services/service_service.dart';
import 'service_detail_screen.dart';
import 'client_extended_flow_screens.dart';

const _clientBg = Color(0xFFF7F7F7);
const _clientPrimary = Color(0xFF8B5CF6);
const _clientBorder = Color(0xFFE0E0E0);
const _clientMuted = Color(0xFF747474);

TextStyle _clientText({double size = 14, FontWeight weight = FontWeight.w400, Color color = const Color(0xFF1A1A1A)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

String _initial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class ClientFlowHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ClientFlowHeader({super.key, required this.title, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left, size: 28)),
          if (onBack == null) const SizedBox(width: 16),
          Expanded(child: Text(title, style: _clientText(size: 20, weight: FontWeight.w600))),
          if (trailing != null) trailing!,
          if (trailing == null) const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class ClientField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const ClientField({super.key, required this.controller, required this.label, this.keyboardType, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _clientText(size: 14, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: _clientText(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _clientBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _clientBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _clientPrimary)),
          ),
        ),
      ],
    );
  }
}

class ClientPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const ClientPrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _clientPrimary,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: _clientText(size: 18, weight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }
}

class ClientBottomNav extends StatelessWidget {
  final int selected;
  const ClientBottomNav({super.key, required this.selected});

  void _go(BuildContext context, int index) {
    if (index == selected) return;
    final widget = switch (index) {
      0 => const ClientHomeFlowScreen(),
      1 => const ClientCategoriesScreen(),
      2 => const ClientBookingsFlowScreen(),
      _ => const ClientMoreScreen(),
    };
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => widget));
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selected,
      onTap: (index) => _go(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _clientPrimary,
      unselectedItemColor: const Color(0xFF7D7F88),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class ClientProfileSetupScreen extends StatefulWidget {
  final OnboardingData data;
  const ClientProfileSetupScreen({super.key, required this.data});

  @override
  State<ClientProfileSetupScreen> createState() => _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  late final TextEditingController _first = TextEditingController(text: widget.data.fullName.split(' ').first);
  late final TextEditingController _last = TextEditingController(text: widget.data.fullName.split(' ').skip(1).join(' '));
  late final TextEditingController _phone = TextEditingController(text: widget.data.phoneNumber);
  final _city = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose(); _last.dispose(); _phone.dispose(); _city.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the required fields')));
      return;
    }
    setState(() => _saving = true);
    final response = await ProfileService.updateClientProfile(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phoneNumber: _phone.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      formattedAddress: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? 'Unable to save profile')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ClientAddressSetupScreen(initialCity: _city.text.trim(), initialNotes: _notes.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _clientBg,
      body: SafeArea(
        child: Column(
          children: [
            ClientFlowHeader(title: 'Complete your profile', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Text('Add your details to book services', style: _clientText(color: _clientMuted)),
                  const SizedBox(height: 28),
                  ClientField(controller: _first, label: 'First name'),
                  const SizedBox(height: 18),
                  ClientField(controller: _last, label: 'Last name'),
                  const SizedBox(height: 18),
                  ClientField(controller: _phone, label: 'Phone number', keyboardType: TextInputType.phone),
                  const SizedBox(height: 18),
                  ClientField(controller: _city, label: 'City'),
                  const SizedBox(height: 18),
                  ClientField(controller: _notes, label: 'Location notes', maxLines: 2),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: ClientPrimaryButton(label: _saving ? 'Saving…' : 'Continue', onPressed: _saving ? null : _continue)),
          ],
        ),
      ),
    );
  }
}

class ClientAddressSetupScreen extends StatefulWidget {
  final String initialCity;
  final String initialNotes;
  const ClientAddressSetupScreen({super.key, this.initialCity = '', this.initialNotes = ''});

  @override
  State<ClientAddressSetupScreen> createState() => _ClientAddressSetupScreenState();
}

class _ClientAddressSetupScreenState extends State<ClientAddressSetupScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final response = await AddressService.getAddresses();
    if (!mounted) return;
    setState(() { _loading = false; _addresses = response.data ?? []; _error = response.success ? null : response.error; });
  }

  Future<void> _addAddress() async {
    final label = TextEditingController();
    final address = TextEditingController(text: widget.initialNotes);
    final city = TextEditingController(text: widget.initialCity);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add address'),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
          TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (address.text.trim().isEmpty || city.text.trim().isEmpty) return;
            Navigator.pop(dialogContext, true);
            final position = await _safePosition();
            final response = await AddressService.addAddress(
              label: label.text.trim(), latitude: position.latitude, longitude: position.longitude,
              address: address.text.trim(), city: city.text.trim(), country: 'Egypt', isDefault: _addresses.isEmpty,
            );
            if (!mounted) return;
            if (!response.success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? 'Unable to add address')));
            await _load();
          }, child: const Text('Save')),
        ],
      ),
    );
    label.dispose();
    address.dispose();
    city.dispose();
  }

  Future<Position> _safePosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      }
    } catch (_) {}
    return Position(latitude: 30.0444, longitude: 31.2357, timestamp: DateTime.now(), accuracy: 1, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 1, headingAccuracy: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _clientBg,
      body: SafeArea(child: Column(children: [
        ClientFlowHeader(title: 'Saved Addresses', onBack: () => Navigator.of(context).maybePop(), trailing: TextButton(onPressed: _addAddress, child: const Text('+ Add address'))),
        Expanded(child: RefreshIndicator(onRefresh: _load, child: _loading
            ? const Center(child: CircularProgressIndicator(color: _clientPrimary))
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Text(_error!, textAlign: TextAlign.center))])
                : ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
                    Row(children: [Expanded(child: _tab('All ${_addresses.length}', true)), Expanded(child: _tab('Default ${_addresses.where((a) => a['is_default'] == true).length}', false)), Expanded(child: _tab('Other ${_addresses.where((a) => a['is_default'] != true).length}', false))]),
                    const SizedBox(height: 16),
                    if (_addresses.isEmpty) const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text('No saved addresses'))),
                    ..._addresses.map(_addressCard),
                  ]))),
        const ClientBottomNav(selected: 3),
      ])),
    );
  }

  Widget _tab(String text, bool selected) => Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: selected ? _clientPrimary : Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(text, textAlign: TextAlign.center, style: _clientText(size: 12, weight: FontWeight.w600, color: selected ? Colors.white : _clientMuted)));

  Widget _addressCard(Map<String, dynamic> address) {
    final isDefault = address['is_default'] == true;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDefault ? _clientPrimary : _clientBorder)), child: Row(children: [Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: _clientPrimary.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: Text((address['label'] ?? 'A').toString().characters.first.toUpperCase(), style: _clientText(size: 18, weight: FontWeight.w700, color: _clientPrimary))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((address['label'] ?? 'Address').toString(), style: _clientText(weight: FontWeight.w600)), const SizedBox(height: 4), Text('${address['address'] ?? ''}, ${address['city'] ?? ''}', style: _clientText(size: 13, color: _clientMuted)), const SizedBox(height: 6), Text(isDefault ? 'Default address' : 'Saved address', style: _clientText(size: 12, weight: FontWeight.w600, color: isDefault ? _clientPrimary : _clientMuted))])), TextButton(onPressed: () {}, child: const Text('Edit'))]));
  }
}

class ClientHomeFlowScreen extends StatefulWidget {
  const ClientHomeFlowScreen({super.key});
  @override State<ClientHomeFlowScreen> createState() => _ClientHomeFlowScreenState();
}

class _ClientHomeFlowScreenState extends State<ClientHomeFlowScreen> {
  bool _loading = true;
  String? _error;
  List<ServiceCategory> _categories = [];
  List<Service> _services = [];
  List<Provider> _providers = [];
  String _name = 'there';
  String _city = 'Choose location';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait<dynamic>([
        ServiceService.getCategories(),
        ServiceService.getServices(isFeatured: true),
        ProviderService.getTopRatedProviders(limit: 2),
        ProfileService.getClientProfile(),
      ]);
      final profile = values[3];
      if (!mounted) return;
      setState(() {
        _categories = values[0] as List<ServiceCategory>;
        _services = values[1] as List<Service>;
        _providers = values[2] as List<Provider>;
        if (profile.success && profile.data != null) {
          _name = profile.data.name.split(' ').first;
          _city = profile.data.city ?? profile.data.formattedAddress ?? _city;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unable to load your home'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _clientBg,
      body: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator(color: _clientPrimary)) : _error != null ? _errorView() : _content()),
      bottomNavigationBar: const ClientBottomNav(selected: 0),
    );
  }

  Widget _errorView() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), const SizedBox(height: 16), TextButton(onPressed: _load, child: const Text('Try again'))]));

  Widget _content() {
    final serviceWidgets = _services.take(1).map(_serviceCard).toList();
    final providerWidgets = _providers.map(_providerCard).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hello, $_name', style: _clientText(size: 20, weight: FontWeight.w600)), const SizedBox(height: 5), Text('$_city  ▾', style: _clientText(size: 13, color: _clientMuted))])), IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))]),
          const SizedBox(height: 18),
          Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _clientBorder)), child: Row(children: [const Icon(Icons.search, color: _clientMuted), const SizedBox(width: 8), Text('Search services, providers, or companies', style: _clientText(size: 13, color: _clientMuted))])),
          const SizedBox(height: 28),
          Text('Quick Services', style: _clientText(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          _quickServices(),
          const SizedBox(height: 22),
          Text('Services for you', style: _clientText(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...serviceWidgets,
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClientRequestTypeScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need something specific?', style: _clientText(weight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  Text('Publish a general request and compare offers', style: _clientText(size: 13, color: _clientMuted)),
                  const SizedBox(height: 12),
                  Text('Create general request  ›', style: _clientText(size: 13, weight: FontWeight.w600, color: _clientPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Top verified providers', style: _clientText(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...providerWidgets,
        ],
      ),
    );
  }

  Widget _serviceCard(Service service) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientServiceDetailsScreen(service: service))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFEDE9FE), child: Icon(Icons.cleaning_services, color: _clientPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(service.nameEn, style: _clientText(weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${service.category.nameEn} · Verified', style: _clientText(size: 12, color: _clientMuted)),
            const SizedBox(height: 5),
            Text('From ${service.basePrice.toStringAsFixed(0)} EGP · ★ ${service.averageRating.toStringAsFixed(1)}', style: _clientText(size: 12, weight: FontWeight.w600, color: _clientPrimary)),
          ])),
          const Icon(Icons.chevron_right, color: _clientPrimary),
        ]),
      ),
    );
  }

  Widget _quickServices() {
    return Row(
      children: _categories.take(4).map((category) {
        return Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCategoriesScreen())),
            child: Column(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: _clientPrimary.withOpacity(.12), shape: BoxShape.circle), child: const Icon(Icons.home_repair_service_outlined, color: _clientPrimary)),
              const SizedBox(height: 8),
              Text(category.nameEn, style: _clientText(size: 11, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _providerCard(Provider provider) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientProviderProfileScreen(providerId: provider.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)),
        child: Row(children: [
          CircleAvatar(backgroundColor: _clientPrimary.withOpacity(.12), child: Text(_initial(provider.fullName), style: _clientText(weight: FontWeight.w700, color: _clientPrimary))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(provider.fullName, style: _clientText(size: 13, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('★ ${(provider.averageRating ?? 0).toStringAsFixed(1)} · Provider', style: _clientText(size: 12, color: _clientMuted)),
          ])),
          const Icon(Icons.chevron_right, color: _clientPrimary),
        ]),
      ),
    );
  }
}

class ClientCategoriesScreen extends StatefulWidget {
  const ClientCategoriesScreen({super.key});
  @override State<ClientCategoriesScreen> createState() => _ClientCategoriesScreenState();
}

class _ClientCategoriesScreenState extends State<ClientCategoriesScreen> {
  List<ServiceCategory> _categories = [];
  List<Service> _services = [];
  bool _loading = true;
  int _tab = 0;
  String _query = '';

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final categories = await ServiceService.getCategories(); final services = await ServiceService.getServices(); if (mounted) setState(() { _categories = categories; _services = services; _loading = false; }); }

  @override Widget build(BuildContext context) {
    final content = _tab == 0
        ? _services.where((s) => s.nameEn.toLowerCase().contains(_query.toLowerCase())).map<Widget>(_serviceTile).toList()
        : <Widget>[
            GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientProvidersScreen())), child: _categoryTile('Verified Providers', 'Explore trusted independent providers', Icons.people_outline)),
            if (_tab == 2) GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCompaniesScreen())), child: _categoryTile('Verified Companies', 'Explore verified service companies', Icons.business_outlined)),
          ];
    return Scaffold(backgroundColor: _clientBg, body: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator(color: _clientPrimary)) : Column(children: [ClientFlowHeader(title: 'Service Categories', onBack: () => Navigator.pop(context)), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search services', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _clientBorder))))), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [_tabButton('Services', 0), _tabButton('Providers', 1), _tabButton('Companies', 2)])), Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: content))])), bottomNavigationBar: const ClientBottomNav(selected: 1));
  }

  Widget _tabButton(String text, int index) => Expanded(child: GestureDetector(onTap: () => setState(() => _tab = index), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _tab == index ? _clientPrimary : Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(text, textAlign: TextAlign.center, style: _clientText(size: 12, weight: FontWeight.w600, color: _tab == index ? Colors.white : _clientMuted)))));
  Widget _categoryTile(String title, String subtitle, IconData icon) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)), child: Row(children: [CircleAvatar(backgroundColor: _clientPrimary.withOpacity(.12), child: Icon(icon, color: _clientPrimary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _clientText(weight: FontWeight.w600)), const SizedBox(height: 5), Text(subtitle, style: _clientText(size: 12, color: _clientMuted))])), const Icon(Icons.chevron_right)]));
  Widget _serviceTile(Service s) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientServiceDetailsScreen(service: s))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFEDE9FE), child: Icon(Icons.home_repair_service_outlined, color: _clientPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.nameEn, style: _clientText(weight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: _clientText(size: 12, color: _clientMuted)),
            const SizedBox(height: 5),
            Text('From ${s.basePrice.toStringAsFixed(0)} EGP', style: _clientText(size: 12, weight: FontWeight.w600, color: _clientPrimary)),
          ])),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }
}

class ClientProvidersScreen extends StatefulWidget {
  const ClientProvidersScreen({super.key});
  @override State<ClientProvidersScreen> createState() => _ClientProvidersScreenState();
}

class _ClientProvidersScreenState extends State<ClientProvidersScreen> {
  List<Provider> _providers = [];
  bool _loading = true;
  String _query = '';

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final providers = await ProviderService.getProviders(); if (mounted) setState(() { _providers = providers; _loading = false; }); }

  @override
  Widget build(BuildContext context) {
    final providers = _providers.where((p) => p.fullName.toLowerCase().contains(_query.toLowerCase())).map(_providerTile).toList();
    return Scaffold(
      backgroundColor: _clientBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _clientPrimary))
            : Column(children: [
                ClientFlowHeader(title: 'Verified Providers', onBack: () => Navigator.pop(context)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search providers', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _clientBorder))))),
                Expanded(child: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: providers))),
              ]),
      ),
      bottomNavigationBar: const ClientBottomNav(selected: 1),
    );
  }

  Widget _providerTile(Provider p) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientProviderProfileScreen(providerId: p.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)),
        child: Row(children: [
          CircleAvatar(backgroundColor: _clientPrimary.withOpacity(.12), child: Text(_initial(p.fullName), style: _clientText(weight: FontWeight.w700, color: _clientPrimary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.fullName, style: _clientText(weight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('Independent provider', style: _clientText(size: 12, color: _clientMuted)),
            const SizedBox(height: 5),
            Text('★ ${(p.averageRating ?? 0).toStringAsFixed(1)} · ${p.totalRatings ?? 0} reviews', style: _clientText(size: 12, weight: FontWeight.w600, color: _clientPrimary)),
          ])),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }
}

class ClientProviderProfileScreen extends StatefulWidget {
  final int providerId;
  const ClientProviderProfileScreen({super.key, required this.providerId});
  @override State<ClientProviderProfileScreen> createState() => _ClientProviderProfileScreenState();
}

class _ClientProviderProfileScreenState extends State<ClientProviderProfileScreen> {
  Provider? _provider;
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final provider = await ProviderService.getProviderById(widget.providerId); if (mounted) setState(() { _provider = provider; _loading = false; _error = provider == null ? 'Provider not found' : null; }); }

  Future<void> _requestService() async {
    final services = await ServiceService.getServices(isFeatured: true);
    if (!mounted || services.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ClientServiceDetailsScreen(service: services.first)));
  }

  @override Widget build(BuildContext context) => Scaffold(backgroundColor: _clientBg, body: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator(color: _clientPrimary)) : _error != null ? Center(child: Text(_error!)) : _content()), bottomNavigationBar: const ClientBottomNav(selected: 1));

  Widget _content() {
    final p = _provider!;
    return Column(
      children: [
        ClientFlowHeader(title: p.fullName, onBack: () => Navigator.pop(context)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)),
                child: Column(children: [
                  Row(children: [
                    CircleAvatar(radius: 28, backgroundColor: _clientPrimary.withOpacity(.12), child: Text(_initial(p.fullName), style: _clientText(size: 20, weight: FontWeight.w700, color: _clientPrimary))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Verified independent provider', style: _clientText(size: 13, color: _clientMuted)),
                      const SizedBox(height: 8),
                      Text('★ ${(p.averageRating ?? 0).toStringAsFixed(1)} · ${p.totalRatings ?? 0} reviews', style: _clientText(size: 13, weight: FontWeight.w600, color: _clientPrimary)),
                    ])),
                  ]),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Completed services', style: _clientText(size: 13, color: _clientMuted)), Text('${p.totalRatings ?? 0}', style: _clientText(size: 14, weight: FontWeight.w600))]),
                ]),
              ),
              const SizedBox(height: 14),
              _review('Professional, punctual, and highly recommended.', '2 days ago', '5.0'),
              _review('Great cleaning quality and communication.', '1 week ago', '4.0'),
              _review('Reliable provider and fair pricing.', '2 weeks ago', '5.0'),
              const SizedBox(height: 20),
              ClientPrimaryButton(label: 'Request service', onPressed: _requestService),
            ],
          ),
        ),
      ],
    );
  }
  Widget _review(String text, String time, String rating) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _clientBorder)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Client review', style: _clientText(size: 13, weight: FontWeight.w600)), Text('★ $rating', style: _clientText(size: 12, weight: FontWeight.w600, color: _clientPrimary))]), const SizedBox(height: 8), Text(text, style: _clientText(size: 13)), const SizedBox(height: 8), Text(time, style: _clientText(size: 11, color: _clientMuted))]));
}
