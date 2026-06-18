import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/group_service.dart';
import 'package:drivesense/services/profile_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:flutter/material.dart';

enum InviteLinkType { group, vehicle }

class PendingInviteLink {
  final InviteLinkType type;
  final String code;

  const PendingInviteLink({required this.type, required this.code});
}

class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;
  static Timer? _processingTimer;
  static PendingInviteLink? _pendingInvite;
  static bool _isProcessing = false;

  static Future<void> initialize() async {
    _subscription ??= _appLinks.uriLinkStream.listen(
      handleUri,
      onError: (Object error) {
        debugPrint('Deep link stream error: $error');
      },
    );

    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await handleUri(initialUri);
    }
  }

  static Future<void> handleUri(Uri uri) async {
    final PendingInviteLink? invite = _parseInvite(uri);
    if (invite == null) {
      return;
    }

    _pendingInvite = invite;
    _schedulePendingInviteProcessing();
  }

  static Future<bool> processPendingInvite() async {
    final PendingInviteLink? invite = _pendingInvite;
    if (invite == null) {
      return false;
    }

    if (_isProcessing) {
      return true;
    }

    _isProcessing = true;
    try {
      if ((RuntimeStore.getAuthToken() ?? '').trim().isEmpty) {
        _showSnackBar('Bitte melde dich an, um die Einladung anzunehmen.');
        return true;
      }

      if (invite.type == InviteLinkType.vehicle) {
        final VehicleActionResult result =
            await VehicleService.acceptVehicleInviteAuto(code: invite.code);
        _showSnackBar(result.message);
        if (result.isSuccess) {
          _pendingInvite = null;
          if (RuntimeStore.currentProfileId != null) {
            await VehicleService.fetchVehicles();
          }
        }
        return result.isSuccess;
      }

      final Profile? profile = await _resolveProfileForGroupInvite(invite.code);
      if (profile == null) {
        return false;
      }

      final GroupActionResult acceptResult = await GroupService.acceptInvite(
        code: invite.code,
        profileId: profile.id,
      );
      _showSnackBar(acceptResult.message);
      if (!acceptResult.isSuccess) {
        return false;
      }

      await ProfileService.selectProfile(profile.id);
      _pendingInvite = null;
      return true;
    } finally {
      _isProcessing = false;
    }
  }

  static PendingInviteLink? _parseInvite(Uri uri) {
    final bool isCustomInvite =
        uri.scheme == 'drivesense' && uri.host == 'invite';
    final bool isWebInvite =
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.path == '/invite';
    if (!isCustomInvite && !isWebInvite) {
      return null;
    }

    final String code = uri.queryParameters['code']?.trim() ?? '';
    if (code.isEmpty) {
      return null;
    }

    final String type = uri.queryParameters['type']?.trim().toLowerCase() ?? '';
    return PendingInviteLink(
      type: type == 'vehicle' ? InviteLinkType.vehicle : InviteLinkType.group,
      code: code,
    );
  }

  static Future<Profile?> _resolveProfileForGroupInvite(String code) async {
    final GroupInviteVerificationResult verification =
        await GroupService.verifyInvite(code);
    if (!verification.isSuccess) {
      _showSnackBar(verification.message);
      return null;
    }

    final List<Profile> joinableProfiles = verification.profiles
        .where((Profile profile) => profile.joinable)
        .toList();
    if (joinableProfiles.isEmpty) {
      _showSnackBar(
        'Kein Profil dieses Accounts kann dieser Gruppe beitreten.',
      );
      return null;
    }

    final int? currentProfileId = RuntimeStore.currentProfileId;
    if (currentProfileId != null) {
      for (final Profile profile in joinableProfiles) {
        if (profile.id == currentProfileId) {
          return profile;
        }
      }
    }

    if (joinableProfiles.length == 1) {
      return joinableProfiles.single;
    }

    _showSnackBar(
      'Mehrere Profile koennen beitreten. Waehle zuerst ein Profil aus und oeffne die Einladung erneut.',
    );
    return null;
  }

  static void _showSnackBar(String message) {
    debugPrint('Deep link invite: $message');
  }

  static void _schedulePendingInviteProcessing() {
    if (_processingTimer?.isActive == true) {
      return;
    }

    _processingTimer = Timer(const Duration(milliseconds: 250), () {
      processPendingInvite();
    });
  }

  static Future<void> dispose() async {
    _processingTimer?.cancel();
    _processingTimer = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
