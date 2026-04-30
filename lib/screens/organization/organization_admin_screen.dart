import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../models/organization.dart';
import '../../providers/organization_provider.dart';
import '../../services/storage_service.dart';

class OrganizationAdminScreen extends ConsumerStatefulWidget {
  const OrganizationAdminScreen({super.key});

  @override
  ConsumerState<OrganizationAdminScreen> createState() =>
      _OrganizationAdminScreenState();
}

class _OrganizationAdminScreenState
    extends ConsumerState<OrganizationAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(organizationProvider.notifier).loadForCurrentUser();
    });
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = ref.read(l10nProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.codeCopied),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmRemoveMember(
      BuildContext context, OrgMember member) async {
    final l10n = ref.read(l10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor(context),
        title: Text(
          l10n.removeMemberTitle,
          style: TextStyle(
            color: AppColors.onSurface(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.removeMemberConfirm(member.fullName),
          style: TextStyle(color: AppColors.secondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeMember,
                style: const TextStyle(color: AppColors.hot)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref
        .read(organizationProvider.notifier)
        .removeMember(member.userId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.hot),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.memberRemovedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final l10n = ref.read(l10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor(context),
        title: Text(l10n.leaveOrgTitle,
            style: TextStyle(
                color: AppColors.onSurface(context),
                fontWeight: FontWeight.w700)),
        content: Text(l10n.leaveOrgConfirm,
            style: TextStyle(color: AppColors.secondary(context))),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.leaveOrg,
                  style: const TextStyle(color: AppColors.hot))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await ref.read(organizationProvider.notifier).leaveOrganization();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.hot),
      );
    } else {
      final l10n2 = ref.read(l10nProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n2.orgLeftSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  Future<void> _confirmDeleteOrg(BuildContext context) async {
    final l10n = ref.read(l10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor(context),
        title: Text(l10n.deleteOrgTitle,
            style: TextStyle(
                color: AppColors.onSurface(context),
                fontWeight: FontWeight.w700)),
        content: Text(l10n.deleteOrgConfirm,
            style: TextStyle(color: AppColors.secondary(context))),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.deleteOrg,
                  style: const TextStyle(color: AppColors.hot))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await ref.read(organizationProvider.notifier).deleteOrganization();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.hot),
      );
    } else {
      final l10n2 = ref.read(l10nProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n2.orgDeletedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  Future<void> _updatePrivileges(OrgMember member,
      {required bool canEdit, required bool canCreate}) async {
    final l10n = ref.read(l10nProvider);
    final messenger = ScaffoldMessenger.of(context);
    final err = await ref.read(organizationProvider.notifier).updateMemberPrivileges(
      userId: member.userId,
      canEdit: canEdit,
      canCreate: canCreate,
    );
    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.hot),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.privilegeUpdated),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showRenameDialog(BuildContext context, Organization org) async {
    final l10n = ref.read(l10nProvider);
    final ctrl = TextEditingController(text: org.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor(context),
        title: Text(l10n.orgSettingsTitle,
            style: TextStyle(
                color: AppColors.onSurface(context),
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          cursorColor: AppColors.primary,
          style: TextStyle(color: AppColors.onSurface(context)),
          decoration: InputDecoration(hintText: l10n.orgNameHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.saveButton,
                  style: const TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await ref.read(organizationProvider.notifier).updateOrgName(ctrl.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.hot),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orgNameUpdated),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final orgState = ref.watch(organizationProvider);
    final currentUserId = StorageService.currentUser?.id ?? '';
    final currentUserRole = StorageService.currentUser?.orgRole ?? 'member';
    final isAdmin = currentUserRole == 'admin';

    if (orgState.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(l10n.orgAdminMenuTitle,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final org = orgState.organization;
    if (org == null) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            l10n.noOrgMembers,
            style: TextStyle(color: AppColors.secondary(context)),
          ),
        ),
      );
    }

    final members = orgState.members;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          org.name,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: isAdmin
            ? [
                PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'rename') _showRenameDialog(context, org);
                    if (v == 'delete') _confirmDeleteOrg(context);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(l10n.orgSettingsTitle),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.hot),
                        const SizedBox(width: 10),
                        Text(l10n.deleteOrg,
                            style: const TextStyle(color: AppColors.hot)),
                      ]),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Invite code card (admin only)
          if (isAdmin) ...[
            _SectionLabel(l10n.inviteCodeLabel),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.inviteInfo,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.secondary(context)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            org.inviteCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _copyCode(org.inviteCode),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.copy_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Members list
          _SectionLabel('${l10n.orgMembersTitle} (${members.length})'),
          const SizedBox(height: 10),
          if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.noOrgMembers,
                    style: TextStyle(color: AppColors.secondary(context))),
              ),
            )
          else
            ...members.map((m) => _MemberCard(
                  member: m,
                  isCurrentUser: m.userId == currentUserId,
                  isAdmin: isAdmin,
                  l10n: l10n,
                  onRemove: isAdmin && m.userId != currentUserId
                      ? () => _confirmRemoveMember(context, m)
                      : null,
                  onToggleEdit: isAdmin && m.role != 'admin'
                      ? (val) => _updatePrivileges(m, canEdit: val, canCreate: m.canCreate)
                      : null,
                  onToggleCreate: isAdmin && m.role != 'admin'
                      ? (val) => _updatePrivileges(m, canEdit: m.canEdit, canCreate: val)
                      : null,
                )),

          const SizedBox(height: 24),

          // Leave org (for all roles)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.hot,
                side: const BorderSide(color: AppColors.hot),
              ),
              onPressed: () => _confirmLeave(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.leaveOrg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.hint(context),
        letterSpacing: 1,
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isCurrentUser,
    required this.isAdmin,
    required this.l10n,
    this.onRemove,
    this.onToggleEdit,
    this.onToggleCreate,
  });

  final OrgMember member;
  final bool isCurrentUser;
  final bool isAdmin;
  final AppL10n l10n;
  final VoidCallback? onRemove;
  final void Function(bool)? onToggleEdit;
  final void Function(bool)? onToggleCreate;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminMember = member.role == 'admin';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isAdminMember
                    ? AppColors.primaryGradient
                    : AppColors.accentGradient,
                borderRadius: BorderRadius.circular(14),
                image: member.photoPath != null && !kIsWeb
                    ? DecorationImage(
                        image: FileImage(File(member.photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: member.photoPath == null || kIsWeb
                  ? Center(
                      child: Text(
                        _initials(member.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.fullName + (isCurrentUser ? ' (vous)' : ''),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _RoleBadge(
                        label: isAdminMember
                            ? l10n.orgAdminBadge
                            : l10n.orgMemberBadge,
                        color:
                            isAdminMember ? AppColors.primary : AppColors.warm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.secondary(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.orgContactsCount(member.contactCount)}  •  '
                    '${l10n.memberSince} ${DateFormat('dd/MM/yyyy').format(member.joinedAt)}',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.hint(context)),
                  ),
                  // Privilege toggles — only shown to admin for non-admin members
                  if (onToggleEdit != null || onToggleCreate != null) ...[
                    const SizedBox(height: 10),
                    Divider(
                        height: 1, color: AppColors.borderColor(context)),
                    const SizedBox(height: 8),
                    _PrivilegeToggle(
                      label: l10n.editPrivilege,
                      value: member.canEdit,
                      onChanged: onToggleEdit,
                    ),
                    _PrivilegeToggle(
                      label: l10n.createPrivilege,
                      value: member.canCreate,
                      onChanged: onToggleCreate,
                    ),
                  ],
                ],
              ),
            ),

            // Remove button (admin only, not self)
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.hot.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_remove_rounded,
                      size: 18, color: AppColors.hot),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PrivilegeToggle extends StatelessWidget {
  const _PrivilegeToggle({
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.secondary(context)),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
