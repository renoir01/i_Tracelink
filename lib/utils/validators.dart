/// Form validation utilities for the iTraceLink application
///
/// Provides validators for common input fields including:
/// - Phone numbers (Rwanda format)
/// - Email addresses
/// - Quantities and numeric values
/// - Prices and currency
/// - Percentages
/// - Text fields

class Validators {
  // ==================== PHONE NUMBER VALIDATION ====================

  /// Validates Rwanda phone numbers
  ///
  /// Accepted formats:
  /// - +250 7XX XXX XXX
  /// - +250 7XXXXXXXX
  /// - 07XX XXX XXX
  /// - 07XXXXXXXX
  ///
  /// Examples:
  /// - +250 788 123 456 ✓
  /// - +250788123456 ✓
  /// - 0788 123 456 ✓
  /// - 0788123456 ✓
  static String? validateRwandaPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and special characters for validation
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Rwanda phone format: +250 7X XXX XXXX or 07X XXX XXXX
    final phoneRegex = RegExp(r'^(\+250|0)(7[0-9])\d{7}$');

    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Invalid Rwanda phone number (e.g., +250 788 123 456)';
    }

    return null;
  }

  // ==================== EMAIL VALIDATION ====================

  /// Validates email address format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ==================== QUANTITY VALIDATION ====================

  /// Validates quantity fields (must be positive numbers)
  ///
  /// Parameters:
  /// - value: The input value to validate
  /// - unit: Optional unit name for error message (default: 'kg')
  /// - allowZero: Whether to allow zero as valid (default: false)
  /// - min: Minimum allowed value (default: > 0)
  /// - max: Maximum allowed value (optional)
  static String? validateQuantity(
    String? value, {
    String unit = 'kg',
    bool allowZero = false,
    double? min,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }

    final quantity = double.tryParse(value.trim());

    if (quantity == null) {
      return 'Please enter a valid number';
    }

    final minValue = min ?? (allowZero ? 0.0 : 0.01);

    if (quantity < minValue) {
      if (allowZero && quantity == 0) {
        return null; // Zero is allowed
      }
      return 'Quantity must be at least $minValue $unit';
    }

    if (max != null && quantity > max) {
      return 'Quantity cannot exceed $max $unit';
    }

    return null;
  }

  // ==================== PRICE VALIDATION ====================

  /// Validates price/currency fields
  ///
  /// Parameters:
  /// - value: The input value to validate
  /// - currency: Currency symbol for error message (default: 'RWF')
  /// - allowZero: Whether to allow zero as valid (default: false)
  /// - maxDecimals: Maximum decimal places allowed (default: 2)
  static String? validatePrice(
    String? value, {
    String currency = 'RWF',
    bool allowZero = false,
    int maxDecimals = 2,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value.trim());

    if (price == null) {
      return 'Please enter a valid price';
    }

    if (!allowZero && price <= 0) {
      return 'Price must be greater than 0';
    }

    if (allowZero && price < 0) {
      return 'Price cannot be negative';
    }

    // Check decimal places
    if (value.contains('.')) {
      final decimalPart = value.split('.')[1];
      if (decimalPart.length > maxDecimals) {
        return 'Price can have maximum $maxDecimals decimal places';
      }
    }

    return null;
  }

  // ==================== PERCENTAGE VALIDATION ====================

  /// Validates percentage fields (0-100)
  ///
  /// Parameters:
  /// - value: The input value to validate
  /// - fieldName: Name of the field for error messages (default: 'Value')
  /// - min: Minimum percentage (default: 0)
  /// - max: Maximum percentage (default: 100)
  static String? validatePercentage(
    String? value, {
    String fieldName = 'Value',
    double min = 0.0,
    double max = 100.0,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final percentage = double.tryParse(value.trim());

    if (percentage == null) {
      return 'Please enter a valid number';
    }

    if (percentage < min || percentage > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  // ==================== TEXT FIELD VALIDATION ====================

  /// Validates required text fields
  ///
  /// Parameters:
  /// - value: The input value to validate
  /// - fieldName: Name of the field for error message (default: 'Field')
  /// - minLength: Minimum required length (optional)
  /// - maxLength: Maximum allowed length (optional)
  static String? validateNotEmpty(
    String? value, {
    String fieldName = 'Field',
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (minLength != null && value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null;
  }

  // ==================== PASSWORD VALIDATION ====================

  /// Validates password strength
  ///
  /// Requirements:
  /// - At least 6 characters (configurable)
  /// - Optional: must contain uppercase letter
  /// - Optional: must contain lowercase letter
  /// - Optional: must contain number
  /// - Optional: must contain special character
  static String? validatePassword(
    String? value, {
    int minLength = 6,
    bool requireUppercase = false,
    bool requireLowercase = false,
    bool requireNumber = false,
    bool requireSpecialChar = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChar && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // ==================== LOCATION VALIDATION ====================

  /// Validates Rwanda location fields (district, sector, cell)
  static String? validateLocation(String? value, {required String locationType}) {
    if (value == null || value.trim().isEmpty) {
      return '$locationType is required';
    }

    if (value.trim().length < 2) {
      return '$locationType must be at least 2 characters';
    }

    return null;
  }

  // ==================== REGISTRATION NUMBER VALIDATION ====================

  /// Validates business/cooperative registration numbers
  ///
  /// Rwanda registration format: XXX-XXXX-XXXXXX
  static String? validateRegistrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }

    // Basic format check (adapt to actual Rwanda registration format)
    if (value.trim().length < 5) {
      return 'Invalid registration number format';
    }

    return null;
  }

  // ==================== DATE VALIDATION ====================

  /// Validates that a date is not in the future
  static String? validatePastDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }

    return null;
  }

  /// Validates that a date is in the future
  static String? validateFutureDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isBefore(DateTime.now())) {
      return '$fieldName must be in the future';
    }

    return null;
  }

  // ==================== IRON CONTENT VALIDATION ====================

  /// Validates iron content values (specific for bean traceability)
  ///
  /// Typical range: 40-120 mg per 100g
  static String? validateIronContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Iron content is required';
    }

    final ironContent = double.tryParse(value.trim());

    if (ironContent == null) {
      return 'Please enter a valid number';
    }

    if (ironContent < 0 || ironContent > 200) {
      return 'Iron content must be between 0 and 200 mg/100g';
    }

    return null;
  }

  // ==================== LAND SIZE VALIDATION ====================

  /// Validates land size in hectares
  static String? validateLandSize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Land size is required';
    }

    final landSize = double.tryParse(value.trim());

    if (landSize == null) {
      return 'Please enter a valid number';
    }

    if (landSize <= 0) {
      return 'Land size must be greater than 0';
    }

    if (landSize > 10000) {
      return 'Land size seems unusually large, please verify';
    }

    return null;
  }

  // ==================== MEMBER COUNT VALIDATION ====================

  /// Validates number of members in a cooperative
  static String? validateMemberCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of members is required';
    }

    final memberCount = int.tryParse(value.trim());

    if (memberCount == null) {
      return 'Please enter a valid whole number';
    }

    if (memberCount < 1) {
      return 'Must have at least 1 member';
    }

    if (memberCount > 100000) {
      return 'Member count seems unusually high, please verify';
    }

    return null;
  }
}
