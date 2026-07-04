import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Background message handler - يجب أن يكون top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // عرض الإشعار المحلي مع الصوت عندما التطبيق في الخلفية
  final notification = message.notification;
  final data = message.data;

  // استخراج العنوان والنص من notification أو من data
  String? title = notification?.title;
  String? body = notification?.body;

  // إذا مفيش notification payload، استخدم data
  if (title == null || body == null) {
    title = data['title'] ?? data['notification_title'] ?? 'إشعار جديد';
    body = data['body'] ?? data['message'] ?? data['notification_body'] ?? 'لديك إشعار جديد';
  }

  // عرض الإشعار حتى لو مفيش notification payload
  if (title != null && body != null) {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    // تهيئة الإشعارات المحلية
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await localNotifications.initialize(initSettings);

    // إنشاء قنوات الإشعارات لـ Android
    if (Platform.isAndroid) {
      final androidPlugin = localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // قناة للرسائل العامة
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'amina_notifications_v3',  // 🆕 v3
          'رسائل أمينة',
          description: 'إشعارات عامة من تطبيق أمينة مع صوت واهتزاز',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        ),
      );

      // قناة لرسائل الشات
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'amina_chat_v3',  // 🆕 v3
          'رسائل الشات',
          description: 'رسائل جديدة من الشات مع صوت واهتزاز',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        ),
      );

      // قناة للرسائل المهمة
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'amina_urgent_v3',  // 🆕 v3
          'إشعارات مهمة',
          description: 'إشعارات مهمة تتطلب اهتمام فوري مع صوت واهتزاز قوي',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
          ledColor: const Color.fromARGB(255, 139, 92, 246),
        ),
      );
    }

    // تحديد قناة الإشعار بناءً على النوع
    String channelId = 'amina_notifications_v3';  // 🆕 v3
    String channelName = 'إشعارات أمينة';
    String sound = 'notification_sound'; // صوت مخصص - ديفولت

    if (data['type'] == 'chat' || data['notification_type'] == 'NEW_MESSAGE') {
      channelId = 'amina_chat_v3';  // 🆕 v3
      channelName = 'رسائل الشات';
      sound = 'short_bang';  // 🔊 صوت مخصص للشات (مختلف!)
    } else if (data['priority'] == 'high' || data['notification_type'] == 'BOOKING_CONFIRMED') {
      channelId = 'amina_urgent_v3';  // 🆕 v3
      channelName = 'إشعارات مهمة';
      sound = 'notification_sound';  // 🔊 صوت مخصص للإشعارات العاجلة
    } else {
      // إشعار عادي
      sound = 'notification_sound';  // 🔊 صوت مخصص للإشعارات العادية
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound),  // دايماً يستخدم صوت مخصص
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      enableLights: true,
      ledColor: const Color.fromARGB(255, 139, 92, 246),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        body ?? '',
        htmlFormatBigText: true,
        contentTitle: title ?? '',
        htmlFormatContentTitle: true,
      ),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: data.toString(),
    );

  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // ⚠️ استخدم lazy getter بدلاً من final field لتجنب مشكلة ترتيب التهيئة
  // FirebaseMessaging.instance يجب أن يُستدعى بعد تهيئة Firebase
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTapped => _notificationController.stream;

  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize({bool forceReinit = false}) async {
    // إذا كانت مهيأة بالفعل وليس إعادة تهيئة قسرية
    if (_isInitialized && !forceReinit) {
      // حتى لو مهيأة، نحاول نرسل الـ token للسيرفر مرة تانية
      // في حالة تغيير المستخدم
      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      } else {
      }
      return;
    }

    try {

      // 1. تهيئة Firebase
      await _initializeFirebase();

      // 2. تهيئة Local Notifications
      await _initializeLocalNotifications();

      // 3. طلب الأذونات
      await _requestPermissions();

      // 4. الحصول على FCM Token
      await _getFCMToken();

      // 5. إعداد معالجات الرسائل
      _setupMessageHandlers();

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// تهيئة Firebase
  Future<void> _initializeFirebase() async {
    try {
      // Try to initialize Firebase - will throw if already initialized
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase already initialized or other error
      if (e.toString().contains('duplicate-app') || e.toString().contains('already been created')) {
      } else {
      }
      // Don't rethrow - Firebase might already be initialized
    }
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    // إعدادات Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قناة الإشعارات لـ Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

  }

  /// إنشاء قنوات الإشعارات (Android)
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // 🗑️ حذف الإصدارات القديمة من الـ Channels
    await androidPlugin.deleteNotificationChannel('amina_notifications_v2');
    await androidPlugin.deleteNotificationChannel('amina_urgent_v2');
    await androidPlugin.deleteNotificationChannel('amina_chat_v2');
    await androidPlugin.deleteNotificationChannel('amina_notifications');
    await androidPlugin.deleteNotificationChannel('amina_urgent');
    await androidPlugin.deleteNotificationChannel('amina_chat');

    // ✅ إنشاء Channels جديدة بأصوات مخصصة

    // قناة للرسائل العامة - مع صوت notification_sound
    final generalChannel = AndroidNotificationChannel(
      'amina_notifications_v3',  // 🆕 v3 - نسخة جديدة
      'إشعارات أمينة',
      description: 'إشعارات عامة - صوت notification_sound.mp3',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'), // 🔊 صوت مخصص!
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    // قناة للرسائل المهمة - مع صوت notification_sound
    final urgentChannel = AndroidNotificationChannel(
      'amina_urgent_v3',  // 🆕 v3 - نسخة جديدة
      'إشعارات مهمة',
      description: 'إشعارات مهمة وعاجلة - صوت notification_sound.mp3',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'), // 🔊 صوت مخصص!
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
      ledColor: const Color.fromARGB(255, 139, 92, 246),
    );

    // قناة لرسائل الشات - مع صوت short_bang (مختلف!)
    final chatChannel = AndroidNotificationChannel(
      'amina_chat_v3',  // 🆕 v3 - نسخة جديدة
      'رسائل الشات',
      description: 'رسائل جديدة من الشات - صوت short-bang.mp3 المميز',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('short_bang'), // 🔊 صوت مختلف تماماً!
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
    );

    await androidPlugin.createNotificationChannel(generalChannel);
    await androidPlugin.createNotificationChannel(urgentChannel);
    await androidPlugin.createNotificationChannel(chatChannel);

  }

  /// طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {

    if (Platform.isAndroid) {
      // طلب أذونات Android 13+
      PermissionStatus notificationStatus = await Permission.notification.request();

      if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
        // يمكنك هنا عرض dialog توضيحي للمستخدم
      } else if (notificationStatus.isGranted) {
      }
    }

    // أذونات Firebase (لـ iOS و Android)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );


    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    } else {
    }

    // طلب أذونات Local Notifications لـ Android
    if (Platform.isAndroid) {
      final bool? granted = await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// الحصول على FCM Token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        // حفظ التوكن محليًا
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);

        // إرسال التوكن للسيرفر
        await _sendTokenToServer(_fcmToken!);
      }

      // الاستماع لتحديثات التوكن
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _sendTokenToServer(newToken);
      });

      return _fcmToken;
    } catch (e) {
      return null;
    }
  }

  /// إرسال التوكن للسيرفر
  Future<void> _sendTokenToServer(String token) async {
    try {

      // التحقق من وجود auth token
      final authToken = ApiClient.authToken;
      if (authToken != null) {
      }

      final response = await ApiClient.post(
        '/api/users/fcm-token/',  // ApiClient يضيف baseUrl تلقائياً
        needsAuth: true,
        body: {
          'fcm_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        },
      );


      if (response.success) {
      } else {

        // رسالة توضيحية للمستخدم
        if (response.statusCode == 401) {
        } else if (response.statusCode == 404) {
        } else if (response.statusCode == 500) {
        }
      }
    } catch (e, stackTrace) {
    }
  }

  /// إعداد معالجات الرسائل
  void _setupMessageHandlers() {
    // معالج الرسائل في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // معالج الرسائل عندما التطبيق مفتوح (foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالج الرسائل عند النقر على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // معالج الرسالة التي فتحت التطبيق (من حالة terminated)
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

  }

  /// معالج الرسائل عندما التطبيق في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {

    // عرض الإشعار المحلي (يعمل حتى لو مفيش notification payload)
    await _showLocalNotification(message);
  }

  /// معالج النقر على الإشعار
  void _handleNotificationTap(RemoteMessage message) {

    // إرسال البيانات للمستمعين
    _notificationController.add(message.data);
  }

  /// معالج النقر على الإشعار المحلي
  void _onNotificationTapped(NotificationResponse response) {
    print('📲 Notification tapped - Payload: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // ✅ تحويل JSON payload إلى Map
        final Map<String, dynamic> data = json.decode(response.payload!);
        print('📲 Parsed notification data: $data');
        _notificationController.add(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
        print('❌ Payload was: ${response.payload}');
        // في حالة فشل الـ parsing، نبعت payload كما هو
        _notificationController.add({'payload': response.payload});
      }
    }
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // استخراج العنوان والنص من notification أو من data
    String? title = notification?.title;
    String? body = notification?.body;

    // إذا مفيش notification payload، استخدم data
    if (title == null || body == null) {
      title = data['title'] ?? data['notification_title'] ?? 'إشعار جديد';
      body = data['body'] ?? data['message'] ?? data['notification_body'] ?? 'لديك إشعار جديد';
    }

    // تحديد قناة الإشعار بناءً على النوع - استخدام القنوات الجديدة v3
    String channelId = 'amina_notifications_v3';  // 🆕 v3
    String channelName = 'إشعارات أمينة';
    String sound = 'notification_sound'; // صوت مخصص - ديفولت

    if (data['type'] == 'chat' || data['notification_type'] == 'NEW_MESSAGE') {
      channelId = 'amina_chat_v3';  // 🆕 v3
      channelName = 'رسائل الشات';
      sound = 'short_bang';  // 🔊 صوت مخصص للشات (short-bang.mp3) - مختلف!
    } else if (data['priority'] == 'high' || data['notification_type'] == 'BOOKING_CONFIRMED') {
      channelId = 'amina_urgent_v3';  // 🆕 v3
      channelName = 'إشعارات مهمة';
      sound = 'notification_sound';  // 🔊 صوت مخصص للإشعارات العاجلة
    } else {
      sound = 'notification_sound';  // 🔊 صوت مخصص للإشعارات العادية
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max, // max بدلاً من high
      priority: Priority.max, // max بدلاً من high
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound), // دايماً يستخدم صوت مخصص
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      enableLights: true,
      ledColor: const Color.fromARGB(255, 139, 92, 246),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        body ?? '',
        htmlFormatBigText: true,
        contentTitle: title ?? '',
        htmlFormatContentTitle: true,
      ),
      // إضافة أيقونة كبيرة (optional)
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff', // لـ iOS
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // حفظ الـ data كـ JSON string علشان نقدر نستخدمه بعدين
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: json.encode(message.data), // ✅ حفظ كـ JSON بدلاً من toString()
    );

  }

  /// إرسال إشعار اختبار
  Future<void> showTestNotification({String type = 'general'}) async {
    String channelId = 'amina_notifications_v3';  // 🆕 v3
    String channelName = 'إشعارات أمينة';
    String sound = 'notification_sound'; // ديفولت
    String title;
    String body;

    // تحديد النوع والصوت
    if (type == 'chat') {
      channelId = 'amina_chat_v3';  // 🆕 v3
      channelName = 'رسائل الشات';
      sound = 'short_bang';  // 🔊 صوت مختلف!
      title = '💬 رسالة شات تجريبية';
      body = 'هذا اختبار لصوت رسائل الشات. هل سمعت الصوت؟';
    } else if (type == 'urgent') {
      channelId = 'amina_urgent_v3';  // 🆕 v3
      channelName = 'إشعارات مهمة';
      sound = 'notification_sound';
      title = '⚡ إشعار عاجل تجريبي';
      body = 'هذا اختبار لصوت الإشعارات العاجلة. هل سمعت الصوت؟';
    } else {
      sound = 'notification_sound';
      title = '🔔 إشعار تجريبي';
      body = 'هذا اختبار لصوت الإشعارات العامة. هل سمعت الصوت؟';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound), // دايماً يستخدم صوت مخصص
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      enableLights: true,
      ledColor: const Color.fromARGB(255, 139, 92, 246),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );

  }

  /// الحصول على FCM Token الحالي
  String? get fcmToken => _fcmToken;

  /// إلغاء الاشتراك في topic معين
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
    }
  }

  /// إلغاء الاشتراك من topic معين
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
    }
  }

  /// حذف FCM Token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
    } catch (e) {
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _notificationController.close();
  }
}
