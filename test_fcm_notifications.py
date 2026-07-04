#!/usr/bin/env python3
"""
🔔 سكريبت اختبار شامل لإشعارات FCM - Amina Platform
يدعم جميع أنواع الإشعارات والأصوات المخصصة

الاستخدام:
    python test_fcm_notifications.py <FCM_TOKEN>
    python test_fcm_notifications.py <FCM_TOKEN> --test chat
    python test_fcm_notifications.py <FCM_TOKEN> --test all

المتطلبات:
    pip install firebase-admin
"""

import firebase_admin
from firebase_admin import credentials, messaging
import sys
import os
from datetime import datetime


def initialize_firebase():
    """تهيئة Firebase Admin SDK"""
    # ⚠️ استبدل بمسار ملف credentials الخاص بك
    # يمكنك تحميله من Firebase Console:
    # Project Settings > Service Accounts > Generate New Private Key

    # ابحث عن ملف serviceAccountKey.json في المجلد الحالي
    cred_path = 'serviceAccountKey.json'

    if not os.path.exists(cred_path):
        print("⚠️ ملف serviceAccountKey.json غير موجود!")
        print("📥 يرجى تحميل Service Account Key من Firebase Console:")
        print("   1. افتح Firebase Console")
        print("   2. اذهب إلى Project Settings > Service Accounts")
        print("   3. اضغط على 'Generate New Private Key'")
        print("   4. احفظ الملف باسم 'serviceAccountKey.json' في نفس المجلد\n")

        # محاولة استخدام متغير البيئة
        if 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
            cred_path = os.environ['GOOGLE_APPLICATION_CREDENTIALS']
            print(f"✅ استخدام credentials من: {cred_path}")
        else:
            sys.exit(1)

    try:
        cred = credentials.Certificate(cred_path)

        # تحقق إذا كان Firebase مُهيأ مسبقاً
        try:
            firebase_admin.get_app()
            print("✅ Firebase Admin SDK already initialized")
        except ValueError:
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialized successfully")

        return True
    except Exception as e:
        print(f"❌ خطأ في تهيئة Firebase: {e}")
        return False


def send_chat_notification(fcm_token, sender_name="أحمد"):
    """
    إرسال إشعار رسالة شات
    الصوت المتوقع: chat_sound.mp3 (صوت قصير ومميز)
    """
    print("\n" + "="*60)
    print("💬 اختبار إشعار الشات")
    print("="*60)
    print(f"📱 Token: {fcm_token[:30]}...")
    print(f"👤 المرسل: {sender_name}")
    print(f"🔊 الصوت المتوقع: chat_sound.mp3")
    print(f"📳 نمط الاهتزاز: سريع (300ms)")

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"💬 رسالة جديدة من {sender_name}",
            body="مرحباً! كيف حالك؟ هل أنت جاهز لبدء الخدمة؟",
        ),
        data={
            'notification_type': 'NEW_MESSAGE',
            'type': 'chat',
            'conversation_id': '123',
            'sender_id': '456',
            'sender_name': sender_name,
            'message_preview': 'مرحباً! كيف حالك؟',
            'timestamp': str(int(datetime.now().timestamp())),
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_chat_v2',
                sound='default',  # سيستخدم chat_sound.mp3
                color='#8B5CF6',
                icon='ic_launcher',
                priority='max',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"\n✅ تم إرسال إشعار الشات بنجاح!")
        print(f"📝 Message ID: {response}")
        print(f"⏰ الوقت: {datetime.now().strftime('%H:%M:%S')}")
        return True
    except Exception as e:
        print(f"\n❌ فشل إرسال إشعار الشات!")
        print(f"💥 الخطأ: {e}")
        return False


def send_booking_notification(fcm_token, client_name="سارة", service_name="تنظيف منزل"):
    """
    إرسال إشعار حجز جديد
    الصوت المتوقع: notification_sound.mp3 (صوت هادئ)
    """
    print("\n" + "="*60)
    print("📅 اختبار إشعار الحجز")
    print("="*60)
    print(f"📱 Token: {fcm_token[:30]}...")
    print(f"👤 العميل: {client_name}")
    print(f"🛠️ الخدمة: {service_name}")
    print(f"🔊 الصوت المتوقع: notification_sound.mp3")
    print(f"📳 نمط الاهتزاز: طويل (500ms)")

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"📅 حجز جديد من {client_name}",
            body=f"خدمة: {service_name}\nالتاريخ: 20 نوفمبر 2025\nالوقت: 10:00 صباحاً",
        ),
        data={
            'notification_type': 'BOOKING_CONFIRMED',
            'type': 'booking',
            'booking_id': '789',
            'client_name': client_name,
            'service_name': service_name,
            'booking_date': '2025-11-20',
            'booking_time': '10:00',
            'timestamp': str(int(datetime.now().timestamp())),
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_urgent_v2',
                sound='default',  # سيستخدم notification_sound.mp3
                color='#10B981',
                icon='ic_launcher',
                priority='max',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"\n✅ تم إرسال إشعار الحجز بنجاح!")
        print(f"📝 Message ID: {response}")
        print(f"⏰ الوقت: {datetime.now().strftime('%H:%M:%S')}")
        return True
    except Exception as e:
        print(f"\n❌ فشل إرسال إشعار الحجز!")
        print(f"💥 الخطأ: {e}")
        return False


def send_payment_notification(fcm_token, amount=250.00):
    """
    إرسال إشعار دفع ناجح
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*60)
    print("💰 اختبار إشعار الدفع")
    print("="*60)
    print(f"📱 Token: {fcm_token[:30]}...")
    print(f"💵 المبلغ: {amount} جنيه")
    print(f"🔊 الصوت المتوقع: notification_sound.mp3")

    message = messaging.Message(
        notification=messaging.Notification(
            title="✅ تم الدفع بنجاح",
            body=f"تم دفع {amount} جنيه للحجز رقم #789\nيمكنك الآن بدء تقديم الخدمة.",
        ),
        data={
            'notification_type': 'PAYMENT_SUCCESS',
            'type': 'payment',
            'amount': str(amount),
            'booking_id': '789',
            'timestamp': str(int(datetime.now().timestamp())),
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_urgent_v2',
                sound='default',
                color='#10B981',
                icon='ic_launcher',
                priority='max',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"\n✅ تم إرسال إشعار الدفع بنجاح!")
        print(f"📝 Message ID: {response}")
        print(f"⏰ الوقت: {datetime.now().strftime('%H:%M:%S')}")
        return True
    except Exception as e:
        print(f"\n❌ فشل إرسال إشعار الدفع!")
        print(f"💥 الخطأ: {e}")
        return False


def send_offer_notification(fcm_token, provider_name="محمد", price=200.00):
    """
    إرسال إشعار عرض جديد من مقدم خدمة
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*60)
    print("💼 اختبار إشعار العرض")
    print("="*60)
    print(f"📱 Token: {fcm_token[:30]}...")
    print(f"👤 مقدم الخدمة: {provider_name}")
    print(f"💵 السعر المقترح: {price} جنيه")
    print(f"🔊 الصوت المتوقع: notification_sound.mp3")

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"💰 عرض جديد من {provider_name}",
            body=f"السعر المقترح: {price} جنيه\nلديك عرض جديد على طلب الحجز الخاص بك.",
        ),
        data={
            'notification_type': 'OFFER_SUBMITTED',
            'type': 'offer',
            'provider_name': provider_name,
            'price': str(price),
            'offer_id': '456',
            'timestamp': str(int(datetime.now().timestamp())),
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_notifications_v2',
                sound='default',
                color='#8B5CF6',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"\n✅ تم إرسال إشعار العرض بنجاح!")
        print(f"📝 Message ID: {response}")
        print(f"⏰ الوقت: {datetime.now().strftime('%H:%M:%S')}")
        return True
    except Exception as e:
        print(f"\n❌ فشل إرسال إشعار العرض!")
        print(f"💥 الخطأ: {e}")
        return False


def send_data_only_notification(fcm_token):
    """
    إرسال Data-Only notification (بدون notification payload)
    لاختبار استخراج title/body من data
    """
    print("\n" + "="*60)
    print("🔬 اختبار Data-Only Notification")
    print("="*60)
    print(f"📱 Token: {fcm_token[:30]}...")
    print(f"⚠️ هذا اختبار خاص: لا يوجد notification payload")
    print(f"📝 سيتم استخراج title/body من data")
    print(f"🔊 الصوت المتوقع: chat_sound.mp3")

    message = messaging.Message(
        data={
            'notification_type': 'NEW_MESSAGE',
            'type': 'chat',
            'title': '🔬 رسالة اختبار (Data-Only)',  # ✅ مهم!
            'body': 'هذا إشعار يستخدم data فقط بدون notification payload. إذا ظهر، فالنظام يعمل بشكل صحيح!',  # ✅ مهم!
            'conversation_id': '999',
            'timestamp': str(int(datetime.now().timestamp())),
        },
        android=messaging.AndroidConfig(
            priority='high',
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"\n✅ تم إرسال Data-Only notification بنجاح!")
        print(f"📝 Message ID: {response}")
        print(f"⏰ الوقت: {datetime.now().strftime('%H:%M:%S')}")
        print(f"\n💡 ملاحظة: إذا ظهر الإشعار، فهذا يعني أن:")
        print(f"   ✅ استخراج title/body من data يعمل بشكل صحيح")
        print(f"   ✅ Background handler يدعم Data-Only messages")
        return True
    except Exception as e:
        print(f"\n❌ فشل إرسال Data-Only notification!")
        print(f"💥 الخطأ: {e}")
        return False


def send_general_notification(fcm_token, title="🔔 إشعار عام", body="هذا إشعار تجريبي"):
    """
    إرسال إشعار عام
    الصوت المتوقع: notification_sound.mp3
    """
    print("\n" + "="*60)
    print("🔔 اختبار إشعار عام")
    print("="*60)
    print(f"📱 Token: {fcm_token[:30]}...")
    print(f"📝 العنوان: {title}")
    print(f"🔊 الصوت المتوقع: notification_sound.mp3")

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            'notification_type': 'GENERAL',
            'type': 'general',
            'timestamp': str(int(datetime.now().timestamp())),
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='amina_notifications_v2',
                sound='default',
                color='#8B5CF6',
                icon='ic_launcher',
            ),
        ),
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"\n✅ تم إرسال الإشعار العام بنجاح!")
        print(f"📝 Message ID: {response}")
        print(f"⏰ الوقت: {datetime.now().strftime('%H:%M:%S')}")
        return True
    except Exception as e:
        print(f"\n❌ فشل إرسال الإشعار العام!")
        print(f"💥 الخطأ: {e}")
        return False


def run_all_tests(fcm_token):
    """تشغيل جميع الاختبارات بالترتيب"""
    print("\n" + "🚀"*30)
    print("بدء اختبار شامل لنظام الإشعارات - Amina Platform")
    print("🚀"*30 + "\n")

    print(f"📱 FCM Token: {fcm_token[:40]}...")
    print(f"⏰ وقت البدء: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"\n{'='*60}")
    print("📋 سيتم اختبار 6 أنواع من الإشعارات:")
    print("   1. رسالة شات (chat_sound.mp3)")
    print("   2. حجز جديد (notification_sound.mp3)")
    print("   3. دفع ناجح (notification_sound.mp3)")
    print("   4. عرض جديد (notification_sound.mp3)")
    print("   5. Data-Only (chat_sound.mp3)")
    print("   6. إشعار عام (notification_sound.mp3)")
    print(f"{'='*60}\n")

    input("اضغط Enter للمتابعة...")

    results = {
        'رسالة شات': send_chat_notification(fcm_token),
        'حجز جديد': send_booking_notification(fcm_token),
        'دفع ناجح': send_payment_notification(fcm_token),
        'عرض جديد': send_offer_notification(fcm_token),
        'Data-Only': send_data_only_notification(fcm_token),
        'إشعار عام': send_general_notification(fcm_token),
    }

    print("\n" + "="*60)
    print("📊 ملخص النتائج:")
    print("="*60)

    for test_name, success in results.items():
        status = "✅ نجح" if success else "❌ فشل"
        print(f"{status:10} | {test_name}")

    total = len(results)
    passed = sum(results.values())

    print("\n" + "="*60)
    print(f"النتيجة النهائية: {passed}/{total} اختبار نجح ({passed*100//total}%)")
    print(f"⏰ وقت الانتهاء: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60 + "\n")

    if passed == total:
        print("🎉 مبروك! جميع الاختبارات نجحت!")
        print("✅ نظام الإشعارات يعمل بشكل ممتاز!")
    else:
        print(f"⚠️ بعض الاختبارات فشلت ({total - passed} من {total})")
        print("💡 تحقق من:")
        print("   - FCM Token صحيح")
        print("   - Firebase Admin SDK معد بشكل صحيح")
        print("   - التطبيق مثبت على الموبايل")
        print("   - الأذونات ممنوحة")

    return passed == total


def print_usage():
    """طباعة معلومات الاستخدام"""
    print("\n" + "="*60)
    print("🔔 سكريبت اختبار إشعارات FCM - Amina Platform")
    print("="*60 + "\n")

    print("الاستخدام:")
    print("  python test_fcm_notifications.py <FCM_TOKEN>")
    print("  python test_fcm_notifications.py <FCM_TOKEN> --test <TYPE>\n")

    print("أمثلة:")
    print("  python test_fcm_notifications.py YOUR_FCM_TOKEN")
    print("  python test_fcm_notifications.py YOUR_FCM_TOKEN --test all")
    print("  python test_fcm_notifications.py YOUR_FCM_TOKEN --test chat")
    print("  python test_fcm_notifications.py YOUR_FCM_TOKEN --test booking\n")

    print("أنواع الاختبارات المتاحة:")
    print("  all        - تشغيل جميع الاختبارات")
    print("  chat       - اختبار إشعار الشات")
    print("  booking    - اختبار إشعار الحجز")
    print("  payment    - اختبار إشعار الدفع")
    print("  offer      - اختبار إشعار العرض")
    print("  data_only  - اختبار Data-Only notification")
    print("  general    - اختبار إشعار عام\n")

    print("المتطلبات:")
    print("  pip install firebase-admin\n")

    print("ملاحظات:")
    print("  - ضع ملف serviceAccountKey.json في نفس المجلد")
    print("  - أو استخدم متغير البيئة GOOGLE_APPLICATION_CREDENTIALS")
    print("="*60 + "\n")


def main():
    """الدالة الرئيسية"""
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    fcm_token = sys.argv[1]

    # تهيئة Firebase
    if not initialize_firebase():
        sys.exit(1)

    # تحديد نوع الاختبار
    if len(sys.argv) > 3 and sys.argv[2] == '--test':
        test_type = sys.argv[3].lower()

        tests = {
            'chat': lambda: send_chat_notification(fcm_token),
            'booking': lambda: send_booking_notification(fcm_token),
            'payment': lambda: send_payment_notification(fcm_token),
            'offer': lambda: send_offer_notification(fcm_token),
            'data_only': lambda: send_data_only_notification(fcm_token),
            'general': lambda: send_general_notification(fcm_token),
            'all': lambda: run_all_tests(fcm_token),
        }

        if test_type in tests:
            success = tests[test_type]()
            sys.exit(0 if success else 1)
        else:
            print(f"❌ نوع اختبار غير معروف: {test_type}")
            print(f"الأنواع المتاحة: {', '.join(tests.keys())}")
            sys.exit(1)
    else:
        # تشغيل جميع الاختبارات افتراضياً
        success = run_all_tests(fcm_token)
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
