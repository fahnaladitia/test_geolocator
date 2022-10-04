import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Testing Geolocator and Geocoding'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? message;
  String? city;
  String? messageStream;
  String? cityStream;
  Position? currentPosition;

  bool isMock = false;
  bool isMockStream = false;

  @override
  void initState() {
    super.initState();

    _refreshCurrentLocation();
    _streamPosition().listen((position) async {
      if (position.isMocked) {
        if (currentPosition != null) {
          _getPlacemarks(currentPosition!.latitude, currentPosition!.longitude).then((value) {
            final cityData = value[0];
            setState(() {
              isMockStream = position.isMocked;
              messageStream =
                  "lat: ${currentPosition!.latitude}, long: ${currentPosition!.longitude}";
              cityStream =
                  "${cityData.subAdministrativeArea}, ${cityData.administrativeArea}, ${cityData.country}";
            });
          });
        } else {
          setState(() {
            cityStream = "Kosong";
            messageStream = "Kosong";
            isMockStream = position.isMocked;
          });
        }

        return;
      }
      currentPosition = position;

      _getPlacemarks(position.latitude, position.longitude).then((value) {
        final cityData = value[0];
        setState(() {
          isMockStream = position.isMocked;
          messageStream = "lat: ${position.latitude}, long: ${position.longitude}";
          cityStream =
              "${cityData.subAdministrativeArea}, ${cityData.administrativeArea}, ${cityData.country}";
        });
      }).catchError((e) {
        setState(() {
          cityStream = e.toString();
        });
      });
    }).onError((e) {
      setState(() {
        message = e.toString();
        cityStream = e.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Single Request With Button"),
          Text(message ?? "Kosong"),
          Text(city ?? "Kosong"),
          Text("isMock: $isMock"),
          const SizedBox(
            height: 50,
          ),
          const Text("Stream Data always listen position"),
          Text(messageStream ?? "Kosong"),
          Text(cityStream ?? "Kosong"),
          Text("isMockStream: $isMockStream"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                message = "Loading...";
                city = "Loading...";
              });
              _refreshCurrentLocation();
            },
            child: const Text("Get Current Position & City"),
          ),
        ],
      )),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _refreshCurrentLocation() {
    _determinePosition().then((position) async {
      if (position.isMocked) {
        toast("U use mock location");

        if (currentPosition != null) {
          _getPlacemarks(currentPosition!.latitude, currentPosition!.longitude).then((value) {
            final cityData = value[0];
            setState(() {
              city =
                  "${cityData.subAdministrativeArea}, ${cityData.administrativeArea}, ${cityData.country}";
              message = "lat: ${currentPosition!.latitude}, long: ${currentPosition!.longitude}";
              isMock = position.isMocked;
            });
          });
        } else {
          setState(() {
            city = "Kosong";
            message = "Kosong";
            isMock = position.isMocked;
          });
        }
        return;
      }
      _getPlacemarks(position.latitude, position.longitude).then((value) {
        final cityData = value[0];
        setState(() {
          message = "lat: ${position.latitude}, long: ${position.longitude}";
          city =
              "${cityData.subAdministrativeArea}, ${cityData.administrativeArea}, ${cityData.country}";
          isMock = position.isMocked;
        });
      }).catchError((e) {
        setState(() {
          city = e.toString();
        });
      });
    }).catchError((e) {
      setState(() {
        message = e.toString();
        city = e.toString();
      });
    });
  }

  Future<List<Placemark>> _getPlacemarks(double lat, double lng) async {
    return await placemarkFromCoordinates(lat, lng);
  }

  Stream<Position> _streamPosition() async* {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      yield* Stream.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        yield* Stream.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      yield* Stream.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    yield* Geolocator.getPositionStream();
  }

  void toast(String message) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
