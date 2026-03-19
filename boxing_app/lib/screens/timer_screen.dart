import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

enum TimerPhase { idle, ready, exercise, rest, finished }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
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

  // 애니메이션
  AnimationController? _animController;

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

  bool get _isRunning => _phase != TimerPhase.idle && _phase != TimerPhase.finished;

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
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
  void dispose() {
    _timer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  String _statusText(AppLocalizations l10n) {
    switch (_phase) {
      case TimerPhase.idle:
        return '';
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

  void _showTimerSettingDialog() {
    final l10n = AppLocalizations.of(context)!;

    final roundController = TextEditingController(text: '$_totalRounds');
    final waitMinController = TextEditingController(text: '$_waitMinutes');
    final waitSecController = TextEditingController(text: '$_waitSeconds');
    final exMinController = TextEditingController(text: '$_exerciseMinutes');
    final exSecController = TextEditingController(text: '$_exerciseSeconds');
    final restMinController = TextEditingController(text: '$_restMinutes');
    final restSecController = TextEditingController(text: '$_restSeconds');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.timerSetting),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingRow(
                label: l10n.roundLabel,
                children: [
                  _buildNumberField(roundController, width: 60),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingRow(
                label: l10n.waitTime,
                children: [
                  Text(l10n.minute),
                  const SizedBox(width: 4),
                  _buildNumberField(waitMinController, width: 50),
                  const SizedBox(width: 12),
                  Text(l10n.second),
                  const SizedBox(width: 4),
                  _buildNumberField(waitSecController, width: 50),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingRow(
                label: l10n.exerciseTime,
                children: [
                  Text(l10n.minute),
                  const SizedBox(width: 4),
                  _buildNumberField(exMinController, width: 50),
                  const SizedBox(width: 12),
                  Text(l10n.second),
                  const SizedBox(width: 4),
                  _buildNumberField(exSecController, width: 50),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingRow(
                label: l10n.restTime,
                children: [
                  Text(l10n.minute),
                  const SizedBox(width: 4),
                  _buildNumberField(restMinController, width: 50),
                  const SizedBox(width: 12),
                  Text(l10n.second),
                  const SizedBox(width: 4),
                  _buildNumberField(restSecController, width: 50),
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
                  _totalRounds = int.tryParse(roundController.text) ?? _totalRounds;
                  _waitMinutes = int.tryParse(waitMinController.text) ?? _waitMinutes;
                  _waitSeconds = int.tryParse(waitSecController.text) ?? _waitSeconds;
                  _exerciseMinutes = int.tryParse(exMinController.text) ?? _exerciseMinutes;
                  _exerciseSeconds = int.tryParse(exSecController.text) ?? _exerciseSeconds;
                  _restMinutes = int.tryParse(restMinController.text) ?? _restMinutes;
                  _restSeconds = int.tryParse(restSecController.text) ?? _restSeconds;
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
  }

  Widget _buildSettingRow({
    required String label,
    required List<Widget> children,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, {required double width}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final timerSize = screenWidth * 0.65;
    final phaseColor = _phaseColor(colorScheme);
    final isPaused = _phase != TimerPhase.idle && _phase != TimerPhase.finished && _timer == null;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),

          // 라운드 표시
          Text(
            '$_currentRound / $_totalRounds ${l10n.round}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 32),

          // 원형 타이머
          SizedBox(
            width: timerSize,
            height: timerSize,
            child: CustomPaint(
              painter: _TimerCirclePainter(
                progress: _smoothProgress.clamp(0.0, 1.0),
                progressColor: phaseColor,
                backgroundColor: colorScheme.surfaceContainerHighest,
                strokeWidth: 6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상태 표시
                  if (_phase != TimerPhase.idle)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _statusText(l10n),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: phaseColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // 시간 표시
                  Text(
                    _displayTime,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: timerSize * 0.2,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 시작/일시정지 버튼
                  if (_phase != TimerPhase.finished)
                    FilledButton.icon(
                      onPressed: _toggleTimer,
                      icon: Icon(
                        _isRunning && _timer != null ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(
                        _isRunning && _timer != null ? l10n.pause : l10n.start,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isPaused ? Colors.orange : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                    onPressed: _isRunning ? null : () {},
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
                    onPressed: _isRunning ? null : () {},
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
