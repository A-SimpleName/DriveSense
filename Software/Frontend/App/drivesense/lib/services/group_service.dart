import 'dart:async';
import 'dart:convert';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/model/user_group.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/service_error_messages.dart';
import 'package:flutter/foundation.dart';

class GroupActionResult {
  final bool isSuccess;
  final String message;

  const GroupActionResult({required this.isSuccess, required this.message});
}

class GroupMutationResult {
  final bool isSuccess;
  final String message;
  final UserGroup? group;

  const GroupMutationResult({
    required this.isSuccess,
    required this.message,
    this.group,
  });
}

class GroupInviteVerificationResult {
  final bool isSuccess;
  final String message;
  final List<Profile> profiles;

  const GroupInviteVerificationResult({
    required this.isSuccess,
    required this.message,
    this.profiles = const <Profile>[],
  });
}

class GroupService {
  GroupService._();

  static Future<List<UserGroup>> fetchGroups() async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/groups');

    try {
      final http.Response response = await http
          .get(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <UserGroup>[];
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! List) {
        return <UserGroup>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(UserGroup.fromJson)
          .where((UserGroup group) => group.id > 0)
          .toList();
    } catch (e) {
      debugPrint('FetchGroups failed at $uri: $e');
      return <UserGroup>[];
    }
  }

  static Future<List<GroupMember>> fetchGroupMembers(int groupId) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/groups/$groupId/members',
    );

    try {
      final http.Response response = await http
          .get(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <GroupMember>[];
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! List) {
        return <GroupMember>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GroupMember.fromJson)
          .where((GroupMember member) => member.profileId > 0)
          .toList();
    } catch (e) {
      debugPrint('FetchGroupMembers failed at $uri: $e');
      return <GroupMember>[];
    }
  }

  static Future<GroupMutationResult> createGroup({required String name}) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/groups');
    final String trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return const GroupMutationResult(
        isSuccess: false,
        message: 'Gruppenname darf nicht leer sein.',
      );
    }

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{'name': trimmedName}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GroupMutationResult(
          isSuccess: false,
          message: _httpFailure(response, 'Gruppe konnte nicht erstellt werden'),
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      final UserGroup? group = decoded is Map<String, dynamic>
          ? UserGroup.fromJson(decoded)
          : null;

      return GroupMutationResult(
        isSuccess: true,
        message: 'Gruppe wurde erstellt.',
        group: group,
      );
    } catch (e) {
      debugPrint('CreateGroup failed at $uri: $e');
      return GroupMutationResult(
        isSuccess: false,
        message: _exceptionFailure(e, 'Gruppe konnte nicht erstellt werden'),
      );
    }
  }

  static Future<GroupActionResult> updateGroup({
    required int groupId,
    required String name,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId');
    final String trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return const GroupActionResult(
        isSuccess: false,
        message: 'Gruppenname darf nicht leer sein.',
      );
    }

    try {
      final http.Response response = await http
          .put(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{'name': trimmedName}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GroupActionResult(
          isSuccess: true,
          message: 'Gruppe wurde umbenannt.',
        );
      }

      return GroupActionResult(
        isSuccess: false,
        message: _httpFailure(response, 'Gruppe konnte nicht umbenannt werden'),
      );
    } catch (e) {
      debugPrint('UpdateGroup failed at $uri: $e');
      return GroupActionResult(
        isSuccess: false,
        message: _exceptionFailure(e, 'Gruppe konnte nicht umbenannt werden'),
      );
    }
  }

  static Future<GroupActionResult> deleteGroup(int groupId) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId');

    try {
      final http.Response response = await http
          .delete(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GroupActionResult(
          isSuccess: true,
          message: 'Gruppe wurde gelöscht.',
        );
      }

      return GroupActionResult(
        isSuccess: false,
        message: _httpFailure(response, 'Gruppe konnte nicht gelöscht werden'),
      );
    } catch (e) {
      debugPrint('DeleteGroup failed at $uri: $e');
      return GroupActionResult(
        isSuccess: false,
        message: _exceptionFailure(e, 'Gruppe konnte nicht gelöscht werden'),
      );
    }
  }

  static Future<GroupActionResult> inviteMember({
    required int groupId,
    required String email,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/groups/$groupId/invite',
    );
    final String trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return const GroupActionResult(
        isSuccess: false,
        message: 'E-Mail darf nicht leer sein.',
      );
    }

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{'email': trimmedEmail}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GroupActionResult(
          isSuccess: true,
          message: 'Gruppeneinladung wurde per E-Mail gesendet.',
        );
      }

      return GroupActionResult(
        isSuccess: false,
        message:
            _httpFailure(
              response,
              'Gruppeneinladung konnte nicht gesendet werden',
            ),
      );
    } catch (e) {
      debugPrint('InviteGroupMember failed at $uri: $e');
      return GroupActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Gruppeneinladung konnte nicht gesendet werden',
        ),
      );
    }
  }

  static Future<GroupActionResult> deleteMember({
    required int groupId,
    required int profileId,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/groups/$groupId/members/$profileId',
    );

    try {
      final http.Response response = await http
          .delete(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GroupActionResult(
          isSuccess: true,
          message: 'Mitglied wurde entfernt.',
        );
      }

      return GroupActionResult(
        isSuccess: false,
        message: _httpFailure(response, 'Mitglied konnte nicht entfernt werden'),
      );
    } catch (e) {
      debugPrint('DeleteGroupMember failed at $uri: $e');
      return GroupActionResult(
        isSuccess: false,
        message: _exceptionFailure(e, 'Mitglied konnte nicht entfernt werden'),
      );
    }
  }

  static Future<GroupActionResult> updateMemberRole({
    required int groupId,
    required int profileId,
    required String role,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/groups/$groupId/members/$profileId/role',
    );

    try {
      final http.Response response = await http
          .put(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{'role': role.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GroupActionResult(
          isSuccess: true,
          message: 'Rolle wurde aktualisiert.',
        );
      }

      return GroupActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Rolle konnte nicht aktualisiert werden',
        ),
      );
    } catch (e) {
      debugPrint('UpdateGroupMemberRole failed at $uri: $e');
      return GroupActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Rolle konnte nicht aktualisiert werden',
        ),
      );
    }
  }

  static Future<GroupInviteVerificationResult> verifyInvite(String code) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/groups/verify-invite');
    final String trimmedCode = code.trim();

    if (trimmedCode.isEmpty) {
      return const GroupInviteVerificationResult(
        isSuccess: false,
        message: 'Einladungscode darf nicht leer sein.',
      );
    }

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{'code': trimmedCode}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GroupInviteVerificationResult(
          isSuccess: false,
          message: _httpFailure(
            response,
            'Einladungscode konnte nicht geprüft werden',
          ),
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      final List<Profile> profiles = decoded is List
          ? decoded
                .whereType<Map<String, dynamic>>()
                .map(Profile.fromJson)
                .where((Profile profile) => profile.id > 0)
                .toList()
          : <Profile>[];

      return GroupInviteVerificationResult(
        isSuccess: true,
        message: 'Einladungscode wurde geprüft.',
        profiles: profiles,
      );
    } catch (e) {
      debugPrint('VerifyGroupInvite failed at $uri: $e');
      return GroupInviteVerificationResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Einladungscode konnte nicht geprüft werden',
        ),
      );
    }
  }

  static Future<GroupActionResult> acceptInvite({
    required String code,
    required int profileId,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/groups/accept-invite');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{
              'code': code.trim(),
              'profileId': profileId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GroupActionResult(
          isSuccess: true,
          message: 'Gruppeneinladung wurde angenommen.',
        );
      }

      return GroupActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Gruppeneinladung konnte nicht angenommen werden',
        ),
      );
    } catch (e) {
      debugPrint('AcceptGroupInvite failed at $uri: $e');
      return GroupActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Gruppeneinladung konnte nicht angenommen werden',
        ),
      );
    }
  }

  static dynamic _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return null;
    }
  }

  static String _httpFailure(http.Response response, String action) {
    return ServiceErrorMessages.forHttpStatus(
      statusCode: response.statusCode,
      action: action,
      responseBody: response.body,
    );
  }

  static String _exceptionFailure(Object error, String action) {
    return ServiceErrorMessages.forException(error, action: action);
  }
}
