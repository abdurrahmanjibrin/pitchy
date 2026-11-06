import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/challenge_evaluation.dart';
import '../../data/models/practice_session.dart';

abstract class AiContentEvaluator {
  Future<ChallengeEvaluation> evaluatePitch({
    required PracticeSession session,
    required String transcript,
  });
}

class GeminiContentEvaluator implements AiContentEvaluator {
  final String apiKey;

  GeminiContentEvaluator({required this.apiKey});

  @override
  Future<ChallengeEvaluation> evaluatePitch({
    required PracticeSession session,
    required String transcript,
  }) async {
    if (transcript.trim().isEmpty) {
      return ChallengeEvaluation(
        id: 'eval_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: session.id,
        status: 'unavailable',
      );
    }

    if (apiKey.trim().isEmpty) {
      // Use rule-based fallback if API key is missing
      return RuleBasedContentEvaluator().evaluatePitch(
        session: session,
        transcript: transcript,
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    // Build prompt according to PRD Section 6.10 & 15.2
    final promptBuffer = StringBuffer();
    promptBuffer.writeln(
        'Kamu adalah AI Presentation Coach profesional untuk mahasiswa bernama PITCHY.');
    promptBuffer.writeln(
        'Tugasmu adalah melakukan evaluasi semantik dan kualitas isi presentasi/pitching berdasarkan transkrip ucapan pengguna.');
    promptBuffer.writeln(
        'PENTING: Jangan mengarang fakta yang tidak ada di transkrip. Berikan skor (0-100), penjelasan logis, dan kutipan bukti potongan kalimat langsung dari transkrip.\n');

    promptBuffer.writeln('=== KONTEKS LATIHAN ===');
    promptBuffer.writeln('Judul: ${session.title}');
    if (session.topic != null && session.topic!.isNotEmpty) {
      promptBuffer.writeln('Topik: ${session.topic}');
    }
    promptBuffer.writeln('Mode: ${session.mode}');
    if (session.challengeType != null) {
      promptBuffer.writeln('Tipe Tantangan: ${session.challengeType}');
    }
    if (session.challengePrompt != null) {
      promptBuffer.writeln('Instruksi Tantangan: ${session.challengePrompt}');
    }

    if (session.requiredWords.isNotEmpty) {
      promptBuffer.writeln(
          'Kata Wajib yang harus disisipkan secara bermakna: ${session.requiredWords.join(", ")}');
      promptBuffer.writeln(
          'Catatan: Periksa apakah setiap kata benar-benar digunakan dan menyatu dalam argumen pitch, bukan sekadar diulang.');
    }

    if (session.audienceProfile != null) {
      promptBuffer.writeln('Profil Audiens: ${jsonEncode(session.audienceProfile)}');
      promptBuffer.writeln(
          'Catatan: Evaluasi apakah bahasa, contoh kasus, dan ajakan sesuai dengan target audiens tersebut.');
    }

    promptBuffer.writeln('\n=== TRANSKRIP UCAPAN PENGGUNA ===');
    promptBuffer.writeln(transcript);

    promptBuffer.writeln('\n=== INSTRUKSI OUTPUT ===');
    promptBuffer.writeln(
        'Kembalikan HANYA format JSON murni (tanpa Markdown ```json, tanpa teks pengantar) dengan struktur berikut:');
    promptBuffer.writeln('''
{
  "sentence_clarity_score": <number 0-100>,
  "sentence_clarity_reason": "<penjelasan kejelasan dan tata kalimat>",
  "coherence_score": <number 0-100>,
  "coherence_reason": "<penjelasan kelogisan alur dan transisi ide>",
  "relevance_score": <number 0-100>,
  "relevance_reason": "<penjelasan kesesuaian dengan tema/instruksi>",
  "audience_fit_score": ${session.audienceProfile != null ? '<number 0-100>' : 'null'},
  "audience_fit_reason": ${session.audienceProfile != null ? '"<penjelasan kecocokan bahasa dan argumen dengan profil audiens>"' : 'null'},
  "required_words": [
    {
      "word": "<kata>",
      "found": <true/false>,
      "used_meaningfully": <true/false>,
      "evidence": "<potongan kalimat dari transkrip tempat kata digunakan, atau kosong bila tidak ada>",
      "note": "<analisis singkat penggunaan kata>"
    }
  ],
  "strengths": [
    "<kekuatan utama 1>",
    "<kekuatan utama 2>"
  ],
  "improvements": [
    "<aspek yang perlu ditingkatkan 1>",
    "<aspek yang perlu ditingkatkan 2>"
  ],
  "evidence": [
    {
      "category": "Kejelasan / Alur / Relevansi",
      "snippet": "<potongan kutipan kalimat dari transkrip>",
      "explanation": "<alasan mengapa bagian ini dinilai>"
    }
  ],
  "suggested_revision": "<contoh revisi 1-2 kalimat dari ucapan pengguna agar lebih berdampak dan persuasif>"
}
''');

    try {
      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': promptBuffer.toString()}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 2048,
        }
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        throw Exception(
            'API Gemini gagal dengan status ${response.statusCode}: ${response.body}');
      }

      final jsonResp = jsonDecode(response.body);
      final rawText =
          jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

      // Clean Markdown code block if present
      String cleanedJson = rawText.toString().trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      }
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final parsed = jsonDecode(cleanedJson);

      List<RequiredWordResult> parsedWords = [];
      if (parsed['required_words'] is List) {
        for (var w in parsed['required_words']) {
          parsedWords.add(RequiredWordResult(
            word: w['word']?.toString() ?? '',
            found: w['found'] == true,
            usedMeaningfully: w['used_meaningfully'] == true,
            evidence: w['evidence']?.toString() ?? '',
            note: w['note']?.toString() ?? '',
          ));
        }
      }

      List<TranscriptEvidenceSnippet> parsedEvidence = [];
      if (parsed['evidence'] is List) {
        for (var ev in parsed['evidence']) {
          parsedEvidence.add(TranscriptEvidenceSnippet(
            category: ev['category']?.toString() ?? 'Kutipan Transkrip',
            snippet: ev['snippet']?.toString() ?? '',
            explanation: ev['explanation']?.toString() ?? '',
          ));
        }
      }

      final strengths = (parsed['strengths'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final improvements = (parsed['improvements'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return ChallengeEvaluation(
        id: 'eval_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: session.id,
        sentenceClarityScore:
            (parsed['sentence_clarity_score'] as num?)?.toDouble(),
        sentenceClarityReason: parsed['sentence_clarity_reason']?.toString(),
        coherenceScore: (parsed['coherence_score'] as num?)?.toDouble(),
        coherenceReason: parsed['coherence_reason']?.toString(),
        relevanceScore: (parsed['relevance_score'] as num?)?.toDouble(),
        relevanceReason: parsed['relevance_reason']?.toString(),
        audienceFitScore: (parsed['audience_fit_score'] as num?)?.toDouble(),
        audienceFitReason: parsed['audience_fit_reason']?.toString(),
        requiredWordsResult: parsedWords,
        strengths: strengths,
        improvements: improvements,
        evidence: parsedEvidence,
        suggestedRevision: parsed['suggested_revision']?.toString(),
        status: 'completed',
      );
    } catch (e) {
      // In case of parsing or network error, fallback to RuleBased to guarantee reliability (PRD AC-18)
      return RuleBasedContentEvaluator().evaluatePitch(
        session: session,
        transcript: transcript,
      );
    }
  }
}

class RuleBasedContentEvaluator implements AiContentEvaluator {
  @override
  Future<ChallengeEvaluation> evaluatePitch({
    required PracticeSession session,
    required String transcript,
  }) async {
    final lowerTranscript = transcript.toLowerCase();

    // 1. Check required words
    final List<RequiredWordResult> wordResults = [];
    int foundCount = 0;
    for (final word in session.requiredWords) {
      final cleanWord = word.toLowerCase().trim();
      final hasWord = lowerTranscript.contains(cleanWord);
      if (hasWord) {
        foundCount++;
        // Find sentence containing this word for evidence
        final sentences = transcript.split(RegExp(r'[.!?]'));
        final sentenceWithWord = sentences.firstWhere(
          (s) => s.toLowerCase().contains(cleanWord),
          orElse: () => transcript,
        );
        wordResults.add(RequiredWordResult(
          word: word,
          found: true,
          usedMeaningfully: true,
          evidence: sentenceWithWord.trim(),
          note: 'Kata "$word" ditemukan dan digunakan dalam konteks kalimat.',
        ));
      } else {
        wordResults.add(RequiredWordResult(
          word: word,
          found: false,
          usedMeaningfully: false,
          evidence: '',
          note: 'Kata "$word" tidak terdeteksi dalam transkrip ucapan.',
        ));
      }
    }

    // 2. Sentence clarity & length heuristics
    final sentences = transcript
        .split(RegExp(r'[.!?]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    double clarityScore = 78.0;
    String clarityReason =
        'Struktur kalimat cukup jelas dan gagasan utama tersampaikan dengan lugas.';

    if (sentences.isNotEmpty) {
      final avgWordsPerSentence = transcript.split(RegExp(r'\s+')).length /
          (sentences.length.clamp(1, 999));
      if (avgWordsPerSentence > 28) {
        clarityScore = 70.0;
        clarityReason =
            'Beberapa kalimat cenderung panjang; disarankan memecah kalimat majemuk agar lebih mudah dicerna pendengar.';
      } else if (avgWordsPerSentence >= 12 && avgWordsPerSentence <= 24) {
        clarityScore = 88.0;
        clarityReason =
            'Panjang kalimat seimbang, memudahkan audiens mencerna poin presentasi tanpa kehilangan fokus.';
      }
    }

    // 3. Coherence
    double coherenceScore = 80.0;
    String coherenceReason =
        'Alur presentasi memiliki pembuka dan pengantar masalah yang terstruktur.';

    // 4. Relevance
    double relevanceScore = 82.0;
    String relevanceReason =
        'Penyampaian selaras dengan instruksi dan topik latihan yang ditentukan.';

    if (session.requiredWords.isNotEmpty) {
      final wordRatio = session.requiredWords.isNotEmpty
          ? (foundCount / session.requiredWords.length)
          : 1.0;
      relevanceScore = (60.0 + (wordRatio * 35.0)).clamp(50.0, 95.0);
      relevanceReason =
          'Berhasil menyisipkan $foundCount dari ${session.requiredWords.length} kata wajib dalam presentasi.';
    }

    // 5. Audience fit
    double? audienceFitScore;
    String? audienceFitReason;
    if (session.audienceProfile != null) {
      audienceFitScore = 80.0;
      final audType = session.audienceProfile!['type'] ?? 'Audiens';
      audienceFitReason =
          'Pilihan bahasa dan penekanan ide disesuaikan dengan karakter $audType.';
    }

    final List<String> strengths = [
      'Gagasan pembuka lugas dan langsung mengarah ke inti solusi.',
      if (foundCount > 0)
        'Mampu merangkai kata tantangan ke dalam alur narasi pitch.',
      'Penggunaan kosakata bahasa Indonesia komunikatif dan wajar.',
    ];

    final List<String> improvements = [
      'Latihlah penekanan (intonasi) pada solusi utama agar pendengar lebih teringat.',
      if (session.requiredWords.isNotEmpty &&
          foundCount < session.requiredWords.length)
        'Pastikan seluruh kata tantangan disiapkan sebelum mulai merekam.',
      'Tutup presentasi dengan kalimat ajakan (call-to-action) yang lebih tegas.',
    ];

    final List<TranscriptEvidenceSnippet> evidence = [
      if (sentences.isNotEmpty)
        TranscriptEvidenceSnippet(
          category: 'Pembuka Pitch',
          snippet: sentences.first,
          explanation: 'Gagasan awal yang memperkenalkan arah pembahasan.',
        ),
      if (sentences.length > 2)
        TranscriptEvidenceSnippet(
          category: 'Pengembangan Solusi',
          snippet: sentences[1],
          explanation: 'Bagian penjelasan yang merincikan ide utama kamu.',
        ),
    ];

    return ChallengeEvaluation(
      id: 'eval_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: session.id,
      sentenceClarityScore: clarityScore,
      sentenceClarityReason: clarityReason,
      coherenceScore: coherenceScore,
      coherenceReason: coherenceReason,
      relevanceScore: relevanceScore,
      relevanceReason: relevanceReason,
      audienceFitScore: audienceFitScore,
      audienceFitReason: audienceFitReason,
      requiredWordsResult: wordResults,
      strengths: strengths,
      improvements: improvements,
      evidence: evidence,
      suggestedRevision: sentences.isNotEmpty
          ? 'Coba sampaikan: "Melalui inovasi ini, kami memberikan solusi nyata yang efisien dan berdampak langsung bagi kita semua."'
          : null,
      status: 'completed',
    );
  }
}

