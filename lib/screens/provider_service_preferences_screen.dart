import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import '../services/profile_service.dart';
import '../widgets/connectivity_button.dart';

class ProviderServicePreferencesScreen extends StatefulWidget {
  const ProviderServicePreferencesScreen({super.key});

  @override
  State<ProviderServicePreferencesScreen> createState() =>
      _ProviderServicePreferencesScreenState();
}

class _ProviderServicePreferencesScreenState
    extends State<ProviderServicePreferencesScreen> {
  List<ServiceCategory> _categories = [];
  Set<int> _selectedCategories = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load categories
      final categories = await ServiceService.getCategories();

      // Load current user's preferences
      final profileResponse = await ProfileService.getProviderProfile();
      final List<int> currentPreferences =
          profileResponse.data?.preferredServiceCategories ?? [];

      setState(() {
        _categories = categories;
        _selectedCategories = Set<int>.from(currentPreferences);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await ProfileService.updateProviderProfile(
        preferredServiceCategories: _selectedCategories.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ تفضيلات الخدمات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ التفضيلات: \u200F$e\u200F'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.servicePreferences ?? 'تفضيلات الخدمات',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: const Color(0xFF4A148C),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'حفظ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد فئات خدمات متاحة',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFF5F5F5),
                      child: Text(
                        'اختر فئات الخدمات التي تقدمها\n'
                        'سيتم عرض طلبات الحجز المتعلقة بهذه الفئات لك',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              _selectedCategories.contains(category.id);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            elevation: isSelected ? 4 : 1,
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCategories.add(category.id);
                                  } else {
                                    _selectedCategories.remove(category.id);
                                  }
                                });
                              },
                              title: Text(
                                category.name,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: category.description != null &&
                                      category.description!.isNotEmpty
                                  ? Text(
                                      category.description!,
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 13,
                                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                      ),
                                    )
                                  : null,
                              secondary: category.icon != null
                                  ? CircleAvatar(
                                      backgroundColor: isSelected
                                          ? const Color(0xFF4A148C)
                                          : const Color(0xFFE0E0E0),
                                      child: Icon(
                                        Icons.cleaning_services,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF666666),
                                      ),
                                    )
                                  : null,
                              activeColor: const Color(0xFF4A148C),
                              selected: isSelected,
                              selectedTileColor:
                                  const Color(0xFF4A148C).withOpacity( 0.05),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity( 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'تم اختيار ${_selectedCategories.length} فئة',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                          ),
                          ConnectivityIconButton(
                            onPressed: _isSaving ? null : _savePreferences,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: const Text(
                              'حفظ التفضيلات',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A148C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
