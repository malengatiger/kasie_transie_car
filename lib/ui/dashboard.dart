import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/maps/association_route_maps.dart';
import 'package:kasie_transie_library/maps/directions_dog.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/messaging/heartbeat.dart';
import 'package:kasie_transie_library/utils/device_background_location.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:workmanager/workmanager.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm = '🌀🌀🌀🌀🌀🌀🌀🌀Dashboard 🌀🌀';

  lm.Vehicle? car;
  var arrivals = 0;
  var departures = 0;
  var heartbeats = 0;
  var dispatches = 0;
  late StreamSubscription<String> routeChangesSub;

  String? routeId;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getCar();
  }

  Future _initialize() async {
    pp('\n\n$mm initialize ...');
    await theGreatGeofencer.buildGeofences();
    await fcmBloc.subscribeToTopics();
    heartbeat.startHeartbeat();
    deviceBackgroundLocation.initialize();

    routeChangesSub = fcmBloc.routeChangesStream.listen((event) {
      pp('$mm routeChangesStream delivered a routeId: $event');
      routeId = event;
      setState(() {

      });
      if (mounted) {
        showSnackBar(message: "A Route update has been issued. The download will happen automatically.", context: context);
      }
    });


// Periodic task registration
    Workmanager().registerPeriodicTask(
      "periodic-task-identifier",
      "simplePeriodicTask",
      // When no frequency is provided the default 15 minutes is set.
      // Minimum frequency is 15 min. Android will automatically change your frequency to 15 min if you have configured a lower frequency.
      frequency: const Duration(minutes: 15),
    );
  }
  Future _getCounts() async {
    pp('$mm ... get counts ...');
  }

  void _getCar() async {
    car = await prefs.getCar();
    if (car != null) {
      pp('$mm ........... resident car:');
      myPrettyJsonPrint(car!.toJson());
      _getCounts();
      _initialize();
    }
    setState(() {});
  }

  void _navigateToMap() {
    navigateWithScale(const AssociationRouteMaps(), context);
  }
  @override
  void dispose() {
    _controller.dispose();
    routeChangesSub.cancel();
    super.dispose();
  }

  void getDirections() async {
    final loc = await locationBloc.getLocation();
    final res = await directionsDog.getDirections(originLat: loc.latitude, originLng: loc.longitude,
        destinationLat: 26.107567, destinationLng: 28.056702);
    pp('$mm directions should be here by now ... ${res.toString()}');
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: myTextStyleLarge(context),
        ),
        actions: [
          IconButton(onPressed: (){
            _navigateToMap();
          }, icon:  Icon(Icons.map, color: Theme.of(context).primaryColor,)),
          IconButton(onPressed: (){
              getDirections();
          }, icon:  Icon(Icons.directions, color: Theme.of(context).primaryColor,))
        ],
      ),
      body: car == null
          ? Container(
              color: Colors.amber,
            )
          : Card(
              shape: getRoundedBorder(radius: 16),
              elevation: 2,
              child: Column(
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    '${car!.vehicleReg}',
                    style: myTextStyleLargePrimaryColor(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    '${car!.make} ${car!.model} - ${car!.year}',
                    style: myTextStyleMedium(context),
                  ),

                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    'Owner',
                    style: myTextStyleSmall(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    car!.ownerName == null ? 'Owner Unknown' : car!.ownerName!,
                    style: myTextStyleMediumLargeWithSize(context, 20),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView(
                    gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisSpacing: 2, crossAxisSpacing: 2),
                    children: [
                        NumberWidget(title: 'Arrivals', number: arrivals),
                        NumberWidget(title: 'Departures', number: departures),
                        NumberWidget(title: 'Heartbeats', number: heartbeats),
                        NumberWidget(title: 'Dispatches', number: dispatches),
                    ],
                  ),
                      )),
                ],
              ),
            ),
    ));
  }
}

class NumberWidget extends StatelessWidget {
  const NumberWidget({Key? key, required this.title, required this.number})
      : super(key: key);

  final String title;
  final int number;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 8,
      child: SizedBox(
        height: 120,
        width: 120,
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Text(
              '$number',
              style: myNumberStyleLargerWithColor(Theme.of(context).primaryColor, 32, context),
            ),
            Text(
              title,
              style: myTextStyleSmall(context),
            ),
          ],
        ),
      ),
    );
  }
}
