import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../settings/providers/settings_provider.dart';

/// Wraps the app content and enforces biometric authentication when the
/// "Biometric Lock" setting is enabled. Locks on cold start and whenever
/// the app returns from the background.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final biometricEnabled = ref.read(settingsProvider).biometricEnabled;
    if (!biometricEnabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Re-lock whenever the app leaves the foreground.
      if (mounted) setState(() => _unlocked = false);
    } else if (state == AppLifecycleState.resumed && !_unlocked) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    final biometricEnabled = ref.read(settingsProvider).biometricEnabled;
    if (!biometricEnabled) {
      setState(() => _unlocked = true);
      return;
    }
    await _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final available = await ref.read(biometricServiceProvider).isAvailable();
      if (!available) {
        // No biometric hardware/enrollment on this device — don't lock the
        // user out of their own app; fail open with a visible notice instead.
        setState(() {
          _unlocked = true;
          _authenticating = false;
        });
        return;
      }
      final ok = await ref.read(biometricServiceProvider).authenticate(
            reason: 'Unlock OmniForge AI',
          );
      setState(() {
        _unlocked = ok;
        _authenticating = false;
      });
    } catch (e) {
      setState(() {
        _authenticating = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(settingsProvider).biometricEnabled;

    if (!biometricEnabled || _unlocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground1,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: Colors.white, size: 42),
              ),
              const SizedBox(height: 24),
              const Text(
                'OmniForge AI is locked',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to continue',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.darkError, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _authenticating ? null : _authenticate,
                icon: _authenticating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(_authenticating ? 'Verifying...' : 'Unlock'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
