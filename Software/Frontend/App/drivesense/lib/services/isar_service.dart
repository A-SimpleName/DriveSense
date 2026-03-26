import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drivesense/model/pending_trip.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> getInstance() async {
    if (_isar != null) return _isar!;

    final directory = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [PendingTripSchema],
      directory: directory.path,
      name: 'drivesense_db',
    );

    return _isar!;
  }
}