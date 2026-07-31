/// Centralized application exception hierarchy.
///
/// All exceptions that cross layer boundaries should be one of these types.
/// UI code catches [AppException] subtypes and maps them to user-friendly
/// messages. Raw Firebase, HTTP, or platform exceptions must never reach the UI.
///
/// Usage example:
/// ```dart
/// try {
///   await songRepository.addSong(song);
/// } on NetworkException catch (e) {
///   // show "Check your internet connection"
/// } on AuthException catch (e) {
///   // redirect to login
/// } on AppException catch (e) {
///   // generic error message
/// }
/// ```
sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => 'AppException[$runtimeType]: $message';
}

/// Thrown when a network request fails due to connectivity issues.
class NetworkException extends AppException {
  const NetworkException([
    String message = 'No internet connection. Please check your network.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when the user is not authenticated or their session has expired.
class AuthException extends AppException {
  const AuthException([
    String message = 'Please sign in to continue.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when the user does not have permission to perform an operation.
class PermissionException extends AppException {
  const PermissionException([
    String message = 'You do not have permission to perform this action.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when the requested resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'The requested item was not found.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when server returns an unexpected error (5xx).
class ServerException extends AppException {
  final int? statusCode;

  const ServerException([
    String message = 'Something went wrong on our end. Please try again later.',
    Object? cause,
    this.statusCode,
  ]) : super(message, cause: cause);
}

/// Thrown when local data (Hive, SharedPreferences) cannot be read or written.
class CacheException extends AppException {
  const CacheException([
    String message = 'Failed to load cached data.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when user input or API response fails validation.
class ValidationException extends AppException {
  const ValidationException(String message, {Object? cause})
      : super(message, cause: cause);
}

/// Fallback for unexpected exceptions not covered by the above categories.
class UnknownException extends AppException {
  const UnknownException([
    String message = 'An unexpected error occurred.',
    Object? cause,
  ]) : super(message, cause: cause);
}
