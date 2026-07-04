# دليل تتبع مشكلة التقييم (Rating Debug Guide)

## التحديثات التي تمت
تم إضافة logging مفصل جداً في الأماكن التالية:

### 1. chat_screen.dart (الشاشة)
**الموقع**: `lib/screens/chat_screen.dart:391-463`
- يطبع معلومات المستخدم الحالي
- يطبع معلومات الـ conversation (client & provider IDs)
- يحدد من يقيّم من (CLIENT → PROVIDER أو العكس)
- يطبع النتيجة النهائية من RatingService

### 2. rating_service.dart (السيرفيس)
**الموقع**: `lib/services/rating_service.dart:15-100`
- يطبع جميع البارامترات المرسلة (bookingId, ratedUserId, rating, comment)
- يطبع الـ JSON المرسل للـ API
- يطبع الـ endpoint الكامل
- يطبع الـ response المستلم (success, statusCode, data, error)
- يتعامل مع أخطاء الـ parsing بشكل منفصل

### 3. api_client.dart (الـ HTTP Client)
**الموقع**: `lib/services/api_client.dart:323-349`
- يطبع الـ status code
- يطبع الـ response body كاملاً
- يتحقق من أن الـ response ليس HTML
- يطبع نجاح/فشل الـ JSON decoding

## كيفية تتبع المشكلة

### الخطوة 1: تشغيل التطبيق
```bash
flutter run
```

### الخطوة 2: إرسال تقييم
1. افتح شاشة المحادثة (chat screen)
2. اضغط على أيقونة النجمة (⭐) في الـ AppBar
3. اختر التقييم واكتب تعليق
4. اضغط "إرسال التقييم"

### الخطوة 3: قراءة الـ Logs
ستظهر الـ logs بالترتيب التالي:

```
🔵 [ChatScreen] _submitRating called
   Rating: 5
   Comment: "تعليق مثالي"
   BookingId: 123
   Current User ID: 1
   Conversation Client ID: 1
   Conversation Provider ID: 2
   → Current user is CLIENT, rating PROVIDER (ID: 2)
✅ [ChatScreen] Calling RatingService.createRating...

🔵 [RatingService] Starting createRating...
   📌 bookingId: 123
   📌 ratedUserId: 2
   📌 rating: 5
   📌 comment: تعليق مثالي
📤 [RatingService] Request JSON: {booking: 123, rated_user: 2, rating: 5, comment: تعليق مثالي}
📤 [RatingService] API Endpoint: /api/bookings/ratings/create/

🌐 POST Request URL: http://10.0.2.2:8000/api/bookings/ratings/create/
📦 Request Body: {"booking":123,"rated_user":2,"rating":5,"comment":"تعليق مثالي"}
🔑 Auth Token: Present
📋 Headers: {Content-Type: application/json, Authorization: Token xxx...}

📡 Response Status: 201 (أو 400، 500، إلخ)
📡 Response Body: {...}

🔍 [ApiClient._handleResponse] Starting...
   Status Code: 201
   Body Length: XXX characters
   Full Response Body: {...}
🔍 [ApiClient._handleResponse] Attempting to decode JSON...
✅ [ApiClient._handleResponse] JSON decoded successfully
📦 Raw API Response keys: [id, booking, rated_user, rating, comment, created_at]

📥 [RatingService] Response received:
   ✓ success: true/false
   ✓ statusCode: 201
   ✓ data: {...}
   ✓ error: null

✅ [RatingService] Rating created successfully! ID: 123
📥 [ChatScreen] RatingService returned:
   success: true
   error: null
   statusCode: 201
✅ [ChatScreen] Rating submitted successfully!
```

## ماذا تبحث عنه في الـ Logs

### ✅ إذا كان كل شيء يعمل:
- `Response Status: 201` (Created)
- `success: true`
- `Rating created successfully!`

### ❌ إذا كان هناك خطأ - احتمالات المشاكل:

#### 1. مشكلة في الـ Backend API
```
Response Status: 400
error: "خطأ معين من الـ backend"
```
**الحل**: تحقق من الـ Django backend logs

#### 2. مشكلة في الـ Authentication
```
Response Status: 401
error: "Unauthorized"
```
**الحل**: تحقق من الـ Token

#### 3. مشكلة في الـ Network
```
💥 POST Request Exception: SocketException
```
**الحل**: تحقق من أن الـ backend شغال والـ URL صحيح

#### 4. مشكلة في الـ Data Parsing
```
❌ [RatingService] Error parsing response data: type 'String' is not a subtype of type 'int'
```
**الحل**: تحقق من أن الـ backend يرجع البيانات بالـ format الصحيح

#### 5. Server غير متوفر
```
❌ Server returned HTML instead of JSON
```
**الحل**: تحقق من الـ Django server والـ URL في `api_config.dart`

## معلومات إضافية

### الـ Endpoint المستخدم
```
POST /api/bookings/ratings/create/
```

### الـ Request Body Format
```json
{
  "booking": 123,
  "rated_user": 2,
  "rating": 5,
  "comment": "تعليق اختياري"
}
```

### الـ Expected Response Format (201 Created)
```json
{
  "id": 1,
  "booking": 123,
  "rated_by": 1,
  "rated_user": 2,
  "rating": 5,
  "comment": "تعليق اختياري",
  "created_at": "2025-10-28T12:00:00Z"
}
```

## بعد الحصول على الـ Logs

1. **انسخ الـ logs كاملة** من الـ terminal/console
2. **ابحث عن أول ❌ أو 💥** - هذا عادة مكان المشكلة
3. **انظر إلى الـ status code**:
   - `200-299` = نجاح
   - `400-499` = خطأ من الـ client (بيانات خاطئة، unauthorized، إلخ)
   - `500-599` = خطأ من الـ server (مشكلة في الـ backend)
4. **أرسل الـ logs** مع شرح المشكلة

## ملاحظات هامة

- الـ logs تظهر في الـ **Flutter Console/Terminal** وليس في الـ UI
- إذا كنت تستخدم VS Code، الـ logs تظهر في **Debug Console**
- إذا كنت تستخدم Android Studio، الـ logs تظهر في **Run Tab**
- يمكن تصفية الـ logs بالبحث عن `[RatingService]` أو `[ChatScreen]`
