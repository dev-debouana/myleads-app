/// User account stored in the local SQLite database.
///
/// Sensitive fields (email, names, phone, dateOfBirth) are persisted
/// in encrypted form via [EncryptionService] before being written.
class UserAccount {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? dateOfBirth;
  final String passwordHash; // "salt:hash" or empty for OAuth accounts
  final String authProvider; // 'email' | 'google' | 'apple'
  final String? sessionToken;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime passwordChangedAt;
  final String? photoPath; // local file path to profile photo

  UserAccount({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    required this.passwordHash,
    this.authProvider = 'email',
    this.sessionToken,
    DateTime? createdAt,
    this.lastLoginAt,
    DateTime? passwordChangedAt,
    this.photoPath,
  })  : createdAt = createdAt ?? DateTime.now(),
        passwordChangedAt = passwordChangedAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();

  UserAccount copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? passwordHash,
    String? authProvider,
    String? sessionToken,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? passwordChangedAt,
    String? photoPath,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      passwordHash: passwordHash ?? this.passwordHash,
      authProvider: authProvider ?? this.authProvider,
      sessionToken: sessionToken ?? this.sessionToken,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

/// Saved payment method (only stored if user opts in).
class PaymentMethod {
  final String id;
  final String userId;
  final String type; // 'card' | 'mobile_money' | 'paypal'
  final String label;
  final String encryptedDetails; // AES-256 encrypted JSON
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.label,
    required this.encryptedDetails,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
