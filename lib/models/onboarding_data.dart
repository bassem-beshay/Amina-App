/// Account type chosen during onboarding.
enum AccountType { user, provider }

/// Provider sub-type (only relevant when [AccountType.provider]).
enum ProviderType { company, individual }

/// Carries the state collected across the multi-step onboarding flow.
///
/// This is intentionally a plain mutable object passed between screens via
/// constructor arguments. No backend wiring yet (mock flow): the fields are
/// gathered locally and used only to drive navigation and the final role
/// routing.
class OnboardingData {
  String fullName;
  String phoneNumber;
  AccountType accountType;
  ProviderType providerType;

  // Uploaded document paths (local file paths, not yet sent to the server).
  String? taxCardPath;
  String? companyLogoPath;
  String? idFrontPath;
  String? idBackPath;

  OnboardingData({
    this.fullName = '',
    this.phoneNumber = '',
    this.accountType = AccountType.user,
    this.providerType = ProviderType.company,
  });

  bool get isProvider => accountType == AccountType.provider;
}
