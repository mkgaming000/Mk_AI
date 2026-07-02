import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});
  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  final int? statusCode;
  const NetworkFailure({required super.message, super.code, this.statusCode});
  @override
  List<Object?> get props => [...super.props, statusCode];
}

class AiProviderFailure extends Failure {
  final String providerId;
  const AiProviderFailure(
      {required super.message, required this.providerId, super.code});
  @override
  List<Object?> get props => [...super.props, providerId];
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
