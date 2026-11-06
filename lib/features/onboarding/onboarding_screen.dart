import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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
      'title': 'Latih Pitching Spontan',
      'desc': 'Hadapi tantangan unik: menyisipkan kata wajib secara alami, tema acak mendadak, atau skenario audiens spesifik.',
    },
    {
      'icon': Icons.graphic_eq_rounded,
      'title': 'Metrik Berbicara Terukur',
      'desc': 'Evaluasi tempo bicara (Words Per Minute), deteksi kata pengisi (filler words) seperti "eee" dan "anu", serta durasi bicara.',
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'AI Coach Berbasis Bukti',
      'desc': 'Dapatkan feedback semantik atas kejelasan susunan kalimat, kelogisan alur, relevansi ide, dan kecocokan pesan bagi audiens.',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header Skip Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'PITCHY',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          2,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Lewati'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Page Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 54,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        if (index == 2) ...[
                          const SizedBox(height: 28),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nama Panggilan Kamu:',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Budi / Siti',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Page Indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action button
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
                child: Text(_currentPage == 2 ? 'Mulai Sekarang' : 'Lanjut'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
