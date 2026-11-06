import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/challenge_item.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pitchy_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. challenge_library
    await db.execute('''
      CREATE TABLE challenge_library (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        prompt TEXT NOT NULL,
        required_words_json TEXT,
        audience_profile_json TEXT,
        difficulty TEXT NOT NULL,
        category TEXT NOT NULL,
        suggested_duration INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. practice_sessions
    await db.execute('''
      CREATE TABLE practice_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        topic TEXT,
        mode TEXT NOT NULL,
        challenge_type TEXT,
        challenge_id TEXT,
        challenge_prompt TEXT,
        required_words_json TEXT,
        audience_profile_json TEXT,
        preparation_seconds INTEGER NOT NULL DEFAULT 0,
        target_duration INTEGER,
        actual_duration INTEGER NOT NULL,
        recording_type TEXT NOT NULL DEFAULT 'audio',
        recording_path TEXT,
        transcript TEXT,
        total_words INTEGER,
        speaking_pace REAL,
        filler_count INTEGER,
        pause_count INTEGER,
        average_pause REAL,
        delivery_score REAL,
        content_score REAL,
        overall_score REAL,
        ai_feedback TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        created_at TEXT NOT NULL,
        FOREIGN KEY (challenge_id) REFERENCES challenge_library (id) ON DELETE SET NULL
      )
    ''');

    // 4. challenge_evaluations
    await db.execute('''
      CREATE TABLE challenge_evaluations (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL UNIQUE,
        clarity_score REAL,
        clarity_reason TEXT,
        coherence_score REAL,
        coherence_reason TEXT,
        relevance_score REAL,
        relevance_reason TEXT,
        audience_fit_score REAL,
        audience_fit_reason TEXT,
        required_words_result_json TEXT,
        strengths_json TEXT,
        improvements_json TEXT,
        evidence_json TEXT,
        suggested_revision TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        FOREIGN KEY (session_id) REFERENCES practice_sessions (id) ON DELETE CASCADE
      )
    ''');

    // 5. filler_statistics
    await db.execute('''
      CREATE TABLE filler_statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        filler_word TEXT NOT NULL,
        count INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES practice_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Seed default challenge items
    await _seedChallenges(db);
  }

  Future<void> _seedChallenges(Database db) async {
    final batch = db.batch();

    final List<ChallengeItem> seedItems = [
      // Random Words Challenges
      ChallengeItem(
        id: 'rw_01',
        type: 'random_words',
        prompt:
            'Pitch ide produk atau solusi inovatif dan selipkan seluruh kata wajib secara alami ke dalam argumenmu.',
        requiredWords: ['kopi', 'robot', 'kampus', 'waktu', 'payung'],
        difficulty: 'Medium',
        category: 'Inovasi Kampus',
        suggestedDuration: 120,
      ),
      ChallengeItem(
        id: 'rw_02',
        type: 'random_words',
        prompt:
            'Tawarkan konsep bisnis atau program mahasiswa dengan mengintegrasikan kata-kata berikut secara bermakna.',
        requiredWords: ['buku', 'sepatu', 'awan', 'ekonomi', 'sinyal'],
        difficulty: 'Hard',
        category: 'Kreativitas Bisnis',
        suggestedDuration: 180,
      ),
      ChallengeItem(
        id: 'rw_03',
        type: 'random_words',
        prompt:
            'Gambarkan solusi untuk mengatasi kejenuhan belajar dengan menyisipkan kata wajib berikut ke dalam narasi pitch.',
        requiredWords: ['sarapan', 'jembatan', 'baterai', 'kucing'],
        difficulty: 'Easy',
        category: 'Kehidupan Mahasiswa',
        suggestedDuration: 60,
      ),
      ChallengeItem(
        id: 'rw_04',
        type: 'random_words',
        prompt:
            'Sampaikan pitch layanan mobilitas pintar di lingkungan perkotaan yang menyertakan kata-kata berikut.',
        requiredWords: ['kereta', 'dompet', 'satelit', 'kreativitas', 'hujan'],
        difficulty: 'Hard',
        category: 'Teknologi & Transportasi',
        suggestedDuration: 180,
      ),
      ChallengeItem(
        id: 'rw_05',
        type: 'random_words',
        prompt:
            'Jelaskan terobosan platform edukasi masa depan dengan merangkai kata wajib berikut secara koheren.',
        requiredWords: ['kacamata', 'ai', 'perpustakaan', 'kecepatan'],
        difficulty: 'Medium',
        category: 'EdTech',
        suggestedDuration: 120,
      ),

      // Random Theme Challenges
      ChallengeItem(
        id: 'rt_01',
        type: 'random_theme',
        prompt:
            'Pitch ide untuk mengurangi sampah makanan dan sisa konsumsi di kantin lingkungan kampus.',
        difficulty: 'Easy',
        category: 'Lingkungan',
        suggestedDuration: 120,
      ),
      ChallengeItem(
        id: 'rt_02',
        type: 'random_theme',
        prompt:
            'Pitch aplikasi peer-to-peer untuk jual beli atau sewa buku teks kuliah bekas antar mahasiswa.',
        difficulty: 'Medium',
        category: 'Pendidikan',
        suggestedDuration: 120,
      ),
      ChallengeItem(
        id: 'rt_03',
        type: 'random_theme',
        prompt:
            'Pitch platform bimbingan skripsi dan konsultasi metodologi terjangkau antar alumni dan mahasiswa tingkat akhir.',
        difficulty: 'Medium',
        category: 'Kehidupan Kampus',
        suggestedDuration: 180,
      ),
      ChallengeItem(
        id: 'rt_04',
        type: 'random_theme',
        prompt:
            'Pitch inisiatif sistem carpooling atau nebeng bareng aman khusus civitas akademika untuk hemat bensin dan emisi.',
        difficulty: 'Easy',
        category: 'Mobilitas',
        suggestedDuration: 120,
      ),
      ChallengeItem(
        id: 'rt_05',
        type: 'random_theme',
        prompt:
            'Pitch startup AI personal study assistant yang membantu mahasiswa memecah materi ujian tebal menjadi ringkasan harian.',
        difficulty: 'Hard',
        category: 'Teknologi & AI',
        suggestedDuration: 180,
      ),

      // Audience Scenario Challenges
      ChallengeItem(
        id: 'as_01',
        type: 'audience_scenario',
        prompt:
            'Kamu sedang menawarkan aplikasi pengelolaan sampah dan efisiensi energi kepada pimpinan kampus. Jelaskan manfaat biaya dan reputasi hijau bagi universitas.',
        audienceProfile: {
          'type': 'Pimpinan Kampus / Rektorat',
          'focus': 'Efisiensi anggaran, kepatuhan regulasi, reputasi hijau kampus',
          'knowledge_level': 'Tinggi secara manajemen, umum secara teknis',
          'convincer': 'Data penghematan biaya operasional dan dampak branding institusi',
          'goal': 'Mendapatkan izin uji coba di fakultas percontohan'
        },
        difficulty: 'Hard',
        category: 'Institusi',
        suggestedDuration: 180,
      ),
      ChallengeItem(
        id: 'as_02',
        type: 'audience_scenario',
        prompt:
            'Kamu mempresentasikan ide produk teknologi barumu di hadapan Investor Modal Ventura (VC). Fokuskan pada daya tarik pasar dan monetisasi.',
        audienceProfile: {
          'type': 'Investor Modal Ventura (VC)',
          'focus': 'Ukuran pasar (TAM), keunggulan kompetitif (moat), potensi profitabilitas',
          'knowledge_level': 'Sangat mahir bisnis dan teknologi',
          'convincer': 'Traction awal, unit economics yang sehat, dan scalable business model',
          'goal': 'Mendapatkan pendanaan awal (seed funding)'
        },
        difficulty: 'Hard',
        category: 'Bisnis & Investasi',
        suggestedDuration: 180,
      ),
      ChallengeItem(
        id: 'as_03',
        type: 'audience_scenario',
        prompt:
            'Kamu mempresentasikan gagasanmu kepada Dosen Penguji Seminar. Tekankan validitas masalah, metodologi, dan dasar argumentasi yang logis.',
        audienceProfile: {
          'type': 'Dosen Penguji Seminar',
          'focus': 'Ketepatan teori, kebaruan ide, argumentasi ilmiah yang runtut',
          'knowledge_level': 'Ahli dalam metodologi dan substansi',
          'convincer': 'Dasar fakta riset, kejelasan batasan masalah, dan konsistensi logika',
          'goal': 'Mendapatkan persetujuan proposal penelitian'
        },
        difficulty: 'Medium',
        category: 'Akademik',
        suggestedDuration: 180,
      ),
      ChallengeItem(
        id: 'as_04',
        type: 'audience_scenario',
        prompt:
            'Kamu mengajak teman-teman mahasiswa baru untuk bergabung ke program mentoring organisasi kampus. Gunakan bahasa santai, akrab, dan relevan.',
        audienceProfile: {
          'type': 'Mahasiswa Baru (Gen Z)',
          'focus': 'Teman baru, tips adaptasi kuliah, seru tanpa tekanan berlebih',
          'knowledge_level': 'Pemula di dunia kampus',
          'convincer': 'Cerita nyata pengalaman kakak tingkat yang terbantu',
          'goal': 'Mendaftarkan diri ke sesi bimbingan pertama'
        },
        difficulty: 'Easy',
        category: 'Organisasi Kampus',
        suggestedDuration: 120,
      ),
      ChallengeItem(
        id: 'as_05',
        type: 'audience_scenario',
        prompt:
            'Kamu memperkenalkan produk botol minum ramah lingkungan pintar kepada calon pembeli awam di bazar kampus. Jelaskan manfaat kesehatan dan kemudahan harian.',
        audienceProfile: {
          'type': 'Calon Konsumen Awam',
          'focus': 'Kenyamanan harian, harga terjangkau, desain stylish, manfaat kesehatan',
          'knowledge_level': 'Awam terhadap fitur elektronik rumit',
          'convincer': 'Demonstrasi kepraktisan, garansi produk, dan promo terbatas',
          'goal': 'Melakukan pemesanan langsung saat presentasi'
        },
        difficulty: 'Easy',
        category: 'Direct Sales',
        suggestedDuration: 120,
      ),
    ];

    for (var item in seedItems) {
      batch.insert('challenge_library', item.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
