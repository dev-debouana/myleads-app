import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/organization.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class OrgState {
  final Organization? organization;
  final List<OrgMember> members;
  final bool isLoading;
  final String? error;

  const OrgState({
    this.organization,
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  OrgState copyWith({
    Organization? organization,
    List<OrgMember>? members,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearOrg = false,
  }) {
    return OrgState(
      organization: clearOrg ? null : (organization ?? this.organization),
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrgNotifier extends StateNotifier<OrgState> {
  OrgNotifier() : super(const OrgState());

  /// Load org data for the current user (call on app start / profile open).
  Future<void> loadForCurrentUser() async {
    final user = StorageService.currentUser;
    if (user == null || user.organizationId == null) {
      state = const OrgState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final org = await DatabaseService.findOrganizationById(user.organizationId!);
      if (org == null) {
        state = const OrgState();
        return;
      }
      final members = await DatabaseService.getMembersForOrganization(org.id);
      state = state.copyWith(isLoading: false, organization: org, members: members);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload members (useful after invite/remove).
  Future<void> refreshMembers() async {
    final org = state.organization;
    if (org == null) return;
    try {
      final members = await DatabaseService.getMembersForOrganization(org.id);
      state = state.copyWith(members: members);
    } catch (_) {}
  }

  /// Create a new organization with the current user as admin.
  /// Returns null on success, error string on failure.
  Future<String?> createOrganization(String name) async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';
    if (name.trim().isEmpty) return 'Le nom de l\'organisation est obligatoire';
    if (user.organizationId != null) {
      return 'Vous appartenez déjà à une organisation';
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orgId = _uuid.v4();
      final inviteCode = _generateInviteCode();
      final org = Organization(
        id: orgId,
        name: name.trim(),
        ownerId: user.id,
        inviteCode: inviteCode,
      );

      await DatabaseService.insertOrganization(org);

      // Add admin as first member
      await DatabaseService.insertOrgMember(
        id: _uuid.v4(),
        orgId: orgId,
        userId: user.id,
        role: 'admin',
      );

      // Update user record
      final updated = user.copyWith(organizationId: orgId, orgRole: 'admin');
      await DatabaseService.updateUser(updated);
      await StorageService.setCurrentSession(updated, user.sessionToken ?? '');

      final members = await DatabaseService.getMembersForOrganization(orgId);
      state = state.copyWith(isLoading: false, organization: org, members: members);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  /// Join an existing organization via its invite code.
  /// Returns null on success, error string on failure.
  Future<String?> joinByCode(String code) async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';
    if (code.trim().isEmpty) return 'Le code d\'invitation est obligatoire';
    if (user.organizationId != null) {
      return 'Vous appartenez déjà à une organisation';
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final org = await DatabaseService.findOrganizationByInviteCode(code.trim());
      if (org == null) {
        state = state.copyWith(isLoading: false, error: 'Code invalide ou organisation introuvable');
        return 'Code invalide ou organisation introuvable';
      }

      final alreadyIn = await DatabaseService.isUserInOrganization(org.id, user.id);
      if (alreadyIn) {
        state = state.copyWith(isLoading: false, error: 'Vous êtes déjà membre de cette organisation');
        return 'Vous êtes déjà membre de cette organisation';
      }

      await DatabaseService.insertOrgMember(
        id: _uuid.v4(),
        orgId: org.id,
        userId: user.id,
        role: 'member',
      );

      final updated = user.copyWith(organizationId: org.id, orgRole: 'member');
      await DatabaseService.updateUser(updated);
      await StorageService.setCurrentSession(updated, user.sessionToken ?? '');

      final members = await DatabaseService.getMembersForOrganization(org.id);
      state = state.copyWith(isLoading: false, organization: org, members: members);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  /// Admin removes a member (cannot remove self — use leaveOrganization).
  Future<String?> removeMember(String targetUserId) async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';
    if (user.orgRole != 'admin') return 'Action réservée à l\'administrateur';
    final org = state.organization;
    if (org == null) return 'Aucune organisation';
    if (targetUserId == user.id) return 'Utilisez "Quitter l\'organisation" pour vous retirer';

    try {
      await DatabaseService.removeOrgMember(org.id, targetUserId);
      await refreshMembers();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Current user leaves the organization. Admin must transfer ownership first
  /// (or delete the org if they are the last member).
  Future<String?> leaveOrganization() async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';
    final org = state.organization;
    if (org == null) return 'Aucune organisation';

    try {
      final isLastAdmin =
          user.orgRole == 'admin' && state.members.where((m) => m.role == 'admin').length == 1;

      if (isLastAdmin && state.members.length > 1) {
        return "Transférez l'administration avant de quitter, ou supprimez l'organisation.";
      }

      if (isLastAdmin && state.members.length <= 1) {
        // Admin leaves + last member → delete org
        await DatabaseService.deleteOrganization(org.id);
      } else {
        await DatabaseService.removeOrgMember(org.id, user.id);
        final updated = user.copyWith(organizationId: null, orgRole: null);
        await DatabaseService.updateUser(updated);
        await StorageService.setCurrentSession(updated, user.sessionToken ?? '');
      }

      state = const OrgState();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Admin deletes the entire organization (removes all members).
  Future<String?> deleteOrganization() async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';
    if (user.orgRole != 'admin') return 'Action réservée à l\'administrateur';
    final org = state.organization;
    if (org == null) return 'Aucune organisation';

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await DatabaseService.deleteOrganization(org.id);

      // The deleteOrganization method already clears org fields on all users
      // in the DB; refresh the current user's in-memory session.
      final refreshed = await DatabaseService.findUserById(user.id);
      if (refreshed != null) {
        await StorageService.setCurrentSession(refreshed, refreshed.sessionToken ?? '');
      }

      state = const OrgState();
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  /// Update the organization name (admin only).
  Future<String?> updateOrgName(String newName) async {
    final user = StorageService.currentUser;
    if (user == null) return 'Aucun utilisateur connecté';
    if (user.orgRole != 'admin') return 'Action réservée à l\'administrateur';
    if (newName.trim().isEmpty) return 'Le nom est obligatoire';
    final org = state.organization;
    if (org == null) return 'Aucune organisation';

    try {
      final updated = org.copyWith(name: newName.trim());
      await DatabaseService.updateOrganization(updated);
      state = state.copyWith(organization: updated);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}

final organizationProvider = StateNotifierProvider<OrgNotifier, OrgState>((ref) {
  return OrgNotifier();
});
