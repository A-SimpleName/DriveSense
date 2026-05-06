import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static final String ip = _requiredEnv('API_IP');
  static final String port = _requiredEnv('API_PORT');
  static final String baseUrl = 'https://$ip:$port';

  static String _requiredEnv(String key) {
    final String? value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable: $key. Please set it in .env.',
      );
    }
    return value;
  }
}

