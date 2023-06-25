import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transicar/ui/dashboard.dart';
import 'package:kasie_transie_library/bloc/app_auth.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/utils/country_cities_isolate.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/initializer.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:badges/badges.dart' as bd;

class VehicleList extends StatefulWidget {
  const VehicleList({Key? key, required this.association}) : super(key: key);

  final lm.Association association;

  @override
  VehicleListState createState() => VehicleListState();
}

class VehicleListState extends State<VehicleList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm = '🌎🌎🌎🌎🌎🌎VehicleList 🍐🍐';

  bool busy = false;
  var cars = <lm.Vehicle>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getVehicles();
  }

  void _getVehicles() async {
    setState(() {
      busy = true;
    });
    try {
      cars = await listApiDog.getAssociationVehicles(
          widget.association.associationId!, false);
      cars.sort((a, b) => a.vehicleReg!.compareTo(b.vehicleReg!));
      pp('$mm ..... cars found: ${cars.length}');
    } catch (e) {
      pp(e);
    }

    setState(() {
      busy = false;
    });
  }

  //
  bool initializing = false;
  Timer? timer;
  int secondsElapsed = 0;
  String formattedTime = '';
  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed = timer.tick;
        formattedTime = getFormattedTime(timeInSeconds: secondsElapsed);
      });
    });
  }

  Future _onCarSelected(lm.Vehicle car) async {
    pp('$mm .... car selected ... will start loading initial data ...');
    myPrettyJsonPrint(car.toJson());
    setState(() {
      initializing = true;
    });
    _startTimer();
    try {
      await prefs.saveCar(car);
      final res = await appAuth.signInVehicle();
      pp('$mm car should be authenticated by now; result: $res. ... on to Cleveland Browns ...');
      await listApiDog.getCountries();
      final ass = await listApiDog.getAssociationById(car.associationId!);
      final country = listApiDog.getCountryById(ass.countryId!);
      if (country != null) {
        countryCitiesIsolate.getCountryCities(country.countryId!);
      }
      await initializer.initialize();
      timer!.cancel();
      setState(() {
        doneInitializing = true;
      });
      //
    } catch (e) {
      pp(e);
      showSnackBar(
          duration: const Duration(seconds: 10),
          message: 'Initialization failed: $e',
          context: context);
    }
  }

  bool doneInitializing = false;

  void _navigateToDashboard() {
    pp('$mm Navigate to the Dashboard!! '
        ' ${E.leaf}${E.leaf}${E.leaf}');
    if (mounted) {
      Navigator.of(context).pop();
      navigateWithScale(const Dashboard(), context);
    }
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
                'Association Cars',
                style: myTextStyleLarge(context),
              ),
            ),
            body: Stack(
              children: [
                busy
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            backgroundColor: Colors.amber,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text('Select the vehicle for the app'),
                            const SizedBox(
                              height: 48,
                            ),
                            Expanded(
                              child: bd.Badge(
                                badgeContent: Text('${cars.length}'),
                                badgeStyle: bd.BadgeStyle(
                                    badgeColor: Colors.green[900]!,
                                    padding: const EdgeInsets.all(12)),
                                child: ListView.builder(
                                    itemCount: cars.length,
                                    itemBuilder: (ctx, index) {
                                      final ass = cars.elementAt(index);
                                      return GestureDetector(
                                        onTap: () {
                                          _onCarSelected(ass);
                                        },
                                        child: Card(
                                          shape: getRoundedBorder(radius: 16),
                                          elevation: 4,
                                          child: ListTile(
                                            title: Text(
                                              '${ass.vehicleReg}',
                                              style: myTextStyleMediumBold(
                                                  context),
                                            ),
                                            subtitle: Text(
                                              '${ass.make} ${ass.model} - ${ass.year}',
                                              style: myTextStyleSmall(context),
                                            ),
                                            leading: Icon(
                                              Icons.car_crash,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            )
                          ],
                        ),
                      ),
                initializing
                    ? Positioned(
                        left: 12,
                        right: 12,
                        bottom: 160,
                        top: 160,
                        child: Card(
                          shape: getRoundedBorder(radius: 16),
                          elevation: 16,
                          child: SizedBox(
                            height: 300,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text(
                                    'KasieTransie',
                                    style: myTextStyleLarge(context),
                                  ),
                                  const SizedBox(
                                    height: 48,
                                  ),
                                  doneInitializing
                                      ? const SizedBox()
                                      : const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 6,
                                            backgroundColor: Colors.amber,
                                          ),
                                        ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  const Text('Initializing data resources ...'),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'This may take a few minutes or so ...',
                                    style: myTextStyleMediumLargeWithSize(
                                        context, 16),
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Elapsed Time:'),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        formattedTime,
                                        style: myTextStyleMediumLargeWithColor(
                                            context, Colors.amber[700]!),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 64,
                                  ),
                                  doneInitializing
                                      ? ElevatedButton(
                                          onPressed: () {
                                            _navigateToDashboard();
                                          },
                                          child: const Text(
                                              'Done, please proceed'))
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                        ))
                    : const SizedBox(),
              ],
            )));
  }
}
