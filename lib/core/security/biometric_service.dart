import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../error/exceptions.dart';

class BiometricService {
  static BiometricService? _instance;
  static BiometricService get instance =>
      _instance ??= BiometricService._();
  BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({
    String reason = 'Authenticate to access OmniForge AI',
  }) async {
    try {
      if (!await isAvailable()) throw AuthException.biometricNotAvailable();
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (!ok) throw AuthException.biometricFailed();
      return true;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        throw AuthException.biometricNotAvailable();
      }
      throw AuthException(
          message: e.message ?? 'Authentication failed', code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: e.toString(), code: 'UNKNOWN');
    }
  }
}
