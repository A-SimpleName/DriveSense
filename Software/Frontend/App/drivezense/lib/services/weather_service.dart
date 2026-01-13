import 'package:open_meteo/open_meteo.dart';

Future<num> getTemperatures() async {
  final weatherLatitude = 40.712776;
  final weatherLongitude = -74.005974;

  final weather = WeatherApi(
    userAgent: "drivezense",
    temperatureUnit: TemperatureUnit.celsius,
  );

  final response = await weather.request(
    locations: {
      OpenMeteoLocation(
        latitude: weatherLatitude,
        longitude: weatherLongitude,
      ),
    },
    hourly: {WeatherHourly.temperature_2m},
  );

  if (response.segments.isEmpty) {
    throw Exception("No weather data available");
  }

  final data = response.segments[0].hourlyData[WeatherHourly.temperature_2m];
  if (data == null) {
    throw Exception("temperature_2m missing in hourlyData");
  }

  
  final values = data.values.values;
  return values.first;
}
