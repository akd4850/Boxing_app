import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workout_record.dart';
import '../services/workout_record_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  static const int _defaultRounds = 12;
  static const int _maxRounds = 20;

  late List<String> _activities;
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();

  List<String> _activityOptions(AppLocalizations l10n) => [
        l10n.activityShadow,
        l10n.activityBag,
        l10n.activityMitts,
        l10n.activitySparring,
        l10n.activitySpeedBag,
        l10n.activityJumpRope,
        l10n.activityRest,
        l10n.activityOther,
      ];

  @override
  void initState() {
    super.initState();
    final today = WorkoutRecordService.loadToday();
    if (today != null) {
      _activities = List<String>.from(today.activities);
      _memoController.text = today.memo;
    } else {
      _activities = List.filled(_defaultRounds, '');
    }
    _memoFocusNode.addListener(_onMemoFocusChanged);
  }

  @override
  void dispose() {
    _memoFocusNode.removeListener(_onMemoFocusChanged);
    _memoFocusNode.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onMemoFocusChanged() {
    if (!_memoFocusNode.hasFocus) {
      _autoSave();
    }
  }

  void _autoSave() {
    final record = WorkoutRecord.create(
      totalRounds: _activities.length,
      activities: List<String>.from(_activities),
      memo: _memoController.text.trim(),
    );
    WorkoutRecordService.saveToday(record);
  }

  void _onActivityChanged(int index, String? val) {
    if (val == null) return;
    setState(() => _activities[index] = val);
    _autoSave();
  }

  void _addRound() {
    if (_activities.length >= _maxRounds) return;
    setState(() => _activities.add(''));
    _autoSave();
  }

  void _deleteRound(int index) {
    if (_activities.length <= 1) return;
    setState(() => _activities.removeAt(index));
    _autoSave();
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _activityOptions(l10n);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ..._buildRoundRows(l10n, options, theme),
                _buildAddRoundButton(theme),
                _buildMemoField(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      color: theme.colorScheme.surface,
      child: Text(
        _formattedDate(),
        style: theme.textTheme.titleLarge,
      ),
    );
  }

  List<Widget> _buildRoundRows(
    AppLocalizations l10n,
    List<String> options,
    ThemeData theme,
  ) {
    return List.generate(_activities.length, (i) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                '${l10n.round} ${i + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActivityDropdown(
                value: _activities[i].isEmpty ? null : _activities[i],
                options: options,
                onChanged: (val) => _onActivityChanged(i, val),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: _activities.length > 1 ? () => _deleteRound(i) : null,
              tooltip: '라운드 삭제',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAddRoundButton(ThemeData theme) {
    final canAdd = _activities.length < _maxRounds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: OutlinedButton.icon(
        onPressed: canAdd ? _addRound : null,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(''),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildMemoField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: TextField(
        controller: _memoController,
        focusNode: _memoFocusNode,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.memo,
          hintText: l10n.memoHint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

class _ActivityDropdown extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _ActivityDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          '-',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
