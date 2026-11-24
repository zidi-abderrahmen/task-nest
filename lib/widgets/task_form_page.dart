import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Values collected by the shared task form.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String description;
  final String priority;
  final DateTime? dueDate;
}

/// Shared form used by both Add and Edit task pages.
///
/// The [onSubmit] callback performs the actual persistence and returns
/// the value to pop the route with (e.g. `true` for Add, the updated
/// [Task] for Edit). Any exception thrown from [onSubmit] is shown as
/// a snackbar prefixed with [errorPrefix].
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({
    super.key,
    required this.appBarTitle,
    required this.heading,
    required this.subtitle,
    required this.submitLabel,
    required this.submitIcon,
    required this.errorPrefix,
    required this.initial,
    required this.onSubmit,
  });

  final String appBarTitle;
  final String heading;
  final String subtitle;
  final String submitLabel;
  final IconData submitIcon;
  final String errorPrefix;
  final TaskDraft initial;
  final Future<Object?> Function(TaskDraft draft) onSubmit;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  static const _titleMax = 100;
  static const _descMax = 500;
  static const _priorities = <String>['Low', 'Medium', 'High'];

  final _formKey = GlobalKey<FormState>();
  final _titleFocus = FocusNode();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _priority;
  DateTime? _dueDate;

  bool _isSaving = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  // ---------- lifecycle ----------

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial.title);
    _descriptionController = TextEditingController(text: initial.description);
    _priority = _priorities.contains(initial.priority)
        ? initial.priority
        : 'Medium';
    _dueDate = initial.dueDate;

    // Autofocus the title on the Add page (empty title == new task).
    if (initial.title.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // ---------- helpers ----------

  bool get _isDirty {
    final i = widget.initial;
    return _titleController.text.trim() != i.title.trim() ||
        _descriptionController.text.trim() != i.description.trim() ||
        _priority != i.priority ||
        !_sameDate(_dueDate, i.dueDate);
  }

  bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return DateUtils.isSameDay(a, b);
  }

  String _formatLong(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() => _dueDate = selected);
  }

  // ---------- submit ----------

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final result = await widget.onSubmit(
        TaskDraft(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${widget.errorPrefix}: $e')),
        );
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSaving || !_isDirty) {
          Navigator.of(context).pop();
          return;
        }
        final discard = await _confirmDiscard();
        if (discard && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(widget.appBarTitle)),
        bottomNavigationBar: _buildBottomBar(),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      widget.heading,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTaskCard(),
                    const SizedBox(height: 16),
                    _buildSchedulingCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          heightFactor: 1, // shrink-wrap, never steal the body's space
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(widget.submitIcon),
                label: Text(_isSaving ? 'Saving…' : widget.submitLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard() {
    return _FormCard(
      title: 'TASK',
      children: [
        TextFormField(
          controller: _titleController,
          focusNode: _titleFocus,
          enabled: !_isSaving,
          maxLength: _titleMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'What needs to be done?',
            counterText: '', // hide counter but keep the hard limit
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Task title is required.'
              : null,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _descriptionController,
          enabled: !_isSaving,
          minLines: 3,
          maxLines: 6,
          maxLength: _descMax,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Add notes (optional)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulingCard() {
    return _FormCard(
      title: 'SCHEDULING',
      children: [
        const _FieldLabel('Priority'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _priorities.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PriorityOption(
                  label: _priorities[i],
                  color: AppColors.forPriority(_priorities[i]),
                  selected: _priority == _priorities[i],
                  enabled: !_isSaving,
                  onTap: () => setState(() => _priority = _priorities[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Due date (optional)'),
        const SizedBox(height: 8),
        _buildQuickDateChips(),
        const SizedBox(height: 10),
        _buildDueDateTile(),
      ],
    );
  }

  Widget _buildQuickDateChips() {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final current = _dueDate == null ? null : DateUtils.dateOnly(_dueDate!);

    Widget chip(String label, DateTime value) {
      final selected = current != null && current == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        onSelected: _isSaving ? null : (_) => setState(() => _dueDate = value),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Today', today),
        chip('Tomorrow', tomorrow),
        chip('Next week', nextWeek),
      ],
    );
  }

  Widget _buildDueDateTile() {
    final hasDate = _dueDate != null;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: _isSaving ? null : _selectDueDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasDate ? _formatLong(_dueDate!) : 'No due date',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: hasDate
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (hasDate)
                IconButton(
                  tooltip: 'Clear due date',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _isSaving ? null : () => setState(() => _dueDate = null),
                  icon: const Icon(Icons.close, size: 18),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- small private widgets ----------

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: selected ? color : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag,
                size: 15,
                color: selected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}