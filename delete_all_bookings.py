#!/usr/bin/env python3
"""
🗑️ سكريبت حذف جميع الحجوزات من Database - Amina Platform
يحذف جميع البيانات من جدول bookings_booking والبيانات المرتبطة

الاستخدام:
    python delete_all_bookings.py
    python delete_all_bookings.py --confirm
    python delete_all_bookings.py --backup

المتطلبات:
    - Django project configured
    - Database connection active
    - Admin/Superuser permissions
"""

import os
import sys
import django
from datetime import datetime

# إعداد Django environment
# ⚠️ عدّل اسم المشروع حسب مشروعك
try:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'AminaPlatform.settings')
    django.setup()
except Exception as e:
    print(f"❌ خطأ في إعداد Django: {e}")
    print("⚠️ تأكد من تشغيل السكريبت من مجلد المشروع")
    sys.exit(1)

try:
    from bookings.models import Booking
    from django.core.management import call_command
except ImportError as e:
    print(f"❌ خطأ في استيراد Models: {e}")
    print("⚠️ تأكد من أن تطبيق bookings موجود")
    sys.exit(1)


def print_header():
    """طباعة Header السكريبت"""
    print("\n" + "="*70)
    print("🗑️  سكريبت حذف جميع الحجوزات - Amina Platform")
    print("="*70 + "\n")


def create_backup():
    """إنشاء نسخة احتياطية من البيانات"""
    print("💾 جاري إنشاء نسخة احتياطية...")

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_file = f'bookings_backup_{timestamp}.json'

    try:
        # نسخ احتياطي لجميع بيانات Bookings
        with open(backup_file, 'w') as f:
            call_command('dumpdata', 'bookings.Booking', stdout=f)

        file_size = os.path.getsize(backup_file)
        print(f"✅ تم إنشاء النسخة الاحتياطية: {backup_file}")
        print(f"📦 حجم الملف: {file_size / 1024:.2f} KB\n")
        return backup_file
    except Exception as e:
        print(f"❌ فشل إنشاء النسخة الاحتياطية: {e}")
        return None


def get_booking_stats():
    """الحصول على إحصائيات الحجوزات"""
    try:
        total_count = Booking.objects.count()

        if total_count == 0:
            return None

        # إحصائيات حسب الحالة
        status_counts = {}
        for status_choice in ['CONFIRMED', 'PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']:
            count = Booking.objects.filter(status=status_choice).count()
            if count > 0:
                status_counts[status_choice] = count

        return {
            'total': total_count,
            'by_status': status_counts,
        }
    except Exception as e:
        print(f"⚠️ خطأ في جلب الإحصائيات: {e}")
        return None


def print_stats(stats):
    """طباعة إحصائيات الحجوزات"""
    if not stats:
        return

    print("📊 إحصائيات الحجوزات الحالية:")
    print(f"   📦 إجمالي الحجوزات: {stats['total']}")

    if stats['by_status']:
        print("\n   📋 توزيع حسب الحالة:")
        status_names = {
            'CONFIRMED': 'مؤكد',
            'PAYMENT_COMPLETED': 'تم الدفع',
            'IN_PROGRESS': 'قيد التنفيذ',
            'COMPLETED': 'مكتمل',
            'CANCELLED': 'ملغي',
        }
        for status, count in stats['by_status'].items():
            status_ar = status_names.get(status, status)
            print(f"      - {status_ar} ({status}): {count}")


def delete_all_bookings():
    """حذف جميع الحجوزات"""
    print("\n🗑️  جاري الحذف...")
    print("⏳ قد يستغرق هذا بعض الوقت حسب حجم البيانات...\n")

    try:
        # حذف جميع الحجوزات
        deleted_count, deleted_objects = Booking.objects.all().delete()

        print("✅ تم الحذف بنجاح!\n")
        print("="*70)
        print("📊 ملخص عملية الحذف:")
        print("="*70)
        print(f"\n📦 إجمالي العناصر المحذوفة: {deleted_count}")

        if deleted_objects:
            print("\n📋 تفاصيل الحذف حسب النوع:")
            for model, count in sorted(deleted_objects.items()):
                # استخراج اسم Model
                model_name = model.split('.')[-1]

                # ترجمة أسماء Models
                model_names_ar = {
                    'Booking': 'حجوزات',
                    'Rating': 'تقييمات',
                    'BookingNotification': 'إشعارات الحجوزات',
                    'Conversation': 'محادثات',
                    'Message': 'رسائل',
                    'WorkerOffer': 'عروض العمال',
                }

                model_name_ar = model_names_ar.get(model_name, model_name)
                print(f"   ✓ {model_name_ar} ({model_name}): {count}")

        print("\n" + "="*70 + "\n")
        return True

    except Exception as e:
        print(f"\n❌ فشل الحذف: {e}")
        print(f"💡 الخطأ: {str(e)}\n")
        return False


def verify_deletion():
    """التحقق من نجاح عملية الحذف"""
    print("🔍 التحقق من نجاح الحذف...")

    try:
        remaining_count = Booking.objects.count()

        if remaining_count == 0:
            print("✅ تم التحقق: Database نظيفة (0 حجوزات متبقية)\n")
            return True
        else:
            print(f"⚠️ تحذير: لا يزال هناك {remaining_count} حجز في Database!\n")
            return False
    except Exception as e:
        print(f"❌ فشل التحقق: {e}\n")
        return False


def main():
    """الدالة الرئيسية"""
    print_header()

    # التحقق من Arguments
    args = sys.argv[1:]
    auto_confirm = '--confirm' in args
    create_backup_flag = '--backup' in args or '--confirm' not in args

    # الحصول على الإحصائيات
    stats = get_booking_stats()

    if not stats:
        print("✅ Database نظيفة بالفعل (لا توجد حجوزات للحذف)")
        print("="*70 + "\n")
        return

    # عرض الإحصائيات
    print_stats(stats)
    print()

    # إنشاء نسخة احتياطية
    backup_file = None
    if create_backup_flag:
        backup_file = create_backup()

    # طلب التأكيد
    if not auto_confirm:
        print("="*70)
        print("⚠️  تحذير: هذا الإجراء سيحذف جميع البيانات بشكل نهائي!")
        print("="*70 + "\n")

        response = input(f"❓ هل أنت متأكد من حذف جميع الـ {stats['total']} حجز؟ (yes/no): ")

        if response.lower() != 'yes':
            print("\n❌ تم إلغاء عملية الحذف.")
            print("="*70 + "\n")
            return

    # الحذف
    success = delete_all_bookings()

    if not success:
        print("💡 يمكنك استعادة البيانات من النسخة الاحتياطية:")
        if backup_file:
            print(f"   python manage.py loaddata {backup_file}\n")
        return

    # التحقق من النجاح
    verify_deletion()

    # رسالة النجاح
    print("🎉 تمت العملية بنجاح!")

    if backup_file:
        print(f"\n💾 النسخة الاحتياطية محفوظة في: {backup_file}")
        print("📝 لاستعادة البيانات:")
        print(f"   python manage.py loaddata {backup_file}")

    print("\n" + "="*70 + "\n")


def print_usage():
    """طباعة معلومات الاستخدام"""
    print("\n" + "="*70)
    print("🗑️  سكريبت حذف جميع الحجوزات - Amina Platform")
    print("="*70 + "\n")

    print("الاستخدام:")
    print("  python delete_all_bookings.py                 # حذف مع تأكيد ونسخة احتياطية")
    print("  python delete_all_bookings.py --confirm       # حذف مباشر بدون تأكيد")
    print("  python delete_all_bookings.py --backup        # نسخة احتياطية فقط\n")

    print("الخيارات:")
    print("  --confirm     حذف مباشر بدون طلب تأكيد")
    print("  --backup      إنشاء نسخة احتياطية قبل الحذف")
    print("  --help        عرض هذه الرسالة\n")

    print("أمثلة:")
    print("  # حذف مع تأكيد")
    print("  python delete_all_bookings.py")
    print()
    print("  # حذف مباشر")
    print("  python delete_all_bookings.py --confirm")
    print()
    print("  # حذف مع نسخة احتياطية")
    print("  python delete_all_bookings.py --backup --confirm\n")

    print("⚠️  تحذير: هذا الإجراء سيحذف:")
    print("   - جميع الحجوزات")
    print("   - التقييمات المرتبطة")
    print("   - الإشعارات المرتبطة")
    print("   - المحادثات المرتبطة")
    print("   - جميع البيانات ذات الصلة\n")

    print("💡 نصيحة: احرص على أخذ نسخة احتياطية قبل الحذف!")
    print("="*70 + "\n")


if __name__ == "__main__":
    # التحقق من طلب المساعدة
    if '--help' in sys.argv or '-h' in sys.argv:
        print_usage()
        sys.exit(0)

    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ تم إلغاء العملية بواسطة المستخدم.")
        print("="*70 + "\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ خطأ غير متوقع: {e}")
        print("="*70 + "\n")
        sys.exit(1)
