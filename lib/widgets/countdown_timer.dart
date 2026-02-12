import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final String label;
  final Color color;

  const CountdownTimer({
    super.key,
    required this.targetTime,
    required this.label,
    this.color = Colors.orange,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTime != widget.targetTime) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    final now = DateTime.now().toUtc();
    final diff = widget.targetTime.toUtc().difference(now);
    if (!mounted) return;
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final isPast = _remaining == Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withValues(alpha: 0.15),
            widget.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.check_circle_outline : Icons.timer_outlined,
            color: widget.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (isPast)
            Text(
              '이미 지남',
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600),
            )
          else
            Row(
              children: [
                _buildTimeUnit(hours.toString().padLeft(2, '0'), '시'),
                const Text(' : ', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                _buildTimeUnit(minutes.toString().padLeft(2, '0'), '분'),
                const Text(' : ', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                _buildTimeUnit(seconds.toString().padLeft(2, '0'), '초'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 1),
        Text(unit, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }
}
