import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transicar/ui/car_qrcode.dart';
import 'package:kasie_transicar/ui/vehicle_list.dart';
import 'package:kasie_transie_library/bloc/dispatch_helper.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/data/color_and_locale.dart';
import 'package:kasie_transie_library/data/counter_bag.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/maps/association_route_maps.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/messaging/heartbeat.dart';
import 'package:kasie_transie_library/utils/device_background_location.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/auth/cell_auth_signin.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
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
  late StreamSubscription<lm.DispatchRecord> dispatchSub;
  late StreamSubscription<lm.VehicleHeartbeat> heartbeatSub;
  late StreamSubscription<lm.VehicleArrival> arrivalSub;
  late StreamSubscription<lm.VehicleDeparture> departureSub;

  bool _showVerifier = true;
  bool _showDashboard = false;
  String? arrivalsText,
      departuresText,
      ownerText,
      heartbeatsText,
      dispatchText,
      dashboardText;

  String? routeId;
  late ColorAndLocale colorAndLocale;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _setTexts();
    _getCar();
  }

  void _listen() async {
    dispatchSub = fcmBloc.dispatchStream.listen((event) {
      pp('$mm ... dispatchStream delivered a dispatch ${event.vehicleReg}');
      if (car!.vehicleId == event.vehicleId) {
        dispatches++;
        if (mounted) {
          setState(() {});
        }
      }
    });
    heartbeatSub = fcmBloc.heartbeatStreamStream.listen((event) {
      pp('$mm ... heartbeatStreamStream delivered a heartbeat ${event.vehicleReg}');
      if (car!.vehicleId == event.vehicleId) {
        heartbeats++;
        if (mounted) {
          setState(() {});
        }
      }
    });
    arrivalSub = fcmBloc.vehicleArrivalStream.listen((event) {
      pp('$mm ... vehicleArrivalStream delivered an arrival ${event.vehicleReg}');
      if (car!.vehicleId == event.vehicleId) {
        arrivals++;
        if (mounted) {
          setState(() {});
        }
      }
    });
    departureSub = fcmBloc.vehicleDepartureStream.listen((event) {
      pp('$mm ... vehicleDepartureStream delivered an arrival ${event.vehicleReg}');
      if (car!.vehicleId == event.vehicleId) {
        departures++;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future _setTexts() async {
    colorAndLocale = await prefs.getColorAndLocale();
    arrivalsText =
        await translator.translate('arrivals', colorAndLocale.locale);
    departuresText =
        await translator.translate('departures', colorAndLocale.locale);
    heartbeatsText =
        await translator.translate('heartbeats', colorAndLocale.locale);
    dispatchText =
        await translator.translate('dispatches', colorAndLocale.locale);
    dashboardText =
        await translator.translate('dashboard', colorAndLocale.locale);
    ownerText = await translator.translate('owner', colorAndLocale.locale);
    setState(() {});
  }

  Future _initialize() async {
    pp('\n\n$mm initialize ...');
    await theGreatGeofencer.buildGeofences();
    await fcmBloc.subscribeForCar('CarApp');
    heartbeat.startHeartbeat();
    deviceBackgroundLocation.initialize();

    routeChangesSub = fcmBloc.routeChangesStream.listen((event) {
      pp('$mm routeChangesStream delivered a routeId: $event');
      routeId = event;
      setState(() {});
      if (mounted) {
        showSnackBar(
            message:
                "A Route update has been issued. The download will happen automatically.",
            context: context);
      }
    });

  }

  List<CounterBag> counts = [];

  Future _getCounts() async {
    pp('$mm ... get counts ...');
    counts = await listApiDog.getVehicleCounts(car!.vehicleId!);
    if (counts.isNotEmpty) {
      for (var value in counts) {
        switch (value.description) {
          case 'VehicleArrival':
            arrivals = value.count!;
            break;
          case 'VehicleDeparture':
            departures = value.count!;
            break;
          case 'DispatchRecord':
            dispatches = value.count!;
            break;
          case 'VehicleHeartbeat':
            heartbeats = value.count!;
            break;
        }
      }
    }
    setState(() {});
  }

  void _getCar() async {
    car = await prefs.getCar();
    if (car != null) {
      pp('$mm ........... resident car:');
      myPrettyJsonPrint(car!.toJson());
      setState(() {
        _showVerifier = false;
        _showDashboard = true;
      });
      await _getCounts();
      _initialize();
    } else {
      setState(() {
        _showVerifier = true;
        _showDashboard = false;
      });
    }
  }

  Future<void> _navigateToVehicleList() async {

    final ass = await prefs.getAssociation();
    try {
      if (mounted && ass != null) {
        final res = await navigateWithScale( VehicleList(association: ass,), context);
        if (res is lib.Vehicle) {
              pp('$mm ... back from vehicle list ... car: ${res.vehicleReg}');
              if (mounted) {
                setState(() {
                  car = res;
                });
              }
              _initialize();
            }

        _getCar();
      }
    } catch (e) {
      pp(e);
    }
  }

  void _navigateToMap() {
    navigateWithScale(const AssociationRouteMaps(), context);
  }

  void _navigateToQRCode() {
    if (car != null) {
      navigateWithScale(CarQrcode(vehicle: car!), context);
    }
  }

  void _navigateToColor() async {
    final colorAndLocale =
        await navigateWithScale( LanguageAndColorChooser(onLanguageChosen: (){},), context);
    if (colorAndLocale == null) {
      return;
    }
    _setTexts();
  }

  @override
  void dispose() {
    _controller.dispose();
    routeChangesSub.cancel();
    super.dispose();
  }

  void getDirections() async {
    pp('$mm directions should be here by now ... ');
  }

  @override
  Widget build(BuildContext context) {
    pp('$mm .... build method .... ${E.redDot} check that this happens before going to car list');
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              leading: const SizedBox(),
              title: Text(
                dashboardText == null ? 'Dashboard' : dashboardText!,
                style: myTextStyleMediumLargeWithColor(
                    context, Theme.of(context).primaryColorLight, 16),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      _navigateToColor();
                    },
                    icon: Icon(
                      Icons.color_lens,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      _navigateToMap();
                    },
                    icon: Icon(
                      Icons.map,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      _navigateToQRCode();
                    },
                    icon: Icon(
                      Icons.qr_code,
                      color: Theme.of(context).primaryColor,
                    )),

              ],
            ),
            body: Stack(
              children: [
                _showDashboard
                    ? Card(
                        shape: getRoundedBorder(radius: 16),
                        elevation: 2,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 64,
                            ),
                            GestureDetector(
                              onTap: () {
                                _getCounts();
                              },
                              child: Text(
                                car == null ? '' : '${car!.vehicleReg}',
                                style: myTextStyleLargePrimaryColor(context),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              car == null
                                  ? ''
                                  : '${car!.make} ${car!.model} - ${car!.year}',
                              style: myTextStyleMedium(context),
                            ),
                            const SizedBox(
                              height: 48,
                            ),
                            Text(
                              ownerText == null ? 'Owner' : ownerText!,
                              style: myTextStyleSmall(context),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              car == null
                                  ? ''
                                  : car!.ownerName == null
                                      ? 'Owner Unknown'
                                      : car!.ownerName!,
                              style:
                                  myTextStyleMediumLargeWithSize(context, 20),
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: GestureDetector(
                                onTap: () {
                                  _getCounts();
                                },
                                child: GridView(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 2,
                                          crossAxisSpacing: 2),
                                  children: [
                                    NumberWidget(
                                        title: arrivalsText == null
                                            ? 'Arrivals'
                                            : arrivalsText!,
                                        number: arrivals),
                                    NumberWidget(
                                        title: departuresText == null
                                            ? 'Departures'
                                            : departuresText!,
                                        number: departures),
                                    NumberWidget(
                                        title: heartbeatsText == null
                                            ? 'Heartbeats'
                                            : heartbeatsText!,
                                        number: heartbeats),
                                    NumberWidget(
                                        title: dispatchText == null
                                            ? 'Dispatches'
                                            : dispatchText!,
                                        number: dispatches),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        ),
                      )
                    : const SizedBox(),
                _showVerifier
                    ? CustomPhoneVerification(
                        onUserAuthenticated: (user) {
                          setState(() {
                            _showDashboard = true;
                            _showVerifier = false;
                          });
                          _navigateToVehicleList();
                        },
                        onError: () {},
                        onCancel: () {}, onLanguageChosen: (){},)
                    : const SizedBox(),
              ],
            )));
  }
}

class NumberWidget extends StatelessWidget {
  const NumberWidget({Key? key, required this.title, required this.number})
      : super(key: key);

  final String title;
  final int number;

  @override
  Widget build(BuildContext context) {
    final num = NumberFormat.decimalPattern().format(number);
    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 8,
      child: SizedBox(
        height: 120,
        width: 120,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                num,
                style: myNumberStyleLargerWithColor(
                    Theme.of(context).primaryColor, 32, context),
              ),
              gapH4,
              Text(
                title,
                style: myTextStyleSmall(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
