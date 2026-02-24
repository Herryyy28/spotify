import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static bool _isInitialized = false;
  static final List<String> _logs = [];
  static const int _maxLogs = 1000;

  static void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
      info('Logger initialized');
    }
  }

  static void debug(String message, {dynamic data}) {
    _log(LogLevel.debug, message, data);
  }

  static void info(String message, {dynamic data}) {
    _log(LogLevel.info, message, data);
  }

  static void warning(String message, {dynamic data, dynamic error}) {
    _log(LogLevel.warning, message, data, error);
  }

  static void error(String message, {dynamic data, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, data, error, stackTrace);
  }

  static void _log(LogLevel level, String message, [dynamic data, dynamic error, StackTrace? stackTrace]) {
    final time = DateTime.now().toIso8601String();
    final emoji = _getEmoji(level);
    final logEntry = '$emoji [$time] [${level.name.toUpperCase()}] $message';

    // Add data if present
    String fullLog = logEntry;
    if (data != null) {
      fullLog += '\n📦 Data: $data';
    }
    if (error != null) {
      fullLog += '\n⚠️ Error: $error';
    }
    if (stackTrace != null && level == LogLevel.error) {
      fullLog += '\n🔍 StackTrace: $stackTrace';
    }

    // Print to console
    if (kDebugMode) {
      switch (level) {
        case LogLevel.debug:
          debugPrint('📝 $fullLog');
          break;
        case LogLevel.info:
          debugPrint('ℹ️ $fullLog');
          break;
        case LogLevel.warning:
          debugPrint('⚠️ $fullLog');
          break;
        case LogLevel.error:
          debugPrint('❌ $fullLog');
          break;
      }
    }

    // Store in memory
    _logs.add(fullLog);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  static String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '📝';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  static List<String> getLogs() {
    return List.unmodifiable(_logs);
  }

  static void clearLogs() {
    _logs.clear();
    info('Logs cleared');
  }

  static void exportLogs() {
    // Export logs to file
    final logs = _logs.join('\n');
    // Save to file implementation
  }
}

// Extension for easier logging
extension LoggerExtension on Object {
  void logDebug(String message, {dynamic data}) {
    AppLogger.debug('$runtimeType: $message', data: data);
  }

  void logInfo(String message, {dynamic data}) {
    AppLogger.info('$runtimeType: $message', data: data);
  }

  void logWarning(String message, {dynamic data, dynamic error}) {
    AppLogger.warning('$runtimeType: $message', data: data, error: error);
  }

  void logError(String message, {dynamic data, dynamic error, StackTrace? stackTrace}) {
    AppLogger.error('$runtimeType: $message', data: data, error: error, stackTrace: stackTrace);
  }
}