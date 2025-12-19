import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/application.dart';
import '../../utils/enums.dart';

class AddEditApplicationScreen extends StatefulWidget {
  const AddEditApplicationScreen({
    super.key,
    required this.uid,
    this.existing,
  });

  final String uid;
  final Application? existing;

  @override
  State<AddEditApplicationScreen> createState() => _AddEditApplicationScreenState();
}

class _AddEditApplicationScreenState extends State<AddEditApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _notesCtrl;

  AppStatus _status = AppStatus.applied;
  Priority _priority = Priority.medium;
  DateTime _dateApplied = DateTime.now();

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _companyCtrl = TextEditingController(text: e?.companyName ?? '');
    _roleCtrl = TextEditingController(text: e?.roleTitle ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _urlCtrl = TextEditingController(text: e?.jobUrl ?? '');
    _sourceCtrl = TextEditingController(text: e?.source ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _status = e?.status ?? AppStatus.applied;
    _priority = e?.priority ?? Priority.medium;
    _dateApplied = e?.dateApplied ?? DateTime.now();
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _roleCtrl.dispose();
    _locationCtrl.dispose();
    _urlCtrl.dispose();
    _sourceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _dateApplied,
    );
    if (picked != null) setState(() => _dateApplied = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.existing;

    final app = Application(
      id: existing?.id ?? '',
      uid: widget.uid,
      companyName: _companyCtrl.text.trim(),
      roleTitle: _roleCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      jobUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      status: _status,
      priority: _priority,
      source: _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
      dateApplied: _dateApplied,
      lastUpdated: now,
      tags: existing?.tags ?? const [],
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    Navigator.of(context).pop(app);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit application' : 'Add application'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Company is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _roleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Role title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Role title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Job URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sourceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Source (LinkedIn, Handshake, Referral...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AppStatus>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: AppStatus.values
                              .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(enumToString(s)),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _status = v ?? AppStatus.applied),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<Priority>(
                          value: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: Priority.values
                              .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(enumToString(p)),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _priority = v ?? Priority.medium),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text('Date applied: ${DateFormat('MMM d, yyyy').format(_dateApplied)}'),
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    child: Text(_editing ? 'Save changes' : 'Add application'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
