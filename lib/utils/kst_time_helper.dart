import 'dart:math';

enum SunPeriod { sunrise, daytime, sunset, night }

class KstTimeHelper {
  static DateTime nowKst() =>
      DateTime.now().toUtc().add(const Duration(hours: 9));

  static SunPeriod getSunPeriod(int kstHour) {
    if (kstHour >= 5 && kstHour < 7) return SunPeriod.sunrise;
    if (kstHour >= 7 && kstHour < 17) return SunPeriod.daytime;
    if (kstHour >= 17 && kstHour < 19) return SunPeriod.sunset;
    return SunPeriod.night;
  }

  static String formatKstAmPm(DateTime kst) {
    final hour = kst.hour;
    final minute = kst.minute;
    final ampm = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$ampm $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  static String getStatusText(SunPeriod period) {
    switch (period) {
      case SunPeriod.sunrise:
        return '지금은 일출 시간이에요';
      case SunPeriod.daytime:
        return '맑은 하늘을 즐기세요';
      case SunPeriod.sunset:
        return '지금은 일몰 시간이에요';
      case SunPeriod.night:
        return '별이 빛나는 밤이에요';
    }
  }

  static String getStatusEmoji(SunPeriod period) {
    switch (period) {
      case SunPeriod.sunrise:
        return '\u{1F305}';
      case SunPeriod.daytime:
        return '\u{2600}\u{FE0F}';
      case SunPeriod.sunset:
        return '\u{1F307}';
      case SunPeriod.night:
        return '\u{1F319}';
    }
  }

  /// 현재 시간대 내 진행률 (0.0~1.0)
  static double getPeriodProgress(DateTime kst) {
    final hour = kst.hour + kst.minute / 60.0;
    final period = getSunPeriod(kst.hour);
    switch (period) {
      case SunPeriod.sunrise:
        return ((hour - 5.0) / 2.0).clamp(0.0, 1.0);
      case SunPeriod.daytime:
        return ((hour - 7.0) / 10.0).clamp(0.0, 1.0);
      case SunPeriod.sunset:
        return ((hour - 17.0) / 2.0).clamp(0.0, 1.0);
      case SunPeriod.night:
        if (hour >= 19) return ((hour - 19.0) / 10.0).clamp(0.0, 1.0);
        return ((hour + 5.0) / 10.0).clamp(0.0, 1.0);
    }
  }
}
