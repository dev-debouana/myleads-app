import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/contact.dart';
import '../../models/interaction.dart';
import '../../providers/contacts_provider.dart';
import '../../services/contact_actions.dart';

class ContactDetailScreen extends ConsumerStatefulWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  List<Interaction> _interactions = [];

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  Future<void> _loadInteractions() async {
    final list = await ref
        .read(contactsProvider.notifier)
        .getInteractions(widget.contactId);
    if (mounted) setState(() => _interactions = list);
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(contactByIdProvider(widget.contactId));

    if (contact == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text('Contact non trouvé'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final avatarColor = contact.avatarColor != null
        ? Color(int.parse(contact.avatarColor!))
        : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showActionsSheet(context, contact),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.more_vert,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [avatarColor, avatarColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 3,
                      ),
                      image: contact.photoPath != null && !kIsWeb
                          ? DecorationImage(
                              image: FileImage(File(contact.photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: contact.photoPath == null || kIsWeb
                        ? Center(
                            child: Text(
                              contact.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    contact.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (contact.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      contact.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildStatusChip(contact.status),
                ],
              ),
            ),

            // Action Buttons (functional)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBtn(
                    icon: Icons.phone,
                    label: AppStrings.call,
                    color: AppColors.success,
                    onTap: () => ContactActions.call(context, contact),
                  ),
                  _buildActionBtn(
                    icon: Icons.sms,
                    label: AppStrings.sms,
                    color: AppColors.primary,
                    onTap: () => ContactActions.sms(context, contact),
                  ),
                  _buildActionBtn(
                    icon: Icons.chat,
                    label: AppStrings.whatsapp,
                    color: const Color(0xFF25D366),
                    onTap: () => ContactActions.whatsapp(context, contact),
                  ),
                  _buildActionBtn(
                    icon: Icons.email,
                    label: AppStrings.emailAction,
                    color: AppColors.warm,
                    onTap: () => ContactActions.email(context, contact),
                  ),
                  _buildActionBtn(
                    icon: Icons.share,
                    label: 'Partager',
                    color: AppColors.accent,
                    onTap: () => ContactActions.share(context, contact),
                  ),
                ],
              ),
            ),

            // Edit / Delete row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/contact/${contact.id}/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, contact),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.hot,
                        side:
                            const BorderSide(color: AppColors.hot, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Information Section
            _buildSection(
              AppStrings.information,
              Column(
                children: [
                  if (contact.phone != null && contact.phone!.isNotEmpty)
                    _infoRow('Téléphone', contact.phone!),
                  if (contact.email != null && contact.email!.isNotEmpty)
                    _infoRow('Email', contact.email!),
                  if (contact.company != null && contact.company!.isNotEmpty)
                    _infoRow('Société', contact.company!),
                  if (contact.source != null && contact.source!.isNotEmpty)
                    _infoRow('Source', contact.source!),
                ],
              ),
            ),

            // Projects Section
            if (_hasProjects(contact))
              _buildSection(
                'Projets',
                Column(
                  children: [
                    if (contact.project1 != null && contact.project1!.isNotEmpty) ...[
                      _infoRow('Projet 1', contact.project1!),
                      if (contact.project1Budget != null && contact.project1Budget!.isNotEmpty)
                        _infoRow('Budget', contact.project1Budget!),
                    ],
                    if (contact.project2 != null && contact.project2!.isNotEmpty) ...[
                      if (contact.project1 != null && contact.project1!.isNotEmpty)
                        const Divider(height: 16),
                      _infoRow('Projet 2', contact.project2!),
                      if (contact.project2Budget != null && contact.project2Budget!.isNotEmpty)
                        _infoRow('Budget', contact.project2Budget!),
                    ],
                  ],
                ),
              ),

            // History Section
            if (_interactions.isNotEmpty)
              _buildSection(
                AppStrings.history,
                Column(
                  children: _interactions.map(_timelineItem).toList(),
                ),
              ),

            // Notes Section
            if (contact.notes != null && contact.notes!.isNotEmpty)
              _buildSection(
                AppStrings.notes,
                Text(
                  contact.notes!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMid,
                    height: 1.6,
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  bool _hasProjects(Contact contact) {
    return (contact.project1 != null && contact.project1!.isNotEmpty) ||
        (contact.project2 != null && contact.project2!.isNotEmpty);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'hot':
        color = AppColors.hot;
        label = '● Hot Lead';
        break;
      case 'warm':
        color = AppColors.warm;
        label = '● Warm Lead';
        break;
      default:
        color = AppColors.cold;
        label = '● Cold Lead';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(Interaction interaction) {
    Color dotColor;
    switch (interaction.type) {
      case 'meeting':
        dotColor = AppColors.accent;
        break;
      case 'call':
        dotColor = AppColors.success;
        break;
      case 'email':
        dotColor = AppColors.warm;
        break;
      default:
        dotColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction.content,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(interaction.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActionsSheet(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/contact/${contact.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(ctx);
                ContactActions.share(context, contact);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.hot),
              title: const Text('Supprimer',
                  style: TextStyle(color: AppColors.hot)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, contact);
              },
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.hot.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.hot,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Supprimer le contact ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement ${contact.fullName} ? Cette action est irréversible.',
          style: const TextStyle(fontSize: 14, color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMid,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hot,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(contactsProvider.notifier).deleteContact(contact.id);
      if (mounted) context.pop();
    }
  }
}
