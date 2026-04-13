import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _firstNameCtrl = TextEditingController(text: 'Karen');
  final _lastNameCtrl = TextEditingController(text: 'Ambassa');
  final _jobTitleCtrl = TextEditingController(text: 'CEO');
  final _companyCtrl = TextEditingController(text: 'GreenTech Cameroon');
  final _phoneCtrl = TextEditingController(text: '+237 6 99 88 77 66');
  final _emailCtrl = TextEditingController(text: 'karen@greentech.cm');
  final _sourceCtrl = TextEditingController(text: 'Salon Luxembourg 2026');
  final _project1Ctrl = TextEditingController(text: 'Partenariat Tech');
  final _project1BudgetCtrl = TextEditingController(text: '15 000 €');
  final _project2Ctrl = TextEditingController();
  final _project2BudgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController(
      text: 'Rencontrée au salon Luxembourg. Intéressée par un partenariat.');

  final List<String> _availableTags = [
    'Tech',
    'CEO',
    'Investor',
    'Partner',
    'Event',
    'Priority',
    'B2B',
    'Media',
  ];
  final Set<String> _selectedTags = {'Tech', 'CEO'};

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _sourceCtrl.dispose();
    _project1Ctrl.dispose();
    _project1BudgetCtrl.dispose();
    _project2Ctrl.dispose();
    _project2BudgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _saveContact({bool andContact = false}) async {
    final contact = Contact(
      id: const Uuid().v4(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      jobTitle: _orNull(_jobTitleCtrl.text),
      company: _orNull(_companyCtrl.text),
      phone: _orNull(_phoneCtrl.text),
      email: _orNull(_emailCtrl.text),
      source: _orNull(_sourceCtrl.text),
      project1: _orNull(_project1Ctrl.text),
      project1Budget: _orNull(_project1BudgetCtrl.text),
      project2: _orNull(_project2Ctrl.text),
      project2Budget: _orNull(_project2BudgetCtrl.text),
      notes: _orNull(_notesCtrl.text),
      tags: _selectedTags.toList(),
      status: 'warm',
      captureMethod: 'scan',
    );

    final result = await ref.read(contactsProvider.notifier).addContact(contact);

    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(result.error!)),
            ],
          ),
          backgroundColor: AppColors.hot,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            const Text(AppStrings.contactSaved),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.reviewTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.reviewSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        AppStrings.ocrConfidence,
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(AppStrings.firstName, _firstNameCtrl),
                  _buildField(AppStrings.lastName, _lastNameCtrl),
                  _buildField(AppStrings.jobTitle, _jobTitleCtrl),
                  _buildField(AppStrings.company, _companyCtrl),
                  _buildField(AppStrings.phone, _phoneCtrl, type: TextInputType.phone),
                  _buildField(AppStrings.email, _emailCtrl, type: TextInputType.emailAddress),
                  _buildField(AppStrings.source, _sourceCtrl),
                  _buildField('Projet 1', _project1Ctrl),
                  _buildField('Budget Projet 1', _project1BudgetCtrl),
                  _buildField('Projet 2', _project2Ctrl),
                  _buildField('Budget Projet 2', _project2BudgetCtrl),

                  // Tags
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.tags.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent
                                : AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.primary : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  _buildField(AppStrings.notes, _notesCtrl, maxLines: 3),

                  // Quick Actions
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.quickActions.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickAction(Icons.phone, AppStrings.call, AppColors.success),
                      const SizedBox(width: 10),
                      _buildQuickAction(Icons.chat, AppStrings.whatsapp, const Color(0xFF25D366)),
                      const SizedBox(width: 10),
                      _buildQuickAction(Icons.email, AppStrings.emailAction, AppColors.primary),
                      const SizedBox(width: 10),
                      _buildQuickAction(Icons.sms, AppStrings.sms, AppColors.warm),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Action
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saveContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        AppStrings.save,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label en cours...'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
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
        ),
      ),
    );
  }
}
