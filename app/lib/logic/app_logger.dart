import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogEvent {
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? metadata;
  final String? error;
  final String? stackTrace;

  AppLogEvent({
    DateTime? timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.metadata,
    this.error,
    this.stackTrace,
  }) : timestamp = (timestamp ?? DateTime.now()).toUtc();

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'category': category,
    'message': message,
    if (metadata != null) 'metadata': metadata,
    if (error != null) 'error': error,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}][${level.name.toUpperCase()}][$category] $message';
  }
}

class AppLogger {
  final int maxCapacity;
  final ListQueue<AppLogEvent> _buffer = ListQueue<AppLogEvent>();

  AppLogger({this.maxCapacity = 500});

  List<AppLogEvent> get logs => List.unmodifiable(_buffer);

  int get length => _buffer.length;

  void log({
    required LogLevel level,
    required String category,
    required String message,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final event = AppLogEvent(
      level: level,
      category: category,
      message: message,
      metadata: metadata,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    _buffer.addLast(event);
    while (_buffer.length > maxCapacity) {
      _buffer.removeFirst();
    }

    final metaStr = metadata != null ? ' | meta: $metadata' : '';
    final errStr = error != null ? ' | error: $error' : '';
    debugPrint(
      '[${level.name.toUpperCase()}][$category] $message$metaStr$errStr',
    );
  }

  void debug(
    String message, {
    String category = 'app',
    Map<String, dynamic>? metadata,
  }) {
    log(
      level: LogLevel.debug,
      category: category,
      message: message,
      metadata: metadata,
    );
  }

  void info(
    String message, {
    String category = 'app',
    Map<String, dynamic>? metadata,
  }) {
    log(
      level: LogLevel.info,
      category: category,
      message: message,
      metadata: metadata,
    );
  }

  void warning(
    String message, {
    String category = 'app',
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.warning,
      category: category,
      message: message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    String category = 'app',
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.error,
      category: category,
      message: message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void clear() {
    _buffer.clear();
  }
}
