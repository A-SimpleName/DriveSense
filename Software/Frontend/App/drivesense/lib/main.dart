import 'package:drivesense/pages/sign_in_page.dart';
import 'package:drivesense/pages/sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/pages/main_page.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
import 'package:drivesense/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:drivesense/services/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.getInstance();
  String token = ""; // TODO: get token from secure storage

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(token: token,));
}

class MyApp extends StatelessWidget {
  final String? token;

  const MyApp({super.key, this.token});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveSense',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryPurple),
      ),
      initialRoute: SignInAndSignUp.redirectToHome(token: token),
      routes: {
        'MainPage': (context) => const MainPage(),
        'SignInPage': (context) => const SignInPage(),
        'SignUpPage': (context) => const SignUpPage(),
      },
    );
  }
}