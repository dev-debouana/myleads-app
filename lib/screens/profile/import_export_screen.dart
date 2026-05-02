import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../services/contact_import_export_service.dart';
import '../../services/storage_service.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  CrmExportFormat _crmFormat = CrmExportFormat.generic;
  bool _isLoading = false;
  String? _resultMessage;
  bool _resultIsError = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ─── Import flow ──────────────────────────────────────────────────────────

  Future<void> _pickAndImport(List<String> extensions) async {
    _clearResult();
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        withData: true,
      );
    } catch (_) {
      _setResult(ref.read(l10nProvider).importError, isError: true);
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final String content;
    try {
      content = file.bytes != null
          ? String.fromCharCodes(file.bytes!)
          : await File(file.path!).readAsString();
    } catch (_) {
      _setResult(ref.read(l10nProvider).importError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final ext = (file.extension ?? '').toLowerCase();
    await _doImport(content, ext);
  }

  Future<void> _doImport(String content, String ext) async {
    final l10n = ref.read(l10nProvider);
    final ownerId = StorageService.currentUser?.id ?? '';

    List<Contact> parsed;
    try {
      if (ext == 'vcf' || ext == 'vcard') {
        parsed = ContactImportExportService.importFromVCard(content, ownerId);
      } else if (ext == 'txt') {
        parsed = ContactImportExportService.importFromTxt(content, ownerId);
      } else {
        parsed = ContactImportExportService.importFromCsv(content, ownerId);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _setResult(l10n.importError, isError: true);
      return;
    }

    setState(() => _isLoading = false);

    if (parsed.isEmpty) {
      _setResult(l10n.importNoContacts, isError: true);
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ImportPreviewDialog(contacts: parsed, l10n: l10n),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    int created = 0, skipped = 0;
    final notifier = ref.read(contactsProvider.notifier);
    for (final contact in parsed) {
      try {
        final res = await notifier.addContact(contact);
        res.isSuccess ? created++ : skipped++;
      } catch (_) {
        skipped++;
      }
    }

    setState(() => _isLoading = false);
    _setResult(l10n.importSuccess(created, skipped));
  }

  // ─── Export flow ──────────────────────────────────────────────────────────

  Future<void> _export(String fileType) async {
    _clearResult();
    final l10n = ref.read(l10nProvider);
    final contacts = ref.read(contactsProvider).contacts;

    if (contacts.isEmpty) {
      _setResult(l10n.exportNoContacts, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String content;
      String filename;

      if (fileType == 'csv') {
        content = ContactImportExportService.exportToCsv(
          contacts,
          format: _crmFormat,
        );
        filename = 'me2leads_contacts_${_crmFormat.name}_$ts.csv';
      } else if (fileType == 'vcf') {
        content = ContactImportExportService.exportToVCard(contacts);
        filename = 'me2leads_contacts_$ts.vcf';
      } else {
        content = ContactImportExportService.exportToTxt(contacts);
        filename = 'me2leads_contacts_$ts.txt';
      }

      final file =
          await ContactImportExportService.writeExportFile(content, filename);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: _mimeType(fileType))],
          subject: 'Me2Leads — Contacts Export',
        ),
      );

      if (!mounted) return;
      _setResult(l10n.exportSuccess(contacts.length));
    } catch (_) {
      _setResult(l10n.exportError, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'csv':
        return 'text/csv';
      case 'vcf':
        return 'text/vcard';
      default:
        return 'text/plain';
    }
  }

  // ─── State helpers ────────────────────────────────────────────────────────

  void _setResult(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _resultMessage = message;
      _resultIsError = isError;
    });
  }

  void _clearResult() {
    if (_resultMessage != null) setState(() => _resultMessage = null);
  }

  String _crmLabel(AppL10n l10n, CrmExportFormat f) {
    switch (f) {
      case CrmExportFormat.generic:
        return l10n.crmFormatGeneric;
      case CrmExportFormat.salesforce:
        return 'Salesforce';
      case CrmExportFormat.odoo:
        return 'Odoo';
      case CrmExportFormat.sap:
        return 'SAP';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          _buildHeader(context, l10n),
          if (_resultMessage != null) _buildResultBanner(context),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildImportTab(context, l10n),
                _buildExportTab(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AppL10n l10n) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 0,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.importExportTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.importExportSubtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tab,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: l10n.importTab),
              Tab(text: l10n.exportTab),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Result banner ────────────────────────────────────────────────────────

  Widget _buildResultBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _resultIsError
            ? AppColors.hot.withOpacity(0.08)
            : AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _resultIsError
              ? AppColors.hot.withOpacity(0.25)
              : AppColors.success.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _resultIsError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: _resultIsError ? AppColors.hot : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _resultMessage!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _resultIsError ? AppColors.hot : AppColors.success,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearResult,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.hint(context),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Import tab ───────────────────────────────────────────────────────────

  Widget _buildImportTab(BuildContext context, AppL10n l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            l10n.importSection,
            l10n.importSectionDesc,
            Icons.upload_file_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _formatCard(
            context,
            icon: Icons.table_chart_rounded,
            color: AppColors.success,
            title: 'CSV',
            subtitle: l10n.csvImportDesc,
            onTap: () => _pickAndImport(['csv', 'tsv']),
          ),
          const SizedBox(height: 10),
          _formatCard(
            context,
            icon: Icons.contact_page_rounded,
            color: AppColors.primary,
            title: 'vCard (.vcf)',
            subtitle: l10n.vcardImportDesc,
            onTap: () => _pickAndImport(['vcf', 'vcard']),
          ),
          const SizedBox(height: 10),
          _formatCard(
            context,
            icon: Icons.text_snippet_rounded,
            color: AppColors.warm,
            title: 'TXT',
            subtitle: l10n.txtImportDesc,
            onTap: () => _pickAndImport(['txt']),
          ),
          const SizedBox(height: 24),
          _infoBox(context, l10n.importInfoBox),
        ],
      ),
    );
  }

  // ─── Export tab ───────────────────────────────────────────────────────────

  Widget _buildExportTab(BuildContext context, AppL10n l10n) {
    final contactCount = ref.watch(contactsProvider).contacts.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            l10n.exportSection,
            l10n.exportSectionDesc(contactCount),
            Icons.download_rounded,
            AppColors.accent,
          ),
          const SizedBox(height: 20),
          // CRM format selector
          Text(
            l10n.crmFormatLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.hint(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _crmFormatSelector(context, l10n),
          const SizedBox(height: 22),
          Text(
            l10n.exportFormatLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.hint(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _formatCard(
            context,
            icon: Icons.table_chart_rounded,
            color: AppColors.success,
            title: 'CSV',
            subtitle: l10n.csvExportDesc(_crmLabel(l10n, _crmFormat)),
            onTap: () => _export('csv'),
          ),
          const SizedBox(height: 10),
          _formatCard(
            context,
            icon: Icons.contact_page_rounded,
            color: AppColors.primary,
            title: 'vCard (.vcf)',
            subtitle: l10n.vcardExportDesc,
            onTap: () => _export('vcf'),
          ),
          const SizedBox(height: 10),
          _formatCard(
            context,
            icon: Icons.text_snippet_rounded,
            color: AppColors.warm,
            title: 'TXT',
            subtitle: l10n.txtExportDesc,
            onTap: () => _export('txt'),
          ),
          const SizedBox(height: 24),
          _infoBox(context, l10n.exportInfoBox),
        ],
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title, String subtitle,
      IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface(context),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _crmFormatSelector(BuildContext context, AppL10n l10n) {
    final options = [
      (CrmExportFormat.generic, l10n.crmFormatGeneric, Icons.code_rounded),
      (CrmExportFormat.salesforce, 'Salesforce', Icons.cloud_rounded),
      (CrmExportFormat.odoo, 'Odoo', Icons.shopping_bag_rounded),
      (CrmExportFormat.sap, 'SAP', Icons.business_center_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _crmFormat == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _crmFormat = opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.borderColor(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  opt.$3,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : AppColors.secondary(context),
                ),
                const SizedBox(width: 6),
                Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.onSurface(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _formatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceColor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _isLoading
                            ? AppColors.hint(context)
                            : AppColors.onSurface(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.hint(context),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Import preview dialog ────────────────────────────────────────────────────

class _ImportPreviewDialog extends StatelessWidget {
  final List<Contact> contacts;
  final AppL10n l10n;

  const _ImportPreviewDialog({
    required this.contacts,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final preview = contacts.length > 5 ? contacts.sublist(0, 5) : contacts;
    final extra = contacts.length - preview.length;

    return Dialog(
      backgroundColor: AppColors.surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.importPreviewTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.importPreviewDesc(contacts.length),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondary(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.borderColor(context)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: preview.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.borderColor(context),
                ),
                itemBuilder: (_, i) {
                  final c = preview[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              c.initials.isEmpty ? '?' : c.initials,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.fullName.isEmpty ? '—' : c.fullName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface(context),
                                ),
                              ),
                              if (c.subtitle.isNotEmpty)
                                Text(
                                  c.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (extra > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.importPreviewMore(extra),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.hint(context),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.confirmImport),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
