---
name: flutter-use-dio-package-to-flutter
description: Use Dio to build a production-ready NetworkService with interceptors, structured error handling, and type-safe request methods. Use when you need a robust HTTP layer for a REST API.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 01 Jul 2026 00:00:00 GMT
---
# Implementing Flutter Networking with Dio

## Contents
- [Configuration & Permissions](#configuration--permissions)
- [Project Structure](#project-structure)
- [NetworkException](#networkexception)
- [Interceptors](#interceptors)
- [NetworkService](#networkservice)
- [Workflow: Adding a New Endpoint](#workflow-adding-a-new-endpoint)
- [Examples](#examples)

---

## Configuration & Permissions

1. Add the `dio` package:
   ```bash
   flutter pub add dio
   ```
2. Android — add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```
3. macOS — add to both `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:
   ```xml
   <key>com.apple.security.network.client</key>
   <true/>
   ```

---

## Project Structure

Place all network code under `lib/data/services/network/`:

```
lib/data/services/network/
├── network_service.dart          # Dio wrapper — the only file the rest of the app imports
├── network_exception.dart        # Sealed failure types
└── interceptors/
    ├── auth_interceptor.dart     # Attaches Bearer token to every request
    ├── logging_interceptor.dart  # Logs requests/responses in debug mode
    └── error_interceptor.dart    # Converts DioException → NetworkException
```

Consumers (Repositories) import only `network_service.dart`. Interceptors are internal implementation details.

---

## NetworkException

Define a sealed class so call sites handle every failure case exhaustively via `switch`.

```dart
// lib/data/services/network/network_exception.dart

sealed class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;
}

/// 4xx — server understood the request but refused it.
class BadRequestException extends NetworkException {
  const BadRequestException([super.message = 'Bad request']);
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

class ForbiddenException extends NetworkException {
  const ForbiddenException([super.message = 'Forbidden']);
}

class NotFoundException extends NetworkException {
  const NotFoundException([super.message = 'Resource not found']);
}

/// 5xx — server-side error.
class ServerException extends NetworkException {
  const ServerException([super.message = 'Server error']);
}

/// No internet, DNS failure, refused connection.
class ConnectionException extends NetworkException {
  const ConnectionException([super.message = 'No internet connection']);
}

/// The request timed out before a response was received.
class TimeoutException extends NetworkException {
  const TimeoutException([super.message = 'Request timed out']);
}

/// The request was manually cancelled via a CancelToken.
class CancelledException extends NetworkException {
  const CancelledException([super.message = 'Request cancelled']);
}

/// Catch-all for unexpected errors.
class UnknownException extends NetworkException {
  const UnknownException([super.message = 'An unexpected error occurred']);
}
```

---

## Interceptors

### AuthInterceptor

Reads the token from an injected `TokenProvider` abstraction — no static singletons.

```dart
// lib/data/services/network/interceptors/auth_interceptor.dart

import 'package:dio/dio.dart';

abstract interface class TokenProvider {
  String? get accessToken;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenProvider tokenProvider})
      : _tokenProvider = tokenProvider;

  final TokenProvider _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

### LoggingInterceptor

Logs in debug mode only — compiles to a no-op in release builds.

```dart
// lib/data/services/network/interceptors/logging_interceptor.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('[DIO] --> ${options.method} ${options.uri}');
      if (options.data != null) print('[DIO]     body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('[DIO] <-- ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('[DIO] ERR ${err.type} ${err.requestOptions.uri}: ${err.message}');
    }
    handler.next(err);
  }
}
```

### ErrorInterceptor

Converts every `DioException` into a `NetworkException` before it surfaces to repositories.

```dart
// lib/data/services/network/interceptors/error_interceptor.dart

import 'package:dio/dio.dart';
import '../network_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: _map(err),
        type: err.type,
        response: err.response,
      ),
    );
  }

  NetworkException _map(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const ConnectionException();
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.badResponse:
        return _mapStatus(err.response?.statusCode);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownException(err.message ?? 'Unknown error');
    }
  }

  NetworkException _mapStatus(int? statusCode) => switch (statusCode) {
        400 => const BadRequestException(),
        401 => const UnauthorizedException(),
        403 => const ForbiddenException(),
        404 => const NotFoundException(),
        >= 500 => const ServerException(),
        _ => const UnknownException(),
      };
}
```

---

## NetworkService

The single class the rest of the app depends on. Injected via constructor — no global accessor inside the class.

```dart
// lib/data/services/network/network_service.dart

import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'network_exception.dart';

export 'network_exception.dart';

class NetworkService {
  NetworkService({
    required String baseUrl,
    TokenProvider? tokenProvider,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      if (tokenProvider != null) AuthInterceptor(tokenProvider: tokenProvider),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  late final Dio _dio;

  // ── Request methods ─────────────────────────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    required T Function(dynamic) fromResponse,
    CancelToken? cancelToken,
  }) =>
      _execute(
        () => _dio.get(path,
            queryParameters: queryParams, cancelToken: cancelToken),
        fromResponse,
      );

  Future<T> post<T>(
    String path, {
    Object? body,
    required T Function(dynamic) fromResponse,
    CancelToken? cancelToken,
  }) =>
      _execute(
        () => _dio.post(path, data: body, cancelToken: cancelToken),
        fromResponse,
      );

  Future<T> put<T>(
    String path, {
    Object? body,
    required T Function(dynamic) fromResponse,
    CancelToken? cancelToken,
  }) =>
      _execute(
        () => _dio.put(path, data: body, cancelToken: cancelToken),
        fromResponse,
      );

  Future<T> patch<T>(
    String path, {
    Object? body,
    required T Function(dynamic) fromResponse,
    CancelToken? cancelToken,
  }) =>
      _execute(
        () => _dio.patch(path, data: body, cancelToken: cancelToken),
        fromResponse,
      );

  Future<void> delete(
    String path, {
    CancelToken? cancelToken,
  }) =>
      _execute(
        () => _dio.delete(path, cancelToken: cancelToken),
        (_) {},
      );

  /// Creates a token that can be passed to any request and cancelled via [token.cancel()].
  CancelToken createCancelToken() => CancelToken();

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<T> _execute<T>(
    Future<Response> Function() call,
    T Function(dynamic) fromResponse,
  ) async {
    try {
      final response = await call();
      return fromResponse(response.data);
    } on DioException catch (e) {
      // ErrorInterceptor attaches the mapped NetworkException as e.error.
      throw (e.error is NetworkException)
          ? e.error as NetworkException
          : UnknownException(e.message ?? 'Unknown');
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
```

---

## Workflow: Adding a New Endpoint

### Task Progress
- [ ] **Step 1: Define the domain model** with a `fromJson` factory constructor in `lib/domain/models/`.
- [ ] **Step 2: Choose the method** (GET / POST / PUT / PATCH / DELETE) and confirm the path and payload shape.
- [ ] **Step 3: Implement the Repository method.** Inject `NetworkService`. Call the appropriate method and pass a `fromResponse` mapper. For list responses use `(data as List).map((e) => Model.fromJson(e)).toList()`.
- [ ] **Step 4: Handle errors at the call site.** Catch `NetworkException` and use an exhaustive `switch` on the sealed subtype to map each failure to a user-facing message or state.
- [ ] **Step 5: Register in DI.** Add `NetworkService` as a lazy singleton if not already done. Inject it into the new Repository.
- [ ] **Step 6: Verify.** Run the app → trigger the request → confirm the happy path → toggle airplane mode → confirm the error state displays.

---

## Examples

### Full end-to-end: Repository + Cubit consuming NetworkService

```dart
// 1. Domain model
class Post {
  const Post({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
      );
}

// 2. Repository
class PostRepository {
  PostRepository({required NetworkService networkService})
      : _network = networkService;

  final NetworkService _network;

  Future<List<Post>> getPosts() => _network.get(
        '/posts',
        fromResponse: (data) => (data as List)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<Post> createPost({required String title, required String body}) =>
      _network.post(
        '/posts',
        body: {'title': title, 'body': body, 'userId': 1},
        fromResponse: (data) => Post.fromJson(data as Map<String, dynamic>),
      );

  Future<void> deletePost(int id) => _network.delete('/posts/$id');
}

// 3. Cubit — exhaustive NetworkException handling
class PostCubit extends Cubit<PostState> {
  PostCubit({required PostRepository repository})
      : _repo = repository,
        super(const PostState.loading());

  final PostRepository _repo;

  Future<void> load() async {
    emit(const PostState.loading());
    try {
      final posts = await _repo.getPosts();
      emit(PostState.success(posts));
    } on NetworkException catch (e) {
      final message = switch (e) {
        UnauthorizedException() => 'Please log in again.',
        NotFoundException()     => 'Posts not found.',
        ConnectionException()   => 'Check your internet connection.',
        TimeoutException()      => 'Request timed out. Try again.',
        ServerException()       => 'Server error. Try later.',
        _                       => e.message,
      };
      emit(PostState.error(message));
    }
  }
}

// 4. DI registration (GetIt example)
void setupNetwork() {
  getIt.registerLazySingleton<NetworkService>(
    () => NetworkService(
      baseUrl: 'https://api.example.com',
      tokenProvider: getIt<TokenProvider>(), // omit if no auth needed
    ),
  );

  getIt.registerLazySingleton<PostRepository>(
    () => PostRepository(networkService: getIt<NetworkService>()),
  );
}
```

### Request cancellation (e.g. search-as-you-type)

```dart
class SearchRepository {
  SearchRepository({required NetworkService networkService})
      : _network = networkService;

  final NetworkService _network;
  CancelToken? _activeToken;

  Future<List<Post>> search(String query) {
    // Cancel the previous in-flight request before firing a new one.
    _activeToken?.cancel('New query started');
    _activeToken = _network.createCancelToken();

    return _network.get(
      '/posts',
      queryParams: {'q': query},
      fromResponse: (data) => (data as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      cancelToken: _activeToken,
    );
  }
}
```
