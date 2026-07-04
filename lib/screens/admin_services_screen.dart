import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/service_model.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';
import '../widgets/duration_dropdown.dart';

class AdminServicesScreen extends StatefulWidget {
  final String token;
  const AdminServicesScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminServicesScreenState createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<Service> _services = [];
  List<ServiceCategory> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      // Load categories first
      final categoriesResponse =
          await ApiClient.get(ApiConfig.adminCategories, needsAuth: true);

      if (categoriesResponse.success && categoriesResponse.rawResponse != null) {
        final categoriesData = categoriesResponse.rawResponse['data'] as List;
        _categories = categoriesData
            .map((cat) => ServiceCategory.fromJson(cat as Map<String, dynamic>))
            .toList();
      }

      // Load services
      String servicesUrl = ApiConfig.adminServices;
      if (_selectedCategoryFilter != null) {
        servicesUrl += '?category=$_selectedCategoryFilter';
      }

      final servicesResponse =
          await ApiClient.get(servicesUrl, needsAuth: true);

      if (servicesResponse.success && servicesResponse.rawResponse != null) {
        final data = servicesResponse.rawResponse;
        final servicesData = data['data'] as List;

        setState(() {
          _services = servicesData
              .map((svc) => Service.fromJson(svc as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });

      } else {
        throw Exception(servicesResponse.error ?? 'Failed to load services');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.translate('manageServices') ?? 'إدارة الخدمات',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_categories.isNotEmpty)
            PopupMenuButton<int?>(
              icon: Icon(
                _selectedCategoryFilter == null
                    ? Icons.filter_list
                    : Icons.filter_list_alt,
                color: Theme.of(context).colorScheme.surface,
              ),
              onSelected: (categoryId) {
                setState(() {
                  _selectedCategoryFilter = categoryId;
                });
                _loadData();
              },
              itemBuilder: (context) => [
                const PopupMenuItem<int?>(
                  value: null,
                  child: Text('كل الفئات'),
                ),
                ..._categories.map((category) => PopupMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name),
                    )),
              ],
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ConnectivityIconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_repair_service_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedCategoryFilter == null
                                    ? 'لا توجد خدمات'
                                    : 'لا توجد خدمات في هذه الفئة',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ابدأ بإضافة خدمة جديدة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return _buildServiceCard(service);
                          },
                        ),
                ),
      floatingActionButton: _categories.isEmpty
          ? null
          : ConnectivityFloatingActionButton(
              onPressed: () => _showAddServiceDialog(),
              backgroundColor: const Color(0xFF10B981),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Service Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: service.isActive
                        ? const Color(0xFF10B981).withOpacity( 0.1)
                        : Colors.grey.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.home_repair_service,
                    color: service.isActive
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                // Service Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Featured Badge
                          if (service.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity( 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'مميزة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Active Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: service.isActive
                                  ? Colors.green.withOpacity( 0.1)
                                  : Colors.grey.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              service.isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: service.isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.category.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditServiceDialog(service);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(service);
                    } else if (value == 'toggle') {
                      _toggleServiceStatus(service);
                    } else if (value == 'feature') {
                      _toggleFeaturedStatus(service);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            service.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(service.isActive ? 'تعطيل' : 'تفعيل'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'feature',
                      child: Row(
                        children: [
                          Icon(
                            service.isFeatured ? Icons.star_border : Icons.star,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(service.isFeatured ? 'إلغاء التمييز' : 'تمييز'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                service.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${service.basePrice.toStringAsFixed(0)} جنيه',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${service.estimatedDuration} ساعة',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${service.averageRating.toStringAsFixed(1)} (${service.totalRatings})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddServiceDialog() async {
    final nameController = TextEditingController();
    final nameEnController = TextEditingController();
    final descriptionController = TextEditingController();
    final shortDescriptionController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    int durationHours = 2;
    int? selectedCategoryId = _categories.first.id;
    bool isActive = true;
    bool isFeatured = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('إضافة خدمة جديدة'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'الفئة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة (عربي) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameEnController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة (English) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: shortDescriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'وصف مختصر',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.short_text),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'الوصف الكامل *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'السعر المقترح (جنيه)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر تأكيد لإغلاق الكيبورد (مهم لـ iOS)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'تأكيد',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimpleDurationDropdown(
                          value: durationHours,
                          onChanged: (value) {
                            setDialogState(() {
                              durationHours = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('الحالة'),
                    subtitle: Text(isActive ? 'نشط' : 'غير نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('خدمة مميزة'),
                    subtitle: Text(isFeatured ? 'نعم' : 'لا'),
                    value: isFeatured,
                    onChanged: (value) {
                      setDialogState(() {
                        isFeatured = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ConnectivityTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ConnectivityButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    nameEnController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createService(
                  categoryId: selectedCategoryId!,
                  name: nameController.text.trim(),
                  nameEn: nameEnController.text.trim(),
                  description: descriptionController.text.trim(),
                  shortDescription: shortDescriptionController.text.trim(),
                  price: double.tryParse(priceController.text) ?? 0,
                  duration: durationHours,
                  isActive: isActive,
                  isFeatured: isFeatured,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditServiceDialog(Service service) async {
    final nameController = TextEditingController(text: service.name);
    final nameEnController = TextEditingController(text: '');
    final descriptionController = TextEditingController(text: service.description);
    final shortDescriptionController = TextEditingController(text: '');
    final priceController = TextEditingController(text: service.basePrice.toString());
    int durationHours = service.estimatedDuration;
    int? selectedCategoryId = service.category.id;
    bool isActive = service.isActive;
    bool isFeatured = service.isFeatured;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('تعديل الخدمة'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'الفئة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة (عربي) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameEnController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة (English)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: shortDescriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'وصف مختصر',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.short_text),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'الوصف الكامل *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'السعر المقترح (جنيه)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر تأكيد لإغلاق الكيبورد (مهم لـ iOS)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'تأكيد',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimpleDurationDropdown(
                          value: durationHours,
                          onChanged: (value) {
                            setDialogState(() {
                              durationHours = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('الحالة'),
                    subtitle: Text(isActive ? 'نشط' : 'غير نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('خدمة مميزة'),
                    subtitle: Text(isFeatured ? 'نعم' : 'لا'),
                    value: isFeatured,
                    onChanged: (value) {
                      setDialogState(() {
                        isFeatured = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ConnectivityTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ConnectivityButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _updateService(
                  service.id,
                  categoryId: selectedCategoryId!,
                  name: nameController.text.trim(),
                  nameEn: nameEnController.text.trim(),
                  description: descriptionController.text.trim(),
                  shortDescription: shortDescriptionController.text.trim(),
                  price: double.tryParse(priceController.text) ?? 0,
                  duration: durationHours,
                  isActive: isActive,
                  isFeatured: isFeatured,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف الخدمة "${service.name}"؟\n\nملاحظة: لن تتمكن من حذف الخدمة إذا كانت مرتبطة بطلبات حجز.',
        ),
        actions: [
          ConnectivityTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ConnectivityButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteService(service.id);
    }
  }

  Future<void> _createService({
    required int categoryId,
    required String name,
    required String nameEn,
    required String description,
    required String shortDescription,
    required double price,
    required int duration,
    required bool isActive,
    required bool isFeatured,
  }) async {
    try {

      final response = await ApiClient.post(
        ApiConfig.adminServices,
        needsAuth: true,
        body: {
          'category': categoryId,
          'name': name,
          if (nameEn.isNotEmpty) 'name_en': nameEn,
          'description': description,
          if (shortDescription.isNotEmpty) 'short_description': shortDescription,
          'suggested_price': price.toString(),
          'suggested_duration_hours': duration,
          'is_active': isActive,
          'is_featured': isFeatured,
        },
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم إنشاء الخدمة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
      } else {
        throw Exception(response.error ?? 'Failed to create service');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء الخدمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateService(
    int id, {
    required int categoryId,
    required String name,
    required String nameEn,
    required String description,
    required String shortDescription,
    required double price,
    required int duration,
    required bool isActive,
    required bool isFeatured,
  }) async {
    try {

      final response = await ApiClient.put(
        ApiConfig.adminServiceDetail(id),
        needsAuth: true,
        body: {
          'category': categoryId,
          'name': name,
          if (nameEn.isNotEmpty) 'name_en': nameEn,
          'description': description,
          if (shortDescription.isNotEmpty) 'short_description': shortDescription,
          'suggested_price': price.toString(),
          'suggested_duration_hours': duration,
          'is_active': isActive,
          'is_featured': isFeatured,
        },
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم تحديث الخدمة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
      } else {
        throw Exception(response.error ?? 'Failed to update service');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الخدمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteService(int id) async {
    try {

      final response = await ApiClient.delete(
        ApiConfig.adminServiceDetail(id),
        needsAuth: true,
      );


      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم حذف الخدمة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
      } else {
        // Show error message from server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'فشل حذف الخدمة'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الخدمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleServiceStatus(Service service) async {
    await _updateService(
      service.id,
      categoryId: service.category.id,
      name: service.name,
      nameEn: '',
      description: service.description,
      shortDescription: '',
      price: service.basePrice,
      duration: service.estimatedDuration,
      isActive: !service.isActive,
      isFeatured: service.isFeatured,
    );
  }

  Future<void> _toggleFeaturedStatus(Service service) async {
    await _updateService(
      service.id,
      categoryId: service.category.id,
      name: service.name,
      nameEn: '',
      description: service.description,
      shortDescription: '',
      price: service.basePrice,
      duration: service.estimatedDuration,
      isActive: service.isActive,
      isFeatured: !service.isFeatured,
    );
  }
}
