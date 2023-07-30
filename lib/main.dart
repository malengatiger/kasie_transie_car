import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:flutter/material.dart';
import 'package:kasie_transicar/ui/dashboard.dart';
import 'package:kasie_transicar/widgets/splash_page.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:page_transition/page_transition.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

late fb.FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
var themeIndex = 0;
// String? locale;
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
    pp('$mx  this car has NOT been initialized yet ${E.redDot}');
  } else {
    pp('$mx  this car has been initialized! ${E.leaf}: ${vehicle!.vehicleReg}');
  }
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );

  // fcmBloc.initialize();
  runApp(const KasieTransieCarApp());
}

class KasieTransieCarApp extends StatelessWidget {
  const KasieTransieCarApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        pp('$mx 🌀🌀🌀🌀 Tap detected; should dismiss keyboard ...');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder(
          stream: themeBloc.localeAndThemeStream,
          builder: (ctx, snapshot) {
            if (snapshot.hasData) {
              pp(' 🔵 🔵 🔵'
                  'build: theme index has changed to ${snapshot.data!.themeIndex}'
                  '  and locale is ${snapshot.data!.locale.toString()}');
              themeIndex = snapshot.data!.themeIndex;
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
                  nextScreen: const Dashboard(),
                  splashTransition: SplashTransition.fadeTransition,
                  pageTransitionType: PageTransitionType.leftToRight,
                  backgroundColor: Colors.purple.shade700,
                ));
          }),
    );
  }
}

callbackDispatcher() {
}
