import 'dart:async';
import 'dart:convert';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/service_error_messages.dart';
import 'package:flutter/foundation.dart';

class VehicleActionResult {
  final bool isSuccess;
  final String message;

  const VehicleActionResult({required this.isSuccess, required this.message});
}

class VehicleService {
  VehicleService._();

  static Future<int?> resolveFirstAvailableVehicleId() async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/vehicles');

    try {
      final http.Response response = await http
          .get(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! List) {
        return null;
      }

      for (final dynamic item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final dynamic idValue = item['id'];
        int? id;
        if (idValue is int) {
          id = idValue;
        } else if (idValue is num) {
          id = idValue.toInt();
        } else if (idValue != null) {
          id = int.tryParse(idValue.toString());
        }

        if (id != null && id > 0) {
          return id;
        }
      }
    } catch (e) {
      debugPrint('ResolveFirstAvailableVehicleId failed at $uri: $e');
    }

    return null;
  }

  static Future<int?> resolvePreferredCurrentOrFirstAvailableVehicleId({
    int preferredVehicleId = 0,
  }) async {
    List<Vehicle> vehicles = RuntimeStore.vehicles;
    if (vehicles.isEmpty) {
      vehicles = await fetchVehicles();
    }

    if (preferredVehicleId > 0) {
      for (final Vehicle vehicle in vehicles) {
        if (vehicle.id == preferredVehicleId) {
          return vehicle.id;
        }
      }
    }

    final int currentVehicleId = RuntimeStore.getCurrentVehicleId();
    for (final Vehicle vehicle in vehicles) {
      if (vehicle.id == currentVehicleId && vehicle.id > 0) {
        return vehicle.id;
      }
    }

    return vehicles.isNotEmpty && vehicles.first.id > 0
        ? vehicles.first.id
        : null;
  }

  // ─── Alle Fahrzeuge des aktuellen Profils vom Server laden ───────────────
  // Gibt eine leere Liste zurück wenn etwas schiefgeht (kein Crash).
  static Future<List<Vehicle>> fetchVehicles() async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/vehicles');

    try {
      final http.Response response = await http
          .get(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [];
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! List) return [];

      // Jeden JSON-Eintrag in ein Vehicle-Objekt umwandeln,
      // fehlerhafte Einträge werden übersprungen (whereType filtert null raus)
      final List<Vehicle> vehicles = decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => Vehicle.fromJson(json))
          .toList();
      RuntimeStore.setVehicles(vehicles);
      return vehicles;
    } catch (e) {
      debugPrint('FetchVehicles failed at $uri: $e');
      return [];
    }
  }

  // ─── Ein bestehendes Fahrzeug am Server aktualisieren ────────────────────
  // Gibt true zurück wenn erfolgreich, false wenn nicht.
  static Future<List<VehicleMember>> fetchVehicleMembers(int vehicleId) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/$vehicleId/members',
    );

    try {
      final http.Response response = await http
          .get(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <VehicleMember>[];
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! List) {
        return <VehicleMember>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VehicleMember.fromJson)
          .where((VehicleMember member) => member.profileId > 0)
          .toList();
    } catch (e) {
      debugPrint('FetchVehicleMembers failed at $uri: $e');
      return <VehicleMember>[];
    }
  }

  static Future<VehicleActionResult> removeVehicleMember({
    required int vehicleId,
    required int profileId,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/$vehicleId/members/$profileId',
    );

    try {
      final http.Response response = await http
          .delete(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Mitglied wurde entfernt.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Mitglied konnte nicht entfernt werden',
        ),
      );
    } catch (e) {
      debugPrint('RemoveVehicleMember failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Mitglied konnte nicht entfernt werden',
        ),
      );
    }
  }

  static Future<VehicleActionResult> updateVehicleMemberRole({
    required int vehicleId,
    required int profileId,
    required String role,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/$vehicleId/members/$profileId/role',
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
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Rolle wurde aktualisiert.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Rolle konnte nicht aktualisiert werden',
        ),
      );
    } catch (e) {
      debugPrint('UpdateVehicleMemberRole failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Rolle konnte nicht aktualisiert werden',
        ),
      );
    }
  }

  static Future<bool> updateVehicle(Vehicle vehicle) async {
    final VehicleActionResult result = await updateVehicleWithResult(vehicle);
    return result.isSuccess;
  }

  static Future<VehicleActionResult> updateVehicleWithResult(
    Vehicle vehicle,
  ) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/${vehicle.id}',
    );

    try {
      final http.Response response = await http
          .put(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(vehicle.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Fahrzeug wurde gespeichert.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Fahrzeug konnte nicht gespeichert werden',
        ),
      );
    } catch (e) {
      debugPrint('UpdateVehicle failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Fahrzeug konnte nicht gespeichert werden',
        ),
      );
    }
  }

  // ─── Ein Fahrzeug am Server löschen ──────────────────────────────────────
  static Future<bool> deleteVehicle(int vehicleId) async {
    final VehicleActionResult result = await deleteVehicleWithResult(vehicleId);
    return result.isSuccess;
  }

  static Future<VehicleActionResult> deleteVehicleWithResult(
    int vehicleId,
  ) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/vehicles/$vehicleId');

    try {
      final http.Response response = await http
          .delete(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Fahrzeug wurde aus diesem Profil entfernt.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Fahrzeug konnte nicht gelöscht werden',
        ),
      );
    } catch (e) {
      debugPrint('DeleteVehicle failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Fahrzeug konnte nicht gelöscht werden',
        ),
      );
    }
  }

  // ─── Ein neues Fahrzeug erstellen ─────────────────────────────────────────
  // Backend gibt die rohe Vehicle-Entity zurück (HTTP 201).
  static Future<VehicleActionResult> inviteVehicle({
    required int vehicleId,
    required String email,
    required String role,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/$vehicleId/invitations',
    );

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, String>{'email': email, 'role': role}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Fahrzeugeinladung wurde per E-Mail gesendet.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Fahrzeugeinladung konnte nicht gesendet werden',
        ),
      );
    } catch (e) {
      debugPrint('InviteVehicle failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Fahrzeugeinladung konnte nicht gesendet werden',
        ),
      );
    }
  }

  static Future<VehicleActionResult> acceptVehicleInvite({
    required String code,
    required int profileId,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/invitations/accept',
    );

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{
              'code': code,
              'profileId': profileId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Fahrzeugeinladung wurde angenommen.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Fahrzeugeinladung konnte nicht angenommen werden',
        ),
      );
    } catch (e) {
      debugPrint('AcceptVehicleInvite failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Fahrzeugeinladung konnte nicht angenommen werden',
        ),
      );
    }
  }

  static Future<VehicleActionResult> acceptVehicleInviteAuto({
    required String code,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/vehicles/invitations/accept',
    );

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(
              clientType: 'mobile',
              includeProfileToken: false,
            ),
            body: jsonEncode(<String, dynamic>{'code': code}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const VehicleActionResult(
          isSuccess: true,
          message: 'Fahrzeugeinladung wurde angenommen.',
        );
      }

      return VehicleActionResult(
        isSuccess: false,
        message: _httpFailure(
          response,
          'Fahrzeugeinladung konnte nicht angenommen werden',
        ),
      );
    } catch (e) {
      debugPrint('AcceptVehicleInviteAuto failed at $uri: $e');
      return VehicleActionResult(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Fahrzeugeinladung konnte nicht angenommen werden',
        ),
      );
    }
  }

  static Future<Vehicle?> createVehicle({
    required String model,
    required String licensePlate,
    required int mileage,
  }) async {
    final VehicleActionResultWithVehicle result = await createVehicleWithResult(
      model: model,
      licensePlate: licensePlate,
      mileage: mileage,
    );
    return result.vehicle;
  }

  static Future<VehicleActionResultWithVehicle> createVehicleWithResult({
    required String model,
    required String licensePlate,
    required int mileage,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/vehicles');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode({
              'model': model,
              'licensePlate': licensePlate,
              'mileage': mileage,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'CreateVehicle <- status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('CreateVehicle failed: HTTP ${response.statusCode}');
        return VehicleActionResultWithVehicle(
          isSuccess: false,
          message: _httpFailure(
            response,
            'Fahrzeug konnte nicht erstellt werden',
          ),
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const VehicleActionResultWithVehicle(
          isSuccess: false,
          message:
              'Fahrzeug konnte nicht erstellt werden. Bitte spaeter erneut versuchen.',
        );
      }
      return VehicleActionResultWithVehicle(
        isSuccess: true,
        message: 'Fahrzeug wurde erstellt.',
        vehicle: Vehicle.fromJson(decoded),
      );
    } catch (e) {
      debugPrint('CreateVehicle failed at $uri: $e');
      return VehicleActionResultWithVehicle(
        isSuccess: false,
        message: _exceptionFailure(
          e,
          'Fahrzeug konnte nicht erstellt werden',
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

class VehicleActionResultWithVehicle extends VehicleActionResult {
  final Vehicle? vehicle;

  const VehicleActionResultWithVehicle({
    required super.isSuccess,
    required super.message,
    this.vehicle,
  });
}
