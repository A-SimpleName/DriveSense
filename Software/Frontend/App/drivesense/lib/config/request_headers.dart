import 'package:drivesense/runtime_store.dart';

/// Builds backend request headers with the cookies expected by auth filters.
///
/// Authenticated requests include the app's internal profile-token marker so
/// AuthHttpClient can refresh and rebuild cookie headers immediately before
/// the request is sent.
class RequestHeaders {
  RequestHeaders._();

  /// Internal marker consumed by AuthHttpClient before the request is sent.
  static const String includeProfileTokenHeader =
      'X-DriveSense-Include-Profile-Token';

  /// Headers for authenticated requests without a JSON body.
  static Map<String, String> authenticated({
    String? clientType,
    bool includeProfileToken = true,
    bool includeRefreshToken = false,
  }) {
    return _build(
      clientType: clientType,
      includeProfileToken: includeProfileToken,
      includeRefreshToken: includeRefreshToken,
    );
  }

  /// Headers for authenticated requests with a JSON body.
  static Map<String, String> authenticatedJson({
    String? clientType,
    bool includeProfileToken = true,
    bool includeRefreshToken = false,
  }) {
    return _build(
      contentType: 'application/json',
      clientType: clientType,
      includeProfileToken: includeProfileToken,
      includeRefreshToken: includeRefreshToken,
    );
  }

  /// Headers for unauthenticated JSON requests.
  static Map<String, String> json({String? clientType}) {
    return _build(
      contentType: 'application/json',
      clientType: clientType,
    );
  }

  static Map<String, String> _build({
    String? contentType,
    String? clientType,
    bool includeProfileToken = true,
    bool includeRefreshToken = false,
  }) {
    final String? cookieHeader = RuntimeStore.getCookieHeader(
      includeProfileToken: includeProfileToken,
      includeRefreshToken: includeRefreshToken,
    );

    return <String, String>{
      if (contentType != null) 'Content-Type': contentType,
      if (clientType != null && clientType.isNotEmpty)
        'X-Client-Type': clientType,
      includeProfileTokenHeader: includeProfileToken ? 'true' : 'false',
      ..._cookieHeaders(cookieHeader),
    };
  }

  static Map<String, String> _cookieHeaders(String? cookieHeader) {
    if (cookieHeader == null) {
      return const <String, String>{};
    }

    return <String, String>{'Cookie': cookieHeader};
  }
}
