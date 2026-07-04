# 🗑️ دليل حذف جميع الحجوزات من Django Admin

## التاريخ: 17 نوفمبر 2025

---

## ⚠️ تحذير مهم:

**هذا الإجراء سيحذف جميع البيانات بشكل نهائي ولا يمكن التراجع عنه!**

تأكد من أخذ نسخة احتياطية قبل الحذف.

---

## الطريقة 1: من Django Admin Interface (الأسهل)

### الخطوات:

1. **افتح صفحة الحجوزات:**
   ```
   https://amina.bdcbiz.com/admin/bookings/booking/
   ```

2. **حدد جميع الحجوزات:**
   - ✅ اضغط على المربع في رأس الجدول (Select all)
   - أو ✅ اضغط على رابط "Select all XXX bookings" إذا ظهر

3. **اختر إجراء الحذف:**
   - من قائمة "Action" في الأعلى
   - اختر **"Delete selected bookings"**

4. **تأكيد الحذف:**
   - سيظهر لك صفحة تأكيد تعرض:
     - عدد الحجوزات التي ستُحذف
     - العناصر المرتبطة التي ستُحذف (ratings, notifications, etc.)
   - اضغط **"Yes, I'm sure"** للتأكيد

5. **النتيجة:**
   - ✅ تم حذف جميع الحجوزات
   - ✅ تم حذف جميع البيانات المرتبطة

---

## الطريقة 2: من Django Shell (للحذف السريع)

### الخطوات:

```bash
# 1. افتح Django Shell
python manage.py shell

# 2. استيراد Model
from bookings.models import Booking

# 3. حذف جميع الحجوزات
Booking.objects.all().delete()

# النتيجة:
# (XXX, {'bookings.Booking': XXX, ...})
```

---

## الطريقة 3: من Terminal باستخدام Management Command

### إنشاء Command مخصص:

#### 1. أنشئ ملف Command:

```bash
# المسار:
# your_project/bookings/management/commands/delete_all_bookings.py
```

#### 2. محتوى الملف:

```python
from django.core.management.base import BaseCommand
from bookings.models import Booking


class Command(BaseCommand):
    help = 'Delete all bookings from database'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Confirm deletion without prompt',
        )

    def handle(self, *args, **options):
        count = Booking.objects.count()

        if count == 0:
            self.stdout.write(self.style.WARNING('No bookings to delete.'))
            return

        self.stdout.write(f'Found {count} bookings.')

        if not options['confirm']:
            confirm = input(f'Are you sure you want to delete ALL {count} bookings? (yes/no): ')
            if confirm.lower() != 'yes':
                self.stdout.write(self.style.ERROR('Deletion cancelled.'))
                return

        # حذف جميع الحجوزات
        deleted_count, deleted_objects = Booking.objects.all().delete()

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully deleted {deleted_count} objects:\n'
                f'{deleted_objects}'
            )
        )
```

#### 3. تشغيل الأمر:

```bash
# مع تأكيد
python manage.py delete_all_bookings

# بدون تأكيد (حذف مباشر)
python manage.py delete_all_bookings --confirm
```

---

## الطريقة 4: باستخدام SQL مباشرة (متقدم)

### ⚠️ خطر! استخدم بحذر شديد

```sql
-- 1. اتصل بقاعدة البيانات
psql -U your_user -d your_database
-- أو
mysql -u your_user -p your_database

-- 2. حذف جميع الحجوزات
DELETE FROM bookings_booking;

-- 3. إعادة تعيين Auto Increment (اختياري)
-- PostgreSQL:
ALTER SEQUENCE bookings_booking_id_seq RESTART WITH 1;

-- MySQL:
ALTER TABLE bookings_booking AUTO_INCREMENT = 1;
```

---

## الطريقة 5: سكريبت Python كامل

### `delete_all_bookings.py`

```python
#!/usr/bin/env python3
"""
سكريبت لحذف جميع الحجوزات من Database
"""

import os
import sys
import django

# إعداد Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')
django.setup()

from bookings.models import Booking


def delete_all_bookings(confirm=False):
    """حذف جميع الحجوزات"""
    count = Booking.objects.count()

    if count == 0:
        print('⚠️ لا توجد حجوزات للحذف.')
        return

    print(f'📊 وجدت {count} حجز في Database.')

    if not confirm:
        response = input(f'\n❓ هل أنت متأكد من حذف جميع الـ {count} حجز؟ (yes/no): ')
        if response.lower() != 'yes':
            print('❌ تم إلغاء عملية الحذف.')
            return

    print('\n🗑️ جاري الحذف...')

    try:
        deleted_count, deleted_objects = Booking.objects.all().delete()

        print('\n✅ تم الحذف بنجاح!')
        print(f'\n📊 ملخص الحذف:')
        print(f'   - إجمالي العناصر المحذوفة: {deleted_count}')
        print(f'\n📋 التفاصيل:')
        for model, count in deleted_objects.items():
            print(f'   - {model}: {count}')

    except Exception as e:
        print(f'\n❌ خطأ أثناء الحذف: {e}')
        sys.exit(1)


if __name__ == '__main__':
    # التحقق من وجود --confirm في Arguments
    confirm = '--confirm' in sys.argv

    delete_all_bookings(confirm=confirm)
```

### الاستخدام:

```bash
# مع تأكيد
python delete_all_bookings.py

# بدون تأكيد (حذف مباشر)
python delete_all_bookings.py --confirm
```

---

## 🔄 نسخ احتياطي قبل الحذف:

### Backup باستخدام Django:

```bash
# نسخ احتياطي لجميع البيانات
python manage.py dumpdata bookings.Booking > bookings_backup.json

# أو نسخ احتياطي لجميع تطبيق Bookings
python manage.py dumpdata bookings > bookings_full_backup.json
```

### Backup باستخدام Database:

```bash
# PostgreSQL
pg_dump -U your_user -d your_database -t bookings_booking > bookings_backup.sql

# MySQL
mysqldump -u your_user -p your_database bookings_booking > bookings_backup.sql
```

### استعادة النسخة الاحتياطية:

```bash
# من JSON
python manage.py loaddata bookings_backup.json

# من SQL (PostgreSQL)
psql -U your_user -d your_database < bookings_backup.sql

# من SQL (MySQL)
mysql -u your_user -p your_database < bookings_backup.sql
```

---

## 📊 التحقق بعد الحذف:

### من Django Shell:

```python
from bookings.models import Booking

# عدد الحجوزات
count = Booking.objects.count()
print(f'عدد الحجوزات المتبقية: {count}')

# إذا كان 0، فقد تم الحذف بنجاح
```

### من Django Admin:

```
افتح: https://amina.bdcbiz.com/admin/bookings/booking/
تحقق من: يجب أن تكون الصفحة فارغة (0 bookings)
```

---

## ⚠️ ملاحظات مهمة:

### 1. البيانات المرتبطة:

عند حذف حجز، سيتم حذف:
- ✅ Ratings المرتبطة بالحجز
- ✅ Notifications المرتبطة بالحجز
- ✅ Conversations المرتبطة بالحجز
- ✅ Messages في Conversations
- ✅ أي بيانات أخرى مرتبطة (حسب on_delete)

### 2. لا يمكن التراجع:

- ❌ بمجرد الحذف، لا يمكن استرجاع البيانات
- ✅ احرص على أخذ نسخة احتياطية أولاً

### 3. الصلاحيات:

- تأكد من أن لديك صلاحيات Admin
- تأكد من أنك مسجل الدخول كـ superuser

---

## 🚀 التوصية:

**الطريقة الأسهل والأكثر أماناً:**

1. ✅ خذ نسخة احتياطية:
   ```bash
   python manage.py dumpdata bookings > backup_$(date +%Y%m%d).json
   ```

2. ✅ افتح Django Admin:
   ```
   https://amina.bdcbiz.com/admin/bookings/booking/
   ```

3. ✅ حدد الكل → Delete selected bookings → تأكيد

4. ✅ تحقق من النتيجة

---

## 📞 للمساعدة:

إذا واجهت مشكلة:
- تحقق من Logs: `/var/log/django/error.log`
- تحقق من Database connection
- تحقق من الصلاحيات

---

**⚠️ مرة أخرى: هذا حذف نهائي! تأكد من أخذ نسخة احتياطية!**

**✅ بعد الحذف، ستكون Database نظيفة وجاهزة للبدء من جديد.**
