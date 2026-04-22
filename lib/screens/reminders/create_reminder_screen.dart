import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/reminder.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../services/calendar_service.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final Reminder? existing;
  const CreateReminderScreen({super.key, this.existing});
  @override
  ConsumerState<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  List<String> _contactIds = [];
  DateTime _startDateTime = DateTime.now().add(const Duration(hours: 1));
  DateTime? _endDateTime;
  String? _repeatFrequency;
  String _toDoAction = 'call';
  String _priority = 'normal';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _contactIds = [...e.contactIds];
      _startDateTime = e.startDateTime;
      _endDateTime = e.endDateTime;
      _repeatFrequency = e.repeatFrequency;
      _toDoAction = e.toDoAction;
      _priority = e.priority;
      _noteCtrl.text = e.note;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final base = isStart
        ? _startDateTime
        : (_endDateTime ?? _startDateTime.add(const Duration(hours: 1)));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDateTime = dt;
        if (_endDateTime != null && _endDateTime!.isBefore(dt)) _endDateTime = null;
      } else {
        _endDateTime = dt;
      }
    });
  }

  void _pickContacts() {
    final contacts = ref.read(contactsProvider).contacts;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final selected = {..._contactIds};
        return StatefulBuilder(
          builder: (ctx, setSt) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Selectionner des contacts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: contacts.isEmpty
                      ? const Center(child: Text('Aucun contact disponible'))
                      : ListView.builder(
                          itemCount: contacts.length,
                          itemBuilder: (_, i) {
                            final c = contacts[i];
                            final isSel = selected.contains(c.id);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                child: Text(c.initials,
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ),
                              title: Text(c.fullName),
                              subtitle: Text(c.phone ?? c.email ?? ''),
                              trailing: isSel
                                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                                  : const Icon(Icons.radio_button_unchecked, color: AppColors.textLight),
                              onTap: () => setSt(() {
                                if (isSel) {
                                  selected.remove(c.id);
                                } else {
                                  selected.add(c.id);
                                }
                              }),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _contactIds = selected.toList());
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Valider (${selected.length})',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Au moins 1 contact requis'), backgroundColor: AppColors.hot),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      Reminder saved;
      if (widget.existing != null) {
        saved = widget.existing!.copyWith(
          contactIds: _contactIds,
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          repeatFrequency: _repeatFrequency,
          note: _noteCtrl.text.trim(),
          toDoAction: _toDoAction,
          priority: _priority,
        );
        await ref.read(remindersProvider.notifier).updateReminder(saved);
      } else {
        saved = await ref.read(remindersProvider.notifier).addReminder(
              contactIds: _contactIds,
              startDateTime: _startDateTime,
              endDateTime: _endDateTime,
              repeatFrequency: _repeatFrequency,
              note: _noteCtrl.text.trim(),
              toDoAction: _toDoAction,
              priority: _priority,
            );
      }
      if (_priority == 'important' || _priority == 'very_important') {
        try {
          await CalendarService.addReminderToCalendar(saved);
        } catch (_) {}
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final contacts = ref.watch(contactsProvider).contacts;
    final selectedContacts = contacts.where((c) => _contactIds.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: Text(
                        isEdit ? 'Modifier le rappel' : 'Nouveau rappel',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Contacts'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...selectedContacts.map((c) => Chip(
                                label: Text(c.fullName),
                                onDeleted: () => setState(() => _contactIds.remove(c.id)),
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                              )),
                          ActionChip(
                            label: const Text('+ Ajouter'),
                            onPressed: _pickContacts,
                            backgroundColor: AppColors.card,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _section('Planification'),
                      _rowField(
                        icon: Icons.play_arrow_rounded,
                        label: 'Debut',
                        value: DateFormat('dd MMM yyyy HH:mm').format(_startDateTime),
                        onTap: () => _pickDate(isStart: true),
                      ),
                      const SizedBox(height: 8),
                      _rowField(
                        icon: Icons.stop_rounded,
                        label: 'Fin (optionnel)',
                        value: _endDateTime == null ? '-' : DateFormat('dd MMM yyyy HH:mm').format(_endDateTime!),
                        onTap: () => _pickDate(isStart: false),
                        trailing: _endDateTime == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _endDateTime = null),
                              ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: _repeatFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Repetition (optionnel)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.repeat_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Aucune')),
                          DropdownMenuItem(value: '30m', child: Text('Toutes les 30 min')),
                          DropdownMenuItem(value: '1h', child: Text('Toutes les heures')),
                          DropdownMenuItem(value: '1d', child: Text('Chaque jour')),
                          DropdownMenuItem(value: '1w', child: Text('Chaque semaine')),
                          DropdownMenuItem(value: '1mo', child: Text('Chaque mois')),
                        ],
                        onChanged: (v) => setState(() => _repeatFrequency = v),
                      ),
                      const SizedBox(height: 20),
                      _section('Note'),
                      TextFormField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Note requise' : null,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Rappeler pour offre 50k',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _section('A faire'),
                      Wrap(
                        spacing: 8,
                        children: [
                          _choiceChip('call', 'Appeler', Icons.phone_rounded),
                          _choiceChip('sms', 'SMS', Icons.sms_rounded),
                          _choiceChip('whatsapp', 'WhatsApp', Icons.chat_rounded),
                          _choiceChip('email', 'Email', Icons.email_rounded),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _section('Priorite'),
                      Wrap(
                        spacing: 8,
                        children: [
                          _priorityChip('normal', 'Normal', AppColors.success),
                          _priorityChip('important', 'Important', AppColors.warm),
                          _priorityChip('very_important', 'Tres important', AppColors.hot),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Enregistrer' : 'Creer le rappel',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t.toUpperCase(),
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.textLight),
        ),
      );

  Widget _rowField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String v, String label, IconData icon) {
    final sel = _toDoAction == v;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: sel ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _toDoAction = v),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600),
    );
  }

  Widget _priorityChip(String v, String label, Color color) {
    final sel = _priority == v;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _priority = v),
      selectedColor: color,
      labelStyle: TextStyle(color: sel ? Colors.white : color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color),
      backgroundColor: Colors.white,
    );
  }
}
