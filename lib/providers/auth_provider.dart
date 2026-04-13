import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/validators.dart';
import '../models/user_account.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String userName;
  final String userEmail;
  final String? userPhotoPath;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.userName = '',
    this.userEmail = '',
    this.userPhotoPath,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? userName,
    String? userEmail,
    String? userPhotoPath,
    String? error,
    bool clearError = false,
    bool clearPhoto = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoPath: clearPhoto ? null : (userPhotoPath ?? this.userPhotoPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          isLoggedIn: StorageService.isLoggedIn,
          userName: StorageService.userName,
          userEmail: StorageService.userEmail,
          userPhotoPath: StorageService.currentUser?.photoPath,
        ));

  // ---------------- Email login ----------------

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final emailErr = Validators.validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(isLoading: false, error: emailErr);
      return false;
    }

    final lookup = _emailLookup(email);
    final user = await DatabaseService.findUserByEmailLookup(lookup);
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Aucun compte trouvé pour cet email',
      );
      return false;
    }

    if (user.authProvider != 'email') {
      state = state.copyWith(
        isLoading: false,
        error:
            'Ce compte utilise ${user.authProvider == 'google' ? 'Google' : 'Apple'}. Connectez-vous via ce service.',
      );
      return false;
    }

    if (!EncryptionService.verifyPassword(password, user.passwordHash)) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email ou mot de passe incorrect',
      );
      return false;
    }

    final token = EncryptionService.generateSessionToken();
    final updated = user.copyWith(
      sessionToken: token,
      lastLoginAt: DateTime.now(),
    );
    await DatabaseService.updateUser(updated);
    await StorageService.setCurrentSession(updated, token);

    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      userName: updated.fullName,
      userEmail: updated.email,
      clearError: true,
    );
    return true;
  }

  // ---------------- Email signup ----------------

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Prénom et nom sont obligatoires',
      );
      return false;
    }

    final emailErr = Validators.validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(isLoading: false, error: emailErr);
      return false;
    }

    final pwdErr = Validators.validatePassword(password);
    if (pwdErr != null) {
      state = state.copyWith(isLoading: false, error: pwdErr);
      return false;
    }

    if (phone != null && phone.trim().isNotEmpty) {
      final phoneErr = Validators.validatePhone(phone, required: false);
      if (phoneErr != null) {
        state = state.copyWith(isLoading: false, error: phoneErr);
        return false;
      }
    }

    if (await DatabaseService.isEmailTaken(email)) {
      state = state.copyWith(
        isLoading: false,
        error: 'Un compte existe déjà pour cet email',
      );
      return false;
    }

    if (phone != null &&
        phone.trim().isNotEmpty &&
        await DatabaseService.isPhoneTaken(phone)) {
      state = state.copyWith(
        isLoading: false,
        error: 'Un compte existe déjà pour ce numéro de téléphone',
      );
      return false;
    }

    final token = EncryptionService.generateSessionToken();
    final user = UserAccount(
      id: _uuid.v4(),
      email: email.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone?.trim(),
      passwordHash: EncryptionService.hashPassword(password),
      authProvider: 'email',
      sessionToken: token,
      lastLoginAt: DateTime.now(),
    );

    await DatabaseService.insertUser(user);
    await StorageService.setCurrentSession(user, token);

    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      userName: user.fullName,
      userEmail: user.email,
      clearError: true,
    );
    return true;
  }

  // ---------------- Google sign-in ----------------

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final google = GoogleSignIn(scopes: ['email']);
      final account = await google.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      return _upsertOAuthUser(
        email: account.email,
        firstName: account.displayName?.split(' ').first ?? 'User',
        lastName: account.displayName?.split(' ').skip(1).join(' ') ?? '',
        provider: 'google',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connexion Google échouée: ${e.toString()}',
      );
      return false;
    }
  }

  // ---------------- Apple sign-in ----------------

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final email = credential.email;
      if (email == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Apple n\'a pas fourni d\'email',
        );
        return false;
      }
      return _upsertOAuthUser(
        email: email,
        firstName: credential.givenName ?? 'User',
        lastName: credential.familyName ?? '',
        provider: 'apple',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connexion Apple échouée: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> _upsertOAuthUser({
    required String email,
    required String firstName,
    required String lastName,
    required String provider,
  }) async {
    final lookup = _emailLookup(email);
    var user = await DatabaseService.findUserByEmailLookup(lookup);
    final token = EncryptionService.generateSessionToken();

    if (user == null) {
      user = UserAccount(
        id: _uuid.v4(),
        email: email,
        firstName: firstName,
        lastName: lastName,
        passwordHash: '',
        authProvider: provider,
        sessionToken: token,
        lastLoginAt: DateTime.now(),
      );
      await DatabaseService.insertUser(user);
    } else {
      if (user.authProvider != provider) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Cet email est déjà associé à un compte ${user.authProvider}.',
        );
        return false;
      }
      user = user.copyWith(sessionToken: token, lastLoginAt: DateTime.now());
      await DatabaseService.updateUser(user);
    }

    await StorageService.setCurrentSession(user, token);
    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      userName: user.fullName,
      userEmail: user.email,
      clearError: true,
    );
    return true;
  }

  // ---------------- Logout ----------------

  Future<void> logout() async {
    await StorageService.clearSession();
    state = const AuthState();
  }

  // ---------------- Change password ----------------

  /// Changes the user's password and rotates the session token.
  /// All other devices using the previous token will fail validation
  /// and be forced to log in again (effectively logging them out).
  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';

    if (user.authProvider != 'email') {
      return 'Mot de passe non modifiable pour les comptes ${user.authProvider}';
    }

    if (!EncryptionService.verifyPassword(currentPassword, user.passwordHash)) {
      return 'Mot de passe actuel incorrect';
    }

    final pwdErr = Validators.validatePassword(newPassword);
    if (pwdErr != null) return pwdErr;

    // Rotate session token — invalidates all other devices.
    final newToken = EncryptionService.generateSessionToken();
    final updated = user.copyWith(
      passwordHash: EncryptionService.hashPassword(newPassword),
      sessionToken: newToken,
      passwordChangedAt: DateTime.now(),
    );
    await DatabaseService.updateUser(updated);
    await StorageService.setCurrentSession(updated, newToken);
    return null; // success
  }

  /// Update the current user's profile photo path.
  Future<void> updatePhoto(String? photoPath) async {
    final user = StorageService.currentUser;
    if (user == null) return;
    final updated = user.copyWith(photoPath: photoPath);
    await DatabaseService.updateUser(updated);
    await StorageService.setCurrentSession(updated, user.sessionToken ?? '');
    state = state.copyWith(userPhotoPath: photoPath);
  }

  String _emailLookup(String email) =>
      DatabaseService.lookupHashForEmail(email);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
