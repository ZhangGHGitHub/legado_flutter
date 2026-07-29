import 'dart:async';

import 'package:flutter/foundation.dart';

enum StartupTaskStatus { running, succeeded, failed, skipped }

class StartupTaskReport {
  const StartupTaskReport({
    required this.id,
    required this.status,
    required this.attempt,
    required this.startedAt,
    this.finishedAt,
    this.error,
    this.stackTrace,
  });

  final String id;
  final StartupTaskStatus status;
  final int attempt;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isTerminal => status != StartupTaskStatus.running;

  Duration? get elapsed {
    final end = finishedAt;
    if (end == null) return null;
    return end.difference(startedAt);
  }
}

typedef StartupTaskAction = Future<void> Function();

class StartupTaskSkipped implements Exception {
  const StartupTaskSkipped([this.reason = '']);

  final String reason;
}

/// 启动后台任务的统一边界：独立超时、失败隔离、重复调用合并和失败重试。
final class StartupTaskRunner {
  StartupTaskRunner({
    void Function(StartupTaskReport report)? onReport,
    DateTime Function()? clock,
  }) : _onReport = onReport,
       _clock = clock ?? DateTime.now;

  static const defaultTimeout = Duration(seconds: 30);

  final void Function(StartupTaskReport report)? _onReport;
  final DateTime Function() _clock;
  final Map<String, Future<StartupTaskReport>> _running = {};
  final Map<String, StartupTaskReport> _reports = {};

  Map<String, StartupTaskReport> get reports =>
      Map.unmodifiable(Map<String, StartupTaskReport>.from(_reports));

  Future<StartupTaskReport> run(
    String id,
    StartupTaskAction action, {
    Duration timeout = defaultTimeout,
  }) {
    final existing = _running[id];
    if (existing != null) return existing;

    final previous = _reports[id];
    if (previous != null &&
        previous.status != StartupTaskStatus.failed &&
        previous.status != StartupTaskStatus.running) {
      return Future<StartupTaskReport>.value(previous);
    }

    final future = _execute(
      id,
      action,
      timeout: timeout,
      attempt: (previous?.attempt ?? 0) + 1,
    );
    _running[id] = future;
    future.whenComplete(() {
      if (identical(_running[id], future)) _running.remove(id);
    });
    return future;
  }

  Future<StartupTaskReport> skip(String id) {
    final previous = _reports[id];
    if (previous != null && previous.status == StartupTaskStatus.skipped) {
      return Future<StartupTaskReport>.value(previous);
    }
    final report = StartupTaskReport(
      id: id,
      status: StartupTaskStatus.skipped,
      attempt: previous?.attempt ?? 0,
      startedAt: _clock(),
      finishedAt: _clock(),
    );
    _reports[id] = report;
    _emit(report);
    return Future<StartupTaskReport>.value(report);
  }

  Future<StartupTaskReport> _execute(
    String id,
    StartupTaskAction action, {
    required Duration timeout,
    required int attempt,
  }) async {
    final startedAt = _clock();
    _emit(
      StartupTaskReport(
        id: id,
        status: StartupTaskStatus.running,
        attempt: attempt,
        startedAt: startedAt,
      ),
    );
    try {
      await action().timeout(timeout);
      return _complete(
        id: id,
        status: StartupTaskStatus.succeeded,
        attempt: attempt,
        startedAt: startedAt,
      );
    } on StartupTaskSkipped {
      return _complete(
        id: id,
        status: StartupTaskStatus.skipped,
        attempt: attempt,
        startedAt: startedAt,
      );
    } catch (error, stackTrace) {
      debugPrint('[StartupTask][$id] 启动任务失败: $error');
      return _complete(
        id: id,
        status: StartupTaskStatus.failed,
        attempt: attempt,
        startedAt: startedAt,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  StartupTaskReport _complete({
    required String id,
    required StartupTaskStatus status,
    required int attempt,
    required DateTime startedAt,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final report = StartupTaskReport(
      id: id,
      status: status,
      attempt: attempt,
      startedAt: startedAt,
      finishedAt: _clock(),
      error: error,
      stackTrace: stackTrace,
    );
    _reports[id] = report;
    _emit(report);
    return report;
  }

  void _emit(StartupTaskReport report) {
    _reports[report.id] = report;
    try {
      _onReport?.call(report);
    } catch (error) {
      debugPrint('[StartupTask][${report.id}] 任务报告失败: $error');
    }
  }
}
