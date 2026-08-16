import '../domain/reader/book_progress.dart';

/// The relationship between two replicas after comparing them with a common
/// synchronization baseline.
enum SyncConflictDecision {
  sameVersion,
  remoteAhead,
  localAhead,
  concurrentConflict,
}

/// The default action associated with a sync decision.
enum SyncConflictResolution { noChange, applyRemote, uploadLocal, requireMerge }

/// A revision plus an optional content identity for same-revision checks.
class SyncRevision {
  final int value;
  final String? fingerprint;

  const SyncRevision({required this.value, this.fingerprint});
}

class SyncConflictResult {
  final SyncConflictDecision decision;
  final SyncConflictResolution resolution;

  const SyncConflictResult({required this.decision, required this.resolution});
}

typedef SyncConflictDecider =
    SyncConflictResult Function({
      required int baseRevision,
      required SyncRevision local,
      required SyncRevision remote,
    });

/// Pure conflict classification shared by progress and bookmark sync.
///
/// The baseline is the last revision known to be shared by both replicas.
/// This keeps clock skew out of the decision: a remote file timestamp is a
/// useful transport hint, but it cannot by itself prove that a local edit did
/// not happen after the last sync.
class SyncConflictPolicy {
  const SyncConflictPolicy(this.decider);

  final SyncConflictDecider decider;

  SyncConflictResult call({
    required int baseRevision,
    required SyncRevision local,
    required SyncRevision remote,
  }) {
    return decider(baseRevision: baseRevision, local: local, remote: remote);
  }

  static SyncConflictResult compare({
    required int baseRevision,
    required SyncRevision local,
    required SyncRevision remote,
  }) {
    final localChanged = local.value != baseRevision;
    final remoteChanged = remote.value != baseRevision;

    if (local.value == remote.value) {
      final sameContent =
          local.fingerprint == null ||
          remote.fingerprint == null ||
          local.fingerprint == remote.fingerprint;
      if (sameContent || !localChanged || !remoteChanged) {
        return const SyncConflictResult(
          decision: SyncConflictDecision.sameVersion,
          resolution: SyncConflictResolution.noChange,
        );
      }
    }

    if (localChanged && remoteChanged) {
      return const SyncConflictResult(
        decision: SyncConflictDecision.concurrentConflict,
        resolution: SyncConflictResolution.requireMerge,
      );
    }
    if (remoteChanged) {
      return const SyncConflictResult(
        decision: SyncConflictDecision.remoteAhead,
        resolution: SyncConflictResolution.applyRemote,
      );
    }
    if (localChanged) {
      return const SyncConflictResult(
        decision: SyncConflictDecision.localAhead,
        resolution: SyncConflictResolution.uploadLocal,
      );
    }
    return const SyncConflictResult(
      decision: SyncConflictDecision.sameVersion,
      resolution: SyncConflictResolution.noChange,
    );
  }

  /// Compare two serialized bookmark snapshots using their caller-provided
  /// revision and content identity (for example WebDAV mtime and a digest).
  static SyncConflictResult compareBookmarkFiles({
    required int baseRevision,
    required int localRevision,
    required int remoteRevision,
    String? localFingerprint,
    String? remoteFingerprint,
  }) {
    return compare(
      baseRevision: baseRevision,
      local: SyncRevision(value: localRevision, fingerprint: localFingerprint),
      remote: SyncRevision(
        value: remoteRevision,
        fingerprint: remoteFingerprint,
      ),
    );
  }

  /// Compare progress snapshots while retaining the original position data
  /// as a same-revision identity check.
  static SyncConflictResult compareBookProgress({
    required int baseRevision,
    required BookProgress local,
    required BookProgress remote,
  }) {
    return compare(
      baseRevision: baseRevision,
      local: SyncRevision(
        value: local.durChapterTime,
        fingerprint: _progressFingerprint(local),
      ),
      remote: SyncRevision(
        value: remote.durChapterTime,
        fingerprint: _progressFingerprint(remote),
      ),
    );
  }

  static String _progressFingerprint(BookProgress progress) {
    return '${progress.durChapterIndex}:${progress.durChapterPos}:\n'
        '${progress.durChapterTitle ?? ''}';
  }
}
