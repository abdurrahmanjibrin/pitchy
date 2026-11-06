import 'dart:math';
import '../../data/datasources/local_database.dart';
import '../../data/models/challenge_item.dart';

class ChallengeService {
  final LocalDatabase _localDb;
  final Random _random = Random();

  ChallengeService({LocalDatabase? localDb})
      : _localDb = localDb ?? LocalDatabase.instance;

  Future<List<ChallengeItem>> getChallengesByType(String type) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'challenge_library',
      where: 'type = ? AND is_active = 1',
      whereArgs: [type],
    );
    return rows.map((r) => ChallengeItem.fromMap(r)).toList();
  }

  Future<ChallengeItem> getRandomChallenge({
    required String type,
    String? excludeId,
  }) async {
    final db = await _localDb.database;

    // Get last 5 used challenge IDs of this type to avoid immediate repetition (PRD 6.3.5)
    final recentRows = await db.query(
      'practice_sessions',
      columns: ['challenge_id'],
      where: 'challenge_type = ? AND challenge_id IS NOT NULL',
      whereArgs: [type],
      orderBy: 'created_at DESC',
      limit: 5,
    );

    final recentIds = recentRows
        .map((r) => r['challenge_id'] as String?)
        .whereType<String>()
        .toSet();

    if (excludeId != null) {
      recentIds.add(excludeId);
    }

    final allItems = await getChallengesByType(type);
    if (allItems.isEmpty) {
      // Fallback default
      return _getDefaultFallback(type);
    }

    // Filter out recently used
    final candidates =
        allItems.where((item) => !recentIds.contains(item.id)).toList();

    if (candidates.isNotEmpty) {
      return candidates[_random.nextInt(candidates.length)];
    }

    // If all were recently used or candidates empty, pick from all excluding current
    final pool =
        allItems.where((item) => item.id != excludeId).toList();
    if (pool.isNotEmpty) {
      return pool[_random.nextInt(pool.length)];
    }

    return allItems[_random.nextInt(allItems.length)];
  }

  ChallengeItem _getDefaultFallback(String type) {
    switch (type) {
      case 'random_words':
        return ChallengeItem(
          id: 'fallback_rw',
          type: 'random_words',
          prompt:
              'Pitch ide solusi kampus dengan mengintegrasikan kata-kata berikut secara alami.',
          requiredWords: ['kopi', 'robot', 'kampus', 'waktu', 'payung'],
          difficulty: 'Medium',
          category: 'Kreativitas',
          suggestedDuration: 120,
        );
      case 'random_theme':
        return ChallengeItem(
          id: 'fallback_rt',
          type: 'random_theme',
          prompt:
              'Pitch ide pengelolaan sampah makanan di kantin kampus untuk menciptakan lingkungan hijau.',
          difficulty: 'Easy',
          category: 'Lingkungan',
          suggestedDuration: 120,
        );
      case 'audience_scenario':
      default:
        return ChallengeItem(
          id: 'fallback_as',
          type: 'audience_scenario',
          prompt:
              'Presentasikan ide aplikasimu di hadapan Dosen Penguji. Tekankan ketepatan metodologi dan dasar logika.',
          audienceProfile: {
            'type': 'Dosen Penguji',
            'focus': 'Ketepatan teori dan konsistensi logika',
            'knowledge_level': 'Tinggi secara akademis',
            'convincer': 'Bukti data riset dan metodologi jelas',
            'goal': 'Mendapatkan persetujuan proposal'
          },
          difficulty: 'Medium',
          category: 'Akademik',
          suggestedDuration: 180,
        );
    }
  }
}

