import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tracking_location/tracking_location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _trackingLocationPlugin = TrackingLocation();
  int? status;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    int result = await _trackingLocationPlugin.start();
    if(result == 1) {
      _trackingLocationPlugin.listen();
    }
    setState(() {
      status = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Tracking service is: ${(status == null) ? 'Unavailable' : (status == 0) ? 'Stop' : 'Running'}'),
        ),
      ),
    );
  }
}
