import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/preset.dart';
import '../services/preset_service.dart';

enum TimerPhase { idle, ready, exercise, rest, finished }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  // 설정값
  int _totalRounds = 12;
  int _exerciseMinutes = 3;
  int _exerciseSeconds = 0;
  int _restMinutes = 0;
  int _restSeconds = 30;
  int _waitMinutes = 0;
  int _waitSeconds = 30;

  // 타이머 상태
  TimerPhase _phase = TimerPhase.idle;
  int _currentRound = 1;
  int _remainingSeconds = 0;
  Timer? _timer;
  String _currentPresetName = Preset.defaultName;
  Preset _loadedPreset = Preset.defaultPreset;

  // 애니메이션
  AnimationController? _animController;

  bool get _isSettingChanged =>
      _totalRounds != _loadedPreset.totalRounds ||
      _waitMinutes != _loadedPreset.waitMinutes ||
      _waitSeconds != _loadedPreset.waitSeconds ||
      _exerciseMinutes != _loadedPreset.exerciseMinutes ||
      _exerciseSeconds != _loadedPreset.exerciseSeconds ||
      _restMinutes != _loadedPreset.restMinutes ||
      _restSeconds != _loadedPreset.restSeconds;

  int get _exerciseTotalSeconds => _exerciseMinutes * 60 + _exerciseSeconds;
  int get _restTotalSeconds => _restMinutes * 60 + _restSeconds;
  int get _waitTotalSeconds => _waitMinutes * 60 + _waitSeconds;

  int get _currentPhaseTotalSeconds {
    switch (_phase) {
      case TimerPhase.ready:
        return _waitTotalSeconds;
      case TimerPhase.exercise:
        return _exerciseTotalSeconds;
      case TimerPhase.rest:
        return _restTotalSeconds;
      default:
        return 0;
    }
  }

  String get _displayTime {
    if (_phase == TimerPhase.idle) {
      final min = _exerciseMinutes.toString();
      final sec = _exerciseSeconds.toString().padLeft(2, '0');
      return '$min:$sec';
    }
    final min = (_remainingSeconds ~/ 60).toString();
    final sec = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  bool get _isRunning =>
      _phase != TimerPhase.idle && _phase != TimerPhase.finished;

  double get _smoothProgress {
    if (_phase == TimerPhase.idle || _phase == TimerPhase.finished) return 0.0;
    final total = _currentPhaseTotalSeconds;
    if (total == 0) return 1.0;
    final elapsed = total - _remainingSeconds;
    final animValue = _animController?.value ?? 0.0;
    return (elapsed - 1 + animValue) / total;
  }

  void _startAnimationCycle() {
    _animController?.dispose();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            setState(() {});
          });
    _animController!.forward(from: 0.0);
  }

  void _startTimer() {
    if (_phase == TimerPhase.idle) {
      _currentRound = 1;
      _remainingSeconds = _waitTotalSeconds;
      _phase = TimerPhase.ready;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _startAnimationCycle();
    setState(() {});
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _animController?.stop();
    setState(() {});
  }

  void _toggleTimer() {
    if (_phase == TimerPhase.finished) return;
    if (_timer != null && _timer!.isActive) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _tick() {
    setState(() {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _animController?.forward(from: 0.0);
        return;
      }

      switch (_phase) {
        case TimerPhase.ready:
          _phase = TimerPhase.exercise;
          _remainingSeconds = _exerciseTotalSeconds;
          _animController?.forward(from: 0.0);
          break;
        case TimerPhase.exercise:
          if (_currentRound >= _totalRounds) {
            _phase = TimerPhase.finished;
            _timer?.cancel();
            _timer = null;
            _animController?.stop();
          } else {
            _phase = TimerPhase.rest;
            _remainingSeconds = _restTotalSeconds;
            _animController?.forward(from: 0.0);
          }
          break;
        case TimerPhase.rest:
          _currentRound++;
          _phase = TimerPhase.exercise;
          _remainingSeconds = _exerciseTotalSeconds;
          _animController?.forward(from: 0.0);
          break;
        default:
          break;
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    _animController?.stop();
    _animController?.dispose();
    _animController = null;
    setState(() {
      _phase = TimerPhase.idle;
      _currentRound = 1;
      _remainingSeconds = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    final preset = PresetService.loadLastPreset();
    _currentPresetName = preset.name;
    _loadedPreset = preset;
    _totalRounds = preset.totalRounds;
    _waitMinutes = preset.waitMinutes;
    _waitSeconds = preset.waitSeconds;
    _exerciseMinutes = preset.exerciseMinutes;
    _exerciseSeconds = preset.exerciseSeconds;
    _restMinutes = preset.restMinutes;
    _restSeconds = preset.restSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  String _statusText(AppLocalizations l10n) {
    switch (_phase) {
      case TimerPhase.idle:
        return l10n.statusIdle;
      case TimerPhase.ready:
        return l10n.statusReady;
      case TimerPhase.exercise:
        return l10n.statusExercise;
      case TimerPhase.rest:
        return l10n.statusRest;
      case TimerPhase.finished:
        return l10n.statusFinished;
    }
  }

  Color _phaseColor(ColorScheme colorScheme) {
    switch (_phase) {
      case TimerPhase.idle:
        return colorScheme.primary;
      case TimerPhase.ready:
        return Colors.orange;
      case TimerPhase.exercise:
        return Colors.green;
      case TimerPhase.rest:
        return Colors.blue;
      case TimerPhase.finished:
        return colorScheme.primary;
    }
  }

  Future<void> _saveCurrentPreset() async {
    final updated = Preset(
      name: _currentPresetName,
      totalRounds: _totalRounds,
      waitMinutes: _waitMinutes,
      waitSeconds: _waitSeconds,
      exerciseMinutes: _exerciseMinutes,
      exerciseSeconds: _exerciseSeconds,
      restMinutes: _restMinutes,
      restSeconds: _restSeconds,
    );
    await PresetService.save(updated);
    await PresetService.saveLastPresetName(updated.name);
    setState(() => _loadedPreset = updated);
  }

  void _showSavePresetDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.savePreset),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: l10n.presetNameHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final newPreset = Preset.defaultPreset.copyWith(name: name);
              await PresetService.save(newPreset);
              await PresetService.saveLastPresetName(name);
              setState(() {
                _currentPresetName = name;
                _loadedPreset = newPreset;
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showLoadPresetDialog() {
    final l10n = AppLocalizations.of(context)!;
    final presets = PresetService.getAll();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.loadPreset),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return ListTile(
                title: Text(preset.name),
                subtitle: Text(
                  '${preset.totalRounds}R  ${preset.exerciseMinutes}:${preset.exerciseSeconds.toString().padLeft(2, '0')} / ${preset.restMinutes}:${preset.restSeconds.toString().padLeft(2, '0')}',
                ),
                trailing: (preset.isDefault || preset.name == _currentPresetName)
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await PresetService.delete(preset.name);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                onTap: () {
                  PresetService.saveLastPresetName(preset.name);
                  setState(() {
                    _currentPresetName = preset.name;
                    _loadedPreset = preset;
                    _totalRounds = preset.totalRounds;
                    _waitMinutes = preset.waitMinutes;
                    _waitSeconds = preset.waitSeconds;
                    _exerciseMinutes = preset.exerciseMinutes;
                    _exerciseSeconds = preset.exerciseSeconds;
                    _restMinutes = preset.restMinutes;
                    _restSeconds = preset.restSeconds;
                  });
                  _resetTimer();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showTimerSettingDialog() {
    final l10n = AppLocalizations.of(context)!;

    int tempRounds = _totalRounds;
    int tempWaitMin = _waitMinutes;
    int tempWaitSec = _waitSeconds;
    int tempExMin = _exerciseMinutes;
    int tempExSec = _exerciseSeconds;
    int tempRestMin = _restMinutes;
    int tempRestSec = _restSeconds;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.timerSetting),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingRow(
                    label: l10n.roundLabel,
                    children: [
                      _buildDropdown(
                        value: tempRounds,
                        items: List.generate(30, (i) => i + 1),
                        onChanged: (v) => setDialogState(() => tempRounds = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    label: l10n.waitTime,
                    children: [
                      _buildDropdown(
                        value: tempWaitMin,
                        items: List.generate(60, (i) => i),
                        onChanged: (v) =>
                            setDialogState(() => tempWaitMin = v!),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.minute),
                      const SizedBox(width: 12),
                      _buildDropdown(
                        value: tempWaitSec,
                        items: List.generate(60, (i) => i),
                        onChanged: (v) =>
                            setDialogState(() => tempWaitSec = v!),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.second),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    label: l10n.exerciseTime,
                    children: [
                      _buildDropdown(
                        value: tempExMin,
                        items: List.generate(60, (i) => i),
                        onChanged: (v) => setDialogState(() => tempExMin = v!),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.minute),
                      const SizedBox(width: 12),
                      _buildDropdown(
                        value: tempExSec,
                        items: List.generate(60, (i) => i),
                        onChanged: (v) => setDialogState(() => tempExSec = v!),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.second),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    label: l10n.restTime,
                    children: [
                      _buildDropdown(
                        value: tempRestMin,
                        items: List.generate(60, (i) => i),
                        onChanged: (v) =>
                            setDialogState(() => tempRestMin = v!),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.minute),
                      const SizedBox(width: 12),
                      _buildDropdown(
                        value: tempRestSec,
                        items: List.generate(60, (i) => i),
                        onChanged: (v) =>
                            setDialogState(() => tempRestSec = v!),
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.second),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _totalRounds = tempRounds;
                      _waitMinutes = tempWaitMin;
                      _waitSeconds = tempWaitSec;
                      _exerciseMinutes = tempExMin;
                      _exerciseSeconds = tempExSec;
                      _restMinutes = tempRestMin;
                      _restSeconds = tempRestSec;
                    });
                    _resetTimer();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButton<int>(
      value: value,
      isDense: true,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSettingRow({
    required String label,
    required List<Widget> children,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final phaseColor = _phaseColor(colorScheme);
    final isPaused =
        _phase != TimerPhase.idle &&
        _phase != TimerPhase.finished &&
        _timer == null;

    // 고정 UI 영역 높이: 상단 여백 + 라운드텍스트 + 간격 + 리셋버튼 + 하단버튼3개 + 여백
    const fixedVerticalSpace =
        24.0 + 32.0 + 24.0 + 48.0 + (52.0 * 3) + (12.0 * 2) + 32.0;
    final availableHeight = screenHeight - fixedVerticalSpace;
    final timerSize = (screenWidth * 0.9).clamp(0.0, availableHeight * 0.85);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // 라운드 표시
          Text(
            '$_currentRound / $_totalRounds ${l10n.round}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),

          const SizedBox(height: 24),

          // 원형 타이머
          SizedBox(
            width: timerSize,
            height: timerSize,
            child: CustomPaint(
              painter: _TimerCirclePainter(
                progress: _smoothProgress.clamp(0.0, 1.0),
                progressColor: phaseColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
                strokeWidth: 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상태 표시
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _statusText(l10n),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: phaseColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 시간 표시
                  Text(
                    _displayTime,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: timerSize * 0.22,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 시작/일시정지 버튼
                  if (_phase != TimerPhase.finished)
                    GestureDetector(
                      onTap: _toggleTimer,
                      child: Container(
                        width: timerSize * 0.22,
                        height: timerSize * 0.22,
                        decoration: BoxDecoration(
                          color: isPaused ? Colors.orange : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRunning && _timer != null
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: colorScheme.onPrimary,
                          size: timerSize * 0.12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 리셋 버튼
          TextButton.icon(
            onPressed: _resetTimer,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reset),
          ),

          const Spacer(),

          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // 현재 프리셋 표시
                Text(
                  '${AppLocalizations.of(context)!.currentPreset}: $_currentPresetName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isRunning ? null : _showTimerSettingDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.timerSetting),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (!_isRunning && _isSettingChanged)
                        ? _saveCurrentPreset
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.savePreset),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isRunning ? null : _showSavePresetDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.addPreset),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isRunning ? null : _showLoadPresetDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.loadPreset),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TimerCirclePainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerCirclePainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 진행 원
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
