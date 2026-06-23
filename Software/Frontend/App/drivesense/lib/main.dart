import 'package:drivesense/pages/profile_select_page.dart';
import 'package:drivesense/pages/imprint_page.dart';
import 'package:drivesense/pages/privacy_policy_page.dart';
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
import 'package:drivesense/services/deep_link_service.dart';

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
class MyApp extends StatefulWidget {
  /// Restored account token, if a previous session is available.
  final String? token;

  const MyApp({super.key, this.token});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.initialize();
    });
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveSense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryDarkBlue),
      ),
      initialRoute: SignInAndSignUp.redirectToProfileSelectPage(
        token: widget.token,
      ),
      onGenerateRoute: _generateRoute,
      routes: {
        'MainPage': (context) => const MainPage(),
        'SignInPage': (context) => const SignInPage(),
        'SignUpPage': (context) => const SignUpPage(),
        'ForgotPasswordPage': (context) => const ForgotPasswordPage(),
        'ProfileSelectPage': (context) => const ProfileSelectPage(),
        'AccountPage': (context) => const AccountPage(),
        'ChangePasswordPage': (context) => const ChangePasswordPage(),
        'ImprintPage': (context) => const ImprintPage(),
        'PrivacyPolicyPage': (context) => const PrivacyPolicyPage(),
        'ResetPasswordPage': (context) {
          final Map<String, String> args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return ResetPasswordPage(email: args['email']!, code: args['code']!);
        },
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';
    final Uri? uri = Uri.tryParse(routeName);

    if (uri != null && _isInviteRoute(uri)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeepLinkService.handleUri(uri);
      });

      return MaterialPageRoute<void>(
        settings: RouteSettings(
          name: SignInAndSignUp.redirectToProfileSelectPage(
            token: widget.token,
          ),
        ),
        builder: (BuildContext context) {
          if ((widget.token ?? '').isEmpty) {
            return const SignInPage();
          }
          return const ProfileSelectPage();
        },
      );
    }

    return null;
  }

  bool _isInviteRoute(Uri uri) {
    final bool isRelativeInvite = uri.path == '/invite';
    final bool isWebInvite =
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'drivesense.htl-perg.ac.at' &&
        uri.path == '/invite';
    final bool isCustomInvite =
        uri.scheme == 'drivesense' && uri.host == 'invite';

    return isRelativeInvite || isWebInvite || isCustomInvite;
  }
}
