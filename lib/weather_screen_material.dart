import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/secret.dart';

class WeatherScreenMaterial extends StatefulWidget {
  const WeatherScreenMaterial({super.key});

  @override
  State<WeatherScreenMaterial> createState() => _WeatherScreenMaterialState();
}

class _WeatherScreenMaterialState extends State<WeatherScreenMaterial> {
  late Future<Map<String, dynamic>> weather;

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      String cityName = 'Depok';
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey'));

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'Un expected error occured';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }
  
  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather App",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
              onPressed: () {
                setState(() {
                  weather = getCurrentWeather();
                });
              },
              icon: const Icon(Icons.refresh_sharp))
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          // Error State
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          final data = snapshot.data!;

          // pass data
          final currentData = data['list'][0];
          final currentTemp = double.parse(
              (currentData['main']['temp'] - 273.15).toStringAsFixed(1));
          final weather = currentData['weather'][0]['main'];
          final pressure = currentData['main']['pressure'];
          final humidity = currentData['main']['humidity'];
          final windSpeed = currentData['wind']['speed'];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Text(
                                "$currentTemp °C",
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                  weather == 'Rain' || weather == 'Clouds'
                                      ? Icons.cloud
                                      : Icons.sunny,
                                  size: 64),
                              const SizedBox(height: 10),
                              Text(
                                weather,
                                style: const TextStyle(fontSize: 20),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                // Forecast Card
                const Text(
                  'Hourly Forecast',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: 5,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final forecastData = data['list'][index + 1];
                      final forecastTime = DateFormat.j()
                          .format(DateTime.parse(forecastData['dt_txt']));
                      final forecastIcon =
                          forecastData['weather'][0]['main'] == 'Clouds' ||
                                  forecastData['weather'][0]['main'] == 'Rain'
                              ? Icons.cloud
                              : Icons.sunny;
                      final forecastTemp =
                          (forecastData['main']['temp'] - 271.35)
                              .toStringAsFixed(1);

                      return HourlyForecastItem(
                          time: forecastTime,
                          icon: forecastIcon,
                          temperature: '$forecastTemp °C');
                    },
                  ),
                ),
                const SizedBox(height: 25),
                // Info card
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AdditionalInfoItem(
                        icon: Icons.water_drop_rounded,
                        label: 'Humidity',
                        value: humidity.toString()),
                    AdditionalInfoItem(
                        icon: Icons.air,
                        label: 'Wind Speed',
                        value: windSpeed.toString()),
                    AdditionalInfoItem(
                        icon: Icons.beach_access,
                        label: 'Pressure',
                        value: pressure.toString()),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
