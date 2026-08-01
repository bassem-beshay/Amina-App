/// Account type chosen during onboarding.
enum AccountType { user, provider }

/// Provider sub-type (only relevant when [AccountType.provider]).
enum ProviderType { company, individual }

/// Carries the state collected across the multi-step onboarding flow.
///
/// This is intentionally a plain mutable object passed between screens via
/// constructor arguments. Role-specific screens use the collected values to
/// complete registration and submit the provider/client profile.
class OnboardingData {
  String fullName;
  String phoneNumber;
  String? registrationToken;
  AccountType accountType;
  ProviderType providerType;

  // Uploaded document paths. Provider verification submits these files to the
  // backend when the user taps "Submit for review".
  String? taxCardPath;
  String? companyLogoPath;
  String? idFrontPath;
  String? idBackPath;

  // Individual-provider profile data collected across P05/P07.
  String bio;
  String city;
  String address;
  List<int> preferredServiceCategories;

  OnboardingData({
    this.fullName = '',
    this.phoneNumber = '',
    this.accountType = AccountType.user,
    this.providerType = ProviderType.company,
    this.registrationToken,
    this.bio = '',
    this.city = '',
    this.address = '',
    this.preferredServiceCategories = const <int>[],
  });

  bool get isProvider => accountType == AccountType.provider;
}
