import 'package:flutter/material.dart';
import 'package:intercom_flutter/intercom_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const darkNavy = Color(0xFF00171F);
  static const deepBlue = Color(0xFF003459);
  static const cyanBlue = Color(0xFF007EA7);
  static const brightCyan = Color(0xFF00A8E8);
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  
  runApp(const MyApp());
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
      title: 'Urban Route',
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
      initialRoute: devMode ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/profile/settings': (context) => const ProfileSettingsPage(),
        '/navigate': (context) => const NavigatePage(),
      },
    );
  }
}