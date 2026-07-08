import 'package:flutter/material.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';

/// Widget لعرض متوسط التقييمات وقائمة التقييمات الفردية في بروفايل العاملة
class RatingsSection extends StatefulWidget {
  final int providerId;
  final double? initialAverageRating;
  final int? initialTotalRatings;
  final Function(int totalRatings)? onRatingsLoaded;

  const RatingsSection({
    Key? key,
    required this.providerId,
    this.initialAverageRating,
    this.initialTotalRatings,
    this.onRatingsLoaded,
  }) : super(key: key);

  @override
  _RatingsSectionState createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<RatingsSection> {
  List<Rating> _ratings = [];
  bool _isLoading = true;
  String? _errorMessage;
  double? _averageRating;
  int? _totalRatings;

  @override
  void initState() {
    super.initState();
    _averageRating = widget.initialAverageRating;
    _totalRatings = widget.initialTotalRatings;
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await RatingService.getProviderRatings(widget.providerId);

      if (response.success && response.data != null) {
        setState(() {
          _ratings = response.data!;
          _isLoading = false;

          // حساب المتوسط من التقييمات المحملة
          if (_ratings.isNotEmpty) {
            final sum = _ratings.fold<int>(0, (prev, rating) => prev + rating.rating);
            _averageRating = sum / _ratings.length;
            _totalRatings = _ratings.length;
            // إبلاغ الـ parent بعدد التقييمات
            if (widget.onRatingsLoaded != null) {
              widget.onRatingsLoaded!(_totalRatings!);
            }
          } else {
            // حتى لو مفيش تقييمات، نبلغ الـ parent بـ 0
            if (widget.onRatingsLoaded != null) {
              widget.onRatingsLoaded!(0);
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = response.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            AppLocalizations.of(context)?.ratings ?? 'التقييمات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),

        // متوسط التقييمات
        _buildAverageRatingCard(),

        const SizedBox(height: 16),

        // قائمة التقييمات الفردية
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadRatings,
                    child: Text(AppLocalizations.of(context)?.retry ?? 'إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          )
        else if (_ratings.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                AppLocalizations.of(context)?.noRatingsYet ?? 'لا توجد تقييمات بعد',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          _buildRatingsList(),
      ],
    );
  }

  /// بطاقة متوسط التقييمات
  Widget _buildAverageRatingCard() {
    final avgRating = _averageRating ?? 0.0;
    final totalRatings = _totalRatings ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // النجوم والتقييم
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFBBF24),
                    size: 40,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  if (index < avgRating.floor()) {
                    return const Icon(Icons.star, color: Color(0xFFFBBF24), size: 20);
                  } else if (index < avgRating) {
                    return const Icon(Icons.star_half, color: Color(0xFFFBBF24), size: 20);
                  } else {
                    return const Icon(Icons.star_border, color: Colors.white70, size: 20);
                  }
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getBasedOnRatingsText(totalRatings),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// قائمة التقييمات الفردية (كـ comments)
  Widget _buildRatingsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _ratings.length,
      itemBuilder: (context, index) {
        final rating = _ratings[index];
        return _buildRatingCard(rating);
      },
    );
  }

  /// بطاقة تقييم واحد
  Widget _buildRatingCard(Rating rating) {
    final hasComment = rating.comment != null && rating.comment!.isNotEmpty;
    final clientName = rating.ratedByName ?? (AppLocalizations.of(context)?.client ?? 'عميل');
    final profilePicture = rating.ratedByProfilePicture;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة: صورة العميل + الاسم + النجوم
            Row(
              children: [
                // صورة العميل
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                  backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage('${ApiConfig.baseUrl}$profilePicture')
                      : null,
                  child: profilePicture == null || profilePicture.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF8B5CF6), size: 28)
                      : null,
                ),
                const SizedBox(width: 12),

                // اسم العميل والنجوم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < rating.rating ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFBBF24),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rating.rating}/5',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // تاريخ التقييم
                Text(
                  _formatDate(rating.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            // التعليق (إن وجد)
            if (hasComment) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  rating.comment!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get based on ratings text
  String _getBasedOnRatingsText(int count) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return 'بناءً على \u200F$count\u200F تقييم';
    }
    final template = localizations.translate('basedOnRatings');
    return template.replaceAll('{count}', count.toString());
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final localizations = AppLocalizations.of(context);

    if (difference.inDays == 0) {
      return localizations?.today ?? 'اليوم';
    } else if (difference.inDays == 1) {
      return localizations?.yesterday ?? 'أمس';
    } else if (difference.inDays < 7) {
      final template = localizations?.daysAgo ?? 'منذ \u200F{count}\u200F أيام';
      return template.replaceAll('{count}', difference.inDays.toString());
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (weeks == 1) {
        return localizations?.weekAgo ?? 'منذ أسبوع';
      }
      final template = localizations?.weeksAgo ?? 'منذ \u200F{count}\u200F أسابيع';
      return template.replaceAll('{count}', weeks.toString());
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return localizations?.monthAgo ?? 'منذ شهر';
      }
      final template = localizations?.monthsAgo ?? 'منذ \u200F{count}\u200F أشهر';
      return template.replaceAll('{count}', months.toString());
    } else {
      final years = (difference.inDays / 365).floor();
      if (years == 1) {
        return localizations?.yearAgo ?? 'منذ سنة';
      }
      final template = localizations?.yearsAgo ?? 'منذ \u200F{count}\u200F سنوات';
      return template.replaceAll('{count}', years.toString());
    }
  }
}
