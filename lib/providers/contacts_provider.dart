import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/contact.dart';
import '../models/interaction.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

/// Result of a contact mutation. [error] is null on success.
class ContactResult {
  final Contact? contact;
  final String? error;
  const ContactResult.success(this.contact) : error = null;
  const ContactResult.failure(this.error) : contact = null;
  bool get isSuccess => error == null;
}

class ContactsState {
  final List<Contact> contacts;
  final String searchQuery;
  final String activeFilter;
  final bool isLoading;

  const ContactsState({
    this.contacts = const [],
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.isLoading = false,
  });

  /// Returns contacts filtered by search query (name, company, role) AND
  /// the active status/tag filter. Sorted hot → warm → cold then by date.
  List<Contact> get filteredContacts {
    var filtered = List<Contact>.from(contacts);

    // Status / tag filter
    if (activeFilter != 'all') {
      filtered = filtered.where((c) {
        if (c.status == activeFilter) return true;
        return c.tags.any(
            (t) => t.toLowerCase() == activeFilter.toLowerCase());
      }).toList();
    }

    // Search by name, company, or job title (role)
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.firstName.toLowerCase().contains(q) ||
            c.lastName.toLowerCase().contains(q) ||
            c.fullName.toLowerCase().contains(q) ||
            (c.company?.toLowerCase().contains(q) ?? false) ||
            (c.jobTitle?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    filtered.sort((a, b) {
      const priority = {'hot': 0, 'warm': 1, 'cold': 2};
      final cmp = (priority[a.status] ?? 2).compareTo(priority[b.status] ?? 2);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  int get totalContacts => contacts.length;
  int get hotLeads => contacts.where((c) => c.status == 'hot').length;
  int get warmLeads => contacts.where((c) => c.status == 'warm').length;
  int get coldLeads => contacts.where((c) => c.status == 'cold').length;

  ContactsState copyWith({
    List<Contact>? contacts,
    String? searchQuery,
    String? activeFilter,
    bool? isLoading,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  ContactsNotifier() : super(const ContactsState()) {
    _loadContacts();
  }

  String get _ownerId => StorageService.currentUserId;

  Future<void> _loadContacts() async {
    state = state.copyWith(isLoading: true);
    if (_ownerId.isEmpty) {
      state = state.copyWith(contacts: [], isLoading: false);
      return;
    }
    final contacts = await StorageService.getAllContacts();
    if (contacts.isEmpty) {
      await _seedDemoData();
    } else {
      state = state.copyWith(contacts: contacts, isLoading: false);
    }
  }

  /// Reloads contacts from disk (call after login).
  Future<void> reload() => _loadContacts();

  Future<void> _seedDemoData() async {
    final ownerId = _ownerId;
    if (ownerId.isEmpty) {
      state = state.copyWith(contacts: [], isLoading: false);
      return;
    }
    final demoContacts = [
      Contact(
        id: _uuid.v4(),
        ownerId: ownerId,
        firstName: 'Karen',
        lastName: 'Ambassa',
        jobTitle: 'CEO',
        company: 'GreenTech Cameroon',
        phone: '+237699887766',
        email: 'karen@greentech.cm',
        source: 'Salon Luxembourg 2026',
        project1: 'Partenariat Tech',
        project1Budget: '25 000 €',
        project2: 'Expansion Digitale',
        project2Budget: '15 000 €',
        notes:
            'Rencontrée au salon Luxembourg. Très intéressée par un partenariat technologique.',
        tags: ['Tech', 'CEO', 'Event'],
        status: 'hot',
        avatarColor: '0xFFE74C3C',
        captureMethod: 'scan',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Contact(
        id: _uuid.v4(),
        ownerId: ownerId,
        firstName: 'Mike',
        lastName: 'Investor',
        jobTitle: 'Partner',
        company: 'TechFund Africa',
        phone: '+352621123456',
        email: 'mike@techfund.africa',
        source: 'Networking Event',
        project1: 'Investissement Seed',
        project1Budget: '50 000 €',
        tags: ['Finance', 'Partner', 'Investor'],
        status: 'warm',
        avatarColor: '0xFFF39C12',
        captureMethod: 'qr',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Contact(
        id: _uuid.v4(),
        ownerId: ownerId,
        firstName: 'Thomas',
        lastName: 'Matouke',
        jobTitle: 'CTO',
        company: 'Digitech Solutions',
        phone: '+237655443322',
        email: 'thomas@digitech.cm',
        source: 'Conférence IT',
        project1: 'Intégration API',
        project1Budget: '12 000 €',
        project2: 'Migration Cloud',
        project2Budget: '30 000 €',
        tags: ['Tech', 'CTO'],
        status: 'hot',
        avatarColor: '0xFFD4AF37',
        captureMethod: 'scan',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Contact(
        id: _uuid.v4(),
        ownerId: ownerId,
        firstName: 'Sophie',
        lastName: 'Nguema',
        jobTitle: 'Directrice Générale',
        company: 'MediaCorp Gabon',
        phone: '+241712345600',
        email: 'sophie@mediacorp.ga',
        source: 'Salon Digital',
        tags: ['Media', 'Event'],
        status: 'warm',
        avatarColor: '0xFF8E44AD',
        captureMethod: 'manual',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Contact(
        id: _uuid.v4(),
        ownerId: ownerId,
        firstName: 'Pierre',
        lastName: 'Onana',
        jobTitle: 'Directeur Commercial',
        company: 'SNCI',
        phone: '+237677665544',
        email: 'pierre.onana@snci.cm',
        project1: 'Contrat B2B',
        project1Budget: '40 000 €',
        tags: ['B2B', 'Priority'],
        status: 'hot',
        avatarColor: '0xFF2C3E50',
        captureMethod: 'nfc',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    for (final c in demoContacts) {
      await DatabaseService.insertContact(c);
    }

    // Demo interactions for Karen
    final karenId = demoContacts[0].id;
    final interactions = [
      Interaction(
        id: _uuid.v4(),
        ownerId: ownerId,
        contactId: karenId,
        type: 'meeting',
        content: 'Rencontre au Salon Luxembourg',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Interaction(
        id: _uuid.v4(),
        ownerId: ownerId,
        contactId: karenId,
        type: 'call',
        content: 'Appel de suivi - 15 min',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Interaction(
        id: _uuid.v4(),
        ownerId: ownerId,
        contactId: karenId,
        type: 'email',
        content: 'Email de proposition envoyé',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    for (final i in interactions) {
      await DatabaseService.insertInteraction(i);
    }

    state = state.copyWith(contacts: demoContacts, isLoading: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  // ============== VALIDATION ==============

  /// Validates a contact against business rules:
  /// - last name required
  /// - phone OR email required
  /// - no duplicate phone/email for the same owner
  /// - no contact with same first+last+(phone or email)
  String? _validateContact(Contact c) {
    if (c.lastName.trim().isEmpty) {
      return 'Le nom de famille est obligatoire';
    }
    final hasPhone = c.phone != null && c.phone!.trim().isNotEmpty;
    final hasEmail = c.email != null && c.email!.trim().isNotEmpty;
    if (!hasPhone && !hasEmail) {
      return 'Au moins un numéro de téléphone ou un email est requis';
    }
    return null;
  }

  // ============== CRUD ==============

  Future<ContactResult> addContact(Contact contact) async {
    final ownerId = _ownerId;
    if (ownerId.isEmpty) {
      return const ContactResult.failure('Vous devez être connecté');
    }

    final newContact = contact.copyWith(
      id: _uuid.v4(),
      ownerId: ownerId,
    );

    final validationErr = _validateContact(newContact);
    if (validationErr != null) return ContactResult.failure(validationErr);

    final conflict = await DatabaseService.findContactConflict(
      ownerId: ownerId,
      phone: newContact.phone,
      email: newContact.email,
    );
    if (conflict != null) return ContactResult.failure(conflict);

    final identical = await DatabaseService.hasIdenticalContact(
      ownerId: ownerId,
      firstName: newContact.firstName,
      lastName: newContact.lastName,
      phone: newContact.phone,
      email: newContact.email,
    );
    if (identical) {
      return const ContactResult.failure(
          'Un contact identique (même nom et coordonnées) existe déjà');
    }

    await DatabaseService.insertContact(newContact);
    state = state.copyWith(contacts: [...state.contacts, newContact]);
    return ContactResult.success(newContact);
  }

  Future<ContactResult> updateContact(Contact contact) async {
    final ownerId = _ownerId;
    if (ownerId.isEmpty) {
      return const ContactResult.failure('Vous devez être connecté');
    }

    final updated = contact.copyWith(ownerId: ownerId);
    final validationErr = _validateContact(updated);
    if (validationErr != null) return ContactResult.failure(validationErr);

    final conflict = await DatabaseService.findContactConflict(
      ownerId: ownerId,
      phone: updated.phone,
      email: updated.email,
      excludeId: updated.id,
    );
    if (conflict != null) return ContactResult.failure(conflict);

    final identical = await DatabaseService.hasIdenticalContact(
      ownerId: ownerId,
      firstName: updated.firstName,
      lastName: updated.lastName,
      phone: updated.phone,
      email: updated.email,
      excludeId: updated.id,
    );
    if (identical) {
      return const ContactResult.failure(
          'Un contact identique (même nom et coordonnées) existe déjà');
    }

    await DatabaseService.updateContact(updated);
    final list = state.contacts.map((c) => c.id == updated.id ? updated : c).toList();
    state = state.copyWith(contacts: list);
    return ContactResult.success(updated);
  }

  Future<void> deleteContact(String id) async {
    await DatabaseService.deleteContact(id);
    state = state.copyWith(
      contacts: state.contacts.where((c) => c.id != id).toList(),
    );
  }

  Future<void> addInteraction(Interaction interaction) async {
    final ownerId = _ownerId;
    final i = interaction.ownerId.isEmpty
        ? Interaction(
            id: interaction.id,
            ownerId: ownerId,
            contactId: interaction.contactId,
            type: interaction.type,
            content: interaction.content,
            createdAt: interaction.createdAt,
          )
        : interaction;
    await DatabaseService.insertInteraction(i);
    final contact = state.contacts.firstWhere(
      (c) => c.id == i.contactId,
      orElse: () => throw Exception('Contact not found'),
    );
    await updateContact(
      contact.copyWith(lastContactDate: DateTime.now()),
    );
  }

  Future<List<Interaction>> getInteractions(String contactId) {
    return DatabaseService.getInteractionsForContact(contactId);
  }
}

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier();
});

// Derived providers
final hotLeadsProvider = Provider<List<Contact>>((ref) {
  final contacts = ref.watch(contactsProvider).contacts;
  return contacts.where((c) => c.status == 'hot').toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final contactByIdProvider = Provider.family<Contact?, String>((ref, id) {
  final contacts = ref.watch(contactsProvider).contacts;
  try {
    return contacts.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
