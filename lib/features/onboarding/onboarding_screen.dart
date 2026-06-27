import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../app/app_shell.dart';

// ─── Données des slides ────────────────────────────────────────────────────
class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String description;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

const _slides = [
  _Slide(
    icon: Icons.school_rounded,
    color: primaryBlue,
    title: 'Bienvenue sur ECOLE+',
    subtitle: 'La plateforme scolaire intelligente',
    description: 'Centralisez la vie scolaire de votre établissement :\n'
        'élèves, enseignants, parents et administration\n'
        'dans une seule application.',
  ),
  _Slide(
    icon: Icons.insights_rounded,
    color: Color(0xFF7C3AED),
    title: 'Suivi en temps réel',
    subtitle: 'Notes, présences et performances',
    description: 'Consultez les notes, bulletins et absences\n'
        'instantanément. Recevez des alertes\n'
        'automatiques en cas d\'absence.',
  ),
  _Slide(
    icon: Icons.account_balance_wallet_rounded,
    color: successGreen,
    title: 'Paiements simplifiés',
    subtitle: 'Mobile Money & reçus PDF',
    description: 'Payez les frais scolaires via Orange Money,\n'
        'Wave ou MTN. Recevez vos reçus\n'
        'PDF instantanément.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingProvider.notifier).markDone();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bouton passer ──────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Passer',
                  style: TextStyle(color: textGrey, fontSize: 14),
                ),
              ),
            ),

            // ── PageView slides ────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _SlideWidget(slide: _slides[index]),
              ),
            ),

            // ── Indicateurs + bouton ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => _Dot(
                          active: i == _currentPage,
                          color: _slides[_currentPage].color),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton suivant / démarrer
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage].color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1
                            ? 'Suivant →'
                            : 'Commencer',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide ──────────────────────────────────────────────────────────────────
class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône dans cercle coloré
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: slide.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(slide.icon, size: 52, color: slide.color),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Titre
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Sous-titre coloré
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: slide.color,
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: textGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot indicateur ─────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool active;
  final Color color;
  const _Dot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
