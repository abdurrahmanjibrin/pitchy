import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../../shared/widgets/duo_progress_bar.dart';
import '../dashboard/main_navigation_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController(
    text: 'Mahasiswa',
  );
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.bolt_rounded,
      'color': AppColors.orange,
      'title': 'Latih Pitching Spontan',
      'desc':
          'Hadapi tantangan unik: menyisipkan kata wajib secara alami, tema acak mendadak, atau simulasi di depan audiens spesifik.',
      'speech': 'Halo! Aku Pitchy, pelatih pitching pribadimu. Siap mulai?',
    },
    {
      'icon': Icons.videocam_rounded,
      'color': AppColors.blue,
      'title': 'AI Kamera & Bahasa Tubuh',
      'desc':
          'Evaluasi gestur tangan di Strike Zone, postur ekspansif tegap, kestabilan kuda-kuda, dan tempo bicara terukur secara real-time.',
      'speech': 'Kamera AI kami memantau gestur tubuhmu agar memancarkan percaya diri!',
    },
    {
      'icon': Icons.stars_rounded,
      'color': AppColors.yellow,
      'title': 'AI Coach Berbasis Bukti',
      'desc':
          'Dapatkan evaluasi semantik atas kejelasan susunan kalimat, kelogisan alur, dan rekomendasi perbaikan berbasis AI.',
      'speech': 'Siapa nama panggilanmu? Biar latihannya makin akrab!',
    },
  ];

  Future<void> _finishOnboarding() async {
    final userRepo = ref.read(userRepositoryProvider);
    final name = _nameController.text.trim();
    await userRepo.saveUserName(name.isNotEmpty ? name : 'Mahasiswa');
    await userRepo.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Duolingo-style Progress Bar
              Row(
                children: [
                  const Text(
                    'PITCHY',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DuoProgressBar(
                      value: (_currentPage + 1) / _pages.length,
                      height: 14,
                      fillColor: AppColors.green,
                    ),
                  ),
                  if (_currentPage < 2) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _pageController.animateToPage(
                          2,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'LEWATI',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Page Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    final color = item['color'] as Color;

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Mascot avatar with speech bubble
                          DuoMascotAvatar(
                            speechText: item['speech'] as String,
                            size: 72,
                          ),
                          const SizedBox(height: 32),

                          // Large Hero Icon
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  offset: const Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 54,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 28),

                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            item['desc'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          if (index == 2) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F7),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE5E5E5),
                                  width: 2.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NAMA PANGGILAN KAMU',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Contoh: Budi / Siti',
                                      prefixIcon: Icon(
                                        Icons.person_rounded,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Action button (Duolingo 3D Tactile Button)
              DuoButton(
                text: _currentPage == 2 ? 'MULAI SEKARANG' : 'LANJUT',
                color: DuoButtonColor.green,
                onPressed: () {
                  if (_currentPage < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
