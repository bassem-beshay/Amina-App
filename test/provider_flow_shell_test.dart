import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aminaapplication/screens/provider_flow_shell.dart';
import 'package:aminaapplication/screens/provider_flow_requests_screen.dart';
import 'package:aminaapplication/screens/provider_bookings_screen.dart';
import 'package:aminaapplication/screens/provider_offer_edit_screen.dart';
import 'package:aminaapplication/models/worker_offer_model.dart';
import 'package:aminaapplication/models/booking_model.dart';
import 'package:aminaapplication/screens/provider_booking_details_screen.dart';
import 'package:aminaapplication/screens/provider_reschedule_screens.dart';
import 'package:aminaapplication/screens/provider_communication_screens.dart';
import 'package:aminaapplication/screens/provider_feedback_screens.dart';
import 'package:aminaapplication/screens/provider_remaining_screens.dart';
import 'package:aminaapplication/models/user_model.dart';

void main() {
  testWidgets('individual provider verified home matches P10 shell content',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: ProviderFlowHomeScreen(usePlaceholderDestinations: true)));

    expect(find.text('Hello, Karim Hassan'), findsOneWidget);
    expect(find.text('Verified provider'), findsOneWidget);
    expect(find.text('New requests'), findsOneWidget);
    expect(find.text('Active bookings'), findsOneWidget);
    expect(find.text('My offers'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('company verified home uses company-specific labels',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderFlowHomeScreen(company: true)),
    );

    expect(find.text('Hello, Amina Home Services'), findsOneWidget);
    expect(find.text('Verified company'), findsOneWidget);
    expect(find.text('Add service'), findsOneWidget);
    expect(find.text('Company offers'), findsOneWidget);
  });

  testWidgets('quick action opens a destination placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: ProviderFlowHomeScreen(usePlaceholderDestinations: true)));

    await tester.tap(find.text('View requests'));
    await tester.pumpAndSettle();

    expect(find.text('Available requests'), findsOneWidget);
    expect(find.textContaining('implemented in the next task'), findsOneWidget);
  });

  testWidgets('available requests screen renders the API empty state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderAvailableRequestsScreen(
          requestsFuture: Future.value(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available Requests'), findsOneWidget);
    expect(find.text('No available requests'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('bookings screen renders the API empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderBookingsScreen(bookingsFuture: Future.value(const [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('No bookings found'), findsOneWidget);
  });

  testWidgets('non-pending offer is rendered read-only', (tester) async {
    final offer = WorkerOffer(
      id: 7,
      bookingRequestId: 10,
      workerId: 3,
      priceAction: 'accept',
      offeredPrice: 350,
      status: 'rejected',
      createdAt: DateTime(2026, 1, 1),
    );
    await tester
        .pumpWidget(MaterialApp(home: ProviderOfferEditScreen(offer: offer)));
    await tester.pumpAndSettle();

    expect(find.text('Offer Details'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('pending-payment booking blocks service start', (tester) async {
    final booking = Booking(
      id: 11,
      clientId: 4,
      providerId: 8,
      bookingDate: DateTime(2026, 7, 21),
      bookingTime: '09:00',
      location: 'Nasr City',
      agreedPrice: 350,
      status: 'PENDING_PAYMENT',
      createdAt: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(MaterialApp(
        home: ProviderBookingDetailsScreen(
            bookingId: booking.id, booking: booking)));
    await tester.pumpAndSettle();

    expect(find.text('Pending payment'), findsOneWidget);
    expect(find.text('Payment must be completed before the service can start.'),
        findsOneWidget);
    expect(find.text('Start service'), findsNothing);
  });

  testWidgets('P25 provider reschedule form renders required fields',
      (tester) async {
    final booking = Booking(
      id: 12,
      clientId: 4,
      providerId: 8,
      bookingDate: DateTime(2026, 7, 21),
      bookingTime: '09:00',
      location: 'Nasr City',
      agreedPrice: 350,
      status: 'CONFIRMED',
      createdAt: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(
        MaterialApp(home: ProviderRequestRescheduleScreen(booking: booking)));
    expect(find.text('Request reschedule'), findsOneWidget);
    expect(find.text('New schedule'), findsOneWidget);
    expect(find.text('Reason'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Send request'), findsOneWidget);
  });

  testWidgets('P26 incoming reschedule shows approve and reject actions',
      (tester) async {
    final request = BookingReschedule(
      id: 4,
      bookingId: 12,
      requestedById: 4,
      newDate: DateTime(2026, 7, 23),
      newTime: '11:00 AM',
      reason: 'Customer requested this new date and time.',
      status: 'PENDING',
      createdAt: DateTime(2026, 7, 2),
    );
    await tester.pumpWidget(MaterialApp(
      home: ProviderIncomingRescheduleScreen(
          bookingId: 12, reschedulesFuture: Future.value([request])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Reschedule Request'), findsOneWidget);
    expect(find.text('Approve request'), findsOneWidget);
    expect(find.text('Reject request'), findsOneWidget);
  });

  testWidgets('P27 conversations shows API empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProviderConversationsScreen(
            conversationsFuture: Future.value(const []))));
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Search conversations'), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('P28 chat renders composer and empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProviderChatCustomerScreen(
            conversationId: 1, messagesFuture: Future.value(const []))));
    await tester.pumpAndSettle();
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Write a message'), findsOneWidget);
    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('P31 complaints renders API empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProviderComplaintsScreen(
            complaintsFuture: Future.value(const []))));
    await tester.pumpAndSettle();
    expect(find.text('Complaints'), findsOneWidget);
    expect(find.text('No complaints'), findsOneWidget);
  });

  testWidgets('P33 create complaint enforces title and description fields',
      (tester) async {
    final booking = Booking(
      id: 20,
      clientId: 4,
      providerId: 8,
      bookingDate: DateTime(2026, 7, 21),
      bookingTime: '09:00',
      location: 'Nasr City',
      agreedPrice: 350,
      status: 'COMPLETED',
      createdAt: DateTime(2026, 7, 1),
    );
    await tester.pumpWidget(
        MaterialApp(home: ProviderCreateComplaintScreen(booking: booking)));
    expect(find.text('Create Complaint'), findsOneWidget);
    expect(find.text('Submit complaint'), findsOneWidget);
    expect(
        find.text(
            'Complaints can be submitted after the service is fully completed.'),
        findsOneWidget);
  });

  testWidgets('P34 notifications renders API empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProviderNotificationsScreen(
            notificationsFuture: Future.value(const []))));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Read all'), findsOneWidget);
    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets('P30 ratings renders summary and empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProviderRatingsReviewsScreen(
            ratingsFuture: Future.value(const []))));
    await tester.pumpAndSettle();
    expect(find.text('Ratings & Reviews'), findsOneWidget);
    expect(find.text('Trusted independent provider'), findsOneWidget);
    expect(find.text('No ratings yet'), findsOneWidget);
  });

  testWidgets('P32 complaint details renders status and description',
      (tester) async {
    final complaint = Complaint(
      id: 104,
      bookingId: 20,
      complainantId: 8,
      againstId: 4,
      title: 'Missing cleaning materials',
      description: 'Materials were not provided.',
      status: 'UNDER_REVIEW',
      createdAt: DateTime(2026, 7, 21),
    );
    await tester.pumpWidget(MaterialApp(
        home: ProviderComplaintDetailsScreen(complaint: complaint)));
    expect(find.text('Complaint Details'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Materials were not provided.'), findsOneWidget);
  });

  testWidgets('P36 provider profile renders settings entries', (tester) async {
    final user = User(
      id: 8,
      email: 'provider@example.com',
      firstName: 'Karim',
      lastName: 'Hassan',
      role: 'PROVIDER',
      isActive: true,
      dateJoined: DateTime(2026, 1, 1),
      providerProfile: ServiceProviderProfile(
          verificationStatus: 'VERIFIED', providerType: 'MEMBER'),
    );
    await tester.pumpWidget(MaterialApp(
        home: ProviderProfileMoreScreen(userFuture: Future.value(user))));
    await tester.pumpAndSettle();
    expect(find.text('Karim Hassan'), findsOneWidget);
    expect(find.text('Saved addresses'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('P38 saved addresses renders API empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProviderSavedAddressesScreen(
            addressesFuture: Future.value(const []))));
    await tester.pumpAndSettle();
    expect(find.text('Saved Addresses'), findsOneWidget);
    expect(find.text('No saved addresses'), findsOneWidget);
  });

  testWidgets('P39 address form and P40 language screen render',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: ProviderAddEditAddressScreen()));
    expect(find.text('Provider Address'), findsOneWidget);
    expect(find.text('Save address'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
      home: ProviderLanguageSettingsScreen(),
    ));
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English interface'), findsOneWidget);
  });
}
