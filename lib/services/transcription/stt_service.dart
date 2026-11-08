import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

abstract class SttService {
  Future<String> transcribeAudio({
    required String audioFilePath,
    String language = 'id',
    String? challengePrompt,
    List<String> requiredWords = const [],
  });
}

class GeminiSttService implements SttService {
  final String apiKey;

  GeminiSttService({required this.apiKey});

  @override
  Future<String> transcribeAudio({
    required String audioFilePath,
    String language = 'id',
    String? challengePrompt,
    List<String> requiredWords = const [],
  }) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('File audio tidak ditemukan: $audioFilePath');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('File audio kosong atau tidak memiliki data suara.');
    }

    if (apiKey.trim().isEmpty) {
      throw Exception(
          'API Key Gemini belum dikonfigurasi. Silakan atur di Profil & Pengaturan.');
    }

    // Determine mime type
    String mimeType = 'audio/mp4';
    if (audioFilePath.endsWith('.m4a') || audioFilePath.endsWith('.aac')) {
      mimeType = 'audio/mp4';
    } else if (audioFilePath.endsWith('.wav')) {
      mimeType = 'audio/wav';
    } else if (audioFilePath.endsWith('.mp3')) {
      mimeType = 'audio/mp3';
    }

    final base64Audio = base64Encode(bytes);

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Transkripsikan rekaman audio berikut ke dalam teks Bahasa Indonesia secara verbatim dan akurat. '
                  'PENTING: Jangan menyensor atau menghilangkan kata pengisi (filler words) seperti "eee", "emm", "anu", "jadi", "kayak" jika memang diucapkan oleh pembicara. '
                  'Kembalikan HANYA teks transkripsi bersih tanpa teks pengantar, tanpa tanda kutip pembungkus, dan tanpa catatan tambahan.',
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Audio,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 2048,
      }
    });

    final modelCandidates = [
      'gemini-3.8-flash',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
    ];

    http.Response? lastResponse;
    String? lastErrorMessage;

    for (final model in modelCandidates) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(response.body);
          final candidates = jsonResp['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
        }

        lastResponse = response;
        try {
          final errJson = jsonDecode(response.body);
          final msg = errJson['error']?['message'] as String?;
          if (msg != null && msg.isNotEmpty) {
            lastErrorMessage = msg;
          }
        } catch (_) {}

        // If not a 404 (model not found), break so we don't spam other models on auth/quota error
        if (response.statusCode != 404) {
          break;
        }
      } catch (e) {
        lastErrorMessage = e.toString();
      }
    }

    final displayMsg = lastErrorMessage ??
        (lastResponse != null
            ? 'Status ${lastResponse.statusCode}'
            : 'Koneksi ke AI gagal');
    throw Exception('Gagal melakukan transkripsi: $displayMsg');
  }
}

class OfflineMockSttService implements SttService {
  @override
  Future<String> transcribeAudio({
    required String audioFilePath,
    String language = 'id',
    String? challengePrompt,
    List<String> requiredWords = const [],
  }) async {
    // Realistic simulation delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (requiredWords.isNotEmpty) {
      // Natural speech sample containing the required words and Indonesian fillers
      return 'Halo semuanya, selamat pagi. Pada kesempatan kali ini saya ingin membicarakan sebuah ide yang sangat menarik di lingkungan kampus kita. '
          'Eee seperti yang kita tahu, mahasiswa saat ini seringkali kekurangan waktu karena padatnya jadwal kuliah. '
          'Emm jadi kami mengembangkan solusi yang mengintegrasikan inovasi teknologi seperti robot asisten dan pemantau waktu. '
          'Nah waktu kita sedang belajar atau ngopi di kantin dan tiba-tiba hujan, kita tidak perlu repot mencari payung karena sistem kami menyediakannya secara otomatis. '
          'Eee dengan adanya sinergi antara kopi, efisiensi waktu, dan fasilitas kampus, kami yakin mahasiswa dapat belajar jauh lebih produktif dan nyaman.';
    }

    return 'Selamat pagi rekan-rekan semua. Hari ini saya ingin memperkenalkan sebuah inisiatif penting terkait pengelolaan lingkungan di universitas kita. '
        'Eee masalah utama yang kita hadapi adalah tingginya sisa konsumsi harian di kantin utama. '
        'Emm jadi kami merancang aplikasi berbasis komunitas mahasiswa di mana setiap porsi lebih dapat disalurkan secara terorganisir. '
        'Nah dengan sistem ini kita tidak hanya mengurangi sampah, tapi juga menghemat pengeluaran harian teman-teman mahasiswa.';
  }
}
