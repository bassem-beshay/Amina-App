/// Helper class to determine currency based on country
class CurrencyHelper {
  /// Map of country names to their currencies
  static const Map<String, String> _countryCurrencyMap = {
    // Arabic names
    'مصر': 'EGP',
    'السعودية': 'SAR',
    'المملكة العربية السعودية': 'SAR',
    'الإمارات': 'AED',
    'الإمارات العربية المتحدة': 'AED',
    'الكويت': 'KWD',
    'قطر': 'QAR',
    'البحرين': 'BHD',
    'عمان': 'OMR',
    'الأردن': 'JOD',
    'لبنان': 'LBP',
    'سوريا': 'SYP',
    'العراق': 'IQD',
    'ليبيا': 'LYD',
    'تونس': 'TND',
    'الجزائر': 'DZD',
    'المغرب': 'MAD',
    'السودان': 'SDG',
    'اليمن': 'YER',

    // English names
    'Egypt': 'EGP',
    'Saudi Arabia': 'SAR',
    'KSA': 'SAR',
    'United Arab Emirates': 'AED',
    'UAE': 'AED',
    'Kuwait': 'KWD',
    'Qatar': 'QAR',
    'Bahrain': 'BHD',
    'Oman': 'OMR',
    'Jordan': 'JOD',
    'Lebanon': 'LBP',
    'Syria': 'SYP',
    'Iraq': 'IQD',
    'Libya': 'LYD',
    'Tunisia': 'TND',
    'Algeria': 'DZD',
    'Morocco': 'MAD',
    'Sudan': 'SDG',
    'Yemen': 'YER',
  };

  /// Get currency code for a given country
  /// Returns the currency code if found, otherwise returns the default currency (EGP)
  static String getCurrencyForCountry(String? country, {String defaultCurrency = 'EGP'}) {
    if (country == null || country.isEmpty) {
      return defaultCurrency;
    }

    // Try exact match first
    if (_countryCurrencyMap.containsKey(country)) {
      return _countryCurrencyMap[country]!;
    }

    // Try case-insensitive match
    final countryLower = country.toLowerCase().trim();
    for (var entry in _countryCurrencyMap.entries) {
      if (entry.key.toLowerCase() == countryLower) {
        return entry.value;
      }
    }

    // Try partial match (contains)
    for (var entry in _countryCurrencyMap.entries) {
      if (countryLower.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(countryLower)) {
        return entry.value;
      }
    }

    return defaultCurrency;
  }

  /// Get currency symbol for a given currency code
  static String getCurrencySymbol(String currencyCode) {
    const symbols = {
      'EGP': 'ج.م',
      'SAR': 'ر.س',
      'AED': 'د.إ',
      'KWD': 'د.ك',
      'QAR': 'ر.ق',
      'BHD': 'د.ب',
      'OMR': 'ر.ع',
      'JOD': 'د.أ',
      'LBP': 'ل.ل',
      'SYP': 'ل.س',
      'IQD': 'د.ع',
      'LYD': 'د.ل',
      'TND': 'د.ت',
      'DZD': 'د.ج',
      'MAD': 'د.م',
      'SDG': 'ج.س',
      'YER': 'ر.ي',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
    };

    return symbols[currencyCode] ?? currencyCode;
  }

  /// Get currency name in Arabic
  static String getCurrencyNameArabic(String currencyCode) {
    const names = {
      'EGP': 'جنيه مصري',
      'SAR': 'ريال سعودي',
      'AED': 'درهم إماراتي',
      'KWD': 'دينار كويتي',
      'QAR': 'ريال قطري',
      'BHD': 'دينار بحريني',
      'OMR': 'ريال عماني',
      'JOD': 'دينار أردني',
      'LBP': 'ليرة لبنانية',
      'SYP': 'ليرة سورية',
      'IQD': 'دينار عراقي',
      'LYD': 'دينار ليبي',
      'TND': 'دينار تونسي',
      'DZD': 'دينار جزائري',
      'MAD': 'درهم مغربي',
      'SDG': 'جنيه سوداني',
      'YER': 'ريال يمني',
      'USD': 'دولار أمريكي',
      'EUR': 'يورو',
      'GBP': 'جنيه إسترليني',
    };

    return names[currencyCode] ?? currencyCode;
  }

  /// Get currency for a user based on their profile
  /// Tries to extract country from:
  /// 1. Client profile's country field
  /// 2. Provider profile's country field
  /// 3. Client addresses
  /// 4. Formatted address (by parsing common country names)
  ///
  /// Returns the currency code (e.g., 'EGP', 'SAR') or default currency if not found
  static String getCurrencyForUser(dynamic user, {String defaultCurrency = 'EGP'}) {
    if (user == null) {
      return defaultCurrency;
    }

    String? country;

    // Try to get country from client profile
    if (user.clientProfile != null) {
      final profile = user.clientProfile;

      // First, try direct country field
      country = profile.country;

      // If no country in profile, try to extract from addresses
      if ((country == null || country.isEmpty) &&
          profile.addresses != null &&
          profile.addresses!.isNotEmpty) {
        for (var address in profile.addresses!) {
          if (address.country != null && address.country!.isNotEmpty) {
            country = address.country;
            break;
          }
        }
      }

      // If still no country, try to detect from formatted_address
      if ((country == null || country.isEmpty) && profile.formattedAddress != null) {
        country = _detectCountryFromAddress(profile.formattedAddress!);
      }
    }
    // Try to get country from provider profile
    else if (user.providerProfile != null) {
      final profile = user.providerProfile;
      country = profile.country;
    }

    return getCurrencyForCountry(country, defaultCurrency: defaultCurrency);
  }

  /// Detect country name from formatted address by looking for common country/city names
  static String? _detectCountryFromAddress(String address) {
    final addressLower = address.toLowerCase();

    // Egypt
    if (addressLower.contains('egypt') ||
        addressLower.contains('مصر') ||
        addressLower.contains('cairo') ||
        addressLower.contains('القاهرة')) {
      return 'Egypt';
    }

    // Saudi Arabia
    if (addressLower.contains('saudi') ||
        addressLower.contains('السعودية') ||
        addressLower.contains('riyadh') ||
        addressLower.contains('الرياض') ||
        addressLower.contains('jeddah') ||
        addressLower.contains('جدة')) {
      return 'Saudi Arabia';
    }

    // UAE
    if (addressLower.contains('uae') ||
        addressLower.contains('الإمارات') ||
        addressLower.contains('dubai') ||
        addressLower.contains('دبي') ||
        addressLower.contains('abu dhabi') ||
        addressLower.contains('أبوظبي')) {
      return 'UAE';
    }

    // Kuwait
    if (addressLower.contains('kuwait') || addressLower.contains('الكويت')) {
      return 'Kuwait';
    }

    // Qatar
    if (addressLower.contains('qatar') || addressLower.contains('قطر') || addressLower.contains('doha')) {
      return 'Qatar';
    }

    // Bahrain
    if (addressLower.contains('bahrain') || addressLower.contains('البحرين')) {
      return 'Bahrain';
    }

    // Oman
    if (addressLower.contains('oman') || addressLower.contains('عمان') || addressLower.contains('muscat')) {
      return 'Oman';
    }

    // Jordan
    if (addressLower.contains('jordan') || addressLower.contains('الأردن') || addressLower.contains('amman')) {
      return 'Jordan';
    }

    return null;
  }
}
