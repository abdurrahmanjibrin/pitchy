import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class Formatters {
  static String formatSecondsToMinutesSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  static String formatDurationHuman(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds dtk';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '$minutes mnt';
    }
    return '$minutes mnt $seconds dtk';
  }

  static String formatDate(DateTime dateTime) {
    final formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    try {
      return formatter.format(dateTime);
    } catch (_) {
      return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
    }
  }

  static String formatDateShort(DateTime dateTime) {
    final formatter = DateFormat('d MMM', 'id_ID');
    try {
      return formatter.format(dateTime);
    } catch (_) {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  static Color getScoreColor(double? score) {
    if (score == null) return AppColors.textMuted;
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  static String getPaceLabel(double wpm) {
    if (wpm == 0) return 'Belum terukur';
    if (wpm < 100) return 'Relatif Lambat';
    if (wpm <= 160) return 'Optimal / Direkomendasikan';
    if (wpm <= 180) return 'Relatif Cepat';
    return 'Sangat Cepat';
  }

  static Color getPaceColor(double wpm) {
    if (wpm == 0) return AppColors.textMuted;
    if (wpm >= 100 && wpm <= 160) return AppColors.success;
    if (wpm >= 85 && wpm < 100) return AppColors.warning;
    if (wpm > 160 && wpm <= 180) return AppColors.warning;
    return AppColors.error;
  }
}

