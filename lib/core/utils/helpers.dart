import 'dart:math';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'dart:async';

class Helpers {
  // Format duration
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  // Format date
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return DateFormat.yMMMd().format(date);
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Format number
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Generate random color
  static Color getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  // Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  // Get password strength label
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'Enter password';
    if (password.length < 6) return 'Too short';
    if (password.length < 8) return 'Weak';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Medium';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Medium';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return 'Strong';
    return 'Very Strong';
  }

  // Get password strength color
  static Color getPasswordStrengthColor(String password) {
    if (password.isEmpty) return Colors.grey;
    if (password.length < 6) return Colors.red;
    if (password.length < 8) return Colors.orange;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return Colors.orange;
    if (!RegExp(r'[0-9]').hasMatch(password)) return Colors.yellow;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return Colors.lightGreen;
    }
    return Colors.green;
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Calculate age from birthdate
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Debouncer for search
  static Debounce get debounce => Debounce();

  // Check if string is URL
  static bool isUrl(String text) {
    return Uri.tryParse(text)?.hasAbsolutePath ?? false;
  }

  // Get file extension
  static String getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  // Convert bytes to human readable
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

// Debouncer class for search
class Debounce {
  Timer? _timer;

  void call(Duration duration, VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
