import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transicar/ui/dashboard.dart';
import 'package:kasie_transie_library/bloc/app_auth.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/isolates/country_cities_isolate.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/initializer.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:badges/badges.dart' as bd;
import 'package:kasie_transie_library/widgets/auth/cell_auth_signin.dart';

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
  var carsToDisplay = <lm.Vehicle>[];
  late StreamSubscription<bool> compSubscription;
  lm.Association? ass;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getVehicles();
  }

  void _listen() async {
    compSubscription = initializer.completionStream.listen((completed) {
      pp('$mm ... initializer.completionStream delivered : $completed');
      if (timer != null) {
        timer!.cancel();
      }
      if (mounted) {
        setState(() {
          initializing = false;
          doneInitializing = true;
        });
      }
    });
  }

  void _getVehicles() async {
    pp('$mm ........... _getVehicles for ${ass!.associationName}');
    myPrettyJsonPrint(ass!.toJson());

    setState(() {
      busy = true;
    });
    try {
      await _fetch();
    } catch (e) {
      pp(e);
    }

    setState(() {
      busy = false;
    });
  }

  Future<void> _fetch() async {
    cars = await listApiDog.getAssociationVehicles(widget.association.associationId!, false);
    cars.sort((a, b) => a.vehicleReg!.compareTo(b.vehicleReg!));
    _carPlates.clear();
    for (var element in cars) {
      _carPlates.add(element.vehicleReg!);
      carsToDisplay.add(element);
    }
    pp('$mm ..... cars found: ${cars.length}');
    setState(() {});
  }
  
  //
  bool initializing = false;
  Timer? timer;
  int secondsElapsed = 0;
  String formattedTime = '';

  lm.Vehicle? car;
  Future _onCarSelected(lm.Vehicle car) async {
    pp('$mm .... car selected ... will'
        ' start loading initial data ...');
    this.car = car;
    myPrettyJsonPrint(car.toJson());

    try {
      await prefs.saveCar(car);
      fcmBloc.subscribeForCar("CarApp");
      if (mounted) {
        Navigator.of(context).pop(car);
        return;
      }
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

  final _carPlates = <String>[];

  void _runFilter(String text) {
    pp('$mm .... _runFilter: text: $text ......');
    if (text.isEmpty) {
      pp('$mm .... text is empty ......');
      carsToDisplay.clear();
      for (var project in cars) {
        carsToDisplay.add(project);
      }
      setState(() {});
      return;
    }
    carsToDisplay.clear();

    pp('$mm ...  filtering cars that contain: $text from ${_carPlates.length} car plates');
    for (var carPlate in _carPlates) {
      if (carPlate.toLowerCase().contains(text.toLowerCase())) {
        var car = _findVehicle(carPlate);
        if (car != null) {
          carsToDisplay.add(car);
        }
      }
    }
    pp('$mm .... set state with projectsToDisplay: ${carsToDisplay.length} ......');
    setState(() {});
  }

  lm.Vehicle? _findVehicle(String carPlate) {
    for (var car in cars) {
      // pp('$mm ... does ${car.vehicleReg!.toLowerCase()} contain the ${E.appleRed} carPlate: ${carPlate.toLowerCase()} ??');
      if (car.vehicleReg!.toLowerCase() == carPlate.toLowerCase()) {
        pp('$mm ..................................${E.leaf} ${E.leaf} found a car! $carPlate');
        return car;
      }
    }
    pp('$mm ..................................${E.redDot} ${E.redDot} DID NOT FIND $carPlate');

    return null;
  }

  void _close(lm.Vehicle country) {
    pp('$mm Vehicle selected: ${country.vehicleReg}, popping out');
  }

  String? search, searchVehicles;
  @override
  void dispose() {
    _controller.dispose();
    compSubscription.cancel();
    super.dispose();
  }

  final TextEditingController _textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Association Vehicles',
                style: myTextStyleMediumLargeWithColor(
                    context, Theme.of(context).primaryColorLight, 16),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      _getVehicles();
                    },
                    icon: const Icon(Icons.refresh))
              ],
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                                child: TextField(
                                  controller: _textEditingController,
                                  onChanged: (text) {
                                    pp(' ........... changing to: $text');
                                    _runFilter(text);
                                  },
                                  decoration: InputDecoration(
                                      label: Text(
                                        search == null ? 'Search' : search!,
                                        style: myTextStyleSmall(
                                          context,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.search,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      border: const OutlineInputBorder(),
                                      hintText: searchVehicles == null
                                          ? 'Search Vehicles'
                                          : searchVehicles!,
                                      hintStyle: myTextStyleSmallWithColor(
                                          context,
                                          Theme.of(context).primaryColor)),
                                )),
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          bd.Badge(
                            position: bd.BadgePosition.topEnd(),
                            badgeContent: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${carsToDisplay.length}',
                                  style: myTextStyleSmallWithColor(
                                      context, Colors.white)),
                            ),
                          )
                        ],
                      )
                    ],
                  )),
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
                    : initializing
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                backgroundColor: Colors.yellow,
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
                                        itemCount: carsToDisplay.length,
                                        itemBuilder: (ctx, index) {
                                          final ass =
                                              carsToDisplay.elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              _onCarSelected(ass);
                                            },
                                            child: Card(
                                              shape:
                                                  getRoundedBorder(radius: 16),
                                              elevation: 4,
                                              child: ListTile(
                                                title: Text(
                                                  '${ass.vehicleReg}',
                                                  style: myTextStyleMediumBold(
                                                      context),
                                                ),
                                                subtitle: Text(
                                                  '${ass.make} ${ass.model} - ${ass.year}',
                                                  style:
                                                      myTextStyleSmall(context),
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
                        left: 24,
                        right: 24,
                        bottom: 60,
                        top: 60,
                        child: Card(
                          shape: getRoundedBorder(radius: 16),
                          elevation: 16,
                          child: SizedBox(
                            height: 460,
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
                                    height: 32,
                                  ),
                                  Text(
                                    '${car!.vehicleReg}',
                                    style: myTextStyleMediumLargeWithColor(
                                        context, Colors.teal[400]!, 32),
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
                                            context, Colors.amber[700]!, 28),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 64,
                                  ),
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
