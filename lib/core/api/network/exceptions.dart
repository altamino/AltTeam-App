


class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException[$code](${statusCode ?? '—'}): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({required super.code, required super.message})
      : super(statusCode: 401);
}

class RefreshFailedException extends ApiException {
  const RefreshFailedException({required super.code, required super.message});
}