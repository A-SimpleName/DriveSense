import 'package:drivesense/pages/profile_select_page.dart';
import 'package:drivesense/pages/sign_in_page.dart';
import 'package:drivesense/pages/forgot_password_page.dart';
import 'package:drivesense/pages/sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/pages/main_page.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
import 'package:drivesense/services/trip_tracking_service.dart';
import 'package:drivesense/config/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/pages/account_page.dart';
import 'package:drivesense/pages/change_password_page.dart';
import 'package:drivesense/pages/reset_password_page.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/auth_http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TripTrackingService.initializeForegroundTask();
  await dotenv.load(fileName: '.env');
  await IsarService.getInstance();
  await AuthHttpClient.restoreSession();
  final String token = RuntimeStore.getAuthToken() ?? '';

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(token: token));
}

/// Root widget that wires restored session state into the initial route.
class MyApp extends StatelessWidget {
  /// Restored account token, if a previous session is available.
  final String? token;

  const MyApp({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveSense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryPurple),
      ),
      initialRoute: SignInAndSignUp.redirectToProfileSelectPage(token: token),
      routes: {
        'MainPage': (context) => const MainPage(),
        'SignInPage': (context) => const SignInPage(),
        'SignUpPage': (context) => const SignUpPage(),
        'ForgotPasswordPage': (context) => const ForgotPasswordPage(),
        'ProfileSelectPage': (context) => const ProfileSelectPage(),
        'AccountPage': (context) => const AccountPage(),
        'ChangePasswordPage': (context) => const ChangePasswordPage(),
        'ResetPasswordPage': (context) {
          final Map<String, String> args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return ResetPasswordPage(email: args['email']!, code: args['code']!);
        },
      },
    );
  }
}
