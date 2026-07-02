import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../shared/widgets/neural_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    context.go(RouteNames.chatList);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeuralBackground(
        nodeCount: 40,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: AppColors.darkPrimary.withOpacity(0.3 + _ctrl.value * 0.2),
                      blurRadius: 30 + _ctrl.value * 20, spreadRadius: 2,
                    )],
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 44))),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                child: const Text('OmniForge AI',
                    style: TextStyle(
                      color: Colors.white, fontSize: 36,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'SpaceGrotesk', letterSpacing: -1.0,
                    )),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Text('Every AI. One place.',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 16),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 64),
              SizedBox(
                width: 48,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.darkBorderFaint,
                  valueColor: const AlwaysStoppedAnimation(AppColors.darkPrimary),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
