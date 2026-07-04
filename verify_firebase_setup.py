#!/usr/bin/env python3
"""
🔥 سكريبت التحقق من إعداد Firebase - Amina Platform

يتحقق من:
1. وجود ملف Service Account Key
2. صحة محتوى الملف
3. تهيئة Firebase Admin SDK
4. إمكانية إرسال إشعارات

الاستخدام:
    python verify_firebase_setup.py
    python verify_firebase_setup.py --send-test
"""

import os
import sys
import json
import django
from pathlib import Path

# إعداد Django environment
try:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'AminaPlatform.settings')
    django.setup()
except Exception as e:
    print(f"❌ خطأ في إعداد Django: {e}")
    sys.exit(1)

from django.conf import settings
import firebase_admin
from firebase_admin import credentials


def print_header():
    """طباعة Header السكريبت"""
    print("\n" + "="*70)
    print("🔥 التحقق من إعداد Firebase - Amina Platform")
    print("="*70 + "\n")


def check_file_exists():
    """التحقق من وجود ملف Service Account Key"""
    print("📁 الخطوة 1: التحقق من وجود ملف الاعتماد...")

    firebase_creds_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)

    if not firebase_creds_path:
        print("❌ FIREBASE_CREDENTIALS_PATH غير موجود في settings.py")
        return False

    print(f"   المسار المتوقع: {firebase_creds_path}")

    file_exists = Path(firebase_creds_path).exists()

    if file_exists:
        file_size = os.path.getsize(firebase_creds_path)
        print(f"✅ الملف موجود!")
        print(f"   الحجم: {file_size} bytes")
        return True
    else:
        print("❌ الملف غير موجود!")
        print("\n💡 لإصلاح المشكلة:")
        print("   1. حمّل Service Account Key من Firebase Console")
        print("   2. احفظه في المسار أعلاه")
        print("   3. شغّل هذا السكريبت مرة أخرى")
        return False


def validate_json_content():
    """التحقق من صحة محتوى JSON"""
    print("\n📄 الخطوة 2: التحقق من صحة محتوى الملف...")

    firebase_creds_path = settings.FIREBASE_CREDENTIALS_PATH

    try:
        with open(firebase_creds_path, 'r') as f:
            data = json.load(f)

        # التحقق من الحقول المطلوبة
        required_fields = [
            'type',
            'project_id',
            'private_key_id',
            'private_key',
            'client_email',
            'client_id',
            'auth_uri',
            'token_uri'
        ]

        missing_fields = []
        for field in required_fields:
            if field not in data:
                missing_fields.append(field)

        if missing_fields:
            print(f"❌ الحقول المفقودة: {', '.join(missing_fields)}")
            return False

        # التحقق من النوع
        if data.get('type') != 'service_account':
            print(f"❌ نوع الملف خطأ: {data.get('type')} (يجب أن يكون: service_account)")
            return False

        print("✅ محتوى الملف صحيح!")
        print(f"   Project ID: {data.get('project_id')}")
        print(f"   Client Email: {data.get('client_email')}")

        return True

    except json.JSONDecodeError as e:
        print(f"❌ خطأ في قراءة JSON: {e}")
        print("   تأكد من أن الملف بصيغة JSON صحيحة")
        return False
    except Exception as e:
        print(f"❌ خطأ: {e}")
        return False


def check_firebase_initialization():
    """التحقق من تهيئة Firebase"""
    print("\n🔥 الخطوة 3: التحقق من تهيئة Firebase Admin SDK...")

    # عدد التطبيقات المهيأة
    initialized_apps = len(firebase_admin._apps)

    print(f"   عدد تطبيقات Firebase المهيأة: {initialized_apps}")

    if initialized_apps == 0:
        print("⚠️ Firebase غير مهيأ. جاري التهيئة...")

        try:
            cred = credentials.Certificate(str(settings.FIREBASE_CREDENTIALS_PATH))
            firebase_admin.initialize_app(cred)
            print("✅ تمت التهيئة بنجاح!")
            return True
        except Exception as e:
            print(f"❌ فشلت التهيئة: {e}")
            return False
    else:
        print("✅ Firebase مهيأ بالفعل!")
        return True


def check_fcm_service():
    """التحقق من FCM Service"""
    print("\n📨 الخطوة 4: التحقق من خدمة الإشعارات...")

    try:
        from users.fcm_service import FCMNotificationService

        # محاولة التهيئة
        FCMNotificationService.initialize()

        print("✅ خدمة الإشعارات جاهزة!")
        return True

    except ImportError:
        print("❌ لا يمكن استيراد FCMNotificationService")
        print("   تأكد من وجود ملف users/fcm_service.py")
        return False
    except Exception as e:
        print(f"⚠️ تحذير: {e}")
        return True  # لا نعتبرها خطأ فادح


def check_fcm_devices():
    """التحقق من وجود أجهزة FCM مسجلة"""
    print("\n📱 الخطوة 5: التحقق من الأجهزة المسجلة...")

    try:
        from users.models import FCMDevice

        total_devices = FCMDevice.objects.count()
        active_devices = FCMDevice.objects.filter(is_active=True).count()

        print(f"   إجمالي الأجهزة: {total_devices}")
        print(f"   الأجهزة النشطة: {active_devices}")

        if active_devices > 0:
            print("✅ يوجد أجهزة جاهزة لاستقبال الإشعارات!")

            # عرض بعض الأجهزة
            devices = FCMDevice.objects.filter(is_active=True)[:3]
            print("\n   أمثلة على الأجهزة المسجلة:")
            for device in devices:
                print(f"   - {device.user.email} ({device.device_type})")

            return True
        else:
            print("⚠️ لا توجد أجهزة نشطة مسجلة")
            print("   سجل دخول من Flutter App لتسجيل جهاز")
            return False

    except Exception as e:
        print(f"❌ خطأ: {e}")
        return False


def send_test_notification():
    """إرسال إشعار تجريبي"""
    print("\n🧪 الخطوة 6: إرسال إشعار تجريبي...")

    try:
        from users.models import FCMDevice
        from users.fcm_service import FCMNotificationService

        # احصل على جهاز نشط للاختبار
        device = FCMDevice.objects.filter(is_active=True).first()

        if not device:
            print("⚠️ لا توجد أجهزة نشطة للاختبار")
            return False

        print(f"   الجهاز المستهدف: {device.user.email}")
        print(f"   نوع الجهاز: {device.device_type}")

        # إرسال إشعار
        result = FCMNotificationService.send_notification(
            user=device.user,
            title="🔔 اختبار Firebase",
            body="تم إعداد Firebase بنجاح! الإشعارات تعمل الآن.",
            data={
                'type': 'test',
                'notification_type': 'TEST_NOTIFICATION',
                'priority': 'high'
            }
        )

        if result and result.get('success'):
            print("✅ تم إرسال الإشعار بنجاح!")
            print(f"   Message ID: {result.get('message_id', 'N/A')[:50]}...")
            print("\n📱 تحقق من هاتفك لرؤية الإشعار!")
            return True
        else:
            print(f"❌ فشل إرسال الإشعار: {result}")
            return False

    except Exception as e:
        print(f"❌ خطأ: {e}")
        import traceback
        traceback.print_exc()
        return False


def print_summary(results):
    """طباعة ملخص النتائج"""
    print("\n" + "="*70)
    print("📊 ملخص التحقق:")
    print("="*70)

    checks = [
        ("وجود ملف الاعتماد", results.get('file_exists', False)),
        ("صحة محتوى JSON", results.get('json_valid', False)),
        ("تهيئة Firebase", results.get('firebase_init', False)),
        ("خدمة الإشعارات", results.get('fcm_service', False)),
        ("الأجهزة المسجلة", results.get('devices', False)),
    ]

    if results.get('test_sent'):
        checks.append(("إرسال إشعار تجريبي", results.get('test_sent', False)))

    for check_name, status in checks:
        status_icon = "✅" if status else "❌"
        print(f"   {status_icon} {check_name}")

    all_passed = all(result for result in results.values())

    print("\n" + "="*70)
    if all_passed:
        print("🎉 جميع الاختبارات نجحت!")
        print("✅ Firebase مهيأ بشكل صحيح والإشعارات جاهزة للعمل!")
    else:
        print("⚠️ بعض الاختبارات فشلت")
        print("راجع الخطوات أعلاه لإصلاح المشاكل")
    print("="*70 + "\n")


def main():
    """الدالة الرئيسية"""
    print_header()

    # التحقق من Arguments
    send_test = '--send-test' in sys.argv

    results = {}

    # 1. التحقق من وجود الملف
    results['file_exists'] = check_file_exists()
    if not results['file_exists']:
        print_summary(results)
        return

    # 2. التحقق من صحة JSON
    results['json_valid'] = validate_json_content()
    if not results['json_valid']:
        print_summary(results)
        return

    # 3. التحقق من تهيئة Firebase
    results['firebase_init'] = check_firebase_initialization()
    if not results['firebase_init']:
        print_summary(results)
        return

    # 4. التحقق من FCM Service
    results['fcm_service'] = check_fcm_service()

    # 5. التحقق من الأجهزة
    results['devices'] = check_fcm_devices()

    # 6. إرسال إشعار تجريبي (اختياري)
    if send_test and results['devices']:
        results['test_sent'] = send_test_notification()
    else:
        if send_test and not results['devices']:
            print("\n⚠️ لا يمكن إرسال إشعار تجريبي بدون أجهزة مسجلة")

    # طباعة الملخص
    print_summary(results)

    # نصائح إضافية
    if all(results.values()):
        print("💡 نصائح:")
        print("   - جرب إرسال إشعار من Flutter App")
        print("   - تأكد من سماع صوت الإشعار")
        print("   - صوت الشات: chat_sound.mp3")
        print("   - صوت الإشعارات: notification_sound.mp3")
        print()


def print_usage():
    """طباعة معلومات الاستخدام"""
    print("\n" + "="*70)
    print("🔥 سكريبت التحقق من إعداد Firebase - Amina Platform")
    print("="*70 + "\n")

    print("الاستخدام:")
    print("  python verify_firebase_setup.py              # تحقق من الإعداد فقط")
    print("  python verify_firebase_setup.py --send-test  # تحقق وأرسل إشعار تجريبي")
    print("  python verify_firebase_setup.py --help       # عرض هذه الرسالة\n")

    print("الوصف:")
    print("  يتحقق هذا السكريبت من:")
    print("  1. وجود ملف Service Account Key")
    print("  2. صحة محتوى JSON")
    print("  3. تهيئة Firebase Admin SDK")
    print("  4. جاهزية خدمة الإشعارات")
    print("  5. وجود أجهزة مسجلة")
    print("  6. (اختياري) إرسال إشعار تجريبي\n")

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
        import traceback
        traceback.print_exc()
        print("="*70 + "\n")
        sys.exit(1)
