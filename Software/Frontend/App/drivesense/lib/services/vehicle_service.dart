import 'dart:async';
import 'dart:convert';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
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

  static Future<int?> createDefaultVehicle(int profileId) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/vehicles');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{
              'model': 'L17 Fahrzeug',
              'licensePlate': 'L17-$profileId',
              'mileage': 0,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'CreateDefaultVehicle <- status=${response.statusCode}, uri=$uri, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final dynamic idValue = decoded['id'];
      if (idValue is int && idValue > 0) {
        return idValue;
      }
      if (idValue is num) {
        final int value = idValue.toInt();
        return value > 0 ? value : null;
      }
      if (idValue != null) {
        final int? value = int.tryParse(idValue.toString());
        if (value != null && value > 0) {
          return value;
        }
      }
    } catch (e) {
      debugPrint('CreateDefaultVehicle failed at $uri: $e');
    }

    return null;
  }

  static Future<int> ensureDefaultVehicleForActiveProfile(int profileId) async {
    int? vehicleId = await resolveFirstAvailableVehicleId();
    vehicleId ??= await createDefaultVehicle(profileId);
    final int resolved = vehicleId ?? 0;
    RuntimeStore.setCurrentVehicleId(resolved);
    return resolved;
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
  static Future<bool> updateVehicle(Vehicle vehicle) async {
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

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('UpdateVehicle failed at $uri: $e');
      return false;
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
        message:
            _extractServerMessage(response.body) ??
            'Fahrzeug konnte nicht geloescht werden.',
      );
    } catch (e) {
      debugPrint('DeleteVehicle failed at $uri: $e');
      return const VehicleActionResult(
        isSuccess: false,
        message: 'Fahrzeug konnte nicht geloescht werden.',
      );
    }
  }

  // ─── Ein neues Fahrzeug erstellen ─────────────────────────────────────────
  // Backend gibt die rohe Vehicle-Entity zurück (HTTP 201).
  static Future<Vehicle?> createVehicle({
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
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return Vehicle.fromJson(decoded);
    } catch (e) {
      debugPrint('CreateVehicle failed at $uri: $e');
      return null;
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

  static String? _extractServerMessage(String rawBody) {
    final dynamic decoded = _decodeJson(rawBody);
    if (decoded is Map<String, dynamic>) {
      final dynamic message = decoded['message'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
