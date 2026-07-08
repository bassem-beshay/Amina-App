import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';

/// Widget احترافي لاختيار مدة الخدمة بالساعات (1-24)
/// يستخدم Bottom Sheet شفاف مع Scroll Picker
class DurationDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int minHours;
  final int maxHours;

  const DurationDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    this.minHours = 1,
    this.maxHours = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _showDurationPicker(context, isDark, localizations),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF374151).withOpacity(0.8)
              : const Color(0xFFF3F4F6).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.2),
                    const Color(0xFF10B981).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.timelapse_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.duration ?? 'مدة الخدمة',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$value ${_getHoursLabel(value, localizations)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, bool isDark, AppLocalizations? localizations) {
    int selectedValue = value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations?.serviceDuration ?? 'اختر مدة الخدمة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        localizations?.cancel ?? 'إلغاء',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Picker
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedValue - minHours,
                    ),
                    itemExtent: 50,
                    diameterRatio: 1.2,
                    squeeze: 1.0,
                    magnification: 1.2,
                    useMagnifier: true,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      setModalState(() {
                        selectedValue = minHours + index;
                      });
                    },
                    children: List.generate(maxHours - minHours + 1, (index) {
                      final hours = minHours + index;
                      final isSelected = hours == selectedValue;
                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$hours',
                                style: TextStyle(
                                  fontSize: isSelected ? 28 : 20,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF8B5CF6)
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getHoursLabel(hours, localizations),
                                style: TextStyle(
                                  fontSize: isSelected ? 18 : 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF8B5CF6).withOpacity(0.8)
                                      : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onChanged(selectedValue);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '${localizations?.confirm ?? 'تأكيد'} ($selectedValue ${_getHoursLabel(selectedValue, localizations)})',
                          style: const TextStyle(
                            fontSize: 16,
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
        ),
      ),
    );
  }

  String _getHoursLabel(int hours, AppLocalizations? localizations) {
    if (hours == 1) {
      return localizations?.hour ?? 'ساعة';
    } else if (hours == 2) {
      return 'ساعتان';
    } else if (hours >= 3 && hours <= 10) {
      return localizations?.hours ?? 'ساعات';
    } else {
      return localizations?.hour ?? 'ساعة';
    }
  }
}

/// Widget مبسط لاختيار الساعات للاستخدام في dialogs
class SimpleDurationDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int minHours;
  final int maxHours;

  const SimpleDurationDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    this.minHours = 1,
    this.maxHours = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showPicker(context, isDark),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'المدة (ساعة)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.schedule, color: Color(0xFF8B5CF6)),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
        ),
        child: Text(
          '$value ${value == 1 ? 'ساعة' : value == 2 ? 'ساعتان' : value <= 10 ? 'ساعات' : 'ساعة'}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, bool isDark) {
    int selectedValue = value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 350,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937).withOpacity(0.98)
                : Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                    Text(
                      'اختر المدة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onChanged(selectedValue);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'تأكيد',
                        style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Picker
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedValue - minHours,
                  ),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    setModalState(() {
                      selectedValue = minHours + index;
                    });
                  },
                  children: List.generate(maxHours - minHours + 1, (index) {
                    final hours = minHours + index;
                    return Center(
                      child: Text(
                        '$hours ${hours == 1 ? 'ساعة' : hours == 2 ? 'ساعتان' : hours <= 10 ? 'ساعات' : 'ساعة'}',
                        style: TextStyle(
                          fontSize: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
