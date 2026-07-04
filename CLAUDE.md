# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Amina Platform** is a Flutter mobile application for a home services marketplace connecting clients with service providers (workers). The app supports three user roles: CLIENT, PROVIDER, and ADMIN. The application is in Arabic (RTL interface) and connects to a Django REST API backend.

## Development Commands

### Running the Application
```bash
# Run on Android emulator
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Build APK
flutter build apk

# Build for iOS
flutter build ios
```

### Dependencies
```bash
# Install/update dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Run code generation (for JSON serialization)
flutter pub run build_runner build

# Run code generation with deletion of conflicting outputs
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing & Quality
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .
```

## Architecture

### Three-Tier Architecture

1. **Presentation Layer** (`lib/screens/`): Flutter UI screens for different user roles
2. **Business Logic Layer** (`lib/services/`): API communication and business logic
3. **Data Layer** (`lib/models/`): Data models representing API entities

### API Integration

The app communicates with a Django backend via REST API:

- **Base Configuration**: `lib/config/api_config.dart` - Contains all API endpoints and configuration
- **HTTP Client**: `lib/services/api_client.dart` - Centralized HTTP client with standardized request/response handling
- **Authentication**: Token-based authentication (Django Token Auth)
  - Token is stored in SharedPreferences via `StorageService`
  - Token is automatically loaded on app initialization in `main.dart` via `AuthService.initialize()`
  - All authenticated requests include `Authorization: Token <token>` header

### Important API Configuration Notes

The `baseUrl` and `wsUrl` in `api_config.dart:22-23` must be configured based on your development environment:

**Production (Current Default)**:
- `baseUrl`: `https://amina.bdcbiz.com` (REST API with SSL)
- `wsUrl`: `wss://amina.bdcbiz.com` (WebSocket with SSL)

**Development Environments** (uncomment appropriate lines):
- **Android Emulator**:
  - `baseUrl`: `http://10.0.2.2:8000` (maps to localhost)
  - `wsUrl`: `ws://10.0.2.2:8000`
- **Physical Android Device**:
  - `baseUrl`: `http://192.168.x.x:8000` (use your machine's IP)
  - `wsUrl`: `ws://192.168.x.x:8000`
- **iOS Simulator**:
  - `baseUrl`: `http://localhost:8000`
  - `wsUrl`: `ws://localhost:8000`

**Running the Backend**:
```bash
# REST API
python manage.py runserver 0.0.0.0:8000

# WebSocket (Django Channels with Daphne)
daphne -b 0.0.0.0 -p 8000 AminaPlatform.asgi:application

# Redis (required for WebSocket channel layer)
redis-server
```

### State Management

The app uses Provider pattern for state management (see `pubspec.yaml:44`). Currently, most screens manage their own state locally using StatefulWidget.

### User Roles & Navigation

The app has different home screens based on user role (determined after login):

- **CLIENT** → `CustomerHomeScreen` (`/customer-home`)
- **PROVIDER** → `ProviderHomeScreen` (`/provider-home`)
- **ADMIN** → `AdminDashboardScreen` (`/admin-dashboard`)

Navigation is handled in `lib/main.dart:39-68` with named routes.

### Data Models

Located in `lib/models/`:

- **User Models** (`user_model.dart`):
  - `User`: Base user with role (CLIENT/PROVIDER/ADMIN)
  - `ClientProfile`: Extended profile for clients with addresses and location
  - `ServiceProviderProfile`: Extended profile for providers with verification status, ratings, documents
  - `Address`: Client address information

- **Service Models** (`service_model.dart`, `booking_model.dart`, `booking_request_model.dart`):
  - `ServiceCategory`: Categories of services
  - `Service`: Individual service offerings
  - `BookingRequest`: Pending booking requests from clients
  - `WorkerOffer`: Offers submitted by providers for booking requests
  - `Booking`: Confirmed bookings with status tracking (CONFIRMED → PAYMENT_COMPLETED → IN_PROGRESS → COMPLETED)

- **Provider Models** (`provider_model.dart`): Public provider information for client browsing

- **Chat Models** (`chat_model.dart`):
  - `Conversation`: Chat conversations linked to bookings
  - `Message`: Individual chat messages with read status
  - Real-time messaging via WebSocket connections

- **Rating & Complaint Models** (`rating_model.dart`):
  - `Rating`: User ratings for completed bookings
  - Complaint models for dispute resolution

All models use `fromJson`/`toJson` for API serialization.

### Services Layer

Located in `lib/services/`:

- **api_client.dart**: Generic HTTP client with methods for GET, POST, PUT, PATCH, DELETE
  - Handles multipart requests for file uploads (`postMultipart`, `putMultipart`)
  - Standardized error handling and response parsing
  - Automatic token injection for authenticated requests

- **auth_service.dart**: Authentication operations
  - `registerClient()`, `registerProvider()`: User registration
  - `login()`: User authentication
  - `logout()`: Clear session
  - `initialize()`: Load saved token on app start
  - All auth methods automatically save token and user data to `StorageService`

- **storage_service.dart**: Local data persistence using SharedPreferences
  - Stores auth token, user data, and login state
  - Used by `AuthService` to persist sessions

- **booking_service.dart**: Booking request and booking operations
  - CRUD for booking requests
  - Accept worker offers to create bookings
  - Start/complete service workflow
  - Cancel bookings and handle reschedules

- **worker_offer_service.dart**: Worker offer operations (provider-side)
- **service_service.dart**: Service and category fetching
- **provider_service.dart**: Provider profile and listing operations
- **profile_service.dart**: User profile management

- **chat_service.dart**: Real-time messaging
  - WebSocket connection management for live chat
  - Message sending/receiving
  - Conversation management linked to bookings
  - Read status tracking

- **rating_service.dart**: Rating and review operations
  - Create ratings after service completion
  - View provider ratings and reviews

- **complaint_service.dart**: Complaint handling
  - File complaints about bookings
  - Track complaint resolution status

### Key Screens

- **auth_screen.dart**: Login and registration (dual-form, role-based)
- **customer_home_screen.dart**: Client dashboard with service browsing, bookings, and provider discovery
- **provider_home_screen.dart**: Provider dashboard with incoming booking requests and offer submission
- **category_services_screen.dart**: Service listing by category with provider selection and booking creation
- **admin_dashboard_screen.dart**: Admin panel for provider verification and platform management
- **profile_screen.dart**: User profile view and editing
- **edit_profile_screen.dart**: Provider profile editing (with document uploads)
- **edit_client_profile_screen.dart**: Client profile editing

- **chat_screen.dart**: Real-time messaging for bookings
  - WebSocket-based live chat
  - Payment buttons (for clients after offer acceptance)
  - Start/Complete service buttons (for providers based on booking status)
  - File complaint and submit rating options

- **payment_screen.dart** & **webview_payment_screen.dart**: Payment processing
  - Integration with payment gateway
  - WebView for external payment flows

- **admin_conversations_ratings_screen.dart**: Admin unified view
  - Manage all conversations
  - View and moderate ratings
  - Handle complaints

- **admin_ratings_screen.dart**: Admin ratings management
- **admin_complaints_screen.dart**: Admin complaints management

## Common Workflows

### Creating a Booking Request (Client Flow)
1. Client browses services in `CustomerHomeScreen`
2. Selects a category → navigates to `CategoryServicesScreen`
3. Selects a service and provider
4. Fills booking form (date, time, notes, optional price)
5. Calls `BookingService.createBookingRequest()` which POSTs to `/api/services/booking-requests/create/`
6. After creation, screen returns and triggers auto-refresh in `CustomerHomeScreen`

### Submitting a Worker Offer (Provider Flow)
1. Provider views pending booking requests in `ProviderHomeScreen`
2. Taps on a request to view details
3. Dialog appears to submit an offer
4. Provider can accept client's price or propose a higher price with optional message
5. Calls `WorkerOfferService.createWorkerOffer()` which POSTs to `/api/services/worker-offers/create/`
6. After submission, requests list auto-refreshes

### Provider Verification (Admin Flow)
1. Admin logs in → navigates to `AdminDashboardScreen`
2. Views pending providers in `AdminPendingProvidersScreen`
3. Reviews provider documents (identity, health certificate)
4. Approves or rejects provider using `ApiClient.post()` to admin endpoints
5. Provider's `verificationStatus` changes from PENDING to VERIFIED or REJECTED

### Complete Booking Lifecycle
1. **Request Creation**: Client creates booking request with service, date, time, optional price
2. **Offer Submission**: Provider views request and submits offer (accept client price or propose higher)
3. **Offer Acceptance**: Client reviews offers and accepts one → creates Booking (status: CONFIRMED)
4. **Payment**: Client pays through payment gateway → status becomes PAYMENT_COMPLETED
5. **Service Start**: Provider clicks "Start Service" → status becomes IN_PROGRESS
6. **Service Completion**: Provider clicks "Complete Service" → status becomes COMPLETED
7. **Rating & Review**: Client can rate provider and leave review
8. **Complaint Filing**: Either party can file complaint if issues arise

### Real-time Chat Flow
1. After booking is confirmed, both parties can access chat
2. Chat uses WebSocket connection for real-time messaging
3. Chat screen shows booking details and status
4. Action buttons appear based on user role and booking status:
   - Client sees "Pay Now" when status is CONFIRMED
   - Provider sees "Start Service" when status is PAYMENT_COMPLETED
   - Provider sees "Complete Service" when status is IN_PROGRESS
   - Both can file complaints or submit ratings when appropriate

### Admin Management Workflows
Admin has comprehensive platform oversight capabilities:

**Provider Management**:
- View pending, verified, rejected, and inactive providers
- Review identity documents and health certificates
- Approve/reject provider applications
- Toggle provider active status
- View provider statistics

**Service & Category Management**:
- Create, update, delete service categories
- Create, update, delete services
- Manage active/inactive status

**Booking Oversight**:
- View all bookings with advanced filters
- Access detailed booking information
- Cancel bookings (override normal restrictions)
- View booking statistics and analytics

**Conversations, Ratings & Complaints**:
- Unified screen (`admin_conversations_ratings_screen.dart`) for:
  - Viewing all chat conversations
  - Moderating ratings and reviews
  - Managing complaints
- Separate detailed screens for ratings and complaints management
- Start review, resolve, or delete inappropriate content

## File Upload Handling

File uploads use multipart/form-data:
- **Registration**: Profile picture, identity document, health certificate
- **Profile Updates**: Same document types

Implementation in `api_client.dart:107-221` (`postMultipart`, `putMultipart`)

## Debugging & Common Issues

### API Connection Issues
- Check that backend server is running on correct host/port
- Verify `ApiConfig.baseUrl` matches your environment
- Check firewall allows connections on port 8000
- For physical devices, ensure device and development machine are on same network

### 404 Errors
If you see a 404 error (like the booking request creation issue), check:
1. Backend endpoint exists and matches `api_config.dart` definition
2. Django URL routing is correct
3. Backend logs for the incoming request path

### Response Parsing Issues
The `ApiClient._handleResponse()` method (api_client.dart:294-390) handles multiple response formats:
- Direct arrays (e.g., provider lists)
- Wrapped objects with `data` key
- Different error structures

If parsing fails, check backend response structure matches expected format.

### Token Issues
If authentication fails after app restart:
- `AuthService.initialize()` is called in `main.dart:16` before app starts
- Token is loaded from SharedPreferences and set in `ApiClient`
- If token is invalid/expired, user must log in again

### WebSocket Connection Issues
Real-time chat uses WebSocket connections:
- WebSocket URL configured in `api_config.dart:23` as `wsUrl`
- Production: `wss://amina.bdcbiz.com` (secure WebSocket)
- Development: `ws://10.0.2.2:8000` (Android Emulator) or appropriate IP
- Connection path: `/ws/chat/{conversationId}/`
- If messages don't appear in real-time:
  1. Check WebSocket URL matches environment
  2. Verify Django Channels is running with Daphne/ASGI server
  3. Check Redis is running (used as channel layer backend)
  4. Look for WebSocket connection errors in Flutter console

### Booking Status Flow Issues
If booking status doesn't update properly:
- Backend may return booking data wrapped in `data` key or directly
- `BookingService` has flexible response parsing to handle both structures (booking_service.dart:285-295, 324-334)
- Check API response format if status updates fail
- Chat screen reloads conversation after payment to refresh status (chat_screen.dart:746)

## Commit Message Conventions

Recent commits show bilingual commit messages (Arabic + English) with structured format:
```
<Arabic summary>

<Arabic details>:
- <Change 1>
- <Change 2>

<Files modified>:
- <file>: <description>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Follow this pattern when committing changes.

## UI/UX Notes

- **Language**: Primary language is Arabic (RTL layout)
- **Color Scheme**: Purple primary (#8B5CF6), Green accent (#10B981)
- **Design**: Material Design 3 with custom theming
- **Font**: Tajawal (Arabic font family) - defined in `main.dart:36`
- **Icons**: Material Icons with Arabic labels
