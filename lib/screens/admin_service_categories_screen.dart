import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../models/service_model.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connectivity_button.dart';

class AdminServiceCategoriesScreen extends StatefulWidget {
  final String token;
  const AdminServiceCategoriesScreen({Key? key, required this.token})
      : super(key: key);

  @override
  _AdminServiceCategoriesScreenState createState() =>
      _AdminServiceCategoriesScreenState();
}

class _AdminServiceCategoriesScreenState
    extends State<AdminServiceCategoriesScreen> {
  List<ServiceCategory> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      ApiClient.setAuthToken(widget.token);

      final response =
          await ApiClient.get(ApiConfig.adminCategories, needsAuth: true);

      if (response.success && response.rawResponse != null) {
        final data = response.rawResponse;
        final categoriesData = data['data'] as List;

        setState(() {
          _categories = categoriesData
              .map((cat) => ServiceCategory.fromJson(cat as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });

      } else {
        throw Exception(response.error ?? 'Failed to load categories');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل الفئات: $e';
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
          AppLocalizations.of(context)?.translate('serviceCategories') ?? 'إدارة فئات الخدمات',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.surface),
            onPressed: _loadCategories,
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
                        onPressed: _loadCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد فئات خدمات',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ابدأ بإضافة فئة جديدة',
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
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return _buildCategoryCard(category);
                          },
                        ),
                ),
      floatingActionButton: ConnectivityFloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.isActive
                    ? const Color(0xFF10B981).withOpacity( 0.1)
                    : Colors.grey.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.category,
                color: category.isActive
                    ? const Color(0xFF10B981)
                    : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Category Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Active Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.isActive
                              ? Colors.green.withOpacity( 0.1)
                              : Colors.grey.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: category.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (category.description != null &&
                      category.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action Buttons
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(category);
                } else if (value == 'toggle') {
                  _toggleCategoryStatus(category);
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
                        category.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category.isActive ? 'تعطيل' : 'تفعيل'),
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
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final nameEnController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isActive = true;

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
              Text('إضافة فئة جديدة'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة (بالعربي) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة (بالإنجليزي) *',
                    hintText: 'Category Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
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
              ],
            ),
          ),
          actions: [
            ConnectivityTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ConnectivityButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال اسم الفئة بالعربي'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (nameEnController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال اسم الفئة بالإنجليزي'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createCategory(
                  name: nameController.text.trim(),
                  nameEn: nameEnController.text.trim(),
                  description: descriptionController.text.trim(),
                  displayOrder: 0,
                  isActive: isActive,
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

  Future<void> _showEditCategoryDialog(ServiceCategory category) async {
    final nameController = TextEditingController(text: category.name);
    final nameEnController = TextEditingController(text: category.nameEn);
    final descriptionController =
        TextEditingController(text: category.description ?? '');
    bool isActive = category.isActive;

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
              Text('تعديل الفئة'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة (بالعربي) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة (بالإنجليزي) *',
                    hintText: 'Category Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
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
              ],
            ),
          ),
          actions: [
            ConnectivityTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ConnectivityButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال اسم الفئة بالعربي'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (nameEnController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال اسم الفئة بالإنجليزي'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _updateCategory(
                  category.id,
                  name: nameController.text.trim(),
                  nameEn: nameEnController.text.trim(),
                  description: descriptionController.text.trim(),
                  displayOrder: category.displayOrder,
                  isActive: isActive,
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

  Future<void> _showDeleteConfirmation(ServiceCategory category) async {
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
          'هل أنت متأكد من حذف الفئة "${category.name}"؟\n\nملاحظة: لن تتمكن من حذف الفئة إذا كانت تحتوي على خدمات.',
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
      await _deleteCategory(category.id);
    }
  }

  Future<void> _createCategory({
    required String name,
    required String nameEn,
    required String description,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {

      final response = await ApiClient.post(
        ApiConfig.adminCategories,
        needsAuth: true,
        body: {
          'name': name,
          'name_en': nameEn,
          if (description.isNotEmpty) 'description': description,
          'display_order': displayOrder,
          'is_active': isActive,
        },
      );


      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم إنشاء الفئة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadCategories();
      } else {
        // Show error message from server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'فشل إنشاء الفئة'),
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
            content: Text('خطأ في إنشاء الفئة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCategory(
    int id, {
    required String name,
    required String nameEn,
    required String description,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {

      final response = await ApiClient.put(
        ApiConfig.adminCategoryDetail(id),
        needsAuth: true,
        body: {
          'name': name,
          'name_en': nameEn,
          if (description.isNotEmpty) 'description': description,
          'display_order': displayOrder,
          'is_active': isActive,
        },
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم تحديث الفئة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadCategories();
      } else {
        throw Exception(response.error ?? 'Failed to update category');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الفئة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {

      final response = await ApiClient.delete(
        ApiConfig.adminCategoryDetail(id),
        needsAuth: true,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'تم حذف الفئة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadCategories();
      } else {
        // Show error message from server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'فشل حذف الفئة'),
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
            content: Text('خطأ في حذف الفئة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCategoryStatus(ServiceCategory category) async {
    await _updateCategory(
      category.id,
      name: category.name,
      nameEn: category.nameEn,
      description: category.description ?? '',
      displayOrder: category.displayOrder,
      isActive: !category.isActive,
    );
  }
}
