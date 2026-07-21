// Exceptions are thrown by data sources (remote/local) and are caught by
// repository implementations, which convert them into Failures.

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred.']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection.']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error occurred.']);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Item not found.']);
}
