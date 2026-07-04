import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'welcome': 'Welcome',
      'welcomeYou': 'Welcome!',
      'aminaPlatform': 'Amina Platform',
      'incompleteData': 'Incomplete Data',
      'completeDataFirst': 'To complete the booking, please complete the following data first:',
      'phoneNumber': 'Phone Number',
      'completeDataButton': 'Complete Data',
      'completeDataHint': 'Press "Complete Data" to go to the profile edit page',
      'hello': 'Hello',
      'search': 'Search',
      'services': 'Services',
      'providers': 'Providers',
      'viewAll': 'View All',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'logout': 'Logout',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'location': 'Location',

      // Home Screen
      'topRatedProviders': 'Available Workers',
      'popularServices': 'Popular Services',
      'categories': 'Categories',
      'requestService': 'Request Service',
      'quickServices': 'Quick Services',
      'availableOffers': 'Available Offers',
      'user': 'User',
      'searchServiceOrWorker': 'Search for a service or worker...',
      'noSearchResults': 'No search results',
      'noServicesAvailable': 'No services available currently',
      'noOffersAvailable': 'No offers available currently',
      'noWorkersAvailable': 'No workers available currently',
      'currency': 'EGP',
      'noSavedAddresses': 'No saved addresses',
      'egypt': 'Egypt',

      // Booking
      'myBookings': 'My Bookings',
      'activeBookings': 'Active Bookings',
      'completedBookings': 'Completed Bookings',
      'bookingDetails': 'Booking Details',
      'bookNow': 'Book Now',
      'dateAndTime': 'Date & Time',
      'amount': 'Amount',
      'city': 'City',

      // Provider
      'providerProfile': 'Provider Profile',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'ratings': 'Ratings',
      'basedOnRatings': 'Based on {count} ratings',
      'noRatingsYet': 'No ratings yet',
      'failedToLoadRatings': 'Failed to load ratings',
      'errorOccurredRatings': 'An error occurred',
      'daysAgo': '{count} days ago',
      'weeksAgo': '{count} weeks ago',
      'weekAgo': 'A week ago',
      'monthsAgo': '{count} months ago',
      'monthAgo': 'A month ago',
      'yearsAgo': '{count} years ago',
      'yearAgo': 'A year ago',
      'experience': 'Experience',
      'skills': 'Skills',

      // Authentication
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',

      // Messages
      'noResults': 'No results found',
      'noNotifications': 'No notifications',
      'noBookings': 'No bookings yet',
      'successfullyBooked': 'Successfully booked!',
      'bookingCancelled': 'Booking cancelled',
      'bookingError': 'Booking Error',
      'ok': 'OK',
      'confirmExit': 'Confirm Exit',
      'exitAppMessage': 'Do you want to exit the app?',
      'exit': 'Exit',
      'pleaseLoginFirst': 'Please login first',

      // Days
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',

      // Auth Screen
      'chooseAccountType': 'Choose Account Type',
      'pleaseSelectAccountType': 'Please select your account type before continuing',
      'client': 'Client',
      'lookingForHomeServices': 'Looking for home services',
      'serviceProvider': 'Service Provider',
      'provideHomeServices': 'I provide home services',
      'loginSuccess': 'Logged in successfully',
      'loginFailed': 'Login failed',
      'operationSuccess': 'Operation completed successfully',
      'errorOccurred': 'An error occurred',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'phoneNumber': 'Phone Number',
      'confirmPassword': 'Confirm Password',
      'signUp': 'Sign Up',
      'signIn': 'Sign In',
      'continueAsGuest': 'Continue as Guest',
      'or': 'Or',
      'welcomeBack': 'Welcome Back',
      'joinUs': 'Join Us',
      'gladToSeeYouAgain': 'Glad to see you again, sign in to continue',
      'createNewAccount': 'Create a new account and start your journey with us',
      'enterValidName': 'Please enter a valid name',
      'enterValidEmail': 'Enter a valid email',
      'passwordMinLength': 'Password must be at least 6 characters',
      'showPassword': 'Show password',
      'hidePassword': 'Hide password',
      'rememberMe': 'Remember me',
      'createAccount': 'Create Account',
      'signInWithGoogle': 'Sign in with Google',
      'enterPhoneNumber': 'Enter your phone number',

      // Profile Screen
      'personalInfo': 'Personal Information',
      'ratingAndStats': 'Rating & Statistics',
      'completedTasks': 'Completed Tasks',
      'taskUnit': 'task',
      'yearUnit': 'year',
      'identityDocument': 'Identity Document',
      'healthCertificate': 'Health Certificate',
      'aboutMe': 'About Me',
      'deleteAddress': 'Delete',
      'confirmDelete': 'Confirm Delete',
      'verified': 'Verified',
      'accountVerified': 'Account Verified ✓',
      'accountVerifiedDescription': 'Your identity and health certificate have been successfully verified. You can now submit offers to client requests.',
      'completeYourInfo': 'Please complete your information',
      'verifiedProviderDescription': 'To become a verified service provider, you must upload your identity document and health certificate from the edit profile page.',
      'underReview': 'Under Review',
      'pleaseCompleteData': 'Please complete data',
      'requestUnderReview': 'Your request is under review ⏳',
      'requestUnderReviewDescription': 'Your documents are being reviewed by the administration. We will notify you as soon as the review is complete.',
      'requestRejected': 'Your request is rejected ✗',
      'requestRejectedDescription': 'Sorry, your documents were not accepted. Please update your identity document and health certificate from the edit profile page.',
      'deleteAddressConfirm': 'Are you sure you want to delete this address?',
      'addressDeletedSuccess': 'Address deleted successfully',
      'defaultAddressSetSuccess': 'Default address set successfully',
      'documentNotAvailable': 'Document not available',
      'loggingOut': 'Logging out...',
      'logoutSuccess': 'Logged out successfully',
      'logoutError': 'An error occurred while logging out',
      'close': 'Close',
      'bookingConfirmedSuccess': 'Booking confirmed successfully',
      'name': 'Name',
      'phone': 'Phone',
      'accountType': 'Account Type',
      'emailAddress': 'Email Address',
      'defaultLabel': 'Default',
      'failedToDeleteAddress': 'Failed to delete address',
      'failedToSetDefaultAddress': 'Failed to set default address',
      'joined': 'Joined',
      'changePassword': 'Change Password',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'aboutApp': 'About App',
      'termsAndConditions': 'Terms and Conditions',
      'privacyPolicy': 'Privacy Policy',
      'contactUs': 'Contact Us',
      'version': 'Version',
      'logoutConfirm': 'Are you sure you want to logout?',

      // Chat Screen
      'typeMessage': 'Type a message...',
      'send': 'Send',
      'online': 'Online',
      'offline': 'Offline',
      'typing': 'Typing...',
      'delivered': 'Delivered',
      'read': 'Read',
      'image': 'Image',
      'video': 'Video',
      'file': 'File',

      // Notifications
      'markAllAsRead': 'Mark as Read',
      'clearAll': 'Clear All',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'newBooking': 'New Booking',
      'bookingAccepted': 'Booking Accepted',
      'bookingRejected': 'Booking Rejected',
      'bookingCompleted': 'Booking Completed',
      'noNotificationsSubtitle': 'Notifications will appear here when there are updates',
      'chatOpenError': 'Error: Cannot open chat - booking ID not found',
      'unknownError': 'Error: ',
      'defaultUser': 'User',

      // Bookings
      'pending': 'Pending',
      'accepted': 'Accepted',
      'inProgress': 'In Progress',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'rejected': 'Rejected',
      'startDate': 'Start Date',
      'endDate': 'End Date',
      'price': 'Price',
      'total': 'Total',
      'subtotal': 'Subtotal',
      'tax': 'Tax',
      'discount': 'Discount',
      'paymentMethod': 'Payment Method',
      'cash': 'Cash',
      'card': 'Card',
      'wallet': 'Wallet',

      // Service Details
      'description': 'Description',
      'serviceType': 'Service Type',
      'duration': 'Duration',
      'hour': 'Hour',
      'hours': 'Hours',
      'minute': 'Minute',
      'minutes': 'Minutes',
      'day': 'Day',
      'days': 'Days',
      'selectDate': 'Select Date',
      'selectTime': 'Select Time',
      'addNotes': 'Add Notes',
      'notes': 'Notes',

      // Common Actions
      'accept': 'Accept',
      'reject': 'Reject',
      'complete': 'Complete',
      'start': 'Start',
      'finish': 'Finish',
      'submit': 'Submit',
      'apply': 'Apply',
      'reset': 'Reset',
      'filter': 'Filter',
      'sortBy': 'Sort By',
      'uploadImage': 'Upload Image',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'remove': 'Remove',
      'update': 'Update',
      'download': 'Download',
      'share': 'Share',
      'copy': 'Copy',
      'paste': 'Paste',

      // Offer Dialog
      'submitProfessionalOffer': 'Submit Professional Offer',
      'clientBudget': 'Client Budget',
      'chooseOfferType': 'Choose Offer Type',
      'acceptClientPrice': 'Accept Client Price',
      'proposeDifferentPrice': 'Propose Different Price',
      'mustBeHigherThanClientBudget': 'Must be higher than client budget',
      'proposedPrice': 'Proposed Price',
      'enterPriceInEGP': 'Enter price in EGP',
      'egpCurrency': 'EGP',
      'messageToClient': 'Message to Client',
      'messageToClientHint': 'Example: I have 5 years of experience in this field and can provide professional service...',
      'sendOffer': 'Send Offer',
      'proposedPriceMustBeHigher': 'Proposed price must be higher than client budget',
      'sendingOffer': 'Sending offer...',
      'offerSubmittedSuccessfully': 'Offer submitted successfully!',
      'waitForClientResponse': 'Wait for client response',
      'failedToSubmitOffer': 'Failed to submit offer',
      'newClient': 'New Client',
      'bookingRequest': 'Booking Request',
      'cannotLoadImage': 'Cannot load image',

      // Booking Request Details
      'date': 'Date',
      'time': 'Time',
      'status': 'Status',
      'offersCount': 'Offers Count',
      'offer': 'Offer',
      'offers': 'Offers',
      'budget': 'Budget',
      'offersSubmitted': 'Offers Submitted',
      'clientInformation': 'Client Information',
      'clientName': 'Client Name',
      'detailedAddress': 'Detailed Address',
      'expectedDuration': 'Expected Duration',
      'requestStatus': 'Request Status',
      'availableForOffers': 'Available for Offers',
      'newStatus': 'New',
      'submitPriceOffer': 'Submit Price Offer',
      'requiredPrice': 'Required Price',
      'additionalNotesOptional': 'Additional Notes (Optional)',
      'addAnyAdditionalNotes': 'Add any additional notes or details...',
      'pleaseEnterPrice': 'Please enter price',
      'noOffersReceived': 'No offers received',
      'receivedOffersText': 'Received',

      // Status Messages
      'success': 'Success',
      'failed': 'Failed',
      'warning': 'Warning',
      'info': 'Information',
      'noData': 'No data available',
      'noInternet': 'No internet connection',
      'noInternetConnection': 'No Internet Connection',
      'checkInternetConnection': 'Check your network connection and try again',
      'tryAgain': 'Try Again',
      'comingSoon': 'Coming Soon',
      'underMaintenance': 'Under Maintenance',

      // Validation
      'required': 'Required',
      'invalidEmail': 'Invalid email',
      'invalidPhone': 'Invalid phone number',
      'passwordMismatch': 'Passwords do not match',
      'passwordTooShort': 'Password too short',
      'fieldRequired': 'This field is required',

      // Screen Titles
      'reviewProviders': 'Review Service Providers',
      'manageClients': 'Manage Clients',
      'rejectedProviders': 'Rejected Providers',
      'verifiedProviders': 'Verified Providers',
      'resetPassword': 'Reset Password',
      'confirmOffer': 'Confirm Offer',
      'requestDetails': 'Request Details',
      'servicePreferences': 'Service Preferences',
      'paymentGateway': 'Payment Gateway',
      'conversations': 'Conversations',
      'activeBookingsTitle': 'My Active Bookings',
      'serviceDetails': 'Service Details',
      'customerDetails': 'Customer Details',
      'providerDetailsTitle': 'Provider Details',
      'offerDetailsTitle': 'Offer Details',
      'paymentTitle': 'Payment',
      'servicesTitle': 'Services',
      'editClientProfileTitle': 'Edit Profile',
      'editProviderProfileTitle': 'Edit Profile',
      'manageServices': 'Manage Services',
      'serviceCategories': 'Service Categories',
      'conversationsRatingsComplaints': 'Conversations, Ratings & Complaints',
      'confirmServiceCompletion': 'Confirm Service Completion',
      'offersReceived': 'Offers Received',
      'recentBookings': 'Recent Bookings',
      'savedAddresses': 'Saved Addresses',
      'noAddressesSaved': 'No addresses saved',
      'noBookingsCurrently': 'No bookings currently',
      'defaultAddress': 'Default',
      'address': 'Address',
      'setAsDefault': 'Set as Default',
      'viewOffers': 'View Offers',

      // Booking Dialog
      'bookingDate': 'Booking Date',
      'selectBookingDate': 'Select booking date',
      'bookingTime': 'Booking Time',
      'selectBookingTime': 'Select booking time',
      'serviceDuration': 'Service Duration (hours)',
      'durationExample': 'Example: 8 hours',
      'selectAddress': 'Select Address',
      'confirmBooking': 'Confirm Booking',
      'optionalPrice': 'Suggested Price (Optional)',
      'priceExample': 'Example: 500 EGP',
      'bookingNotes': 'Booking Notes',
      'bookingNotesHint': 'Add any special requests or notes...',

      // Validation & Errors
      'pleaseCompleteAllFields': 'Please complete all fields',
      'bookingErrorMessage': 'Booking Error',
      'pleaseTryAgainLater': 'Please try again later',
      'bookingSuccess': 'Booking request submitted successfully!',
      'providerWillContact': 'Providers will contact you soon',
      'pleaseSelectAddress': 'Please select an address',

      // Address Dialog
      'addNewAddress': 'Add New Address',
      'useCurrentLocation': 'Use Current Location',
      'addressLabel': 'Address Label',
      'addressLabelHint': 'e.g., Home, Work',
      'street': 'Street',
      'buildingNumber': 'Building Number',
      'floor': 'Floor',
      'apartment': 'Apartment',
      'additionalInfo': 'Additional Information',
      'additionalInfoHint': 'Any additional details...',
      'setDefault': 'Set as Default',
      'addAddress': 'Add Address',
      'gettingLocation': 'Getting your location...',
      'locationError': 'Failed to get location',

      // Service Display
      'perHour': '/hour',
      'egp': 'EGP',
      'viewDetails': 'View Details',
      'available': 'Available',
      'notAvailable': 'Not Available',
      'contactInfo': 'Contact Information',
      'serviceCategory': 'Service Category',

      // Months
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',

      // Time
      'am': 'AM',
      'pm': 'PM',
      'morning': 'Morning',
      'evening': 'Evening',

      // Category Selection
      'selectCategory': 'Select Category',
      'browseAllCategories': 'Browse all available service categories',
      'selected': 'Selected',
      'noServicesInCategory': 'No services available in this category',

      // Location & Errors
      'detectingLocation': 'Detecting location...',
      'useMyCurrentLocation': 'Use my current location',
      'locationDetectedSuccess': 'Location detected successfully',
      'addressLabelOptional': 'Address label (optional)',
      'exampleHomeWork': 'Example: Home, Work, etc.',
      'locationPermissionDenied': 'Location permission denied',
      'locationPermissionDeniedPermanently': 'Location permission is permanently denied. Please enable it from settings',
      'failedToDetect': 'Failed to detect location',
      'addressAddedSuccess': 'Address added successfully',
      'failedToAddAddress': 'Failed to add address',
      'noAddressesSavedMessage': 'Add a new address to continue',
      'perUnit': 'per {unit}',

      // Chat Screen Specific
      'connectionError': 'Connection error - trying again',
      'disconnectedInternet': 'Disconnected - check internet',
      'alreadyRated': 'You have already rated this booking',
      'rateOtherParty': 'Rate the other party',
      'howWasExperience': 'How was your experience?',
      'commentOptional': 'Comment (optional)',
      'shareYourOpinion': 'Share your opinion about the experience...',
      'submitRatingButton': 'Submit Rating',
      'veryBad': 'Very Bad 😞',
      'bad': 'Bad 😕',
      'acceptable': 'Acceptable 😐',
      'goodRating': 'Good 😊',
      'excellent': 'Excellent 🌟',
      'userInfoNotFound': 'User information not found',
      'startServiceButton': 'Start Service',
      'startServiceConfirm': 'Are you sure you want to start the service now?',
      'completeServiceButton': 'Complete Service',
      'completeServiceConfirm': 'Are you sure you want to complete the service?\n\nA notification will be sent to the client for confirmation.',
      'confirmCompletionButton': 'Confirm Service Completion',
      'confirmCompletionMessage': 'Do you confirm that the service has been completed satisfactorily?\n\nAfter confirmation, the booking will be closed.',
      'yesConfirm': 'Yes, Confirm',
      'failedToFetchBooking': 'Failed to fetch booking data',
      'errorFetchingBooking': 'Error fetching booking data',
      'serviceLabel': 'Service',
      'bookingStatusLabel': 'Booking Status',
      'confirmedStatus': 'Confirmed',
      'paymentCompletedStatus': 'Payment Completed',
      'pendingCompletionStatus': 'Pending Completion',
      'startConversationMessage': 'Start the conversation by sending a message',
      'yesterdayLabel': 'Yesterday',
      'completePaymentButton': 'Complete Payment',
      'connectingStatus': 'Connecting...',

      // Customer Home Screen Specific
      'newBookingTitle': 'New Booking',
      'comprehensiveHomeCleaning': 'Comprehensive Home Cleaning',
      'bookingDateLabel': 'Booking Date',
      'bookingTimeLabel': 'Booking Time',
      'serviceDurationLabel': 'Service Duration (hours)',
      'durationExampleHint': 'Example: 8 hours',
      'selectAddressLabel': 'Select Address',
      'noAddressesYetMessage': 'No addresses saved',
      'pleaseAddAddressMessage': 'Please add an address from account settings',
      'defaultAddressLabel': 'Default',
      'pleaseSelectAddressMessage': 'Please select an address',
      'bookingErrorDialogTitle': 'Booking Error',
      'troubleshootingTipsLabel': 'Tips to solve the problem:',
      'troubleshootingTip1': '1. Make sure the server is running on port 8000',
      'troubleshootingTip2': '2. Check network settings',
      'troubleshootingTip3': '3. Check the console for more details',
      'searchForServiceHint': 'Search for a service or worker...',
      'houseCleaningCategory': 'House Cleaning',
      'cookingCategory': 'Cooking',
      'childCareCategory': 'Child Care',
      'elderlyCareCategory': 'Elderly Care',
      'laundryCategory': 'Laundry',
      'ironingCategory': 'Ironing',
      'pressToExploreLabel': 'Press to explore',
      'perUnitLabel': 'per {unit}',
      'availableStatus': 'Available',
      'busyStatus': 'Busy',
      'egyptCountry': 'Egypt',
      'addNewAddressButton': 'Add New Address',
      'addressLabelOptionalHint': 'Address label (optional)',
      'exampleHomeWorkHint': 'Example: Home, Work, etc.',
      'locationPermissionDeniedError': 'Location permission denied',
      'locationPermissionDeniedPermanentlyError': 'Location permission is permanently denied. Please enable it from settings',
      'failedToDetectLocationError': 'Failed to detect location',
      'failedToDetectLocationMessage': 'Failed to detect location: {error}',
      'detectingLocationStatus': 'Detecting location...',
      'detectMyCurrentLocationButton': 'Detect my current location',
      'locationDetectedSuccessMessage': 'Location detected successfully',
      'cityLabelText': 'City',
      'addressLabelText': 'Address',
      'unspecifiedText': 'Unspecified',
      'saveButtonText': 'Save',
      'chatOpenFailure': 'Failed to open chat',
      'addressLabelDefault': 'Address',

      // Provider Home Screen Specific
      'chatOpenErrorSnackbar': 'Error opening chat',
      'newBookingRequestsLabel': 'New booking requests',
      'noSearchResultsLabel': 'No search results',
      'noNewBookingRequestsMessage': 'No new booking requests',
      'serviceProviderLabel': 'Service Provider',
      'bookingDetailsTitleText': 'Booking Details',
      'submitOfferButton': 'Submit Offer',
      'ratingLabelText': 'Rating',
      'newClientLabelText': 'New Client',
      'accountUnderReviewTitle': 'Your account is under review',
      'waitForAdminReviewMessage': 'Wait for admin to review your profile.',
      'accountRejectedTitle': 'Your account was rejected',
      'accountRejectedMessageText': 'You are not authorized to submit requests. Your account was rejected by administration.\n\nPlease contact administration to know the reasons.',
      'verificationRequiredTitle': 'Verification Required',
      'verificationRequiredMessageText': 'Your account must be verified to submit offers on booking requests.\n\nPlease complete your profile data and upload the required documents.',
      'submitProfessionalOfferDialogTitle': 'Submit Professional Offer',
      'selectedLabel': 'Selected',
      'proposeDifferentPriceOption': 'Propose Different Price',
      'mustBeHigherThanBudgetHint': 'Must be higher than client budget',
      'enterPriceEGPHint': 'Enter price in EGP',
      'egpLabelText': 'EGP',
      'exampleMessageHint': 'Example: I have 5 years of experience in this field and can provide professional service...',
      'sendingOfferStatusText': 'Sending offer...',
      'offerSentSuccessMessage': 'Your offer has been sent successfully',
      'offerSentFailedMessage': 'Failed to send offer',
      'cannotLoadImageError': 'Cannot load image',
      'submitOfferNowButton': 'Submit your offer now',

      // Edit Client Profile Screen Specific
      'failedToLoadData': 'Failed to load data',
      'errorLoadingData': 'Error loading data',
      'errorLoadingCategories': 'Error loading categories',
      'locationPermissionDeniedMessage': 'Location permission denied',
      'noLocationInfo': 'Location information not found',
      'errorDetectingLocation': 'Error detecting location',
      'profileUpdatedSuccess': 'Profile updated successfully',
      'failedToUpdateProfile': 'Failed to update profile',
      'errorUpdating': 'Error updating',
      'noCategoriesAvailable': 'No service categories available currently',
      'preferredServices': 'Preferred Services',
      'selectPreferredServicesHint': 'Select services you are interested in to make searching easier',
      'optionalLocation': 'Location (Required)',
      'detectCurrentLocation': 'Detect my current location',
      'locationDetected': 'Location detected',
      'addressWillBeSavedAuto': 'This address will be automatically saved in your saved addresses',

      // Client Bookings Screen Specific
      'myBookingsTitle': 'My Bookings',
      'refresh': 'Refresh',
      'noBookingsCurrentlyMessage': 'No bookings currently',
      'startBookingNewService': 'Start booking a new service',
      'viewAvailableOffers': 'View Available Offers',
      'openStatus': 'Open',
      'tomorrow': 'Tomorrow',
      'availableOffersTitle': 'Available Offers',
      'noOffersYet': 'No offers yet',
      'waitForProviders': 'Wait until service providers submit their offers',
      'closeButton': 'Close',
      'priceLabel': 'Price',
      'acceptOffer': 'Accept Offer',

      // Booking Confirmation Screen
      'offerAcceptedSuccessfully': 'Offer Accepted Successfully!',
      'confirmBookingDetailsMessage': 'Confirm booking details to complete the process',
      'serviceAddress': 'Service Address',
      'change': 'Change',
      'addNotesOrInstructions': 'Add any notes or special instructions...',
      'priceSummary': 'Price Summary',
      'servicePrice': 'Service Price',
      'serviceFee': 'Service Fee',
      'bookingConfirmed': 'Booking Confirmed!',
      'errorConfirmingBooking': 'An error occurred while confirming the booking',
      'addressSelectionComingSoon': 'Address selection page will be added later',
      'householdService': 'Household Service',
      'notSpecified': 'Not specified',
      'bookingConfirmedMessage': 'Your booking has been confirmed successfully. You can track the booking status from the "My Bookings" page.',

      // Payment Fee
      'paymentGatewayFee': 'Payment Gateway Fee',
      'paymentFeeDeduction': '15% payment gateway fee will be deducted',
      'paymentFeeDeductionShort': '15% payment gateway fee deducted',
      'paymentFeeDeductionFromAmount': '15% payment gateway fee will be deducted from the amount',
      'totalAmount': 'Total Amount',
      'gatewayFee': 'Gateway Fee (15%)',
      'netAmountDue': 'Net Amount Due',
    },
    'ar': {
      // Common
      'welcome': 'مرحباً',
      'welcomeYou': 'مرحباً بك!',
      'aminaPlatform': 'منصة أمينة',
      'incompleteData': 'بيانات غير مكتملة',
      'completeDataFirst': 'لإتمام الحجز، يرجى إكمال البيانات التالية أولاً:',
      'phoneNumber': 'رقم الهاتف',
      'completeDataButton': 'إكمال البيانات',
      'completeDataHint': 'اضغط "إكمال البيانات" للانتقال إلى صفحة تعديل الملف الشخصي',
      'hello': 'مرحباً',
      'search': 'بحث',
      'services': 'الخدمات',
      'providers': 'مقدمو الخدمة',
      'viewAll': 'عرض الكل',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'edit': 'تعديل',
      'delete': 'حذف',
      'logout': 'تسجيل الخروج',
      'home': 'الرئيسية',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'notifications': 'الإشعارات',
      'location': 'الموقع',

      // Home Screen
      'topRatedProviders': 'العاملون المتاحين',
      'popularServices': 'الخدمات الشائعة',
      'categories': 'الفئات',
      'requestService': 'طلب خدمة',
      'quickServices': 'الخدمات السريعة',
      'searchServiceOrWorker': 'ابحث عن خدمة أو عاملة...',
      'noSearchResults': 'لا توجد نتائج للبحث',
      'noServicesAvailable': 'لا توجد خدمات متاحة حالياً',
      'noOffersAvailable': 'لا توجد عروض متاحة حالياً',
      'noWorkersAvailable': 'لا توجد عاملات متاحات حالياً',
      'currency': 'جنيه',
      'noSavedAddresses': 'لا توجد عناوين محفوظة',
      'egypt': 'مصر',
      'availableOffers': 'العروض المتاحة',
      'user': 'مستخدم',

      // Booking
      'myBookings': 'حجوزاتي',
      'activeBookings': 'الحجوزات النشطة',
      'completedBookings': 'الحجوزات المكتملة',
      'bookingDetails': 'تفاصيل الحجز',
      'bookNow': 'احجز الآن',
      'dateAndTime': 'التاريخ والوقت',
      'amount': 'المبلغ',
      'city': 'المدينة',

      // Provider
      'providerProfile': 'الملف الشخصي للعامل',
      'rating': 'التقييم',
      'reviews': 'التقييمات',
      'ratings': 'التقييمات',
      'basedOnRatings': 'بناءً على \u200F{count}\u200F تقييم',
      'noRatingsYet': 'لا توجد تقييمات بعد',
      'failedToLoadRatings': 'فشل تحميل التقييمات',
      'errorOccurredRatings': 'حدث خطأ',
      'daysAgo': 'منذ \u200F{count}\u200F أيام',
      'weeksAgo': 'منذ \u200F{count}\u200F أسابيع',
      'weekAgo': 'منذ أسبوع',
      'monthsAgo': 'منذ \u200F{count}\u200F أشهر',
      'monthAgo': 'منذ شهر',
      'yearsAgo': 'منذ \u200F{count}\u200F سنوات',
      'yearAgo': 'منذ سنة',
      'experience': 'الخبرة',
      'skills': 'المهارات',

      // Authentication
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgotPassword': 'هل نسيت كلمة المرور؟',
      'dontHaveAccount': 'ليس لديك حساب؟',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',

      // Messages
      'noResults': 'لا توجد نتائج',
      'noNotifications': 'لا توجد إشعارات',
      'noBookings': 'لا توجد حجوزات بعد',
      'successfullyBooked': 'تم الحجز بنجاح!',
      'bookingCancelled': 'تم إلغاء الحجز',
      'bookingError': 'خطأ في الحجز',
      'ok': 'حسناً',
      'confirmExit': 'تأكيد الخروج',
      'exitAppMessage': 'هل تريد الخروج من التطبيق؟',
      'exit': 'خروج',
      'pleaseLoginFirst': 'يرجى تسجيل الدخول أولاً',

      // Days
      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',

      // Auth Screen
      'chooseAccountType': 'اختر نوع الحساب',
      'pleaseSelectAccountType': 'يرجى تحديد نوع حسابك قبل المتابعة',
      'client': 'عميل',
      'lookingForHomeServices': 'أبحث عن خدمات منزلية',
      'serviceProvider': 'مقدم خدمة',
      'provideHomeServices': 'أقدم خدمات منزلية',
      'loginSuccess': 'تم تسجيل الدخول بنجاح',
      'loginFailed': 'فشل تسجيل الدخول',
      'operationSuccess': 'تمت العملية بنجاح',
      'errorOccurred': 'حدث خطأ',
      'firstName': 'الاسم الأول',
      'lastName': 'الاسم الأخير',
      'phoneNumber': 'رقم الهاتف',
      'confirmPassword': 'تأكيد كلمة المرور',
      'signUp': 'إنشاء حساب',
      'signIn': 'تسجيل الدخول',
      'continueAsGuest': 'الاستمرار كزائر',
      'or': 'أو',
      'welcomeBack': 'مرحباً بك مجدداً',
      'joinUs': 'انضم إلينا',
      'gladToSeeYouAgain': 'سُعدنا برؤيتك مجدداً، سجل دخولك للمتابعة',
      'createNewAccount': 'أنشئ حساباً جديداً وابدأ رحلتك معنا',
      'enterValidName': 'من فضلك أدخل اسمًا صحيحًا',
      'enterValidEmail': 'أدخل بريدًا إلكترونيًا صالحًا',
      'passwordMinLength': 'يجب أن تكون كلمة المرور \u200F6\u200F أحرف على الأقل',
      'showPassword': 'أظهر كلمة المرور',
      'hidePassword': 'أخفِ كلمة المرور',
      'rememberMe': 'تذكرني',
      'createAccount': 'إنشاء حساب',
      'signInWithGoogle': 'تسجيل الدخول عبر Google',
      'enterPhoneNumber': 'أدخل رقم هاتفك',

      // Profile Screen
      'personalInfo': 'المعلومات الشخصية',
      'ratingAndStats': 'التقييم والإحصائيات',
      'completedTasks': 'المهام المكتملة',
      'taskUnit': 'مهمة',
      'yearUnit': 'سنة',
      'identityDocument': 'وثيقة الهوية',
      'healthCertificate': 'الشهادة الصحية',
      'aboutMe': 'نبذة عني',
      'deleteAddress': 'حذف',
      'confirmDelete': 'تأكيد الحذف',
      'verified': 'موثق',
      'accountVerified': 'حسابك موثق ✓',
      'accountVerifiedDescription': 'تم التحقق من هويتك وشهادتك الصحية بنجاح. يمكنك الآن تقديم عروضك على طلبات العملاء.',
      'completeYourInfo': 'يرجى إكمال بياناتك',
      'verifiedProviderDescription': 'لتصبح مزود خدمة موثق، يجب عليك رفع وثيقة الهوية والشهادة الصحية من صفحة تعديل الملف الشخصي.',
      'underReview': 'قيد المراجعة',
      'pleaseCompleteData': 'يرجى إكمال البيانات',
      'requestUnderReview': 'طلبك قيد المراجعة ⏳',
      'requestUnderReviewDescription': 'جاري مراجعة وثائقك من قبل الإدارة. سنقوم بإشعارك فور الانتهاء من المراجعة.',
      'requestRejected': 'طلبك مرفوض ✗',
      'requestRejectedDescription': 'عذراً، لم يتم قبول وثائقك. يرجى تحديث وثيقة الهوية والشهادة الصحية من صفحة تعديل الملف الشخصي.',
      'deleteAddressConfirm': 'هل أنت متأكد من حذف هذا العنوان؟',
      'addressDeletedSuccess': 'تم حذف العنوان بنجاح',
      'defaultAddressSetSuccess': 'تم تعيين العنوان الافتراضي بنجاح',
      'documentNotAvailable': 'الوثيقة غير متوفرة',
      'loggingOut': 'جاري تسجيل الخروج...',
      'logoutSuccess': 'تم تسجيل الخروج بنجاح',
      'logoutError': 'حدث خطأ أثناء تسجيل الخروج',
      'close': 'إغلاق',
      'bookingConfirmedSuccess': 'تم تأكيد الحجز بنجاح',
      'name': 'الاسم',
      'phone': 'الهاتف',
      'accountType': 'نوع الحساب',
      'emailAddress': 'البريد الإلكتروني',
      'defaultLabel': 'افتراضي',
      'failedToDeleteAddress': 'فشل حذف العنوان',
      'failedToSetDefaultAddress': 'فشل تعيين العنوان الافتراضي',
      'joined': 'تاريخ الانضمام',
      'editProfile': 'تعديل الملف الشخصي',
      'changePassword': 'تغيير كلمة المرور',
      'language': 'اللغة',
      'darkMode': 'الوضع الداكن',
      'aboutApp': 'عن التطبيق',
      'termsAndConditions': 'الشروط والأحكام',
      'privacyPolicy': 'سياسة الخصوصية',
      'contactUs': 'اتصل بنا',
      'version': 'الإصدار',
      'logoutConfirm': 'هل تريد تسجيل الخروج؟',

      // Chat Screen
      'typeMessage': 'اكتب رسالة...',
      'send': 'إرسال',
      'online': 'متصل',
      'offline': 'غير متصل',
      'typing': 'يكتب...',
      'delivered': 'تم التسليم',
      'read': 'تم القراءة',
      'image': 'صورة',
      'video': 'فيديو',
      'file': 'ملف',

      // Notifications
      'markAllAsRead': 'وضع علامة مقروء على الكل',
      'clearAll': 'مسح الكل',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'newBooking': 'حجز جديد',
      'bookingAccepted': 'تم قبول الحجز',
      'bookingRejected': 'تم رفض الحجز',
      'bookingCompleted': 'تم إكمال الحجز',
      'noNotificationsSubtitle': 'ستظهر الإشعارات هنا عند وجود تحديثات جديدة',
      'chatOpenError': 'خطأ: لا يمكن فتح المحادثة - معرف الحجز غير موجود',
      'unknownError': 'خطأ: ',
      'defaultUser': 'المستخدم',

      // Bookings
      'pending': 'قيد الانتظار',
      'accepted': 'مقبول',
      'inProgress': 'قيد التنفيذ',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'rejected': 'مرفوض',
      'startDate': 'تاريخ البدء',
      'endDate': 'تاريخ الانتهاء',
      'price': 'السعر',
      'total': 'الإجمالي',
      'subtotal': 'المجموع الفرعي',
      'tax': 'الضريبة',
      'discount': 'الخصم',
      'paymentMethod': 'طريقة الدفع',
      'cash': 'نقداً',
      'card': 'بطاقة',
      'wallet': 'المحفظة',

      // Service Details
      'description': 'الوصف',
      'serviceType': 'نوع الخدمة',
      'duration': 'المدة',
      'hour': 'ساعة',
      'hours': 'ساعات',
      'minute': 'دقيقة',
      'minutes': 'دقائق',
      'day': 'يوم',
      'days': 'أيام',
      'selectDate': 'اختر التاريخ',
      'selectTime': 'اختر الوقت',
      'addNotes': 'إضافة ملاحظات',
      'notes': 'ملاحظات',

      // Common Actions
      'accept': 'قبول',
      'reject': 'رفض',
      'complete': 'إكمال',
      'start': 'بدء',
      'finish': 'إنهاء',
      'submit': 'إرسال',
      'apply': 'تطبيق',
      'reset': 'إعادة تعيين',
      'filter': 'تصفية',
      'sortBy': 'ترتيب حسب',
      'uploadImage': 'رفع صورة',
      'takePhoto': 'التقاط صورة',
      'chooseFromGallery': 'اختر من المعرض',
      'remove': 'إزالة',
      'update': 'تحديث',
      'download': 'تحميل',
      'share': 'مشاركة',
      'copy': 'نسخ',
      'paste': 'لصق',

      // Offer Dialog
      'submitProfessionalOffer': 'تقديم عرض احترافي',
      'clientBudget': 'ميزانية العميل',
      'chooseOfferType': 'اختر نوع العرض',
      'acceptClientPrice': 'قبول سعر العميل',
      'proposeDifferentPrice': 'اقتراح سعر مختلف',
      'mustBeHigherThanClientBudget': 'يجب أن يكون أعلى من ميزانية العميل',
      'proposedPrice': 'السعر المقترح',
      'enterPriceInEGP': 'أدخل السعر بالجنيه',
      'egpCurrency': 'جنيه',
      'messageToClient': 'رسالة للعميل',
      'messageToClientHint': 'مثال: لدي خبرة \u200F5\u200F سنوات في هذا المجال وأستطيع تقديم خدمة احترافية...',
      'sendOffer': 'إرسال العرض',
      'proposedPriceMustBeHigher': 'السعر المقترح يجب أن يكون أعلى من ميزانية العميل',
      'sendingOffer': 'جاري إرسال العرض...',
      'offerSubmittedSuccessfully': 'تم إرسال عرضك بنجاح!',
      'waitForClientResponse': 'انتظر رد العميل',
      'failedToSubmitOffer': 'فشل إرسال العرض',
      'newClient': 'عميل جديد',
      'bookingRequest': 'طلب حجز',
      'cannotLoadImage': 'لا يمكن تحميل الصورة',

      // Booking Request Details
      'date': 'التاريخ',
      'time': 'الوقت',
      'status': 'الحالة',
      'offersCount': 'عدد العروض',
      'offer': 'عرض',
      'offers': 'عروض',
      'budget': 'الميزانية',
      'offersSubmitted': 'العروض المقدمة',
      'clientInformation': 'معلومات العميل',
      'clientName': 'اسم العميل',
      'detailedAddress': 'العنوان التفصيلي',
      'expectedDuration': 'المدة المتوقعة',
      'requestStatus': 'حالة الطلب',
      'availableForOffers': 'متاح للعروض',
      'newStatus': 'جديد',
      'submitPriceOffer': 'قدم عرض السعر',
      'requiredPrice': 'السعر المطلوب',
      'additionalNotesOptional': 'ملاحظات إضافية (اختياري)',
      'addAnyAdditionalNotes': 'أضف أي ملاحظات أو تفاصيل إضافية...',
      'pleaseEnterPrice': 'الرجاء إدخال السعر',
      'noOffersReceived': 'لم تستلم عروض',
      'receivedOffersText': 'تم استلام',

      // Status Messages
      'success': 'نجح',
      'failed': 'فشل',
      'warning': 'تحذير',
      'info': 'معلومات',
      'noData': 'لا توجد بيانات',
      'noInternet': 'لا يوجد اتصال بالإنترنت',
      'noInternetConnection': 'لا يوجد اتصال بالإنترنت',
      'checkInternetConnection': 'تحقق من اتصالك بالشبكة وحاول مرة أخرى',
      'tryAgain': 'حاول مرة أخرى',
      'comingSoon': 'قريباً',
      'underMaintenance': 'تحت الصيانة',

      // Validation
      'required': 'مطلوب',
      'invalidEmail': 'بريد إلكتروني غير صحيح',
      'invalidPhone': 'رقم هاتف غير صحيح',
      'passwordMismatch': 'كلمات المرور غير متطابقة',
      'passwordTooShort': 'كلمة المرور قصيرة جداً',
      'fieldRequired': 'هذا الحقل مطلوب',

      // Screen Titles
      'reviewProviders': 'مراجعة مزودي الخدمة',
      'manageClients': 'إدارة العملاء',
      'rejectedProviders': 'المزودين المرفوضين',
      'verifiedProviders': 'المزودين الموثقين',
      'resetPassword': 'استعادة كلمة المرور',
      'confirmOffer': 'تأكيد العرض',
      'requestDetails': 'تفاصيل الطلب',
      'servicePreferences': 'تفضيلات الخدمات',
      'paymentGateway': 'بوابة الدفع',
      'conversations': 'المحادثات',
      'activeBookingsTitle': 'حجوزاتي النشطة',
      'serviceDetails': 'تفاصيل الخدمة',
      'customerDetails': 'تفاصيل العميل',
      'providerDetailsTitle': 'تفاصيل مقدم الخدمة',
      'offerDetailsTitle': 'تفاصيل العرض',
      'paymentTitle': 'الدفع',
      'servicesTitle': 'الخدمات',
      'editClientProfileTitle': 'تعديل الملف الشخصي',
      'editProviderProfileTitle': 'تعديل الملف الشخصي',
      'manageServices': 'إدارة الخدمات',
      'serviceCategories': 'إدارة فئات الخدمات',
      'conversationsRatingsComplaints': 'المحادثات، التقييمات، والشكاوى',
      'confirmServiceCompletion': 'تأكيد إكمال الخدمة',
      'offersReceived': 'العروض المقدمة',
      'recentBookings': 'آخر الحجوزات',
      'savedAddresses': 'العناوين المحفوظة',
      'noAddressesSaved': 'لا توجد عناوين محفوظة',
      'noBookingsCurrently': 'لا توجد حجوزات حالياً',
      'defaultAddress': 'افتراضي',
      'address': 'عنوان',
      'setAsDefault': 'تعيين كافتراضي',
      'viewOffers': 'عرض العروض',

      // Booking Dialog
      'bookingDate': 'تاريخ الحجز',
      'selectBookingDate': 'اختر تاريخ الحجز',
      'bookingTime': 'وقت الحجز',
      'selectBookingTime': 'اختر وقت الحجز',
      'serviceDuration': 'مدة الخدمة (ساعات)',
      'durationExample': 'مثال: \u200F8\u200F ساعات',
      'selectAddress': 'اختر العنوان',
      'confirmBooking': 'تأكيد الحجز',
      'optionalPrice': 'السعر المقترح (اختياري)',
      'priceExample': 'مثال: \u200F500\u200F جنيه',
      'bookingNotes': 'ملاحظات الحجز',
      'bookingNotesHint': 'أضف أي طلبات خاصة أو ملاحظات...',

      // Validation & Errors
      'pleaseCompleteAllFields': 'يرجى ملء جميع الحقول',
      'bookingErrorMessage': 'خطأ في الحجز',
      'pleaseTryAgainLater': 'يرجى المحاولة مرة أخرى لاحقاً',
      'bookingSuccess': 'تم إرسال طلب الحجز بنجاح!',
      'providerWillContact': 'سيتواصل معك مقدمو الخدمة قريباً',
      'pleaseSelectAddress': 'يرجى اختيار العنوان',

      // Address Dialog
      'addNewAddress': 'إضافة عنوان جديد',
      'useCurrentLocation': 'استخدام الموقع الحالي',
      'addressLabel': 'تسمية العنوان',
      'addressLabelHint': 'مثل: المنزل، العمل',
      'street': 'الشارع',
      'buildingNumber': 'رقم المبنى',
      'floor': 'الطابق',
      'apartment': 'الشقة',
      'additionalInfo': 'معلومات إضافية',
      'additionalInfoHint': 'أي تفاصيل إضافية...',
      'setDefault': 'تعيين كافتراضي',
      'addAddress': 'إضافة عنوان',
      'gettingLocation': 'جاري الحصول على موقعك...',
      'locationError': 'فشل الحصول على الموقع',

      // Service Display
      'perHour': '/ساعة',
      'egp': 'جنيه',
      'viewDetails': 'عرض التفاصيل',
      'available': 'متاح',
      'notAvailable': 'غير متاح',
      'contactInfo': 'معلومات الاتصال',
      'serviceCategory': 'فئة الخدمة',

      // Months
      'january': 'يناير',
      'february': 'فبراير',
      'march': 'مارس',
      'april': 'أبريل',
      'may': 'مايو',
      'june': 'يونيو',
      'july': 'يوليو',
      'august': 'أغسطس',
      'september': 'سبتمبر',
      'october': 'أكتوبر',
      'november': 'نوفمبر',
      'december': 'ديسمبر',

      // Time
      'am': 'ص',
      'pm': 'م',
      'morning': 'صباحاً',
      'evening': 'مساءً',

      // Category Selection
      'selectCategory': 'اختر الفئة',
      'browseAllCategories': 'تصفح جميع فئات الخدمات المتاحة',
      'selected': 'محددة',
      'noServicesInCategory': 'لا توجد خدمات متاحة في هذه الفئة',

      // Location & Errors
      'detectingLocation': 'جاري تحديد الموقع...',
      'useMyCurrentLocation': 'تحديد موقعي الحالي',
      'locationDetectedSuccess': 'تم تحديد الموقع بنجاح',
      'addressLabelOptional': 'تسمية العنوان (اختياري)',
      'exampleHomeWork': 'مثال: المنزل، العمل، إلخ',
      'locationPermissionDenied': 'تم رفض إذن الموقع',
      'locationPermissionDeniedPermanently': 'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من الإعدادات',
      'failedToDetect': 'فشل تحديد الموقع',
      'addressAddedSuccess': 'تم إضافة العنوان بنجاح',
      'failedToAddAddress': 'فشل إضافة العنوان',
      'noAddressesSavedMessage': 'قم بإضافة عنوان جديد للمتابعة',
      'perUnit': 'لكل \u200F{unit}\u200F',

      // Chat Screen Specific
      'connectionError': 'حدث خطأ في الاتصال - جاري المحاولة مرة أخرى',
      'disconnectedInternet': 'انقطع الاتصال - تحقق من الإنترنت',
      'alreadyRated': 'لقد قمت بالفعل بتقييم هذا الحجز',
      'rateOtherParty': 'تقييم الطرف الآخر',
      'howWasExperience': 'كيف كانت تجربتك؟',
      'commentOptional': 'التعليق (اختياري)',
      'shareYourOpinion': 'شاركنا رأيك عن التجربة...',
      'submitRatingButton': 'إرسال التقييم',
      'veryBad': 'سيئ جداً 😞',
      'bad': 'سيئ 😕',
      'acceptable': 'مقبول 😐',
      'goodRating': 'جيد 😊',
      'excellent': 'ممتاز 🌟',
      'userInfoNotFound': 'لم يتم العثور على معلومات المستخدم',
      'startServiceButton': 'بدء الخدمة',
      'startServiceConfirm': 'هل أنت متأكد من بدء الخدمة الآن؟',
      'completeServiceButton': 'إنهاء الخدمة',
      'completeServiceConfirm': 'هل أنت متأكد من إنهاء الخدمة؟\n\nسيتم إرسال إشعار للعميل لتأكيد الإكمال.',
      'confirmCompletionButton': 'تأكيد اكتمال الخدمة',
      'confirmCompletionMessage': 'هل تؤكد أن الخدمة قد تمت بالفعل وبشكل مُرضي؟\n\nبعد التأكيد، سيتم إغلاق الحجز.',
      'yesConfirm': 'نعم، تأكيد',
      'failedToFetchBooking': 'فشل في جلب بيانات الحجز',
      'errorFetchingBooking': 'خطأ في جلب بيانات الحجز',
      'serviceLabel': 'الخدمة',
      'bookingStatusLabel': 'حالة الحجز',
      'confirmedStatus': 'مؤكد',
      'paymentCompletedStatus': 'تم الدفع',
      'pendingCompletionStatus': 'في انتظار التأكيد',
      'startConversationMessage': 'ابدأ المحادثة بإرسال رسالة',
      'yesterdayLabel': 'أمس',
      'completePaymentButton': 'إتمام الدفع',
      'connectingStatus': 'جاري الاتصال...',

      // Customer Home Screen Specific
      'newBookingTitle': 'حجز جديد',
      'comprehensiveHomeCleaning': 'تعريف منزلي شامل',
      'bookingDateLabel': 'تاريخ الحجز',
      'bookingTimeLabel': 'وقت الحجز',
      'serviceDurationLabel': 'مدة الخدمة (ساعات)',
      'durationExampleHint': 'مثال: \u200F8\u200F ساعات',
      'selectAddressLabel': 'اختر العنوان',
      'noAddressesYetMessage': 'لا توجد عناوين محفوظة',
      'pleaseAddAddressMessage': 'يرجى إضافة عنوان من إعدادات الحساب',
      'defaultAddressLabel': 'افتراضي',
      'pleaseSelectAddressMessage': 'يرجى اختيار عنوان',
      'bookingErrorDialogTitle': 'خطأ في الحجز',
      'troubleshootingTipsLabel': 'نصائح لحل المشكلة:',
      'troubleshootingTip1': '\u200F1.\u200F تأكد من أن السيرفر شغال على المنفذ \u200F8000\u200F',
      'troubleshootingTip2': '\u200F2.\u200F تحقق من إعدادات الشبكة',
      'troubleshootingTip3': '\u200F3.\u200F راجع وحدة التحكم للمزيد من التفاصيل',
      'searchForServiceHint': 'ابحث عن خدمة أو عاملة...',
      'houseCleaningCategory': 'تنظيف منزلي',
      'cookingCategory': 'طبخ',
      'childCareCategory': 'رعاية أطفال',
      'elderlyCareCategory': 'رعاية مسنين',
      'laundryCategory': 'غسيل ملابس',
      'ironingCategory': 'كي ملابس',
      'pressToExploreLabel': 'اضغط للاستكشاف',
      'perUnitLabel': 'لكل \u200F{unit}\u200F',
      'availableStatus': 'متاحة',
      'busyStatus': 'مشغولة',
      'egyptCountry': 'مصر',
      'addNewAddressButton': 'إضافة عنوان جديد',
      'addressLabelOptionalHint': 'تسمية العنوان (اختياري)',
      'exampleHomeWorkHint': 'مثل: المنزل، العمل، إلخ',
      'locationPermissionDeniedError': 'تم رفض إذن الموقع',
      'locationPermissionDeniedPermanentlyError': 'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من الإعدادات',
      'failedToDetectLocationError': 'فشل تحديد الموقع',
      'failedToDetectLocationMessage': 'فشل تحديد الموقع: \u200F{error}\u200F',
      'detectingLocationStatus': 'جاري تحديد الموقع...',
      'detectMyCurrentLocationButton': 'تحديد موقعي الحالي',
      'locationDetectedSuccessMessage': 'تم تحديد الموقع بنجاح',
      'cityLabelText': 'المدينة',
      'addressLabelText': 'العنوان',
      'unspecifiedText': 'غير محدد',
      'saveButtonText': 'حفظ',
      'chatOpenFailure': 'فشل فتح المحادثة',
      'addressLabelDefault': 'عنوان',

      // Provider Home Screen Specific
      'chatOpenErrorSnackbar': 'حدث خطأ أثناء فتح المحادثة',
      'newBookingRequestsLabel': 'طلبات حجز جديدة',
      'noSearchResultsLabel': 'لا توجد نتائج للبحث',
      'noNewBookingRequestsMessage': 'لا توجد طلبات حجز جديدة',
      'serviceProviderLabel': 'مقدم الخدمة',
      'bookingDetailsTitleText': 'تفاصيل الحجز',
      'submitOfferButton': 'قدم عرض',
      'ratingLabelText': 'تقييم',
      'newClientLabelText': 'عميل جديد',
      'accountUnderReviewTitle': 'حسابك قيد المراجعة',
      'waitForAdminReviewMessage': 'انتظر الأدمن مراجعة ملفك الشخصي.',
      'accountRejectedTitle': 'تم رفض حسابك',
      'accountRejectedMessageText': 'لا يحق لك تقديم طلب. تم رفض حسابك من قبل الإدارة.\n\nيرجى التواصل مع الإدارة لمعرفة الأسباب.',
      'verificationRequiredTitle': 'التوثيق مطلوب',
      'verificationRequiredMessageText': 'يجب أن يكون حسابك موثقاً لتقديم عروض على طلبات الحجز.\n\nيرجى إكمال بيانات ملفك الشخصي وتحميل المستندات المطلوبة.',
      'submitProfessionalOfferDialogTitle': 'تقديم عرض احترافي',
      'selectedLabel': 'مختار',
      'proposeDifferentPriceOption': 'اقتراح سعر مختلف',
      'mustBeHigherThanBudgetHint': 'يجب أن يكون أعلى من ميزانية العميل',
      'enterPriceEGPHint': 'أدخل السعر بالجنيه',
      'egpLabelText': 'جنيه',
      'exampleMessageHint': 'مثال: لدي خبرة \u200F5\u200F سنوات في هذا المجال وأستطيع تقديم خدمة احترافية...',
      'sendingOfferStatusText': 'جاري إرسال العرض...',
      'offerSentSuccessMessage': 'تم إرسال عرضك بنجاح',
      'offerSentFailedMessage': 'فشل إرسال العرض',
      'cannotLoadImageError': 'لا يمكن تحميل الصورة',
      'submitOfferNowButton': 'قدم عرضك الآن',

      // Edit Client Profile Screen Specific
      'failedToLoadData': 'فشل تحميل البيانات',
      'errorLoadingData': 'خطأ في تحميل البيانات',
      'errorLoadingCategories': 'خطأ في تحميل الفئات',
      'locationPermissionDeniedMessage': 'تم رفض إذن الموقع',
      'noLocationInfo': 'لم يتم العثور على معلومات الموقع',
      'errorDetectingLocation': 'خطأ في تحديد الموقع',
      'profileUpdatedSuccess': 'تم تحديث الملف الشخصي بنجاح',
      'failedToUpdateProfile': 'فشل تحديث الملف الشخصي',
      'errorUpdating': 'خطأ في التحديث',
      'noCategoriesAvailable': 'لا توجد فئات خدمات متاحة حالياً',
      'preferredServices': 'الخدمات المفضلة',
      'selectPreferredServicesHint': 'اختر الخدمات التي تهتم بها لتسهيل عملية البحث',
      'optionalLocation': 'الموقع (إجباري)',
      'detectCurrentLocation': 'تحديد موقعي الحالي',
      'locationDetected': 'تم تحديد الموقع',
      'addressWillBeSavedAuto': 'سيتم حفظ هذا العنوان تلقائياً في العناوين المحفوظة',

      // Client Bookings Screen Specific
      'myBookingsTitle': 'حجوزاتي',
      'refresh': 'تحديث',
      'noBookingsCurrentlyMessage': 'لا توجد حجوزات حالياً',
      'startBookingNewService': 'ابدأ بحجز خدمة جديدة',
      'viewAvailableOffers': 'عرض العروض المتاحة',
      'openStatus': 'مفتوح',
      'tomorrow': 'غداً',
      'availableOffersTitle': 'العروض المتاحة',
      'noOffersYet': 'لا توجد عروض بعد',
      'waitForProviders': 'انتظر حتى يتقدم مقدمو الخدمة بعروضهم',
      'closeButton': 'إغلاق',
      'priceLabel': 'السعر',
      'acceptOffer': 'قبول العرض',

      // Booking Confirmation Screen
      'offerAcceptedSuccessfully': 'تم قبول العرض بنجاح!',
      'confirmBookingDetailsMessage': 'تأكيد تفاصيل الحجز لإتمام العملية',
      'serviceAddress': 'عنوان الخدمة',
      'change': 'تغيير',
      'addNotesOrInstructions': 'أضف أي ملاحظات أو تعليمات خاصة...',
      'priceSummary': 'ملخص السعر',
      'servicePrice': 'سعر الخدمة',
      'serviceFee': 'رسوم الخدمة',
      'bookingConfirmed': 'تم تأكيد الحجز!',
      'errorConfirmingBooking': 'حدث خطأ أثناء تأكيد الحجز',
      'addressSelectionComingSoon': 'سيتم إضافة صفحة اختيار العنوان لاحقاً',
      'householdService': 'خدمة منزلية',
      'notSpecified': 'غير محدد',
      'bookingConfirmedMessage': 'تم تأكيد حجزك بنجاح. يمكنك متابعة حالة الحجز من صفحة "حجوزاتي".',

      // Payment Fee
      'paymentGatewayFee': 'رسوم بوابة الدفع',
      'paymentFeeDeduction': 'يتم خصم \u200F15%\u200F رسوم بوابة الدفع',
      'paymentFeeDeductionShort': 'يتم خصم \u200F15%\u200F رسوم بوابة الدفع',
      'paymentFeeDeductionFromAmount': 'يتم خصم \u200F15%\u200F رسوم بوابة الدفع من المبلغ',
      'totalAmount': 'المبلغ الإجمالي',
      'gatewayFee': 'رسوم البوابة (\u200F15%\u200F)',
      'netAmountDue': 'صافي المبلغ المستحق',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for easy access
  String get welcome => translate('welcome');
  String get welcomeYou => translate('welcomeYou');
  String get aminaPlatform => translate('aminaPlatform');
  String get incompleteData => translate('incompleteData');
  String get completeDataFirst => translate('completeDataFirst');
  String get completeDataButton => translate('completeDataButton');
  String get completeDataHint => translate('completeDataHint');
  String get hello => translate('hello');
  String get search => translate('search');
  String get services => translate('services');
  String get providers => translate('providers');
  String get viewAll => translate('viewAll');
  String get loading => translate('loading');
  String get topRatedProviders => translate('topRatedProviders');
  String get popularServices => translate('popularServices');
  String get categories => translate('categories');
  String get requestService => translate('requestService');
  String get myBookings => translate('myBookings');
  String get activeBookings => translate('activeBookings');
  String get completedBookings => translate('completedBookings');
  String get bookingDetails => translate('bookingDetails');
  String get bookNow => translate('bookNow');
  String get dateAndTime => translate('dateAndTime');
  String get amount => translate('amount');
  String get city => translate('city');
  String get providerProfile => translate('providerProfile');
  String get rating => translate('rating');
  String get reviews => translate('reviews');
  String get experience => translate('experience');
  String get skills => translate('skills');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgotPassword');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get noResults => translate('noResults');
  String get noNotifications => translate('noNotifications');
  String get noBookings => translate('noBookings');
  String get successfullyBooked => translate('successfullyBooked');
  String get bookingCancelled => translate('bookingCancelled');
  String get home => translate('home');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get notifications => translate('notifications');
  String get logout => translate('logout');
  String get location => translate('location');
  String get error => translate('error');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get quickServices => translate('quickServices');
  String get availableOffers => translate('availableOffers');
  String get user => translate('user');
  String get searchServiceOrWorker => translate('searchServiceOrWorker');
  String get noSearchResults => translate('noSearchResults');
  String get noServicesAvailable => translate('noServicesAvailable');
  String get noOffersAvailable => translate('noOffersAvailable');
  String get noWorkersAvailable => translate('noWorkersAvailable');
  String get currency => translate('currency');
  String get noSavedAddresses => translate('noSavedAddresses');
  String get egypt => translate('egypt');
  String get bookingError => translate('bookingError');
  String get ok => translate('ok');
  String get confirmExit => translate('confirmExit');
  String get exitAppMessage => translate('exitAppMessage');
  String get exit => translate('exit');
  String get pleaseLoginFirst => translate('pleaseLoginFirst');
  String get ratingAndStats => translate('ratingAndStats');
  String get completedTasks => translate('completedTasks');
  String get taskUnit => translate('taskUnit');
  String get yearUnit => translate('yearUnit');
  String get identityDocument => translate('identityDocument');
  String get healthCertificate => translate('healthCertificate');
  String get aboutMe => translate('aboutMe');
  String get deleteAddress => translate('deleteAddress');
  String get confirmDelete => translate('confirmDelete');
  String get verified => translate('verified');
  String get accountVerified => translate('accountVerified');
  String get accountVerifiedDescription => translate('accountVerifiedDescription');
  String get completeYourInfo => translate('completeYourInfo');
  String get verifiedProviderDescription => translate('verifiedProviderDescription');
  String get underReview => translate('underReview');
  String get pleaseCompleteData => translate('pleaseCompleteData');
  String get requestUnderReview => translate('requestUnderReview');
  String get requestUnderReviewDescription => translate('requestUnderReviewDescription');
  String get requestRejected => translate('requestRejected');
  String get requestRejectedDescription => translate('requestRejectedDescription');
  String get deleteAddressConfirm => translate('deleteAddressConfirm');
  String get addressDeletedSuccess => translate('addressDeletedSuccess');
  String get defaultAddressSetSuccess => translate('defaultAddressSetSuccess');
  String get emailAddress => translate('emailAddress');
  String get defaultLabel => translate('defaultLabel');
  String get failedToDeleteAddress => translate('failedToDeleteAddress');
  String get failedToSetDefaultAddress => translate('failedToSetDefaultAddress');
  String get documentNotAvailable => translate('documentNotAvailable');
  String get loggingOut => translate('loggingOut');
  String get logoutSuccess => translate('logoutSuccess');
  String get logoutError => translate('logoutError');
  String get close => translate('close');
  String get bookingConfirmedSuccess => translate('bookingConfirmedSuccess');
  String get ratings => translate('ratings');
  String get noRatingsYet => translate('noRatingsYet');
  String get failedToLoadRatings => translate('failedToLoadRatings');
  String get errorOccurredRatings => translate('errorOccurredRatings');
  String get daysAgo => translate('daysAgo');
  String get weeksAgo => translate('weeksAgo');
  String get weekAgo => translate('weekAgo');
  String get monthsAgo => translate('monthsAgo');
  String get monthAgo => translate('monthAgo');
  String get yearsAgo => translate('yearsAgo');
  String get yearAgo => translate('yearAgo');

  // Auth Screen getters
  String get chooseAccountType => translate('chooseAccountType');
  String get pleaseSelectAccountType => translate('pleaseSelectAccountType');
  String get client => translate('client');
  String get lookingForHomeServices => translate('lookingForHomeServices');
  String get serviceProvider => translate('serviceProvider');
  String get provideHomeServices => translate('provideHomeServices');
  String get loginSuccess => translate('loginSuccess');
  String get loginFailed => translate('loginFailed');
  String get operationSuccess => translate('operationSuccess');
  String get errorOccurred => translate('errorOccurred');
  String get firstName => translate('firstName');
  String get lastName => translate('lastName');
  String get phoneNumber => translate('phoneNumber');
  String get confirmPassword => translate('confirmPassword');
  String get signUp => translate('signUp');
  String get signIn => translate('signIn');
  String get continueAsGuest => translate('continueAsGuest');
  String get or => translate('or');
  String get welcomeBack => translate('welcomeBack');
  String get joinUs => translate('joinUs');
  String get gladToSeeYouAgain => translate('gladToSeeYouAgain');
  String get createNewAccount => translate('createNewAccount');
  String get enterValidName => translate('enterValidName');
  String get enterValidEmail => translate('enterValidEmail');
  String get passwordMinLength => translate('passwordMinLength');
  String get showPassword => translate('showPassword');
  String get hidePassword => translate('hidePassword');
  String get rememberMe => translate('rememberMe');
  String get createAccount => translate('createAccount');
  String get signInWithGoogle => translate('signInWithGoogle');
  String get enterPhoneNumber => translate('enterPhoneNumber');

  // Profile Screen getters
  String get personalInfo => translate('personalInfo');
  String get name => translate('name');
  String get phone => translate('phone');
  String get accountType => translate('accountType');
  String get joined => translate('joined');
  String get editProfile => translate('editProfile');
  String get changePassword => translate('changePassword');
  String get language => translate('language');
  String get darkMode => translate('darkMode');
  String get aboutApp => translate('aboutApp');
  String get termsAndConditions => translate('termsAndConditions');
  String get privacyPolicy => translate('privacyPolicy');
  String get contactUs => translate('contactUs');
  String get version => translate('version');
  String get logoutConfirm => translate('logoutConfirm');

  // Chat Screen getters
  String get typeMessage => translate('typeMessage');
  String get send => translate('send');
  String get online => translate('online');
  String get offline => translate('offline');
  String get typing => translate('typing');
  String get delivered => translate('delivered');
  String get read => translate('read');
  String get image => translate('image');
  String get video => translate('video');
  String get file => translate('file');

  // Notifications getters
  String get markAllAsRead => translate('markAllAsRead');
  String get clearAll => translate('clearAll');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get newBooking => translate('newBooking');
  String get bookingAccepted => translate('bookingAccepted');
  String get bookingRejected => translate('bookingRejected');
  String get bookingCompleted => translate('bookingCompleted');
  String get noNotificationsSubtitle => translate('noNotificationsSubtitle');
  String get chatOpenError => translate('chatOpenError');
  String get unknownError => translate('unknownError');
  String get defaultUser => translate('defaultUser');

  // Bookings getters
  String get pending => translate('pending');
  String get accepted => translate('accepted');
  String get inProgress => translate('inProgress');
  String get completed => translate('completed');
  String get cancelled => translate('cancelled');
  String get rejected => translate('rejected');
  String get startDate => translate('startDate');
  String get endDate => translate('endDate');
  String get price => translate('price');
  String get total => translate('total');
  String get subtotal => translate('subtotal');
  String get tax => translate('tax');
  String get discount => translate('discount');
  String get paymentMethod => translate('paymentMethod');
  String get cash => translate('cash');
  String get card => translate('card');
  String get wallet => translate('wallet');

  // Service Details getters
  String get description => translate('description');
  String get serviceType => translate('serviceType');
  String get duration => translate('duration');
  String get hour => translate('hour');
  String get hours => translate('hours');
  String get minute => translate('minute');
  String get minutes => translate('minutes');
  String get day => translate('day');
  String get days => translate('days');
  String get selectDate => translate('selectDate');
  String get selectTime => translate('selectTime');
  String get addNotes => translate('addNotes');
  String get notes => translate('notes');

  // Common Actions getters
  String get accept => translate('accept');
  String get reject => translate('reject');
  String get complete => translate('complete');
  String get start => translate('start');
  String get finish => translate('finish');
  String get submit => translate('submit');
  String get apply => translate('apply');
  String get reset => translate('reset');
  String get filter => translate('filter');
  String get sortBy => translate('sortBy');
  String get uploadImage => translate('uploadImage');
  String get takePhoto => translate('takePhoto');
  String get chooseFromGallery => translate('chooseFromGallery');
  String get remove => translate('remove');
  String get update => translate('update');
  String get download => translate('download');
  String get share => translate('share');
  String get copy => translate('copy');
  String get paste => translate('paste');

  // Offer Dialog getters
  String get submitProfessionalOffer => translate('submitProfessionalOffer');
  String get clientBudget => translate('clientBudget');
  String get chooseOfferType => translate('chooseOfferType');
  String get acceptClientPrice => translate('acceptClientPrice');
  String get proposeDifferentPrice => translate('proposeDifferentPrice');
  String get mustBeHigherThanClientBudget => translate('mustBeHigherThanClientBudget');
  String get proposedPrice => translate('proposedPrice');
  String get enterPriceInEGP => translate('enterPriceInEGP');
  String get egpCurrency => translate('egpCurrency');
  String get messageToClient => translate('messageToClient');
  String get messageToClientHint => translate('messageToClientHint');
  String get sendOffer => translate('sendOffer');
  String get proposedPriceMustBeHigher => translate('proposedPriceMustBeHigher');
  String get sendingOffer => translate('sendingOffer');
  String get offerSubmittedSuccessfully => translate('offerSubmittedSuccessfully');
  String get waitForClientResponse => translate('waitForClientResponse');
  String get failedToSubmitOffer => translate('failedToSubmitOffer');
  String get newClient => translate('newClient');
  String get bookingRequest => translate('bookingRequest');
  String get cannotLoadImage => translate('cannotLoadImage');

  // Booking Request Details getters
  String get date => translate('date');
  String get time => translate('time');
  String get status => translate('status');
  String get offersCount => translate('offersCount');
  String get offer => translate('offer');
  String get offers => translate('offers');
  String get budget => translate('budget');
  String get offersSubmitted => translate('offersSubmitted');
  String get clientInformation => translate('clientInformation');
  String get clientName => translate('clientName');
  String get detailedAddress => translate('detailedAddress');
  String get expectedDuration => translate('expectedDuration');
  String get requestStatus => translate('requestStatus');
  String get availableForOffers => translate('availableForOffers');
  String get newStatus => translate('newStatus');
  String get submitPriceOffer => translate('submitPriceOffer');
  String get requiredPrice => translate('requiredPrice');
  String get additionalNotesOptional => translate('additionalNotesOptional');
  String get addAnyAdditionalNotes => translate('addAnyAdditionalNotes');
  String get pleaseEnterPrice => translate('pleaseEnterPrice');
  String get noOffersReceived => translate('noOffersReceived');
  String get receivedOffersText => translate('receivedOffersText');

  // Status Messages getters
  String get success => translate('success');
  String get failed => translate('failed');
  String get warning => translate('warning');
  String get info => translate('info');
  String get noData => translate('noData');
  String get noInternet => translate('noInternet');
  String get noInternetConnection => translate('noInternetConnection');
  String get checkInternetConnection => translate('checkInternetConnection');
  String get tryAgain => translate('tryAgain');
  String get comingSoon => translate('comingSoon');
  String get underMaintenance => translate('underMaintenance');

  // Validation getters
  String get required => translate('required');
  String get invalidEmail => translate('invalidEmail');
  String get invalidPhone => translate('invalidPhone');
  String get passwordMismatch => translate('passwordMismatch');
  String get passwordTooShort => translate('passwordTooShort');
  String get fieldRequired => translate('fieldRequired');

  // Screen Titles getters
  String get reviewProviders => translate('reviewProviders');
  String get manageClients => translate('manageClients');
  String get rejectedProviders => translate('rejectedProviders');
  String get verifiedProviders => translate('verifiedProviders');
  String get resetPassword => translate('resetPassword');
  String get confirmOffer => translate('confirmOffer');
  String get requestDetails => translate('requestDetails');
  String get servicePreferences => translate('servicePreferences');
  String get paymentGateway => translate('paymentGateway');
  String get conversations => translate('conversations');
  String get activeBookingsTitle => translate('activeBookingsTitle');
  String get serviceDetails => translate('serviceDetails');
  String get customerDetails => translate('customerDetails');
  String get providerDetailsTitle => translate('providerDetailsTitle');
  String get offerDetailsTitle => translate('offerDetailsTitle');
  String get paymentTitle => translate('paymentTitle');
  String get servicesTitle => translate('servicesTitle');
  String get editClientProfileTitle => translate('editClientProfileTitle');
  String get editProviderProfileTitle => translate('editProviderProfileTitle');
  String get manageServices => translate('manageServices');
  String get serviceCategories => translate('serviceCategories');
  String get conversationsRatingsComplaints => translate('conversationsRatingsComplaints');
  String get confirmServiceCompletion => translate('confirmServiceCompletion');
  String get offersReceived => translate('offersReceived');
  String get recentBookings => translate('recentBookings');
  String get savedAddresses => translate('savedAddresses');
  String get noAddressesSaved => translate('noAddressesSaved');
  String get noBookingsCurrently => translate('noBookingsCurrently');
  String get defaultAddress => translate('defaultAddress');
  String get address => translate('address');
  String get setAsDefault => translate('setAsDefault');
  String get viewOffers => translate('viewOffers');

  // Booking Dialog getters
  String get bookingDate => translate('bookingDate');
  String get selectBookingDate => translate('selectBookingDate');
  String get bookingTime => translate('bookingTime');
  String get selectBookingTime => translate('selectBookingTime');
  String get serviceDuration => translate('serviceDuration');
  String get durationExample => translate('durationExample');
  String get selectAddress => translate('selectAddress');
  String get confirmBooking => translate('confirmBooking');
  String get optionalPrice => translate('optionalPrice');
  String get priceExample => translate('priceExample');
  String get bookingNotes => translate('bookingNotes');
  String get bookingNotesHint => translate('bookingNotesHint');

  // Validation & Errors getters
  String get pleaseCompleteAllFields => translate('pleaseCompleteAllFields');
  String get bookingErrorMessage => translate('bookingErrorMessage');
  String get pleaseTryAgainLater => translate('pleaseTryAgainLater');
  String get bookingSuccess => translate('bookingSuccess');
  String get providerWillContact => translate('providerWillContact');
  String get pleaseSelectAddress => translate('pleaseSelectAddress');

  // Address Dialog getters
  String get addNewAddress => translate('addNewAddress');
  String get useCurrentLocation => translate('useCurrentLocation');
  String get addressLabel => translate('addressLabel');
  String get addressLabelHint => translate('addressLabelHint');
  String get street => translate('street');
  String get buildingNumber => translate('buildingNumber');
  String get floor => translate('floor');
  String get apartment => translate('apartment');
  String get additionalInfo => translate('additionalInfo');
  String get additionalInfoHint => translate('additionalInfoHint');
  String get addAddress => translate('addAddress');
  String get gettingLocation => translate('gettingLocation');
  String get locationError => translate('locationError');

  // Service Display getters
  String get perHour => translate('perHour');
  String get egp => translate('egp');
  String get viewDetails => translate('viewDetails');
  String get available => translate('available');
  String get notAvailable => translate('notAvailable');
  String get contactInfo => translate('contactInfo');
  String get serviceCategory => translate('serviceCategory');

  // Months getters
  String get january => translate('january');
  String get february => translate('february');
  String get march => translate('march');
  String get april => translate('april');
  String get may => translate('may');
  String get june => translate('june');
  String get july => translate('july');
  String get august => translate('august');
  String get september => translate('september');
  String get october => translate('october');
  String get november => translate('november');
  String get december => translate('december');

  // Days getters
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');
  String get sunday => translate('sunday');

  // Time getters
  String get am => translate('am');
  String get pm => translate('pm');
  String get morning => translate('morning');
  String get evening => translate('evening');

  // Category Selection getters
  String get selectCategory => translate('selectCategory');
  String get browseAllCategories => translate('browseAllCategories');
  String get selected => translate('selected');
  String get noServicesInCategory => translate('noServicesInCategory');

  // Location & Errors getters
  String get detectingLocation => translate('detectingLocation');
  String get useMyCurrentLocation => translate('useMyCurrentLocation');
  String get locationDetectedSuccess => translate('locationDetectedSuccess');
  String get addressLabelOptional => translate('addressLabelOptional');
  String get exampleHomeWork => translate('exampleHomeWork');
  String get locationPermissionDenied => translate('locationPermissionDenied');
  String get locationPermissionDeniedPermanently => translate('locationPermissionDeniedPermanently');
  String get failedToDetect => translate('failedToDetect');
  String get addressAddedSuccess => translate('addressAddedSuccess');
  String get failedToAddAddress => translate('failedToAddAddress');
  String get noAddressesSavedMessage => translate('noAddressesSavedMessage');
  String get perUnit => translate('perUnit');

  // Chat Screen getters
  String get connectionError => translate('connectionError');
  String get disconnectedInternet => translate('disconnectedInternet');
  String get alreadyRated => translate('alreadyRated');
  String get rateOtherParty => translate('rateOtherParty');
  String get howWasExperience => translate('howWasExperience');
  String get commentOptional => translate('commentOptional');
  String get shareYourOpinion => translate('shareYourOpinion');
  String get submitRatingButton => translate('submitRatingButton');
  String get veryBad => translate('veryBad');
  String get bad => translate('bad');
  String get acceptable => translate('acceptable');
  String get goodRating => translate('goodRating');
  String get excellent => translate('excellent');
  String get userInfoNotFound => translate('userInfoNotFound');
  String get startServiceButton => translate('startServiceButton');
  String get startServiceConfirm => translate('startServiceConfirm');
  String get completeServiceButton => translate('completeServiceButton');
  String get completeServiceConfirm => translate('completeServiceConfirm');
  String get confirmCompletionButton => translate('confirmCompletionButton');
  String get confirmCompletionMessage => translate('confirmCompletionMessage');
  String get yesConfirm => translate('yesConfirm');
  String get failedToFetchBooking => translate('failedToFetchBooking');
  String get errorFetchingBooking => translate('errorFetchingBooking');
  String get serviceLabel => translate('serviceLabel');
  String get bookingStatusLabel => translate('bookingStatusLabel');
  String get confirmedStatus => translate('confirmedStatus');
  String get paymentCompletedStatus => translate('paymentCompletedStatus');
  String get pendingCompletionStatus => translate('pendingCompletionStatus');
  String get startConversationMessage => translate('startConversationMessage');
  String get yesterdayLabel => translate('yesterdayLabel');
  String get completePaymentButton => translate('completePaymentButton');
  String get connectingStatus => translate('connectingStatus');

  // Customer Home Screen getters
  String get newBookingTitle => translate('newBookingTitle');
  String get comprehensiveHomeCleaning => translate('comprehensiveHomeCleaning');
  String get bookingDateLabel => translate('bookingDateLabel');
  String get bookingTimeLabel => translate('bookingTimeLabel');
  String get serviceDurationLabel => translate('serviceDurationLabel');
  String get durationExampleHint => translate('durationExampleHint');
  String get selectAddressLabel => translate('selectAddressLabel');
  String get noAddressesYetMessage => translate('noAddressesYetMessage');
  String get pleaseAddAddressMessage => translate('pleaseAddAddressMessage');
  String get defaultAddressLabel => translate('defaultAddressLabel');
  String get pleaseSelectAddressMessage => translate('pleaseSelectAddressMessage');
  String get bookingErrorDialogTitle => translate('bookingErrorDialogTitle');
  String get troubleshootingTipsLabel => translate('troubleshootingTipsLabel');
  String get searchForServiceHint => translate('searchForServiceHint');
  String get houseCleaningCategory => translate('houseCleaningCategory');
  String get cookingCategory => translate('cookingCategory');
  String get childCareCategory => translate('childCareCategory');
  String get elderlyCareCategory => translate('elderlyCareCategory');
  String get laundryCategory => translate('laundryCategory');
  String get ironingCategory => translate('ironingCategory');
  String get pressToExploreLabel => translate('pressToExploreLabel');
  String get perUnitLabel => translate('perUnitLabel');
  String get availableStatus => translate('availableStatus');
  String get busyStatus => translate('busyStatus');
  String get egyptCountry => translate('egyptCountry');
  String get addNewAddressButton => translate('addNewAddressButton');
  String get addressLabelOptionalHint => translate('addressLabelOptionalHint');
  String get exampleHomeWorkHint => translate('exampleHomeWorkHint');
  String get locationPermissionDeniedError => translate('locationPermissionDeniedError');
  String get locationPermissionDeniedPermanentlyError => translate('locationPermissionDeniedPermanentlyError');
  String get failedToDetectLocationError => translate('failedToDetectLocationError');
  String get detectingLocationStatus => translate('detectingLocationStatus');
  String get detectMyCurrentLocationButton => translate('detectMyCurrentLocationButton');
  String get locationDetectedSuccessMessage => translate('locationDetectedSuccessMessage');
  String get cityLabelText => translate('cityLabelText');
  String get addressLabelText => translate('addressLabelText');
  String get unspecifiedText => translate('unspecifiedText');
  String get saveButtonText => translate('saveButtonText');

  // Provider Home Screen getters
  String get chatOpenErrorSnackbar => translate('chatOpenErrorSnackbar');
  String get newBookingRequestsLabel => translate('newBookingRequestsLabel');
  String get noSearchResultsLabel => translate('noSearchResultsLabel');
  String get noNewBookingRequestsMessage => translate('noNewBookingRequestsMessage');
  String get serviceProviderLabel => translate('serviceProviderLabel');
  String get bookingDetailsTitleText => translate('bookingDetailsTitleText');
  String get submitOfferButton => translate('submitOfferButton');
  String get ratingLabelText => translate('ratingLabelText');
  String get newClientLabelText => translate('newClientLabelText');
  String get accountUnderReviewTitle => translate('accountUnderReviewTitle');
  String get waitForAdminReviewMessage => translate('waitForAdminReviewMessage');
  String get accountRejectedTitle => translate('accountRejectedTitle');
  String get accountRejectedMessageText => translate('accountRejectedMessageText');
  String get verificationRequiredTitle => translate('verificationRequiredTitle');
  String get verificationRequiredMessageText => translate('verificationRequiredMessageText');
  String get submitProfessionalOfferDialogTitle => translate('submitProfessionalOfferDialogTitle');
  String get selectedLabel => translate('selectedLabel');
  String get proposeDifferentPriceOption => translate('proposeDifferentPriceOption');
  String get mustBeHigherThanBudgetHint => translate('mustBeHigherThanBudgetHint');
  String get enterPriceEGPHint => translate('enterPriceEGPHint');
  String get egpLabelText => translate('egpLabelText');
  String get exampleMessageHint => translate('exampleMessageHint');
  String get sendingOfferStatusText => translate('sendingOfferStatusText');
  String get offerSentSuccessMessage => translate('offerSentSuccessMessage');
  String get offerSentFailedMessage => translate('offerSentFailedMessage');
  String get cannotLoadImageError => translate('cannotLoadImageError');
  String get submitOfferNowButton => translate('submitOfferNowButton');

  // Edit Client Profile Screen getters
  String get failedToLoadData => translate('failedToLoadData');
  String get errorLoadingData => translate('errorLoadingData');
  String get errorLoadingCategories => translate('errorLoadingCategories');
  String get locationPermissionDeniedMessage => translate('locationPermissionDeniedMessage');
  String get noLocationInfo => translate('noLocationInfo');
  String get errorDetectingLocation => translate('errorDetectingLocation');
  String get profileUpdatedSuccess => translate('profileUpdatedSuccess');
  String get failedToUpdateProfile => translate('failedToUpdateProfile');
  String get errorUpdating => translate('errorUpdating');
  String get noCategoriesAvailable => translate('noCategoriesAvailable');
  String get preferredServices => translate('preferredServices');
  String get selectPreferredServicesHint => translate('selectPreferredServicesHint');
  String get optionalLocation => translate('optionalLocation');
  String get detectCurrentLocation => translate('detectCurrentLocation');
  String get locationDetected => translate('locationDetected');
  String get addressWillBeSavedAuto => translate('addressWillBeSavedAuto');

  // Client Bookings Screen getters
  String get myBookingsTitle => translate('myBookingsTitle');
  String get refresh => translate('refresh');
  String get noBookingsCurrentlyMessage => translate('noBookingsCurrentlyMessage');
  String get startBookingNewService => translate('startBookingNewService');
  String get viewAvailableOffers => translate('viewAvailableOffers');
  String get openStatus => translate('openStatus');
  String get tomorrow => translate('tomorrow');
  String get availableOffersTitle => translate('availableOffersTitle');
  String get noOffersYet => translate('noOffersYet');
  String get waitForProviders => translate('waitForProviders');
  String get closeButton => translate('closeButton');
  String get priceLabel => translate('priceLabel');
  String get acceptOffer => translate('acceptOffer');

  // Booking Confirmation Screen
  String get offerAcceptedSuccessfully => translate('offerAcceptedSuccessfully');
  String get confirmBookingDetailsMessage => translate('confirmBookingDetailsMessage');
  String get serviceAddress => translate('serviceAddress');
  String get change => translate('change');
  String get addNotesOrInstructions => translate('addNotesOrInstructions');
  String get priceSummary => translate('priceSummary');
  String get servicePrice => translate('servicePrice');
  String get serviceFee => translate('serviceFee');
  String get bookingConfirmed => translate('bookingConfirmed');
  String get errorConfirmingBooking => translate('errorConfirmingBooking');
  String get addressSelectionComingSoon => translate('addressSelectionComingSoon');
  String get householdService => translate('householdService');
  String get notSpecified => translate('notSpecified');
  String get bookingConfirmedMessage => translate('bookingConfirmedMessage');

  // Customer Home Screen Additional getters (only the new ones not defined elsewhere)
  String get troubleshootingTip1 => translate('troubleshootingTip1');
  String get troubleshootingTip2 => translate('troubleshootingTip2');
  String get troubleshootingTip3 => translate('troubleshootingTip3');
  String get failedToDetectLocationMessage => translate('failedToDetectLocationMessage');
  String get chatOpenFailure => translate('chatOpenFailure');
  String get addressLabelDefault => translate('addressLabelDefault');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
