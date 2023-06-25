import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

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

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getCar();
  }

  Future _initialize() async {
    pp('$mm initialize ...');
    theGreatGeofencer.buildGeofences();
  }
  Future _getCounts() async {
    pp('$mm ... get counts ...');
  }

  void _getCar() async {
    car = await prefs.getCar();
    if (car != null) {
      pp('$mm resident car:');
      myPrettyJsonPrint(car!.toJson());
      _getCounts();
      _initialize();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    style: myTextStyleLarge(context),
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
