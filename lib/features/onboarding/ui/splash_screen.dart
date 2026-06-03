import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_logo.dart';

/// Navy-branded splash. Waits for auth to resolve, then routes to onboarding
/// (first run), sign-in, or home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  Future<void> _decideNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding =
        prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;

    // Minimum splash time for brand moment + let auth state settle.
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    if (!seenOnboarding) {
      context.go('/onboarding');
      return;
    }
    final loggedIn = ref.read(authStateProvider).value != null;
    context.go(loggedIn ? '/home' : '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    // Paint the system bars navy too so the brand color runs edge-to-edge
    // (incl. the bottom navigation bar) while the splash is shown. This is
    // nearest-wins and only overrides the global overlay for this screen.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 96, onPrimary: true)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppConstants.appName,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: Colors.white),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppConstants.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inversePrimary,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
