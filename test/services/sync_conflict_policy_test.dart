import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/reader/book_progress.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';
import 'package:legado_flutter/services/sync_conflict_policy.dart';

void main() {
  const base = 100;

  SyncRevision revision(int value, [String? fingerprint]) {
    return SyncRevision(value: value, fingerprint: fingerprint);
  }

  test('same version is a no-op', () {
    final result = SyncConflictPolicy.compare(
      baseRevision: base,
      local: revision(base, 'same'),
      remote: revision(base, 'same'),
    );

    expect(result.decision, SyncConflictDecision.sameVersion);
    expect(result.resolution, SyncConflictResolution.noChange);
  });

  test('remote-only change applies the remote snapshot', () {
    final result = SyncConflictPolicy.compare(
      baseRevision: base,
      local: revision(base, 'base'),
      remote: revision(101, 'remote'),
    );

    expect(result.decision, SyncConflictDecision.remoteAhead);
    expect(result.resolution, SyncConflictResolution.applyRemote);
  });

  test('local-only change uploads the local snapshot', () {
    final result = SyncConflictPolicy.compare(
      baseRevision: base,
      local: revision(102, 'local'),
      remote: revision(base, 'base'),
    );

    expect(result.decision, SyncConflictDecision.localAhead);
    expect(result.resolution, SyncConflictResolution.uploadLocal);
  });

  test('changes on both replicas require an explicit merge', () {
    final result = SyncConflictPolicy.compare(
      baseRevision: base,
      local: revision(102, 'local'),
      remote: revision(101, 'remote'),
    );

    expect(result.decision, SyncConflictDecision.concurrentConflict);
    expect(result.resolution, SyncConflictResolution.requireMerge);
  });

  test('same revision with different content is a concurrent conflict', () {
    final result = SyncConflictPolicy.compareBookmarkFiles(
      baseRevision: base,
      localRevision: 101,
      remoteRevision: 101,
      localFingerprint: 'local-bookmarks',
      remoteFingerprint: 'remote-bookmarks',
    );

    expect(result.decision, SyncConflictDecision.concurrentConflict);
    expect(result.resolution, SyncConflictResolution.requireMerge);
  });

  test('progress adapter uses durChapterTime as its revision', () {
    const local = BookProgress(
      name: '测试书',
      author: '作者',
      durChapterIndex: 2,
      durChapterPos: 10,
      durChapterTime: 100,
    );
    const remote = BookProgress(
      name: '测试书',
      author: '作者',
      durChapterIndex: 3,
      durChapterPos: 5,
      durChapterTime: 101,
    );

    final result = BookProgressSync.decideConflict(
      local: local,
      remote: remote,
      baseRevision: 100,
    );

    expect(result.decision, SyncConflictDecision.remoteAhead);
    expect(result.resolution, SyncConflictResolution.applyRemote);
  });

  test('an injectable decider can be used by a sync coordinator', () {
    final policy = SyncConflictPolicy(({
      required int baseRevision,
      required SyncRevision local,
      required SyncRevision remote,
    }) {
      return const SyncConflictResult(
        decision: SyncConflictDecision.concurrentConflict,
        resolution: SyncConflictResolution.requireMerge,
      );
    });

    final result = policy(
      baseRevision: base,
      local: revision(base),
      remote: revision(base),
    );

    expect(result.decision, SyncConflictDecision.concurrentConflict);
  });
}
