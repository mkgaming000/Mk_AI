import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── BuildContext ───────────────────────────────────────────────────────────

extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
    ));
  }

  void showErrorSnackBar(String message) =>
      showSnackBar(message, isError: true);
}

// ── String ─────────────────────────────────────────────────────────────────

extension StringExt on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidUrl => Uri.tryParse(this)?.hasScheme ?? false;

  String get masked {
    if (length <= 8) return '*' * length;
    return '${substring(0, 4)}${'*' * (length - 8)}${substring(length - 4)}';
  }

  int get wordCount =>
      trim().isEmpty ? 0 : trim().split(RegExp(r'\s+')).length;

  int estimateTokenCount() => (length / 4).ceil();

  Color toProviderColor() {
    const colors = {
      'openai': Color(0xFF10A37F),
      'anthropic': Color(0xFFD97706),
      'google': Color(0xFF4285F4),
      'xai': Color(0xFF9CA3AF),
      'deepseek': Color(0xFF1B6CF2),
      'mistral': Color(0xFFFF7000),
      'openrouter': Color(0xFF6366F1),
      'huggingface': Color(0xFFFFD21E),
      'together': Color(0xFF0467DF),
      'qwen': Color(0xFF6E3CF5),
      'ollama': Color(0xFF4B5563),
      'lmstudio': Color(0xFF4B5563),
      'stability': Color(0xFFA855F7),
      'replicate': Color(0xFF374151),
    };
    return colors[toLowerCase()] ?? const Color(0xFF8B5CF6);
  }

  String providerEmoji() {
    const emojis = {
      'openai': '🤖', 'anthropic': '🧠', 'google': '🔮',
      'xai': '⚡', 'deepseek': '🌊', 'mistral': '🌪️',
      'openrouter': '🔀', 'huggingface': '🤗', 'together': '🦙',
      'qwen': '🌸', 'ollama': '🏠', 'lmstudio': '🖥️',
    };
    return emojis[toLowerCase()] ?? '🤖';
  }
}

// ── DateTime ───────────────────────────────────────────────────────────────

extension DateTimeExt on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    final mo = (diff.inDays / 30).floor();
    if (mo < 12) return '$mo ${mo == 1 ? 'month' : 'months'} ago';
    final y = (diff.inDays / 365).floor();
    return '$y ${y == 1 ? 'year' : 'years'} ago';
  }

  String get formattedDate => DateFormat('MMM d, yyyy').format(this);
  String get formattedTime => DateFormat('h:mm a').format(this);
  String get formattedDateTime => DateFormat('MMM d, yyyy · h:mm a').format(this);
  String get formattedShort => DateFormat('MMM d').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return year == y.year && month == y.month && day == y.day;
  }

  String get conversationDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (DateTime.now().difference(this).inDays < 7) {
      return DateFormat('EEEE').format(this);
    }
    return formattedDate;
  }
}

// ── int ────────────────────────────────────────────────────────────────────

extension IntExt on int {
  String get formattedTokenCount {
    if (this < 1000) return toString();
    if (this < 1000000) return '${(this / 1000).toStringAsFixed(1)}K';
    return '${(this / 1000000).toStringAsFixed(2)}M';
  }

  String get formattedFileSize {
    if (this < 1024) return '${this}B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)}KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}

// ── double ─────────────────────────────────────────────────────────────────

extension DoubleExt on double {
  String get formattedCost {
    if (this == 0) return '\$0.000';
    if (this < 0.001) return '<\$0.001';
    if (this < 1.0) return '\$${toStringAsFixed(4)}';
    if (this < 100) return '\$${toStringAsFixed(2)}';
    return '\$${toStringAsFixed(0)}';
  }
}

// ── List ───────────────────────────────────────────────────────────────────

extension ListExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

// ── Color ──────────────────────────────────────────────────────────────────

extension ColorExt on Color {
  bool get isLight => computeLuminance() > 0.5;
  Color get onColor => isLight ? Colors.black : Colors.white;
}

// ── Widget ─────────────────────────────────────────────────────────────────

extension WidgetExt on Widget {
  Widget padAll(double v) => Padding(padding: EdgeInsets.all(v), child: this);
  Widget padH(double v) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: v), child: this);
  Widget padV(double v) =>
      Padding(padding: EdgeInsets.symmetric(vertical: v), child: this);
  Widget centered() => Center(child: this);
  Widget expanded([int flex = 1]) => Expanded(flex: flex, child: this);
}
