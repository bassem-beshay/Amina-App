# 🗑️ دليل حذف البيانات من السيرفر - Amina Platform

## Server: amina.bdcbiz.com

---

## 🚀 طريقة التنفيذ السريعة:

### الطريقة 1: من Django Admin (الأسهل) ⭐

```
1. افتح الرابط:
   https://amina.bdcbiz.com/admin/bookings/booking/

2. سجل الدخول كـ Admin

3. حدد جميع الحجوزات:
   ☑️ اضغط على المربع في رأس الجدول

4. اختر Action:
   من القائمة اختر "Delete selected bookings"

5. تأكيد:
   اضغط "Yes, I'm sure"

✅ انتهى! تم الحذف
```

---

## الطريقة 2: SSH + Django Shell (سريعة جداً)

### الخطوات:

```bash
# 1. اتصل بالسيرفر
ssh your_user@amina.bdcbiz.com

# 2. اذهب لمجلد المشروع
cd /path/to/AminaPlatform

# 3. فعّل virtual environment
source venv/bin/activate
# أو
source /home/aminauser/venv/bin/activate

# 4. افتح Django Shell
python manage.py shell

# 5. احذف الكل
from bookings.models import Booking
Booking.objects.all().delete()

# 6. اخرج من Shell
exit()
```

**النتيجة:**
```python
(XXX, {'bookings.Booking': XXX, ...})
```

---

## الطريقة 3: استخدام السكريبت (موصى به)

### التحضير:

```bash
# 1. اتصل بالسيرفر
ssh your_user@amina.bdcbiz.com

# 2. ارفع السكريبت للسيرفر
# من جهازك المحلي:
scp delete_bookings_server.sh your_user@amina.bdcbiz.com:/tmp/

# أو
# انسخ محتوى الملف يدوياً وأنشئه على السيرفر:
nano /tmp/delete_bookings_server.sh
# (الصق المحتوى)
```

### تعديل إعدادات السكريبت:

```bash
# افتح السكريبت
nano /tmp/delete_bookings_server.sh

# عدّل السطور التالية (في بداية الملف):
PROJECT_DIR="/home/aminauser/AminaPlatform"  # مسار المشروع
VENV_PATH="/home/aminauser/venv"             # مسار virtual environment

# احفظ: Ctrl+O ثم Enter
# اخرج: Ctrl+X
```

### إعطاء صلاحية التنفيذ:

```bash
chmod +x /tmp/delete_bookings_server.sh
```

### التشغيل:

```bash
# الطريقة العادية (مع تأكيد ونسخة احتياطية)
/tmp/delete_bookings_server.sh

# حذف مباشر بدون تأكيد
/tmp/delete_bookings_server.sh --confirm

# بدون نسخة احتياطية (غير موصى به)
/tmp/delete_bookings_server.sh --confirm --no-backup

# عرض المساعدة
/tmp/delete_bookings_server.sh --help
```

---

## 💾 نسخة احتياطية قبل الحذف:

### من السيرفر:

```bash
# اذهب لمجلد المشروع
cd /path/to/AminaPlatform

# فعّل virtual environment
source venv/bin/activate

# أنشئ نسخة احتياطية
python manage.py dumpdata bookings.Booking > bookings_backup_$(date +%Y%m%d).json

# تحقق من الملف
ls -lh bookings_backup_*.json
```

### تنزيل النسخة الاحتياطية لجهازك:

```bash
# من جهازك المحلي
scp your_user@amina.bdcbiz.com:/path/to/AminaPlatform/bookings_backup_*.json .
```

### استعادة النسخة الاحتياطية:

```bash
# على السيرفر
cd /path/to/AminaPlatform
source venv/bin/activate
python manage.py loaddata bookings_backup_20251117.json
```

---

## 🔍 التحقق من النتيجة:

### من Django Shell:

```bash
python manage.py shell
```

```python
from bookings.models import Booking
count = Booking.objects.count()
print(f"عدد الحجوزات المتبقية: {count}")
# يجب أن يكون: 0
```

### من Django Admin:

```
افتح: https://amina.bdcbiz.com/admin/bookings/booking/
تحقق: يجب أن تكون الصفحة فارغة
```

---

## 📊 مثال على تشغيل السكريبت:

```bash
$ ./delete_bookings_server.sh

======================================================================
🗑️  سكريبت حذف جميع الحجوزات - Amina Platform
======================================================================

🔍 التحقق من البيئة...

✅ البيئة جاهزة

📊 جاري جلب عدد الحجوزات...

📊 عدد الحجوزات الحالية: 150

💾 جاري إنشاء نسخة احتياطية...

✅ تم إنشاء النسخة الاحتياطية: bookings_backup_20251117_143022.json
📦 حجم الملف: 45K

======================================================================
⚠️  تحذير: هذا الإجراء سيحذف جميع البيانات بشكل نهائي!
======================================================================

❓ هل أنت متأكد من حذف جميع الـ 150 حجز؟ (yes/no): yes

🗑️ جاري الحذف...
⏳ قد يستغرق هذا بعض الوقت...

======================================================================
🗑️  بدء عملية الحذف...
======================================================================

✅ تم الحذف بنجاح!

======================================================================
📊 ملخص عملية الحذف:
======================================================================

📦 إجمالي العناصر المحذوفة: 485

📋 تفاصيل الحذف حسب النوع:
   ✓ Booking: 150
   ✓ BookingNotification: 200
   ✓ Conversation: 85
   ✓ Message: 30
   ✓ Rating: 20

======================================================================

🔍 التحقق من نجاح الحذف...

✅ تم التحقق: Database نظيفة (0 حجوزات متبقية)

======================================================================
🎉 تمت العملية بنجاح!
======================================================================

💾 النسخة الاحتياطية محفوظة في: bookings_backup_20251117_143022.json
📝 لاستعادة البيانات:
   cd /home/aminauser/AminaPlatform
   /home/aminauser/venv/bin/python manage.py loaddata bookings_backup_20251117_143022.json

======================================================================
```

---

## 🛡️ نصائح الأمان:

### ✅ قبل الحذف:

1. **خذ نسخة احتياطية من Database كاملة:**
   ```bash
   # PostgreSQL
   pg_dump -U postgres amina_db > full_backup_$(date +%Y%m%d).sql

   # MySQL
   mysqldump -u root -p amina_db > full_backup_$(date +%Y%m%d).sql
   ```

2. **تأكد من الصلاحيات:**
   ```bash
   # تأكد أنك مسجل دخول كـ admin/superuser
   whoami
   ```

3. **تحقق من البيئة:**
   ```bash
   # تأكد أنك في السيرفر الصحيح
   hostname
   ```

### ⚠️ أثناء الحذف:

- لا تقاطع العملية
- راقب Logs للتأكد من عدم وجود أخطاء
- تأكد من اتصال Database

### ✅ بعد الحذف:

1. **تحقق من النتيجة:**
   ```bash
   python manage.py shell
   from bookings.models import Booking
   Booking.objects.count()  # يجب أن يكون 0
   ```

2. **احتفظ بالنسخة الاحتياطية:**
   ```bash
   # انقل النسخة الاحتياطية لمكان آمن
   mv bookings_backup_*.json ~/backups/
   ```

---

## 🚨 حل المشاكل:

### المشكلة: "Permission denied"

```bash
# الحل: أعط صلاحية التنفيذ
chmod +x delete_bookings_server.sh
```

### المشكلة: "manage.py not found"

```bash
# الحل: عدّل PROJECT_DIR في السكريبت
nano delete_bookings_server.sh
# غيّر السطر:
PROJECT_DIR="/home/aminauser/AminaPlatform"  # المسار الصحيح
```

### المشكلة: "No module named 'bookings'"

```bash
# الحل: تأكد من تفعيل virtual environment
source /path/to/venv/bin/activate
```

### المشكلة: "Database connection error"

```bash
# الحل: تحقق من Database settings
python manage.py check
```

---

## 📝 ملخص الأوامر:

```bash
# اتصل بالسيرفر
ssh your_user@amina.bdcbiz.com

# الطريقة السريعة (Django Shell)
cd /path/to/AminaPlatform
source venv/bin/activate
python manage.py shell
>>> from bookings.models import Booking
>>> Booking.objects.all().delete()
>>> exit()

# الطريقة الآمنة (مع نسخة احتياطية)
python manage.py dumpdata bookings.Booking > backup.json
python manage.py shell
>>> from bookings.models import Booking
>>> Booking.objects.all().delete()
```

---

## ⏱️ الوقت المتوقع:

| عدد الحجوزات | الوقت المتوقع |
|--------------|---------------|
| < 100 | 5-10 ثواني |
| 100-1000 | 10-30 ثانية |
| 1000-10000 | 30 ثانية - 2 دقيقة |
| > 10000 | 2-5 دقائق |

---

## ✅ التوصية النهائية:

**أسهل طريقة:**

1. افتح Django Admin: https://amina.bdcbiz.com/admin/bookings/booking/
2. حدد الكل → Delete selected bookings
3. تأكيد
4. ✅ انتهى!

**أسرع طريقة (من SSH):**

```bash
ssh user@amina.bdcbiz.com
cd /path/to/project
source venv/bin/activate
python manage.py shell -c "from bookings.models import Booking; Booking.objects.all().delete()"
```

---

**⚠️ تذكير أخير: هذا حذف نهائي! احرص على أخذ نسخة احتياطية!**

✅ بعد الحذف، Database ستكون نظيفة وجاهزة للبدء من جديد.
