class TripHttpException implements Exception {
  final String message;
  final int? statusCode;

  TripHttpException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
