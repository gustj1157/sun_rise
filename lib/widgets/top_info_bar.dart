import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sun_status_provider.dart';
import '../utils/kst_time_helper.dart';

class TopInfoBar extends StatefulWidget {
  const TopInfoBar({super.key});

  @override
  State<TopInfoBar> createState() => _TopInfoBarState();
}

class _TopInfoBarState extends State<TopInfoBar> {
  late Timer _timer;
  DateTime _kstNow = KstTimeHelper.nowKst();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _kstNow = KstTimeHelper.nowKst());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _buildCountdown() {
    final kst = _kstNow;
    final hour = kst.hour;

    // 다음 일출/일몰까지 남은 시간 계산
    DateTime target;
    String label;

    if (hour >= 5 && hour < 7) {
      // 일출 중 → 일출 끝까지
      target = DateTime(kst.year, kst.month, kst.day, 7, 0);
      label = '일출 끝까지';
    } else if (hour >= 7 && hour < 17) {
      // 낮 → 일몰까지
      target = DateTime(kst.year, kst.month, kst.day, 17, 0);
      label = '일몰까지';
    } else if (hour >= 17 && hour < 19) {
      // 일몰 중 → 일몰 끝까지
      target = DateTime(kst.year, kst.month, kst.day, 19, 0);
      label = '일몰 끝까지';
    } else {
      // 밤 → 다음 일출까지
      if (hour >= 19) {
        target = DateTime(kst.year, kst.month, kst.day + 1, 5, 0);
      } else {
        target = DateTime(kst.year, kst.month, kst.day, 5, 0);
      }
      label = '일출까지';
    }

    final diff = target.difference(kst);
    if (diff.inHours > 0) {
      return '$label ${diff.inHours}시간 ${diff.inMinutes.remainder(60)}분';
    }
    return '$label ${diff.inMinutes}분';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SunStatusProvider>(
      builder: (context, provider, _) {
        final period = provider.currentPeriod;
        final kst = provider.isSimulating ? provider.currentKst : _kstNow;
        final displayPeriod =
            provider.isSimulating ? provider.currentPeriod : period;

        return IgnorePointer(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // 시각
                      Text(
                        KstTimeHelper.formatKstAmPm(kst),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // 상태
                      Text(
                        '${KstTimeHelper.getStatusEmoji(displayPeriod)} '
                        '${KstTimeHelper.getStatusText(displayPeriod)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      // 카운트다운
                      Text(
                        _buildCountdown(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
