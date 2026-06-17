import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/token_storage.dart';
import 'package:http/http.dart' as package_http;

typedef Response = package_http.Response;
typedef ClientException = package_http.ClientException;

/// Sends an authenticated-aware GET request through the shared client.
Future<Response> get(Uri url, {Map<String, String>? headers}) {
  return _AuthHttpClient.instance.request('GET', url, headers: headers);
}

/// Sends a GET request and returns a byte response body.
Future<Response> getBytes(Uri url, {Map<String, String>? headers}) {
  return _AuthHttpClient.instance.request(
    'GET',
    url,
    headers: headers,
    responseBodyType: _ResponseBodyType.bytes,
  );
}

/// Sends an authenticated-aware POST request through the shared client.
Future<Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
  return _AuthHttpClient.instance.request(
    'POST',
    url,
    headers: headers,
    body: body,
  );
}

/// Sends an authenticated-aware PUT request through the shared client.
Future<Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
  return _AuthHttpClient.instance.request(
    'PUT',
    url,
    headers: headers,
    body: body,
  );
}

/// Sends an authenticated-aware DELETE request through the shared client.
Future<Response> delete(Uri url, {Map<String, String>? headers}) {
  return _AuthHttpClient.instance.request('DELETE', url, headers: headers);
}

/// Session facade for startup restore and logout cleanup.
class AuthHttpClient {
  AuthHttpClient._();

  /// Loads persisted tokens into RuntimeStore and refreshes the account token
  /// if it is missing or close to expiry.
  static Future<void> restoreSession() async {
    await TokenStorage.instance.loadIntoRuntimeStore();
    await _AuthHttpClient.instance.ensureAccountToken();
  }

  /// Clears persisted tokens and in-memory session state.
  static Future<void> clearSession() {
    return TokenStorage.instance.clearSession();
  }
}

/// Dio-backed implementation that exposes package:http compatible responses.
///
/// Existing services use the top-level functions in this file as a small
/// compatibility layer while token refresh, profile selection, and cookie
/// rebuilding are centralized here.
class _AuthHttpClient {
  _AuthHttpClient._()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          headers: const <String, dynamic>{'X-Client-Type': 'mobile'},
        ),
      );

  static final _AuthHttpClient instance = _AuthHttpClient._();
  static const Duration _refreshWindow = Duration(minutes: 2);

  final Dio _dio;
  Future<bool>? _refreshInFlight;

  /// Ensures the account token in RuntimeStore is usable before route decisions
  /// or account-only API calls.
  Future<void> ensureAccountToken() async {
    await _ensureTokens(includeProfileToken: false);
  }

  /// Sends a request, refreshing tokens first when the caller supplied an auth
  /// cookie or the profile-token marker header.
  Future<Response> request(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    _ResponseBodyType responseBodyType = _ResponseBodyType.plain,
  }) async {
    final Map<String, String> requestHeaders = <String, String>{
      ...?headers,
      'X-Client-Type': headers?['X-Client-Type'] ?? 'mobile',
    };
    final bool authRequested = _authRequested(requestHeaders);
    final bool includeProfileToken = _includeProfileTokenRequested(
      requestHeaders,
    );
    requestHeaders.remove(RequestHeaders.includeProfileTokenHeader);

    if (authRequested) {
      await _ensureTokens(includeProfileToken: includeProfileToken);
      _replaceCookieHeader(requestHeaders, includeProfileToken);
    }

    Response response = await _send(
      method,
      url,
      headers: requestHeaders,
      body: body,
      responseBodyType: responseBodyType,
    );

    if (authRequested && response.statusCode == 401) {
      final bool refreshed = await _refreshAccountToken();
      if (refreshed) {
        if (includeProfileToken) {
          await _selectStoredProfile();
        }
        _replaceCookieHeader(requestHeaders, includeProfileToken);
        response = await _send(
          method,
          url,
          headers: requestHeaders,
          body: body,
          responseBodyType: responseBodyType,
        );
      } else {
        await TokenStorage.instance.clearSession();
      }
    }

    return response;
  }

  Future<Response> _send(
    String method,
    Uri url, {
    required Map<String, String> headers,
    Object? body,
    required _ResponseBodyType responseBodyType,
  }) async {
    try {
      final dioResponse = await _dio.requestUri<dynamic>(
        url,
        data: body,
        options: Options(
          method: method,
          headers: headers,
          responseType: responseBodyType.dioResponseType,
        ),
      );
      final Map<String, String> responseHeaders = dioResponse.headers.map.map(
        (key, value) => MapEntry(key, value.join(',')),
      );

      if (responseBodyType == _ResponseBodyType.bytes) {
        return package_http.Response.bytes(
          _asBytes(dioResponse.data),
          dioResponse.statusCode ?? 0,
          headers: responseHeaders,
          request: package_http.Request(method, url),
        );
      }

      return package_http.Response(
        dioResponse.data?.toString() ?? '',
        dioResponse.statusCode ?? 0,
        headers: responseHeaders,
        request: package_http.Request(method, url),
      );
    } on DioException catch (e) {
      throw package_http.ClientException(
        e.message ?? 'HTTP request failed',
        url,
      );
    }
  }

  Future<void> _ensureTokens({required bool includeProfileToken}) async {
    await TokenStorage.instance.loadIntoRuntimeStore();

    final String accountToken = RuntimeStore.authToken;
    if (accountToken.isEmpty || _expiresSoon(accountToken)) {
      await _refreshAccountToken();
    }

    if (!includeProfileToken) {
      return;
    }

    final String? profileToken = RuntimeStore.getActiveProfileToken();
    if (profileToken == null ||
        profileToken.isEmpty ||
        _expiresSoon(profileToken)) {
      await _selectStoredProfile();
    }
  }

  Future<bool> _refreshAccountToken() {
    _refreshInFlight ??= _doRefreshAccountToken().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<bool> _doRefreshAccountToken() async {
    final String refreshToken = RuntimeStore.refreshToken.isNotEmpty
        ? RuntimeStore.refreshToken
        : (await TokenStorage.instance.readRefreshToken()) ?? '';
    if (refreshToken.isEmpty ||
        _expiresSoon(refreshToken, allowWindow: false)) {
      return false;
    }

    try {
      final response = await _dio.post<String>(
        '/api/account/refresh',
        data: jsonEncode(<String, String>{'refreshToken': refreshToken}),
        options: Options(
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'X-Client-Type': 'mobile',
          },
        ),
      );

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        return false;
      }

      final Map<String, dynamic>? body = _decodeObject(response.data);
      final dynamic token = body?['accountToken'];
      if (token is! String || token.trim().isEmpty) {
        return false;
      }

      await TokenStorage.instance.saveAccountToken(token.trim());
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> _selectStoredProfile() async {
    final int? storedProfileId = await TokenStorage.instance.readProfileId();
    final int? profileId = RuntimeStore.currentProfileId ?? storedProfileId;
    if (profileId == null || profileId <= 0) {
      return false;
    }

    final String accountToken = RuntimeStore.authToken;
    if (accountToken.isEmpty || _expiresSoon(accountToken)) {
      final bool refreshed = await _refreshAccountToken();
      if (!refreshed) {
        return false;
      }
    }

    try {
      final response = await _dio.post<String>(
        '/api/account/select-profile',
        queryParameters: <String, dynamic>{'profileId': profileId},
        data: jsonEncode(<String, dynamic>{}),
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-Client-Type': 'mobile',
            'Authorization': 'Bearer ${RuntimeStore.authToken}',
            'Cookie': 'accountToken=${RuntimeStore.authToken}',
          },
        ),
      );

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        return false;
      }

      final Map<String, dynamic>? body = _decodeObject(response.data);
      final dynamic profileToken = body?['profileToken'];
      if (profileToken is! String || profileToken.trim().isEmpty) {
        return false;
      }

      final dynamic profile = body?['profile'];
      String? profileRole;
      if (profile is Map<String, dynamic>) {
        final dynamic role = profile['role'];
        profileRole = role is String ? role : null;
      }

      await TokenStorage.instance.saveSelectedProfile(
        profileId: profileId,
        profileToken: profileToken.trim(),
        profileRole: profileRole,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  bool _authRequested(Map<String, String> headers) {
    return (headers['Cookie'] ?? '').trim().isNotEmpty ||
        headers.containsKey(RequestHeaders.includeProfileTokenHeader);
  }

  bool _includeProfileTokenRequested(Map<String, String> headers) {
    final String? requested = headers[RequestHeaders.includeProfileTokenHeader];
    if (requested != null) {
      return requested.toLowerCase() == 'true';
    }
    return (headers['Cookie'] ?? '').contains('profileToken=');
  }

  void _replaceCookieHeader(
    Map<String, String> headers,
    bool includeProfileToken,
  ) {
    final String? cookieHeader = RuntimeStore.getCookieHeader(
      includeProfileToken: includeProfileToken,
    );
    if (cookieHeader == null || cookieHeader.isEmpty) {
      headers.remove('Cookie');
      return;
    }
    headers['Cookie'] = cookieHeader;
  }

  bool _expiresSoon(String token, {bool allowWindow = true}) {
    final int? expiresAt = _jwtExpiresAt(token);
    if (expiresAt == null) {
      return true;
    }

    final DateTime expiry = DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
    );
    final DateTime threshold = allowWindow
        ? DateTime.now().add(_refreshWindow)
        : DateTime.now();
    return !expiry.isAfter(threshold);
  }

  int? _jwtExpiresAt(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final String payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final dynamic exp = decoded['exp'];
      if (exp is int) {
        return exp;
      }
      if (exp is num) {
        return exp.toInt();
      }
      return int.tryParse(exp?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodeObject(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

enum _ResponseBodyType {
  plain,
  bytes;

  ResponseType get dioResponseType {
    return switch (this) {
      _ResponseBodyType.plain => ResponseType.plain,
      _ResponseBodyType.bytes => ResponseType.bytes,
    };
  }
}

List<int> _asBytes(dynamic data) {
  if (data == null) {
    return <int>[];
  }
  if (data is List<int>) {
    return data;
  }
  if (data is List) {
    return data.whereType<int>().toList();
  }
  if (data is String) {
    return utf8.encode(data);
  }
  return utf8.encode(data.toString());
}
