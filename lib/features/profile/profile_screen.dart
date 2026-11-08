import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  bool _useOfflineMock = false;
  bool _isTestingApiKey = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final userRepo = ref.read(userRepositoryProvider);
    _nameController = TextEditingController(text: userRepo.getUserName());
    _apiKeyController = TextEditingController(text: userRepo.getApiKey() ?? '');
    _useOfflineMock = userRepo.useLocalSttFallback();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final userRepo = ref.read(userRepositoryProvider);
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await userRepo.saveUserName(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama panggilan berhasil diperbarui!'),
            backgroundColor: AppColors.greenDark,
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _saveApiKey() async {
    final userRepo = ref.read(userRepositoryProvider);
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await userRepo.saveApiKey(key);
    } else {
      await userRepo.clearApiKey();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi API Key tersimpan.'),
          backgroundColor: AppColors.greenDark,
        ),
      );
    }
  }

  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _testResult = 'API Key kosong.');
      return;
    }

    setState(() {
      _isTestingApiKey = true;
      _testResult = null;
    });

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        setState(() {
          _testResult = 'Koneksi ke Gemini API Berhasil! Model siap digunakan.';
        });
      } else {
        setState(() {
          _testResult = 'Gagal (Status ${resp.statusCode}): ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = 'Koneksi gagal: $e';
      });
    } finally {
      setState(() {
        _isTestingApiKey = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        title: const Text(
          'Hapus Seluruh Data Latihan?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Tindakan ini akan menghapus seluruh rekaman suara, riwayat latihan, dan laporan evaluasi dari penyimpanan lokal perangkat.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DuoButton(
            text: 'HAPUS SEMUA DATA',
            variant: DuoButtonVariant.red,
            height: 42,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(practiceRepositoryProvider);
      await repo.clearAllData();
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(practiceHistoryProvider);
      ref.invalidate(progressDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seluruh data latihan lokal berhasil dibersihkan.'),
            backgroundColor: AppColors.greenDark,
          ),
        );
      }
    }
  }

  Future<void> _resetOnboarding() async {
    final userRepo = ref.read(userRepositoryProvider);
    await userRepo.setOnboardingCompleted(false);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // User Profile Hero DuoCard
            DuoCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const DuoMascotAvatar(size: 58),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'Pitcher Hebat',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pelajar Pitching Aktif • Level 1',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.blue,
                            ),
                            hintText: 'Nama panggilan kamu',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DuoButton(
                        text: 'SIMPAN',
                        variant: DuoButtonVariant.green,
                        height: 48,
                        onPressed: _saveName,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI & Speech-to-Text Settings DuoCard
            DuoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.yellow,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Konfigurasi AI Coach & STT',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'PITCHY menggunakan Gemini 3.8 Flash untuk transkripsi Bahasa Indonesia yang presisi dan evaluasi semantik.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.key_rounded,
                        color: AppColors.blue,
                      ),
                      hintText: 'Gemini API Key (Opsional / Override)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DuoButton(
                          text: _isTestingApiKey ? 'MENGUJI...' : 'UJI KONEKSI',
                          variant: DuoButtonVariant.white,
                          height: 44,
                          onPressed: _isTestingApiKey ? null : _testApiKey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DuoButton(
                          text: 'SIMPAN KEY',
                          variant: DuoButtonVariant.blue,
                          height: 44,
                          onPressed: _saveApiKey,
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testResult!.contains('Berhasil')
                            ? AppColors.greenDark
                            : AppColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 6),

                  // Offline Mock Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mode Simulasi Offline (Mock STT)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Gunakan generator transkrip lokal untuk demo saat tidak ada internet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _useOfflineMock,
                    activeThumbColor: AppColors.green,
                    activeTrackColor: AppColors.green.withValues(alpha: 0.4),
                    onChanged: (val) async {
                      setState(() => _useOfflineMock = val);
                      final userRepo = ref.read(userRepositoryProvider);
                      await userRepo.setUseLocalSttFallback(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy & Architecture DuoCard
            DuoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.privacy_tip_rounded,
                        color: AppColors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Privasi & Penyimpanan Data',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Rekaman suara tersimpan secara privat pada direktori aplikasi di perangkatmu.\n'
                    '• Metrik dan riwayat tersimpan lokal di SQLite dan tidak dibagikan ke pengguna lain.\n'
                    '• Audio hanya dikirim ke engine AI saat proses analisis transkripsi dan dapat dihapus kapan saja.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danger Zone DuoCard
            DuoCard(
              borderColor: AppColors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zona Pengelolaan Data',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DuoButton(
                    text: 'HAPUS SEMUA DATA LATIHAN',
                    icon: Icons.delete_forever_rounded,
                    variant: DuoButtonVariant.red,
                    height: 46,
                    onPressed: _clearAllData,
                  ),
                  const SizedBox(height: 10),
                  DuoButton(
                    text: 'BUKA ULANG PENGENALAN',
                    icon: Icons.restart_alt_rounded,
                    variant: DuoButtonVariant.white,
                    height: 44,
                    onPressed: _resetOnboarding,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
