import 'package:flutter/material.dart';
import 'package:intercom_flutter/intercom_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/bottom_nav_bar.dart';
import 'pages/report_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pages/map_page.dart';
import 'package:flutter/services.dart';
import 'pages/profile_settings_page.dart';
import 'pages/navigate.dart';
import 'pages/home_page.dart';
import 'pages/report_annotation_page.dart';
import 'services/supabase_logging.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const darkNavy = Color(0xFF00171F);
  static const deepBlue = Color(0xFF003459);
  static const cyanBlue = Color(0xFF007EA7);
  static const brightCyan = Color(0xFF00A8E8);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init localization - this should get the system locale and save it
  await EasyLocalization.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Intercom with environment variables
  await Intercom.instance.initialize(
    dotenv.env['INTERCOM_APP_ID']!,
    iosApiKey: dotenv.env['INTERCOM_IOS_API_KEY']!,
    androidApiKey: dotenv.env['INTERCOM_ANDROID_API_KEY']!,
  );
  
  // Register an unidentified user
  await Intercom.instance.loginUnidentifiedUser();
  
  final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
    SupabaseLogging.logEvent(eventType: 'User is authenticated! User ID: ${user.id}');
  } else {
    SupabaseLogging.logError(eventType: 'User is NOT authenticated!', description: 'User is NOT authenticated!', statusCode: 401, error: 'User is NOT authenticated!');
  }
  
  // Load saved language preference or default to device locale
  // setup the initial locale
  final prefs = await SharedPreferences.getInstance();
  String? savedLanguage = prefs.getString('language');
  Locale initialLocale = savedLanguage != null 
      ? Locale(savedLanguage) 
      : Locale('en');
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: initialLocale,
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;
  final bool devMode = dotenv.env['DEV_MODE'] == 'true';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'common.app_name'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F8DED), // Intercom blue color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1F8DED),
        ),
      ),
      builder: (context, child) {
        return Scaffold(
          body: child,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 56.0),
            child: FloatingActionButton(
              onPressed: () {
                Intercom.instance.displayMessenger();
              },
              shape: const CircleBorder(),
              child: Icon(
                Icons.messenger,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
      initialRoute: devMode ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/profile/settings': (context) => const ProfileSettingsPage(),
        '/navigate': (context) => const NavigatePage(),
        '/report/annotation': (context) => const ReportAnnotationPage(),
        '/map': (context) => const MapPage(),
        '/report': (context) => const ReportPage(),
      },
    );
  }
}