abstract class AppException implements Exception {
  final String message;
  final String? code;
  const AppException({required this.message, this.code});
  @override
  String toString() => 'AppException[$code]: $message';
}

class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException({required super.message, super.code, this.statusCode});

  factory NetworkException.noInternet() => const NetworkException(
      message: 'No internet connection. Check your network.', code: 'NO_INTERNET');
  factory NetworkException.timeout() => const NetworkException(
      message: 'Request timed out.', code: 'TIMEOUT');
  factory NetworkException.unauthorized() => const NetworkException(
      message: 'Invalid API key or unauthorised.', code: 'UNAUTHORIZED', statusCode: 401);
  factory NetworkException.rateLimited() => const NetworkException(
      message: 'Rate limit exceeded. Wait and try again.', code: 'RATE_LIMITED', statusCode: 429);
  factory NetworkException.quotaExceeded() => const NetworkException(
      message: 'API quota exceeded. Check your billing.', code: 'QUOTA_EXCEEDED', statusCode: 402);
  factory NetworkException.serverError(int code, String msg) =>
      NetworkException(message: msg, code: 'SERVER_$code', statusCode: code);
}

class AiProviderException extends AppException {
  final String providerId;
  const AiProviderException({
    required super.message, required this.providerId, super.code});

  factory AiProviderException.noApiKey(String provider) =>
      AiProviderException(
        message: 'No API key configured for $provider. Add it in Settings → API Keys.',
        providerId: provider, code: 'NO_API_KEY');

  factory AiProviderException.modelNotAvailable(String model, String provider) =>
      AiProviderException(
        message: 'Model $model is not available on $provider.',
        providerId: provider, code: 'MODEL_NOT_AVAILABLE');

  factory AiProviderException.contentFiltered(String provider) =>
      AiProviderException(
        message: 'Content was filtered by $provider safety system.',
        providerId: provider, code: 'CONTENT_FILTERED');
}

class StorageException extends AppException {
  const StorageException({required super.message, super.code});
  factory StorageException.readError(String key) =>
      StorageException(message: 'Failed to read: $key', code: 'READ_ERROR');
  factory StorageException.writeError(String key) =>
      StorageException(message: 'Failed to write: $key', code: 'WRITE_ERROR');
  factory StorageException.notFound(String key) =>
      StorageException(message: 'Not found: $key', code: 'NOT_FOUND');
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code});
  factory AuthException.biometricFailed() => const AuthException(
      message: 'Biometric authentication failed.', code: 'BIOMETRIC_FAILED');
  factory AuthException.biometricNotAvailable() => const AuthException(
      message: 'Biometric auth not available on this device.',
      code: 'BIOMETRIC_NOT_AVAILABLE');
}

class FileException extends AppException {
  const FileException({required super.message, super.code});
  factory FileException.notFound(String path) =>
      FileException(message: 'File not found: $path', code: 'FILE_NOT_FOUND');
  factory FileException.tooLarge(int maxMb) =>
      FileException(message: 'File exceeds ${maxMb}MB limit.', code: 'FILE_TOO_LARGE');
  factory FileException.unsupportedType(String type) =>
      FileException(message: 'File type .$type not supported.', code: 'UNSUPPORTED_TYPE');
}

class ImageGenException extends AppException {
  const ImageGenException({required super.message, super.code});
  factory ImageGenException.generationFailed(String detail) =>
      ImageGenException(message: 'Generation failed: $detail', code: 'GENERATION_FAILED');
  factory ImageGenException.promptFiltered() => const ImageGenException(
      message: 'Prompt was filtered by safety system.', code: 'PROMPT_FILTERED');
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
  factory ValidationException.emptyPrompt() => const ValidationException(
      message: 'Please enter a message or prompt.', code: 'EMPTY_PROMPT');
}
