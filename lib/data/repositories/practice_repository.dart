import 'dart:io';
import '../datasources/local_database.dart';
import '../models/challenge_evaluation.dart';
import '../models/filler_stat.dart';
import '../models/practice_session.dart';

class DashboardStats {
  final int totalSessions;
  final double averageScore;
  final int totalPracticeSeconds;
  final PracticeSession? lastSession;

  DashboardStats({
    required this.totalSessions,
    required this.averageScore,
    required this.totalPracticeSeconds,
    this.lastSession,
  });
}

class ProgressDataPoint {
  final DateTime date;
  final double? score;
  final double? wpm;
  final double? fillerRate;
  final String challengeType;

  ProgressDataPoint({
    required this.date,
    this.score,
    this.wpm,
    this.fillerRate,
    required this.challengeType,
  });
}

class PracticeRepository {
  final LocalDatabase _localDb;

  PracticeRepository({LocalDatabase? localDb})
      : _localDb = localDb ?? LocalDatabase.instance;

  Future<void> saveSession(PracticeSession session) async {
    final db = await _localDb.database;

    await db.transaction((txn) async {
      // 1. Upsert practice_session
      await txn.insert(
        'practice_sessions',
        session.toMap(),
        conflictAlgorithm: null, // We handle replacement below
      );

      // 2. Save ChallengeEvaluation if present
      if (session.evaluation != null) {
        await txn.insert(
          'challenge_evaluations',
          session.evaluation!.toMap(),
        );
      }

      // 3. Save filler_statistics if present
      for (final stat in session.fillerStats) {
        await txn.insert(
          'filler_statistics',
          stat.toMap(),
        );
      }
    });
  }

  Future<PracticeSession?> getSessionById(String id) async {
    final db = await _localDb.database;

    final sessionRows = await db.query(
      'practice_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (sessionRows.isEmpty) return null;

    final evalRows = await db.query(
      'challenge_evaluations',
      where: 'session_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    ChallengeEvaluation? eval;
    if (evalRows.isNotEmpty) {
      eval = ChallengeEvaluation.fromMap(evalRows.first);
    }

    final fillerRows = await db.query(
      'filler_statistics',
      where: 'session_id = ?',
      whereArgs: [id],
    );

    final fillerStats =
        fillerRows.map((row) => FillerStat.fromMap(row)).toList();

    return PracticeSession.fromMap(
      sessionRows.first,
      evaluation: eval,
      fillerStats: fillerStats,
    );
  }

  Future<List<PracticeSession>> getAllSessions({
    String? modeFilter,
    String? challengeTypeFilter,
  }) async {
    final db = await _localDb.database;

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (modeFilter != null && modeFilter != 'all') {
      whereClause = 'mode = ?';
      whereArgs.add(modeFilter);
    }

    if (challengeTypeFilter != null && challengeTypeFilter != 'all') {
      if (whereClause != null) {
        whereClause += ' AND challenge_type = ?';
      } else {
        whereClause = 'challenge_type = ?';
      }
      whereArgs.add(challengeTypeFilter);
    }

    final rows = await db.query(
      'practice_sessions',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => PracticeSession.fromMap(r)).toList();
  }

  Future<List<PracticeSession>> getRecentSessions(int limit) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'practice_sessions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map((r) => PracticeSession.fromMap(r)).toList();
  }

  Future<void> deleteSession(String id) async {
    final db = await _localDb.database;

    // First find recording path to delete file from disk
    final rows = await db.query(
      'practice_sessions',
      columns: ['recording_path'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rows.isNotEmpty) {
      final path = rows.first['recording_path'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }

    // Delete session (cascade deletes evaluation and filler stats via FK)
    await db.delete(
      'practice_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DashboardStats> getDashboardStats() async {
    final db = await _localDb.database;

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(actual_duration) as total_duration FROM practice_sessions WHERE status = "completed"',
    );

    final totalCount = (countResult.first['count'] as num?)?.toInt() ?? 0;
    final totalDuration =
        (countResult.first['total_duration'] as num?)?.toInt() ?? 0;

    final avgResult = await db.rawQuery(
      'SELECT AVG(overall_score) as avg_score FROM practice_sessions WHERE status = "completed" AND overall_score IS NOT NULL',
    );

    final avgScore = (avgResult.first['avg_score'] as num?)?.toDouble() ?? 0.0;

    final recentRows = await db.query(
      'practice_sessions',
      where: 'status = "completed"',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    PracticeSession? lastSession;
    if (recentRows.isNotEmpty) {
      lastSession = await getSessionById(recentRows.first['id'] as String);
    }

    return DashboardStats(
      totalSessions: totalCount,
      averageScore: avgScore,
      totalPracticeSeconds: totalDuration,
      lastSession: lastSession,
    );
  }

  Future<List<ProgressDataPoint>> getProgressData() async {
    final db = await _localDb.database;
    final rows = await db.query(
      'practice_sessions',
      columns: [
        'created_at',
        'overall_score',
        'speaking_pace',
        'filler_count',
        'total_words',
        'challenge_type',
        'mode'
      ],
      where: 'status = "completed"',
      orderBy: 'created_at ASC',
    );

    return rows.map((r) {
      DateTime date;
      try {
        date = DateTime.parse(r['created_at'] as String);
      } catch (_) {
        date = DateTime.now();
      }

      final score = (r['overall_score'] as num?)?.toDouble();
      final pace = (r['speaking_pace'] as num?)?.toDouble();
      final fillerCount = (r['filler_count'] as num?)?.toInt();
      final totalWords = (r['total_words'] as num?)?.toInt();

      double? fillerRate;
      if (fillerCount != null && totalWords != null && totalWords > 0) {
        fillerRate = (fillerCount / totalWords) * 100.0;
      }

      final chType =
          r['challenge_type'] as String? ?? r['mode'] as String? ?? 'free';

      return ProgressDataPoint(
        date: date,
        score: score,
        wpm: pace,
        fillerRate: fillerRate,
        challengeType: chType,
      );
    }).toList();
  }

  Future<void> clearAllData() async {
    final db = await _localDb.database;
    await db.transaction((txn) async {
      await txn.delete('filler_statistics');
      await txn.delete('challenge_evaluations');
      await txn.delete('practice_sessions');
    });
  }
}

