"""
خدمة إرسال الإشعارات عبر Firebase Cloud Messaging
تم التعديل: إرسال data-only notifications للتحكم الكامل من Flutter
"""
import logging
from typing import List, Dict, Optional
from datetime import datetime
from django.conf import settings
from .fcm_models import FCMDevice, NotificationLog

logger = logging.getLogger(__name__)

# محاولة استيراد Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    logger.warning("Firebase Admin SDK not installed. Install with: pip install firebase-admin")


class FCMService:
    """
    خدمة إرسال الإشعارات عبر FCM
    """
    _initialized = False

    @classmethod
    def initialize(cls):
        """
        تهيئة Firebase Admin SDK
        """
        if not FIREBASE_AVAILABLE:
            return

        # تحقق من التهيئة عن طريق firebase_admin مباشرة
        if len(firebase_admin._apps) > 0:
            cls._initialized = True
            return

        if cls._initialized:
            return

        try:
            # التحقق من وجود ملف credentials
            if hasattr(settings, 'FIREBASE_CREDENTIALS_PATH'):
                cred = credentials.Certificate(str(settings.FIREBASE_CREDENTIALS_PATH))
                firebase_admin.initialize_app(cred)
                cls._initialized = True
                logger.info("✅ Firebase Admin SDK initialized successfully")
            else:
                logger.warning("⚠️ FIREBASE_CREDENTIALS_PATH not found in settings")
        except ValueError as e:
            # Firebase already initialized
            if "already exists" in str(e):
                cls._initialized = True
                logger.info("✅ Firebase Admin SDK already initialized")
            else:
                logger.error(f"❌ Error initializing Firebase Admin SDK: {e}")
        except Exception as e:
            logger.error(f"❌ Error initializing Firebase Admin SDK: {e}")

    @classmethod
    def send_notification(
        cls,
        user,
        title: str,
        body: str,
        notification_type: str = None,
        data: Dict = None,
        sound: str = 'default'
    ) -> Dict:
        """
        إرسال إشعار لمستخدم معين على جميع أجهزته النشطة

        ✅ يتم إرسال notification + data معاً لضمان:
        - Android يعرض الإشعار مباشرة بالصوت الصحيح (من الـ channel)
        - Flutter يستقبل الـ data للتعامل معه

        Args:
            user: User object
            title: عنوان الإشعار
            body: محتوى الإشعار
            notification_type: نوع الإشعار
            data: بيانات إضافية
            sound: ملف الصوت (اختياري - الأولوية للـ channel)

        Returns:
            Dict: معلومات عن نتيجة الإرسال
        """
        if not FIREBASE_AVAILABLE:
            logger.warning("Firebase Admin SDK not available")
            return {'success': False, 'error': 'Firebase not configured'}

        cls.initialize()

        # الحصول على جميع توكنات المستخدم النشطة
        tokens = FCMDevice.get_user_tokens(user, active_only=True)

        if not tokens:
            logger.warning(f"No FCM tokens found for user {user.email}")
            return {'success': False, 'error': 'No FCM tokens found'}

        # تحضير البيانات
        notification_data = data or {}
        notification_data['title'] = title
        notification_data['body'] = body
        notification_data['notification_type'] = notification_type or 'GENERAL'
        notification_data['timestamp'] = datetime.now().isoformat()

        # تحديد channel_id والأولوية بناءً على نوع الإشعار
        # ملاحظة: الأسماء يجب أن تطابق الـ Channels المنشأة في Flutter!
        # v3 - مع حذف وإعادة إنشاء Channels بأصوات مخصصة
        if notification_type in ['NEW_MESSAGE', 'CHAT_MESSAGE']:
            channel_id = 'amina_chat_v3'  # 🆕 v3 - تطابق Flutter
            notification_data['priority'] = 'high'
            notification_data['type'] = 'chat'
        elif notification_type in ['BOOKING_CONFIRMED', 'OFFER_ACCEPTED', 'BOOKING_STARTED']:
            channel_id = 'amina_urgent_v3'  # 🆕 v3 - تطابق Flutter
            notification_data['priority'] = 'high'
            notification_data['type'] = 'booking'
        else:
            channel_id = 'amina_notifications_v3'  # 🆕 v3 - تطابق Flutter
            notification_data['priority'] = 'default'
            notification_data['type'] = notification_data.get('type', 'general')

        # ✅ إنشاء notification payload
        notification = messaging.Notification(
            title=title,
            body=body,
        )

        # إعدادات Android - مع تحديد الـ channel
        android_config = messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id=channel_id,  # ✅ مهم جداً للصوت الصحيح!
            ),
        )

        # إعدادات iOS
        apns_config = messaging.APNSConfig(
            headers={
                'apns-priority': '10',
            },
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(
                        title=title,
                        body=body,
                    ),
                    sound='notification_sound.aiff',
                    badge=1,
                )
            )
        )

        results = {
            'success': True,
            'total_tokens': len(tokens),
            'successful_sends': 0,
            'failed_sends': 0,
            'errors': []
        }

        # إرسال إلى كل توكن
        for token in tokens:
            try:
                fcm_device = FCMDevice.objects.filter(fcm_token=token, is_active=True).first()

                # ✅ إنشاء رسالة مع notification + data
                message = messaging.Message(
                    notification=notification,  # ✅ إضافة notification payload
                    data={k: str(v) for k, v in notification_data.items()},  # FCM يقبل strings فقط
                    token=token,
                    android=android_config,
                    apns=apns_config,
                )

                # إرسال الرسالة
                message_id = messaging.send(message)

                # تسجيل النجاح
                NotificationLog.objects.create(
                    user=user,
                    fcm_device=fcm_device,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=notification_data,
                    status='sent',
                    fcm_message_id=message_id,
                    sent_at=datetime.now()
                )

                results['successful_sends'] += 1
                logger.info(f"✅ Notification sent to {user.email} (channel: {channel_id}): {message_id}")

            except messaging.UnregisteredError:
                # التوكن غير صالح - إلغاء تفعيله
                logger.warning(f"⚠️ Token unregistered, deactivating: {token[:20]}...")
                if fcm_device:
                    fcm_device.deactivate()

                NotificationLog.objects.create(
                    user=user,
                    fcm_device=fcm_device,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=notification_data,
                    status='failed',
                    error_message='Token unregistered'
                )

                results['failed_sends'] += 1
                results['errors'].append(f'Token unregistered: {token[:20]}...')

            except Exception as e:
                logger.error(f"❌ Error sending notification: {e}")

                NotificationLog.objects.create(
                    user=user,
                    fcm_device=fcm_device if 'fcm_device' in locals() else None,
                    title=title,
                    body=body,
                    notification_type=notification_type,
                    data=notification_data,
                    status='failed',
                    error_message=str(e)
                )

                results['failed_sends'] += 1
                results['errors'].append(str(e))

        return results

    @classmethod
    def send_to_multiple_users(
        cls,
        users: List,
        title: str,
        body: str,
        notification_type: str = None,
        data: Dict = None,
        sound: str = 'default'
    ) -> Dict:
        """
        إرسال إشعار لعدة مستخدمين
        """
        results = {
            'total_users': len(users),
            'successful_users': 0,
            'failed_users': 0,
            'details': []
        }

        for user in users:
            result = cls.send_notification(
                user=user,
                title=title,
                body=body,
                notification_type=notification_type,
                data=data,
                sound=sound
            )

            if result['success'] and result['successful_sends'] > 0:
                results['successful_users'] += 1
            else:
                results['failed_users'] += 1

            results['details'].append({
                'user': user.email,
                'result': result
            })

        return results

    @classmethod
    def _get_channel_id(cls, notification_type: str) -> str:
        """
        تحديد channel ID بناءً على نوع الإشعار
        ملاحظة: هذه الدالة للتوافق مع الكود القديم فقط
        Flutter Background Handler سيحدد الـ channel بناءً على notification_type
        """
        if notification_type in ['NEW_MESSAGE', 'CHAT_MESSAGE']:
            return 'chat'
        elif notification_type in ['BOOKING_CONFIRMED', 'OFFER_ACCEPTED', 'BOOKING_STARTED']:
            return 'high_priority'
        else:
            return 'default'

    @classmethod
    def send_chat_notification(cls, user, sender_name: str, message: str, conversation_id: int):
        """
        إرسال إشعار رسالة شات
        """
        return cls.send_notification(
            user=user,
            title=f"💬 رسالة جديدة من {sender_name}",
            body=message[:100],  # قص الرسالة إذا كانت طويلة
            notification_type='NEW_MESSAGE',
            data={
                'conversation_id': str(conversation_id),
                'sender_name': sender_name,
                'type': 'chat',
            },
            sound='chat_sound'  # سيتم استخدامه من Flutter
        )

    @classmethod
    def send_booking_notification(cls, user, title: str, body: str, booking_id: int, notification_type: str):
        """
        إرسال إشعار حجز
        """
        return cls.send_notification(
            user=user,
            title=title,
            body=body,
            notification_type=notification_type,
            data={
                'booking_id': str(booking_id),
                'type': 'booking',
            },
            sound='notification_sound'  # سيتم استخدامه من Flutter
        )

    @classmethod
    def send_offer_notification(cls, user, title: str, body: str, offer_id: int):
        """
        إرسال إشعار عرض جديد
        """
        return cls.send_notification(
            user=user,
            title=title,
            body=body,
            notification_type='OFFER_SUBMITTED',
            data={
                'offer_id': str(offer_id),
                'type': 'offer',
            },
            sound='notification_sound'  # سيتم استخدامه من Flutter
        )


# اسم بديل للتوافق مع الكود القديم
FCMNotificationService = FCMService
