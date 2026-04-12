import 'dart:convert';
import 'package:drivesense/constants/api_config.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; 

class SelectProfileResponse {
  final bool isSuccess;
  final String message;
  final Profile? profile;
  const SelectProfileResponse({
    required this.isSuccess,
    required this.message,
    this.profile,
  });
}

class ProfileService {
  ProfileService._();

  static Future<SelectProfileResponse> selectProfile(int profileId) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles/$profileId');
    final String authToken = RuntimeStore.getAuthToken() ?? '';

    debugPrint(
      'SelectProfile request -> url=$uri, profileId=$profileId, hasToken=${authToken.isNotEmpty}',
    );

    final response = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      'X-Client-Type': 'mobile',
      'Authorization': 'Bearer $authToken',
    }, body: jsonEncode({'profileId': profileId}),);

    debugPrint(
      'SelectProfile response <- status=${response.statusCode}, body=${response.body}',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final Profile profile = Profile.fromJson(json);
      return SelectProfileResponse(
        isSuccess: true,
        message: 'Profile selected successfully',
        profile: profile,
      );
    } else {
      return SelectProfileResponse(
        isSuccess: false,
        message:
            'Failed to select profile: ${response.statusCode} - ${response.body}',
      );
    }
  }  
}