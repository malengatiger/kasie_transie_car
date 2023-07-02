import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:flutter/material.dart';
import 'package:kasie_transicar/ui/association_list.dart';
import 'package:kasie_transicar/ui/dashboard.dart';
import 'package:kasie_transicar/widgets/splash_page.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/messaging/heartbeat.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:page_transition/page_transition.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

late fb.FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
var themeIndex = 0;
Locale? locale;
const mx = '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵 KasieTransie Car : main 🔵🔵';
Vehicle? vehicle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await fb.Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('\n\n$mx '
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user\n');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;
  vehicle = await prefs.getCar();
  if (vehicle == null) {
    pp('$mx  this car has not been initialized yet');
  } else {
    pp('$mx  this car has been initialized! : ${vehicle!.vehicleReg}');

  }
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );
  // deviceBackgroundLocation.initialize();
  //
  // GeolocatorPlatform.instance.

  runApp(const KasieTransieCarApp());
}

class KasieTransieCarApp extends StatelessWidget {
  const KasieTransieCarApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: themeBloc.localeAndThemeStream,
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            pp(' 🔵 🔵 🔵'
                'build: theme index has changed to ${snapshot.data!.themeIndex}'
                '  and locale is ${snapshot.data!.locale.toString()}');
            themeIndex = snapshot.data!.themeIndex;
            locale = snapshot.data!.locale;
            pp(' 🔵 🔵 🔵 GeoApp: build: locale object received from stream: $locale');
          }

          return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'KasieTransie',
              theme: themeBloc.getTheme(themeIndex).lightTheme,
              darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
              themeMode: ThemeMode.system,
              home: AnimatedSplashScreen(
                splash: const SplashWidget(),
                animationDuration: const Duration(milliseconds: 2000),
                curve: Curves.easeInCirc,
                splashIconSize: 160.0,
                nextScreen: vehicle == null? const AssociationList() : const Dashboard(),
                splashTransition: SplashTransition.fadeTransition,
                pageTransitionType: PageTransitionType.leftToRight,
                backgroundColor: Colors.purple.shade700,
              ));
        });

  }
}