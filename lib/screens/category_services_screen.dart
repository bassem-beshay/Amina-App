import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import '../services/booking_service.dart';
import '../services/address_service.dart';
import '../widgets/complete_profile_dialog.dart';
import '../l10n/app_localizations.dart';
import 'service_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../providers/language_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../mixins/connectivity_aware_mixin.dart';
import '../widgets/connectivity_button.dart';
import '../widgets/duration_dropdown.dart';

class CategoryServicesScreen extends StatefulWidget {
  final List<ServiceCategory> categories;
  final ServiceCategory? initialCategory;

  CategoryServicesScreen({
    super.key,
    required this.categories,
    this.initialCategory,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> with ConnectivityAwareMixin {
  ServiceCategory? _selectedCategory;
  List<Service> _services = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? widget.categories.first;
    _loadServices();
  }

  Future<void> _loadServices() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
    });

    final services = await ServiceService.getServices(
      categoryId: _selectedCategory!.id,
    );

    setState(() {
      _services = services;
      _isLoading = false;
    });
  }

  @override
  Future<void> fetchData() async {
    // Implementation required by ConnectivityAwareMixin
    await _loadServices();
  }

  void _onCategorySelected(ServiceCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadServices();
  }

  void _showCategoriesBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.selectCategory ?? 'اختر الفئة',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)?.browseAllCategories ?? 'تصفح جميع فئات الخدمات المتاحة',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
            // Categories grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  final isSelected = category.id == _selectedCategory?.id;
                  return _buildCategoryCard(category, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category, bool isSelected) {
    final categoryIcons = {
      'تنظيف منزلي': {'icon': Icons.cleaning_services, 'color': const Color(0xFF10B981)},
      'طبخ': {'icon': Icons.restaurant, 'color': const Color(0xFFF59E0B)},
      'رعاية أطفال': {'icon': Icons.child_care, 'color': const Color(0xFF3B82F6)},
      'رعاية مسنين': {'icon': Icons.accessible, 'color': const Color(0xFF8B5CF6)},
      'غسيل ملابس': {'icon': Icons.local_laundry_service, 'color': const Color(0xFFEC4899)},
      'كي ملابس': {'icon': Icons.checkroom, 'color': const Color(0xFF06B6D4)},
    };

    final iconData = categoryIcons[category.name];
    final icon = iconData?['icon'] as IconData? ?? Icons.category;
    final color = iconData?['color'] as Color? ?? const Color(0xFF8B5CF6);

    return GestureDetector(
      onTap: () {
        _onCategorySelected(category);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show category image if available
            _buildCategoryImage(category, icon, color, isSelected),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _getCategoryName(category),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)?.selected ?? 'محددة',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showBookingDialog(Service service) async {
    // التحقق من اكتمال البيانات أولاً
    final profileCheck = await ProfileCompletionChecker.showCompletionDialogIfNeeded(context);

    if (profileCheck == 'go_to_edit') {
      // المستخدم اختار التوجيه لشاشة التعديل
      if (mounted) {
        final updated = await Navigator.of(context).pushNamed('/edit-client-profile');

        // بعد ما يرجع من شاشة التعديل، نتحقق لو البيانات اكتملت
        if (updated == true && mounted) {
          // نعيد محاولة الحجز
          _showBookingDialog(service);
        }
      }
      return;
    } else if (profileCheck != 'complete') {
      // المستخدم ألغى
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    int? durationHours;

    // العناوين المحفوظة
    List<Map<String, dynamic>> savedAddresses = [];
    Map<String, dynamic>? selectedAddress;
    bool isLoadingAddresses = true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          // تحميل العناوين عند فتح ال Bottom Sheet
          if (isLoadingAddresses) {
            AddressService.getAddresses().then((response) {
              if (response.success && response.data != null) {
                setModalState(() {
                  savedAddresses = response.data!;
                  isLoadingAddresses = false;
                  // اختيار العنوان الافتراضي تلقائياً
                  if (savedAddresses.isNotEmpty) {
                    selectedAddress = savedAddresses.firstWhere(
                      (addr) => addr['is_default'] == true,
                      orElse: () => savedAddresses.first,
                    );
                  }
                });
              } else {
                setModalState(() {
                  isLoadingAddresses = false;
                });
              }
            });
          }

          return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header مع gradient
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.newBooking ?? 'حجز جديد',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // التاريخ
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.bookingDate ?? 'تاريخ الحجز',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            selectedDate = date;
                            (context as Element).markNeedsBuild();
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: AppLocalizations.of(context)?.selectBookingDate ?? 'اختر تاريخ الحجز',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        controller: TextEditingController(
                          text: selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : '',
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // الوقت
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.bookingTime ?? 'وقت الحجز',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            selectedTime = time;
                            (context as Element).markNeedsBuild();
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: AppLocalizations.of(context)?.selectBookingTime ?? 'اختر وقت الحجز',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        controller: TextEditingController(
                          text: selectedTime != null
                            ? '${selectedTime?.hour.toString().padLeft(2, '0')}:${selectedTime?.minute.toString().padLeft(2, '0')}'
                            : '',
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // المدة
              Row(
                children: [
                  const Icon(Icons.timer, size: 20, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.serviceDuration ?? 'مدة الخدمة (ساعات)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DurationDropdown(
                value: durationHours ?? 1,
                onChanged: (value) {
                  setModalState(() {
                    durationHours = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // العنوان المحفوظ
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.selectAddress ?? 'اختر العنوان',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // قائمة العناوين أو رسالة تحميل
              if (isLoadingAddresses)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  ),
                )
              else if (savedAddresses.isEmpty)
                _buildNoAddressWidget(isDark, setModalState, savedAddresses, (addr) {
                  selectedAddress = addr;
                })
              else
                ..._buildAddressCards(isDark, savedAddresses, selectedAddress, setModalState, (addr) {
                  selectedAddress = addr;
                }),
            ],
                ),
              ),
            ),

            // زر التأكيد في الأسفل
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ConnectivityButton(
                  onPressed: (selectedDate != null &&
                             selectedTime != null &&
                             durationHours != null &&
                             selectedAddress != null)
                    ? () => Navigator.pop(context, true)
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.confirmBooking ?? 'تأكيد الحجز',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
        },
      ),
    );

    if (result == true) {
      // التحقق من أن جميع الحقول مملوءة
      if (selectedDate == null || selectedTime == null || durationHours == null || selectedAddress == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.pleaseCompleteAllFields ?? 'يرجى ملء جميع الحقول'} ${AppLocalizations.of(context)?.pleaseSelectAddress ?? 'واختيار العنوان'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _createBookingRequest(
        service: service,
        bookingDate: selectedDate!,
        bookingTime: selectedTime!,
        durationHours: durationHours!,
        city: selectedAddress!['city'] ?? '',
        address: selectedAddress!['address'] ?? '',
      );
    }
  }

  Future<void> _createBookingRequest({
    required Service service,
    required DateTime bookingDate,
    required TimeOfDay bookingTime,
    required int durationHours,
    required String city,
    required String address,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
    );

    final timeString = '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}:00';


    final result = await BookingService.createBookingRequest(
      serviceId: service.id,
      categoryId: _selectedCategory!.id,
      bookingDate: bookingDate,
      bookingTime: timeString,
      durationHours: durationHours,
      city: city,
      address: address,
      clientBudget: service.basePrice,
    );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (result.success) {
    } else {
    }

    // Show result message
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.surface),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Go back to home screen and tell it to refresh
        Navigator.pop(context, true); // Pass true to indicate success
      } else {
        // Show error dialog with detailed info
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)?.bookingErrorMessage ?? 'خطأ في الحجز'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.error!,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نصائح لحل المشكلة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('1. تأكد من أن السيرفر شغال على المنفذ 8000', style: TextStyle(fontSize: 13)),
                        Text('2. تحقق من إعدادات الشبكة', style: TextStyle(fontSize: 13)),
                        Text('3. راجع الـ console للمزيد من التفاصيل', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ConnectivityTextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context)?.ok ?? 'حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get current category color
    final categoryIcons = {
      'تنظيف منزلي': {'icon': Icons.cleaning_services, 'color': const Color(0xFF10B981)},
      'طبخ': {'icon': Icons.restaurant, 'color': const Color(0xFFF59E0B)},
      'رعاية أطفال': {'icon': Icons.child_care, 'color': const Color(0xFF3B82F6)},
      'رعاية مسنين': {'icon': Icons.accessible, 'color': const Color(0xFF8B5CF6)},
      'غسيل ملابس': {'icon': Icons.local_laundry_service, 'color': const Color(0xFFEC4899)},
      'كي ملابس': {'icon': Icons.checkroom, 'color': const Color(0xFF06B6D4)},
    };

    final currentIconData = categoryIcons[_selectedCategory?.name];
    final currentIcon = currentIconData?['icon'] as IconData? ?? Icons.category;
    final currentColor = currentIconData?['color'] as Color? ?? const Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedCategory?.name ?? AppLocalizations.of(context)?.services ?? 'Services',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildServicesContent(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentColor,
              currentColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: currentColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCategoriesBottomSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(currentIcon, size: 24),
          label: Text(
            AppLocalizations.of(context)?.categories ?? 'الفئات',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
        ),
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(isDark ? 0.2 : 0.1),
                    const Color(0xFF8B5CF6).withOpacity(isDark ? 0.1 : 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 80,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)?.noServicesAvailable ?? 'لا توجد خدمات متاحة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.noServicesInCategory ?? 'لم نجد أي خدمات في هذه الفئة حالياً',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(Service service) {
    const kPrimary = Color(0xFF8B5CF6);
    const kNavGray = Color(0xFF7D7F88);
    const kPriceDark = Color(0xFF1A1E25);

    final title = service.nameEn.isNotEmpty ? service.nameEn : service.name;
    final category = service.category.nameEn.isNotEmpty
        ? service.category.nameEn
        : service.category.name;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(service: service),
              ),
            );
            if (result == true && mounted) Navigator.pop(context, true);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: _offerImageTop(service),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.favorite_border,
                              size: 18, color: kNavGray),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: kNavGray,
                          letterSpacing: 0.13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${service.basePrice.toStringAsFixed(0)}EGP',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kPriceDark,
                                height: 1.3,
                              ),
                            ),
                            TextSpan(
                              text: '  / ${_unitLabelEn(service)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: kNavGray,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ConnectivityButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ServiceDetailScreen(service: service),
                              ),
                            );
                            if (result == true && mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kPrimary,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size.fromHeight(40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: kPrimary, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Book Now',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: kPrimary,
                              letterSpacing: 0.18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _offerImageTop(Service service) {
    String? imageUrl = service.image;
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '${ApiConfig.baseUrl}$imageUrl';
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 149,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(height: 149, color: const Color(0xFFEDEAFB)),
        errorWidget: (context, url, error) => _offerImageTopFallback(),
      );
    }
    return _offerImageTopFallback();
  }

  Widget _offerImageTopFallback() {
    return Container(
      height: 149,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_repair_service, size: 48, color: Colors.white70),
      ),
    );
  }

  String _unitLabelEn(Service service) {
    switch (service.unit) {
      case 'HOUR':
        return 'For Every Hour';
      case 'DAY':
        return 'For Every Day';
      case 'TASK':
        return 'For Every Task';
      default:
        return service.unit;
    }
  }

  // Helper method to get service name based on current language
  String _getServiceName(Service service) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.locale.languageCode == 'ar';
    return isArabic ? service.name : service.nameEn;
  }

  // Helper method to build category image or icon
  Widget _buildCategoryImage(ServiceCategory category, IconData fallbackIcon, Color color, bool isSelected) {
    // Check if category has image (prefer 'image' over 'icon')
    String? imageUrl = category.image ?? category.icon;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }

      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: isSelected ? Colors.white : color,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                fallbackIcon,
                color: isSelected ? Colors.white : color,
                size: 36,
              ),
            ),
          ),
        ),
      );
    }

    // Fallback to icon
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Icon(
        fallbackIcon,
        color: isSelected ? Colors.white : color,
        size: 36,
      ),
    );
  }


  // Helper method to build service image
  Widget _buildServiceImage(Service service, Color categoryColor) {
    if (service.image != null && service.image!.isNotEmpty) {
      String imageUrl = service.image!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      }

      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor,
                    categoryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor,
                    categoryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Icon(
                Icons.home_repair_service,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
      );
    }

    // Fallback to icon
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor,
            categoryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.home_repair_service,
        color: Colors.white,
        size: 34,
      ),
    );
  }

  // Helper method to get category name based on current language
  String _getCategoryName(ServiceCategory category) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.locale.languageCode == 'ar';
    return isArabic ? category.name : category.nameEn;
  }

  // Widget when no addresses exist
  Widget _buildNoAddressWidget(
    bool isDark,
    StateSetter setModalState,
    List<Map<String, dynamic>> savedAddresses,
    Function(Map<String, dynamic>?) setSelectedAddress,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 48,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.noSavedAddresses ?? 'لا توجد عناوين محفوظة',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.noAddressesSavedMessage ?? 'قم بإضافة عنوان جديد للمتابعة',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ConnectivityIconButton(
            onPressed: () => _showAddAddressDialog(setModalState, savedAddresses, setSelectedAddress),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_location_alt, size: 20),
            label: Text(
              AppLocalizations.of(context)?.addNewAddress ?? 'إضافة عنوان جديد',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build address cards for selection
  List<Widget> _buildAddressCards(
    bool isDark,
    List<Map<String, dynamic>> addresses,
    Map<String, dynamic>? selectedAddress,
    StateSetter setModalState,
    Function(Map<String, dynamic>?) setSelectedAddress,
  ) {
    final List<Widget> widgets = [];

    // Add saved address cards
    for (var address in addresses) {
      final isSelected = selectedAddress?['id'] == address['id'];
      final isDefault = address['is_default'] == true;

      widgets.add(
        GestureDetector(
          onTap: () {
            setModalState(() {
              setSelectedAddress(address);
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6).withOpacity(0.1)
                  : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF8B5CF6).withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDefault ? Icons.home : Icons.location_on,
                    color: const Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Address details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address['label'] ?? AppLocalizations.of(context)?.address ?? 'عنوان',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF8B5CF6) : null,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.defaultLabel ?? 'افتراضي',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address['address'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            address['city'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Add "Add New Address" button
    widgets.add(
      const SizedBox(height: 8),
    );
    widgets.add(
      OutlinedButton.icon(
        onPressed: () => _showAddAddressDialog(setModalState, addresses, setSelectedAddress),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8B5CF6),
          side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.add_location_alt, size: 22),
        label: Text(
          AppLocalizations.of(context)?.addNewAddress ?? 'إضافة عنوان جديد',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return widgets;
  }

  // Show dialog to add new address with GPS
  Future<void> _showAddAddressDialog(
    StateSetter setModalState,
    List<Map<String, dynamic>> savedAddresses,
    Function(Map<String, dynamic>?) setSelectedAddress,
  ) async {
    final TextEditingController labelController = TextEditingController();
    bool isDetecting = false;
    String? detectedAddress;
    String? detectedCity;
    double? latitude;
    double? longitude;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_location_alt,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.addNewAddress ?? 'إضافة عنوان جديد',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Label input
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.addressLabelOptional ?? 'تسمية العنوان (اختياري)',
                        hintText: AppLocalizations.of(context)?.exampleHomeWork ?? 'مثل: المنزل، العمل، إلخ',
                        prefixIcon: const Icon(Icons.label, color: Color(0xFF8B5CF6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Detect location button
                    ConnectivityIconButton(
                      onPressed: isDetecting
                          ? null
                          : () async {
                              setDialogState(() {
                                isDetecting = true;
                              });

                              try {
                                // Check location permission
                                LocationPermission permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission = await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) {
                                    throw Exception(AppLocalizations.of(context)?.locationPermissionDenied ?? 'تم رفض إذن الموقع');
                                  }
                                }

                                if (permission == LocationPermission.deniedForever) {
                                  throw Exception(AppLocalizations.of(context)?.locationPermissionDeniedPermanently ?? 'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من الإعدادات');
                                }

                                // Get current position
                                Position position = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                                latitude = position.latitude;
                                longitude = position.longitude;

                                // Reverse geocoding to get address
                                List<Placemark> placemarks = await placemarkFromCoordinates(
                                  position.latitude,
                                  position.longitude,
                                );

                                if (placemarks.isNotEmpty) {
                                  final place = placemarks.first;
                                  setDialogState(() {
                                    detectedCity = place.locality ?? place.administrativeArea ?? (AppLocalizations.of(context)?.translate('noData') ?? 'غير محدد');
                                    detectedAddress = [
                                      place.street,
                                      place.subLocality,
                                      place.locality,
                                    ].where((e) => e != null && e.isNotEmpty).join(', ');
                                    isDetecting = false;
                                  });
                                }
                              } catch (e) {
                                setDialogState(() {
                                  isDetecting = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${AppLocalizations.of(context)?.failedToDetect ?? 'فشل تحديد الموقع'}: \u200F${e.toString()}\u200F'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: isDetecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location, size: 22),
                      label: Text(
                        isDetecting ? (AppLocalizations.of(context)?.detectingLocation ?? 'جاري تحديد الموقع...') : (AppLocalizations.of(context)?.useMyCurrentLocation ?? 'تحديد موقعي الحالي'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                    if (detectedAddress != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)?.locationDetectedSuccess ?? 'تم تحديد الموقع بنجاح',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_city, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'المدينة: $detectedCity',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'العنوان: $detectedAddress',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                ConnectivityTextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
                ),
                ConnectivityButton(
                  onPressed: (detectedAddress != null && latitude != null && longitude != null)
                      ? () async {
                          Navigator.pop(context);

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                            ),
                          );

                          // Add address
                          final result = await AddressService.addAddress(
                            label: labelController.text.trim().isEmpty ? null : labelController.text.trim(),
                            latitude: latitude!,
                            longitude: longitude!,
                            address: detectedAddress!,
                            city: detectedCity ?? (AppLocalizations.of(context)?.translate('noData') ?? 'غير محدد'),
                            country: AppLocalizations.of(context)?.egypt ?? 'Egypt',
                            isDefault: false,
                          );

                          if (mounted) {
                            Navigator.pop(context); // Close loading

                            if (result.success) {
                              // Refresh addresses
                              final addressesResponse = await AddressService.getAddresses();
                              if (addressesResponse.success && addressesResponse.data != null) {
                                setModalState(() {
                                  // Clear and update the savedAddresses list
                                  savedAddresses.clear();
                                  savedAddresses.addAll(addressesResponse.data!);

                                  // Select the newly added address
                                  final newAddress = savedAddresses.firstWhere(
                                    (addr) => addr['address'] == detectedAddress,
                                    orElse: () => savedAddresses.last,
                                  );
                                  setSelectedAddress(newAddress);
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)?.addressAddedSuccess ?? 'تم إضافة العنوان بنجاح'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.error ?? (AppLocalizations.of(context)?.failedToAddAddress ?? 'فشل إضافة العنوان')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)?.save ?? 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
