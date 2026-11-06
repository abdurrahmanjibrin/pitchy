import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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
    _apiKeyController =
        TextEditingController(text: userRepo.getApiKey() ?? '');
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
            content: Text('Nama panggilan berhasil diperbarui.'),
            backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.success,
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
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Seluruh Data Latihan?'),
        content: const Text(
          'Tindakan ini akan menghapus seluruh rekaman suara, riwayat latihan, dan laporan evaluasi dari penyimpanan lokal perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus Semua Data'),
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
            backgroundColor: AppColors.success,
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
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nama Panggilan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                color: AppColors.secondary),
                            hintText: 'Nama panggilan',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _saveName,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 50),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // AI & Speech-to-Text Settings
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Konfigurasi AI Coach & STT',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PITCHY menggunakan Gemini 2.5 Flash untuk transkripsi Bahasa Indonesia yang presisi dan evaluasi semantik.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.key_rounded,
                          color: AppColors.secondary),
                      hintText: 'Gemini API Key (Opsional / Override)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingApiKey ? null : _testApiKey,
                          icon: _isTestingApiKey
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.secondary),
                                )
                              : const Icon(Icons.wifi_tethering_rounded,
                                  size: 18),
                          label: const Text('Uji Koneksi'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveApiKey,
                          child: const Text('Simpan Key'),
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
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Divider(height: 24),

                  // Offline Mock Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mode Simulasi Offline (Mock STT)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Gunakan generator transkrip lokal untuk demo saat tidak ada internet.',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    value: _useOfflineMock,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      setState(() => _useOfflineMock = val);
                      final userRepo = ref.read(userRepositoryProvider);
                      await userRepo.setUseLocalSttFallback(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Privacy & Architecture Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.privacy_tip_outlined,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Privasi & Penyimpanan Data',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Danger Zone
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zona Pengelolaan Data',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _clearAllData,
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.error),
                    label: const Text(
                      'Hapus Semua Data Sesi Latihan',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _resetOnboarding,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Buka Ulang Pengenalan (Onboarding)'),
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
