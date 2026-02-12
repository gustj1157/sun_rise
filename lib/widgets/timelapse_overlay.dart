import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/spot_data.dart';
import '../providers/sun_status_provider.dart';

class TimelapseOverlay extends StatefulWidget {
  final SpotData spot;
  final VoidCallback onClose;

  const TimelapseOverlay({
    super.key,
    required this.spot,
    required this.onClose,
  });

  @override
  State<TimelapseOverlay> createState() => _TimelapseOverlayState();
}

class _TimelapseOverlayState extends State<TimelapseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    final target = widget.spot.type == SpotType.sunset
        ? widget.spot.sunsetTime
        : widget.spot.sunriseTime;

    if (target != null) {
      _startTime = target.subtract(const Duration(hours: 2));
      _endTime = target.add(const Duration(hours: 2));
    } else {
      // Fallback: today 5AM to 9AM
      final today = DateTime.now().toUtc();
      _startTime = DateTime.utc(today.year, today.month, today.day, 20); // UTC 20 = KST 5AM
      _endTime = DateTime.utc(today.year, today.month, today.day, 24);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _controller.addListener(_onTick);
  }

  void _onTick() {
    final ms = _startTime.millisecondsSinceEpoch +
        (_controller.value *
            (_endTime.millisecondsSinceEpoch - _startTime.millisecondsSinceEpoch))
            .round();
    final simTime = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    context.read<SunStatusProvider>().setSimulatedTime(simTime);
  }

  String _currentTimeLabel() {
    final ms = _startTime.millisecondsSinceEpoch +
        (_controller.value *
            (_endTime.millisecondsSinceEpoch - _startTime.millisecondsSinceEpoch))
            .round();
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
        .add(const Duration(hours: 9)); // KST
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _togglePlay() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
        _isPlaying = false;
      } else {
        if (_controller.value >= 1.0) _controller.value = 0.0;
        _controller.forward();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    // Restore real time
    if (mounted) {
      // Can't read context in dispose, so clearing is handled by onClose
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.spot.type == SpotType.sunset ? '일몰 시뮬레이션' : '일출 시뮬레이션',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    _currentTimeLabel(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      context.read<SunStatusProvider>().clearSimulatedTime();
                      widget.onClose();
                    },
                    child: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.reset();
                      _onTick();
                      setState(() => _isPlaying = false);
                    },
                    child: const Icon(Icons.replay, color: Colors.white54, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 3,
                        activeTrackColor: Colors.orange,
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: Colors.orange,
                      ),
                      child: Slider(
                        value: _controller.value,
                        onChanged: (val) {
                          _controller.value = val;
                          if (!_isPlaying) _onTick();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
