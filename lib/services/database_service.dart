import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/contact.dart';
import '../models/interaction.dart';
import '../models/reminder.dart';
import '../models/user_account.dart';
import '../core/utils/validators.dart';
import 'encryption_service.dart';
import 'web_db_factory_stub.dart'
    if (dart.library.html) 'web_db_factory_web.dart';

/// Local SQLite database service.
///
/// All sensitive PII (email, names, phone, dateOfBirth, payment info)
/// are AES-256 encrypted before being persisted. Lookup columns
/// (email_lookup, phone_lookup) are stored as deterministic hashes
/// for uniqueness checks while keeping the plaintext encrypted.
class DatabaseService {
  static Database? _db;
  static const _dbName = 'myleads.db';
  static const _dbVersion = 3;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    if (kIsWeb) {
      final webFactory = getWebDatabaseFactory();
      if (webFactory != null) {
        databaseFactory = webFactory;
      }
      return openDatabase(
        _dbName,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: replace single "project" column with project_1/2 + budgets
      await db.execute('ALTER TABLE contacts ADD COLUMN project_1 TEXT');
      await db.execute('ALTER TABLE contacts ADD COLUMN project_1_budget TEXT');
      await db.execute('ALTER TABLE contacts ADD COLUMN project_2 TEXT');
      await db.execute('ALTER TABLE contacts ADD COLUMN project_2_budget TEXT');
      // Copy old project data into project_1
      await db.execute('UPDATE contacts SET project_1 = project WHERE project IS NOT NULL');
    }
    if (oldVersion < 3) {
      // v2 → v3: add photo_path to users and contacts
      await db.execute('ALTER TABLE users ADD COLUMN photo_path TEXT');
      await db.execute('ALTER TABLE contacts ADD COLUMN photo_path TEXT');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ----- USERS -----
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email_enc TEXT NOT NULL,
        email_lookup TEXT NOT NULL UNIQUE,
        first_name_enc TEXT NOT NULL,
        last_name_enc TEXT NOT NULL,
        phone_enc TEXT,
        phone_lookup TEXT UNIQUE,
        date_of_birth_enc TEXT,
        password_hash TEXT NOT NULL,
        auth_provider TEXT NOT NULL DEFAULT 'email',
        session_token TEXT,
        created_at TEXT NOT NULL,
        last_login_at TEXT,
        password_changed_at TEXT NOT NULL,
        photo_path TEXT
      )
    ''');

    // ----- CONTACTS -----
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        job_title TEXT,
        company TEXT,
        phone TEXT,
        email TEXT,
        phone_lookup TEXT,
        email_lookup TEXT,
        source TEXT,
        project_1 TEXT,
        project_1_budget TEXT,
        project_2 TEXT,
        project_2_budget TEXT,
        interest TEXT,
        notes TEXT,
        tags TEXT,
        status TEXT NOT NULL DEFAULT 'warm',
        created_at TEXT NOT NULL,
        last_contact_date TEXT,
        avatar_color TEXT,
        capture_method TEXT NOT NULL DEFAULT 'manual',
        photo_path TEXT,
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_contacts_owner ON contacts(owner_id)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_contacts_owner_phone ON contacts(owner_id, phone_lookup) WHERE phone_lookup IS NOT NULL');
    await db.execute(
        'CREATE UNIQUE INDEX idx_contacts_owner_email ON contacts(owner_id, email_lookup) WHERE email_lookup IS NOT NULL');

    // ----- REMINDERS -----
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        contact_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'soon',
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_reminders_owner ON reminders(owner_id)');

    // ----- INTERACTIONS -----
    await db.execute('''
      CREATE TABLE interactions (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        contact_id TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_interactions_contact ON interactions(contact_id)');

    // ----- PAYMENT METHODS -----
    await db.execute('''
      CREATE TABLE payment_methods (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        type TEXT NOT NULL,
        label TEXT NOT NULL,
        encrypted_details TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ----- SESSION (active session, single row) -----
    await db.execute('''
      CREATE TABLE session (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // =====================================================================
  // USERS
  // =====================================================================

  static Future<UserAccount?> findUserByEmailLookup(String emailLookup) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email_lookup = ?',
      whereArgs: [emailLookup],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  static Future<bool> isEmailTaken(String email) async {
    final lookup = _hashLookup(Validators.normalizeEmail(email));
    final user = await findUserByEmailLookup(lookup);
    return user != null;
  }

  static Future<bool> isPhoneTaken(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;
    final lookup = _hashLookup(Validators.normalizePhone(phone));
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'phone_lookup = ?',
      whereArgs: [lookup],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<UserAccount?> findUserById(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  static Future<void> insertUser(UserAccount user) async {
    final db = await database;
    await db.insert('users', _userToRow(user));
  }

  static Future<void> updateUser(UserAccount user) async {
    final db = await database;
    await db.update(
      'users',
      _userToRow(user),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Invalidate all sessions for a user (used when password changes).
  /// Sets a fresh session token; older clients holding the previous token
  /// will fail [validateSessionToken] and be forced to re-login.
  static Future<String> rotateSessionToken(String userId) async {
    final db = await database;
    final newToken = EncryptionService.generateSessionToken();
    await db.update(
      'users',
      {'session_token': newToken},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return newToken;
  }

  static Future<bool> validateSessionToken(String userId, String token) async {
    final user = await findUserById(userId);
    return user != null && user.sessionToken == token;
  }

  static Map<String, dynamic> _userToRow(UserAccount u) => {
        'id': u.id,
        'email_enc': EncryptionService.encryptText(u.email),
        'email_lookup': _hashLookup(Validators.normalizeEmail(u.email)),
        'first_name_enc': EncryptionService.encryptText(u.firstName),
        'last_name_enc': EncryptionService.encryptText(u.lastName),
        'phone_enc':
            u.phone != null ? EncryptionService.encryptText(u.phone!) : null,
        'phone_lookup': u.phone != null && u.phone!.trim().isNotEmpty
            ? _hashLookup(Validators.normalizePhone(u.phone))
            : null,
        'date_of_birth_enc': u.dateOfBirth != null
            ? EncryptionService.encryptText(u.dateOfBirth!)
            : null,
        'password_hash': u.passwordHash,
        'auth_provider': u.authProvider,
        'session_token': u.sessionToken,
        'created_at': u.createdAt.toIso8601String(),
        'last_login_at': u.lastLoginAt?.toIso8601String(),
        'password_changed_at': u.passwordChangedAt.toIso8601String(),
        'photo_path': u.photoPath,
      };

  static UserAccount _userFromRow(Map<String, dynamic> row) {
    return UserAccount(
      id: row['id'] as String,
      email: EncryptionService.decryptText(row['email_enc'] as String?),
      firstName: EncryptionService.decryptText(row['first_name_enc'] as String?),
      lastName: EncryptionService.decryptText(row['last_name_enc'] as String?),
      phone: row['phone_enc'] != null
          ? EncryptionService.decryptText(row['phone_enc'] as String?)
          : null,
      dateOfBirth: row['date_of_birth_enc'] != null
          ? EncryptionService.decryptText(row['date_of_birth_enc'] as String?)
          : null,
      passwordHash: row['password_hash'] as String,
      authProvider: row['auth_provider'] as String? ?? 'email',
      sessionToken: row['session_token'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastLoginAt: row['last_login_at'] != null
          ? DateTime.parse(row['last_login_at'] as String)
          : null,
      passwordChangedAt:
          DateTime.parse(row['password_changed_at'] as String),
      photoPath: row['photo_path'] as String?,
    );
  }

  // =====================================================================
  // SESSION (single active user)
  // =====================================================================

  static Future<void> setSessionValue(String key, String value) async {
    final db = await database;
    await db.insert(
      'session',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSessionValue(String key) async {
    final db = await database;
    final rows = await db.query(
      'session',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> clearSession() async {
    final db = await database;
    await db.delete('session');
  }

  // =====================================================================
  // CONTACTS
  // =====================================================================

  static Future<List<Contact>> getAllContactsForOwner(String ownerId) async {
    final db = await database;
    final rows = await db.query(
      'contacts',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_contactFromRow).toList();
  }

  static Future<Contact?> findContactById(String id) async {
    final db = await database;
    final rows =
        await db.query('contacts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _contactFromRow(rows.first);
  }

  static Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.insert('contacts', _contactToRow(contact));
  }

  static Future<void> updateContact(Contact contact) async {
    final db = await database;
    await db.update(
      'contacts',
      _contactToRow(contact),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  static Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
    await db.delete('interactions', where: 'contact_id = ?', whereArgs: [id]);
    await db.delete('reminders', where: 'contact_id = ?', whereArgs: [id]);
  }

  /// Check if another contact (excluding [excludeId]) already has the same
  /// phone OR email for this owner.
  static Future<String?> findContactConflict({
    required String ownerId,
    String? phone,
    String? email,
    String? excludeId,
  }) async {
    final db = await database;
    final phoneLookup = (phone != null && phone.trim().isNotEmpty)
        ? _hashLookup(Validators.normalizePhone(phone))
        : null;
    final emailLookup = (email != null && email.trim().isNotEmpty)
        ? _hashLookup(Validators.normalizeEmail(email))
        : null;

    if (phoneLookup != null) {
      final rows = await db.query(
        'contacts',
        where: 'owner_id = ? AND phone_lookup = ? ${excludeId != null ? 'AND id != ?' : ''}',
        whereArgs: [
          ownerId,
          phoneLookup,
          if (excludeId != null) excludeId,
        ],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return 'Un contact avec ce numéro de téléphone existe déjà';
      }
    }

    if (emailLookup != null) {
      final rows = await db.query(
        'contacts',
        where: 'owner_id = ? AND email_lookup = ? ${excludeId != null ? 'AND id != ?' : ''}',
        whereArgs: [
          ownerId,
          emailLookup,
          if (excludeId != null) excludeId,
        ],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return 'Un contact avec cet email existe déjà';
      }
    }
    return null;
  }

  /// Check duplicate by full identity (firstName + lastName + same phone or email).
  static Future<bool> hasIdenticalContact({
    required String ownerId,
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? excludeId,
  }) async {
    final db = await database;
    final fn = firstName.trim().toLowerCase();
    final ln = lastName.trim().toLowerCase();
    final phoneLookup = (phone != null && phone.trim().isNotEmpty)
        ? _hashLookup(Validators.normalizePhone(phone))
        : null;
    final emailLookup = (email != null && email.trim().isNotEmpty)
        ? _hashLookup(Validators.normalizeEmail(email))
        : null;

    if (phoneLookup == null && emailLookup == null) return false;

    final whereParts = <String>[
      'owner_id = ?',
      'LOWER(first_name) = ?',
      'LOWER(last_name) = ?',
    ];
    final args = <Object?>[ownerId, fn, ln];

    final orParts = <String>[];
    if (phoneLookup != null) {
      orParts.add('phone_lookup = ?');
      args.add(phoneLookup);
    }
    if (emailLookup != null) {
      orParts.add('email_lookup = ?');
      args.add(emailLookup);
    }
    whereParts.add('(${orParts.join(' OR ')})');

    if (excludeId != null) {
      whereParts.add('id != ?');
      args.add(excludeId);
    }

    final rows = await db.query(
      'contacts',
      where: whereParts.join(' AND '),
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Map<String, dynamic> _contactToRow(Contact c) => {
        'id': c.id,
        'owner_id': c.ownerId,
        'first_name': c.firstName,
        'last_name': c.lastName,
        'job_title': c.jobTitle,
        'company': c.company,
        'phone': c.phone,
        'email': c.email,
        'phone_lookup': (c.phone != null && c.phone!.trim().isNotEmpty)
            ? _hashLookup(Validators.normalizePhone(c.phone))
            : null,
        'email_lookup': (c.email != null && c.email!.trim().isNotEmpty)
            ? _hashLookup(Validators.normalizeEmail(c.email))
            : null,
        'source': c.source,
        'project_1': c.project1,
        'project_1_budget': c.project1Budget,
        'project_2': c.project2,
        'project_2_budget': c.project2Budget,
        'interest': c.interest,
        'notes': c.notes,
        'tags': jsonEncode(c.tags),
        'status': c.status,
        'created_at': c.createdAt.toIso8601String(),
        'last_contact_date': c.lastContactDate?.toIso8601String(),
        'avatar_color': c.avatarColor,
        'capture_method': c.captureMethod,
        'photo_path': c.photoPath,
      };

  static Contact _contactFromRow(Map<String, dynamic> row) {
    return Contact(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String? ?? '',
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      jobTitle: row['job_title'] as String?,
      company: row['company'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      source: row['source'] as String?,
      project1: row['project_1'] as String?,
      project1Budget: row['project_1_budget'] as String?,
      project2: row['project_2'] as String?,
      project2Budget: row['project_2_budget'] as String?,
      interest: row['interest'] as String?,
      notes: row['notes'] as String?,
      tags: row['tags'] != null
          ? List<String>.from(jsonDecode(row['tags'] as String) as List)
          : <String>[],
      status: row['status'] as String? ?? 'warm',
      createdAt: DateTime.parse(row['created_at'] as String),
      lastContactDate: row['last_contact_date'] != null
          ? DateTime.parse(row['last_contact_date'] as String)
          : null,
      avatarColor: row['avatar_color'] as String?,
      captureMethod: row['capture_method'] as String? ?? 'manual',
      photoPath: row['photo_path'] as String?,
    );
  }

  // =====================================================================
  // REMINDERS
  // =====================================================================

  static Future<List<Reminder>> getAllRemindersForOwner(String ownerId) async {
    final db = await database;
    final rows = await db.query(
      'reminders',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'due_date ASC',
    );
    return rows.map(_reminderFromRow).toList();
  }

  static Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert('reminders', _reminderToRow(reminder));
  }

  static Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update(
      'reminders',
      _reminderToRow(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  static Map<String, dynamic> _reminderToRow(Reminder r) => {
        'id': r.id,
        'owner_id': r.ownerId,
        'contact_id': r.contactId,
        'title': r.title,
        'description': r.description,
        'due_date': r.dueDate.toIso8601String(),
        'is_completed': r.isCompleted ? 1 : 0,
        'priority': r.priority,
        'created_at': r.createdAt.toIso8601String(),
      };

  static Reminder _reminderFromRow(Map<String, dynamic> row) => Reminder(
        id: row['id'] as String,
        ownerId: row['owner_id'] as String? ?? '',
        contactId: row['contact_id'] as String,
        title: row['title'] as String,
        description: row['description'] as String?,
        dueDate: DateTime.parse(row['due_date'] as String),
        isCompleted: (row['is_completed'] as int) == 1,
        priority: row['priority'] as String? ?? 'soon',
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  // =====================================================================
  // INTERACTIONS
  // =====================================================================

  static Future<List<Interaction>> getInteractionsForContact(
      String contactId) async {
    final db = await database;
    final rows = await db.query(
      'interactions',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_interactionFromRow).toList();
  }

  static Future<void> insertInteraction(Interaction interaction) async {
    final db = await database;
    await db.insert('interactions', _interactionToRow(interaction));
  }

  static Map<String, dynamic> _interactionToRow(Interaction i) => {
        'id': i.id,
        'owner_id': i.ownerId,
        'contact_id': i.contactId,
        'type': i.type,
        'content': i.content,
        'created_at': i.createdAt.toIso8601String(),
      };

  static Interaction _interactionFromRow(Map<String, dynamic> row) =>
      Interaction(
        id: row['id'] as String,
        ownerId: row['owner_id'] as String? ?? '',
        contactId: row['contact_id'] as String,
        type: row['type'] as String,
        content: row['content'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  // =====================================================================
  // PAYMENT METHODS
  // =====================================================================

  static Future<List<PaymentMethod>> getPaymentMethodsForOwner(
      String ownerId) async {
    final db = await database;
    final rows = await db.query(
      'payment_methods',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
    return rows
        .map((r) => PaymentMethod(
              id: r['id'] as String,
              userId: r['owner_id'] as String,
              type: r['type'] as String,
              label: r['label'] as String,
              encryptedDetails: r['encrypted_details'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
  }

  static Future<void> insertPaymentMethod(PaymentMethod pm) async {
    final db = await database;
    await db.insert('payment_methods', {
      'id': pm.id,
      'owner_id': pm.userId,
      'type': pm.type,
      'label': pm.label,
      'encrypted_details': pm.encryptedDetails,
      'created_at': pm.createdAt.toIso8601String(),
    });
  }

  static Future<void> deletePaymentMethod(String id) async {
    final db = await database;
    await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  // =====================================================================
  // Helpers
  // =====================================================================

  /// Deterministic SHA-256 hash used for unique-lookup columns.
  /// We can't store plaintext for uniqueness checks, so we hash with a
  /// fixed app salt. Combined with normalization this gives stable lookups
  /// without leaking the original value.
  static String _hashLookup(String normalized) {
    if (normalized.isEmpty) return '';
    final bytes = utf8.encode('myleads_lookup_salt_v1::$normalized');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Public helper to get the deterministic lookup hash for an email.
  static String lookupHashForEmail(String email) =>
      _hashLookup(Validators.normalizeEmail(email));

  /// Public helper to get the deterministic lookup hash for a phone.
  static String lookupHashForPhone(String phone) =>
      _hashLookup(Validators.normalizePhone(phone));
}

