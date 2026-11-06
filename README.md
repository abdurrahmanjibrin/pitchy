# PITCHY — AI Presentation Coach

Aplikasi mobile berbasis Artificial Intelligence untuk pendamping latihan presentasi dan pitching mandiri bagi mahasiswa. PITCHY membantu pengguna melatih spontanitas, mengukur performa bicara (WPM & kata pengisi), serta mengevaluasi kualitas kalimat dan kesesuaian pesan melalui AI Presentation Coach berbasis bukti (*evidence-based*).

---

## 🎯 Fitur Utama

### 1. Tiga Mode Tantangan Pitching (Challenge Mode)
- **Random Words Pitch**: Mengacak 3–5 kata wajib yang harus disisipkan secara alami dan bermakna ke dalam pitch.
- **Random Theme Pitch**: Memberikan tema atau masalah spontan dengan konteks dan tujuan yang jelas.
- **Audience Scenario Pitch**: Menentukan persona audiens (Investor Modal Ventura, Dosen Penguji, Mahasiswa Baru, Pimpinan Kampus, Calon Konsumen) untuk melatih adaptasi pesan.

### 2. AI Camera & Body Language Coach (On-Device Vision)
- **Pelacakan Pose On-Device**: Memanfaatkan Google ML Kit / MediaPipe Pose Detection yang berjalan 100% lokal di perangkat (privasi penuh tanpa mengunggah frame video ke internet).
- **HUD Panduan "Strike Zone" Real-Time**: Menampilkan kotak panduan interaktif area dada-hingga-pinggang dengan indikator deteksi pergelangan tangan langsung di atas pratinjau kamera.
- **Analisis 4 Parameter Berdasarkan Riset Komunikasi**:
  1. **Postur Ekspansif**: Menilai dada terbuka dan bahu tegap (menurunkan kortisol dan memancarkan wibawa) vs membungkuk (*slouching*) atau menyilangkan tangan (*crossed arms*).
  2. **Gestur Tangan di "Strike Zone"**: Mengukur persentase waktu tangan berada di area persuasif (antara dada dan pinggang) serta mendeteksi tangan tersembunyi atau gerakan terlalu cepat (*jittery/nervous*).
  3. **Kestabilan Kuda-kuda (Purposeful Anchoring vs Pacing)**: Melacak titik pusat gravitasi tubuh (*Center of Gravity*) untuk membedakan antara berdiri mengakar dengan tegas (*spatial anchoring*) atau mondar-mandir cemas (*nervous pacing*).
  4. **Kontak Mata & Orientasi Kepala**: Melacak sudut kepala dan posisi tatapan (*head pose estimation*) untuk mendeteksi apakah pembicara sering menunduk membaca catatan.
- **Arsitektur Penilaian 3 Pilar (Three Pillars Scoring)**:
  - **Delivery Score** (Vokal, WPM, Kata Pengisi)
  - **Body Language Score** (Postur, Strike Zone, Kuda-kuda, Tatapan)
  - **Content Score** (Kejelasan Semantik AI, Struktur Kalimat, Kesesuaian Audiens)

### 3. Perekaman Audio & Pratinjau Langsung
- Visualisasi gelombang audio langsung (*live dynamic waveform*) berbasis amplitudo mikrofon.
- Timer waktu nyata (*real-time*) dengan indikator kepatuhan terhadap target durasi.
- Panel brief tantangan mengambang (*collapsible drawer*) agar pengguna dapat melihat kata wajib saat berbicara.
- Pemutar audio (*playback player*) untuk meninjau rekaman sebelum analisis.

### 3. Pipeline Pemrosesan Terintegrasi
1. **Validasi Audio**: Memastikan durasi dan integritas berkas suara.
2. **Speech-to-Text (STT)**: Transkripsi otomatis Bahasa Indonesia secara *verbatim* menggunakan Gemini 2.5 Flash (atau simulasi *offline mock*).
3. **Analisis Metrik Penyampaian (Delivery Metrics)**:
   - **Words Per Minute (WPM)**: Menilai kelancaran dan tempo berbicara.
   - **Filler Words Detection**: Mendeteksi vokal pengisi (*eee*, *emm*, *hmm*), pengisi leksikal (*anu*, *apa namanya*), dan kata wacana (*jadi*, *nah*, *sebenarnya*).
   - **Delivery Score (0–100)**: Dihitung secara matematis transparan dari tempo dan frekuensi kata pengisi.
4. **AI Content Evaluator**:
   - **Kejelasan Susunan Kalimat (Sentence Clarity)**: Menilai tata bahasa dan memberikan kutipan bukti dari ucapan.
   - **Kelogisan Alur (Coherence & Flow)**: Mengevaluasi transisi dari *hook*, masalah, solusi, hingga *call to action*.
   - **Relevansi Tantangan**: Menilai ketepatan isi terhadap topik dan memeriksa integrasi kata wajib secara kontekstual.
   - **Penyesuaian Audiens (Audience Fit)**: Menilai apakah nada bicara dan contoh cocok dengan profil audiens.
   - **Rekomendasi & Revisi Kalimat**: Menyediakan poin kekuatan, area perbaikan, dan contoh kalimat perbaikan yang lebih persuasif.
5. **Penyimpanan SQLite**: Seluruh sesi tersimpan secara lokal dan aman di perangkat.

### 4. Dasbor, Riwayat, & Grafik Perkembangan (Progress)
- **Dasbor**: Statistik dinamis dari SQLite (total sesi, rata-rata skor, total jam latihan) dan pratinjau sesi terakhir.
- **Riwayat Latihan**: Filter berdasarkan jenis tantangan, buka laporan lengkap, pemutar suara rekaman, dan fitur hapus (*cascade delete* database + berkas audio).
- **Grafik Perkembangan (fl_chart)**: Tren peningkatan skor, grafik kestabilan WPM, dan grafik penurunan persentase kata pengisi dari waktu ke waktu.
- **Profil & Pengaturan**: Manajemen nama, konfigurasi API Key Gemini, uji koneksi API, tombol mode *offline*, dan penghapusan data privat.

---

## 🛠️ Arsitektur & Teknologi

| Lapisan | Teknologi | Deskripsi |
|---|---|---|
| **Framework** | Flutter 3.47.2 / Dart 3.13.2 | Lintas platform Android |
| **State Management** | Flutter Riverpod (v3 Notifiers) | Arsitektur reaktif dan modular |
| **Local Database** | SQLite (`sqflite`) | Penyimpanan relasional lokal untuk sesi, brief, evaluasi, dan statistik |
| **Audio Recording** | `record` (AAC LC 44.1kHz) | Perekaman privat aplikasi dengan stream amplitudo |
| **Audio Playback** | `audioplayers` | Pemutar berkas suara latihan terintegrasi |
| **Visual Charts** | `fl_chart` | Grafik tren skor, WPM, dan kata pengisi |
| **Speech-to-Text & AI** | Google Gemini API (Gemini 2.5 Flash) | Transkripsi suara Indonesia & evaluasi semantik berbasis bukti |
| **Preferences** | `shared_preferences` | Pengaturan pengguna lokal |

---

## 📂 Struktur Proyek

```
lib/
├── core/
│   ├── constants/       # AppConstants, daftar filler words, WPM thresholds
│   ├── theme/           # AppTheme, Dark modern theme (#11111B, #7C3AED, #242438)
│   ├── utils/           # Formatters (durasi, tanggal, skor, pace)
│   └── providers.dart   # Riverpod state management & service providers
├── data/
│   ├── datasources/     # LocalDatabase (SQLite schema, migrations, challenge seeding)
│   ├── models/          # PracticeSession, ChallengeItem, ChallengeEvaluation, FillerStat
│   └── repositories/    # PracticeRepository, UserRepository
├── services/
│   ├── ai/              # GeminiContentEvaluator & RuleBasedContentEvaluator fallback
│   ├── analysis/        # AudioMetricAnalyzer (WPM, filler detection, scoring)
│   ├── challenge/       # ChallengeService (randomization, last-5 avoidance, reroll)
│   ├── playback/        # AudioPlaybackService (play/pause/seek)
│   ├── recording/       # AudioRecordingService (record/pause/amplitude)
│   └── transcription/   # GeminiSttService & OfflineMockSttService
├── features/
│   ├── dashboard/       # DashboardScreen, MainNavigationScreen
│   ├── history/         # PracticeHistoryScreen (filter, search, delete)
│   ├── onboarding/      # OnboardingScreen (3-step carousel, nickname)
│   ├── practice/        # PracticeSetupScreen, ChallengeBriefScreen, PreparationScreen
│   ├── processing/      # ProcessingScreen (5-step pipeline)
│   ├── profile/         # ProfileScreen (API key management, test connection, privacy)
│   ├── progress/        # ProgressScreen (fl_chart trend analytics)
│   ├── recording/       # RecordingStudioScreen, PostRecordingPreviewScreen
│   └── result/          # AnalysisResultScreen (Delivery tab, AI tab, Words tab, Transcript tab)
└── shared/
    └── widgets/         # ScoreBadge, AudioWaveformWidget, ChallengeCard, StatCard, EmptyStateView
```

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (v3.24 atau lebih baru)
- Android SDK & Java 17/21
- Perangkat Android fisik atau Android Emulator

### 2. Menginstal Dependensi
```bash
flutter pub get
```

### 3. Menjalankan Unit Tests
```bash
flutter test
```

### 4. Menjalankan Aplikasi di Emulator / Perangkat
```bash
# Menggunakan API key default dari environment:
flutter run

# Atau menentukan API Key Gemini secara langsung saat build:
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

> **Catatan:** Pengguna juga dapat memasukkan atau mengganti API Key Gemini langsung melalui menu **Profil & Pengaturan -> Konfigurasi AI Coach** di dalam aplikasi, lengkap dengan tombol **Uji Koneksi**.
